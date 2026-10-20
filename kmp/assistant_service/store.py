"""Small session log. Photos and retailer credentials are never stored."""
from __future__ import annotations

import json
from pathlib import Path
import uuid

import aiosqlite


class SessionStore:
    def __init__(self, path: Path, owner: str = "legacy"):
        self.path = path
        self.owner = owner

    def scoped(self, owner: str) -> "SessionStore":
        return SessionStore(self.path, owner)

    async def initialize(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        async with aiosqlite.connect(self.path) as db:
            await db.executescript("""
                PRAGMA journal_mode=WAL;
                CREATE TABLE IF NOT EXISTS sessions (
                    id TEXT PRIMARY KEY,
                    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
                    store_id INTEGER
                );
                CREATE TABLE IF NOT EXISTS messages (
                    id TEXT PRIMARY KEY,
                    session_id TEXT NOT NULL REFERENCES sessions(id),
                    role TEXT NOT NULL,
                    text TEXT NOT NULL,
                    events_json TEXT NOT NULL DEFAULT '[]',
                    request_id TEXT,
                    request_hash TEXT,
                    reply_to TEXT,
                    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
                );
                CREATE INDEX IF NOT EXISTS messages_session ON messages(session_id, created_at);
                CREATE UNIQUE INDEX IF NOT EXISTS messages_request ON messages(session_id, request_id) WHERE request_id IS NOT NULL;
                CREATE UNIQUE INDEX IF NOT EXISTS messages_reply ON messages(reply_to) WHERE reply_to IS NOT NULL;
            """)
            async with db.execute("PRAGMA table_info(sessions)") as cursor:
                columns = {row[1] for row in await cursor.fetchall()}
            if "owner" not in columns:
                await db.execute("ALTER TABLE sessions ADD COLUMN owner TEXT NOT NULL DEFAULT 'legacy'")
            if "store_pending" not in columns:
                await db.execute("ALTER TABLE sessions ADD COLUMN store_pending INTEGER NOT NULL DEFAULT 0")
            await db.execute("CREATE INDEX IF NOT EXISTS sessions_owner ON sessions(owner, created_at)")
            await db.commit()
        self.path.chmod(0o600)

    async def create(self) -> dict:
        session_id = str(uuid.uuid4())
        async with aiosqlite.connect(self.path) as db:
            await db.execute("INSERT INTO sessions(id, owner) VALUES (?,?)", (session_id, self.owner))
            await db.commit()
        return await self.get(session_id)

    async def get(self, session_id: str) -> dict | None:
        async with aiosqlite.connect(self.path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT id, created_at, store_id, store_pending FROM sessions WHERE id=? AND owner=?", (session_id, self.owner)) as cursor:
                row = await cursor.fetchone()
            if row is None:
                return None
            async with db.execute("SELECT id, role, text, events_json, request_id, request_hash, reply_to, created_at FROM messages WHERE session_id=? ORDER BY rowid", (session_id,)) as cursor:
                messages = await cursor.fetchall()
        return {
            "session_id": row["id"], "created_at": row["created_at"], "store_id": row["store_id"], "store_pending": bool(row["store_pending"]),
            "messages": [{"id": m["id"], "role": m["role"], "text": m["text"], "events": json.loads(m["events_json"]), "request_id": m["request_id"], "request_hash": m["request_hash"], "reply_to": m["reply_to"], "created_at": m["created_at"]} for m in messages],
        }

    async def list(self) -> list[dict]:
        async with aiosqlite.connect(self.path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("""
                SELECT s.id, s.created_at, s.store_id,
                       (SELECT text FROM messages m WHERE m.session_id=s.id AND m.role='user' ORDER BY m.created_at, m.rowid LIMIT 1) AS title,
                       (SELECT created_at FROM messages m WHERE m.session_id=s.id ORDER BY m.created_at DESC, m.rowid DESC LIMIT 1) AS updated_at
                FROM sessions s WHERE s.owner=? ORDER BY COALESCE(updated_at, s.created_at) DESC LIMIT 100
            """, (self.owner,)) as cursor:
                rows = await cursor.fetchall()
        return [{"session_id": row["id"], "title": (row["title"] or "Новый диалог")[:80], "created_at": row["created_at"], "updated_at": row["updated_at"] or row["created_at"], "store_id": row["store_id"]} for row in rows]

    async def append(self, session_id: str, role: str, text: str, events: list[dict] | None = None, request_id: str | None = None, request_hash: str | None = None, reply_to: str | None = None) -> dict:
        message_id = str(uuid.uuid4())
        async with aiosqlite.connect(self.path) as db:
            cursor = await db.execute("INSERT INTO messages(id, session_id, role, text, events_json, request_id, request_hash, reply_to) SELECT ?,?,?,?,?,?,?,? WHERE EXISTS(SELECT 1 FROM sessions WHERE id=? AND owner=?)", (message_id, session_id, role, text, json.dumps(events or [], ensure_ascii=False), request_id, request_hash, reply_to, session_id, self.owner))
            if cursor.rowcount != 1:
                raise ValueError("session_not_found")
            await db.commit()
        session = await self.get(session_id)
        assert session is not None
        return next(m for m in session["messages"] if m["id"] == message_id)

    async def find_request(self, session_id: str, request_id: str) -> tuple[dict | None, dict | None]:
        session = await self.get(session_id)
        if session is None:
            return None, None
        user = next((m for m in session["messages"] if m["request_id"] == request_id), None)
        assistant = next((m for m in session["messages"] if user and m["reply_to"] == user["id"]), None)
        return user, assistant

    async def set_store(self, session_id: str, store_id: int) -> None:
        async with aiosqlite.connect(self.path) as db:
            await db.execute("UPDATE sessions SET store_id=? WHERE id=? AND owner=?", (store_id, session_id, self.owner))
            await db.commit()

    async def mark_store_pending(self, session_id: str) -> None:
        async with aiosqlite.connect(self.path) as db:
            await db.execute("UPDATE sessions SET store_id=NULL, store_pending=1 WHERE id=? AND owner=?", (session_id, self.owner))
            await db.commit()

    async def confirm_store(self, session_id: str, store_id: int, request_id: str, request_hash: str, text: str, event: dict) -> dict:
        message_id = str(uuid.uuid4())
        async with aiosqlite.connect(self.path) as db:
            await db.execute("BEGIN IMMEDIATE")
            cursor = await db.execute("UPDATE sessions SET store_id=?,store_pending=0 WHERE id=? AND owner=?", (store_id, session_id, self.owner))
            if cursor.rowcount != 1:
                raise ValueError("session_not_found")
            await db.execute("INSERT INTO messages(id,session_id,role,text,events_json,request_id,request_hash) VALUES(?,?,'assistant',?,?,?,?)", (message_id, session_id, text, json.dumps([event], ensure_ascii=False), request_id, request_hash))
            await db.commit()
        session = await self.get(session_id)
        return next(message for message in session["messages"] if message["id"] == message_id)

    async def commit_replacement(
        self, session_id: str, source_message_id: str, store_id: int,
        request_id: str, request_hash: str, text: str, event: dict,
    ) -> tuple[str, dict | None]:
        """Commit only while source is latest, with a database-wide write lock."""
        message_id = str(uuid.uuid4())
        async with aiosqlite.connect(self.path) as db:
            db.row_factory = aiosqlite.Row
            await db.execute("BEGIN IMMEDIATE")
            try:
                async with db.execute("SELECT 1 FROM sessions WHERE id=? AND owner=?", (session_id, self.owner)) as cursor:
                    if await cursor.fetchone() is None:
                        await db.rollback()
                        return "stale", None
                async with db.execute("SELECT id, role, request_hash FROM messages WHERE session_id=? AND request_id=?", (session_id, request_id)) as cursor:
                    existing = await cursor.fetchone()
                if existing:
                    outcome = "replay" if existing["role"] == "assistant" and existing["request_hash"] == request_hash else "conflict"
                    chosen_id = existing["id"]
                else:
                    async with db.execute("SELECT store_id FROM sessions WHERE id=?", (session_id,)) as cursor:
                        session = await cursor.fetchone()
                    if session is None or session["store_id"] != store_id:
                        outcome, chosen_id = "stale", None
                    else:
                        async with db.execute("SELECT id, events_json FROM messages WHERE session_id=? AND role='assistant' ORDER BY rowid DESC", (session_id,)) as cursor:
                            rows = await cursor.fetchall()
                        latest = next((row["id"] for row in rows if any(item.get("type") == "shopping_list" for item in json.loads(row["events_json"]))), None)
                        if latest != source_message_id:
                            outcome, chosen_id = "stale", None
                        else:
                            await db.execute(
                                "INSERT INTO messages(id, session_id, role, text, events_json, request_id, request_hash) VALUES (?,?,?,?,?,?,?)",
                                (message_id, session_id, "assistant", text, json.dumps([event], ensure_ascii=False), request_id, request_hash),
                            )
                            outcome, chosen_id = "saved", message_id
                if outcome == "saved":
                    await db.commit()
                else:
                    await db.rollback()
            except Exception:
                await db.rollback()
                raise
        if chosen_id is None:
            return outcome, None
        session = await self.get(session_id)
        assert session is not None
        return outcome, next(message for message in session["messages"] if message["id"] == chosen_id)
