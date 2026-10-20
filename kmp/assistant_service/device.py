"""Persistent, account-bound outbound phone command channel. No retailer cookies."""
import asyncio
from datetime import datetime, timezone
import json
import time
from uuid import uuid4
import weakref

import aiosqlite
from fastapi import HTTPException

from .clients import UpstreamUnavailable
from .provenance import envelope_identity, ProvenanceInvalid


class DeviceBroker:
    def __init__(self, path, store_lookup):
        self.path = path
        self.store_lookup = store_lookup
        self.locks = weakref.WeakValueDictionary()

    async def initialize(self):
        async with aiosqlite.connect(self.path) as db:
            await db.executescript("""
                CREATE TABLE IF NOT EXISTS devices (
                    owner TEXT NOT NULL, device_id TEXT NOT NULL, last_seen REAL NOT NULL,
                    PRIMARY KEY(owner, device_id)
                );
                CREATE TABLE IF NOT EXISTS device_store_bindings (
                    owner TEXT NOT NULL, device_id TEXT NOT NULL, store_id INTEGER NOT NULL,
                    sap_id TEXT NOT NULL, verified_at REAL NOT NULL, expires_at REAL NOT NULL,
                    job_id TEXT NOT NULL, evidence TEXT NOT NULL,
                    PRIMARY KEY(owner, device_id, store_id)
                );
                CREATE TABLE IF NOT EXISTS device_jobs (
                    id TEXT PRIMARY KEY, owner TEXT NOT NULL, device_id TEXT NOT NULL,
                    operation TEXT NOT NULL, store_id INTEGER NOT NULL, sap_id TEXT NOT NULL,
                    arguments TEXT NOT NULL, created_at REAL NOT NULL, expires_at REAL NOT NULL,
                    status TEXT NOT NULL, result TEXT
                );
                CREATE INDEX IF NOT EXISTS device_job_queue ON device_jobs(owner,device_id,status,created_at);
                CREATE UNIQUE INDEX IF NOT EXISTS device_job_active ON device_jobs(owner,device_id) WHERE status='pending';
            """)
            await db.commit()

    def bound(self, owner, device_id):
        return BoundDevice(self, owner, device_id)

    async def connected(self, owner, device_id):
        if not device_id:
            return False
        async with aiosqlite.connect(self.path) as db:
            async with db.execute("SELECT last_seen FROM devices WHERE owner=? AND device_id=?", (owner, device_id)) as cursor:
                row = await cursor.fetchone()
        return bool(row and row[0] > time.time() - 35)

    async def poll(self, owner, device_id):
        now = time.time()
        async with aiosqlite.connect(self.path) as db:
            db.row_factory = aiosqlite.Row
            await db.execute("INSERT INTO devices(owner,device_id,last_seen) VALUES(?,?,?) ON CONFLICT(owner,device_id) DO UPDATE SET last_seen=excluded.last_seen", (owner, device_id, now))
            await db.execute("UPDATE device_jobs SET status='expired' WHERE status='pending' AND expires_at<=?", (now,))
            async with db.execute("SELECT * FROM device_jobs WHERE owner=? AND device_id=? AND status='pending' AND expires_at>? ORDER BY created_at LIMIT 1", (owner, device_id, now)) as cursor:
                row = await cursor.fetchone()
            # Keep completed job payloads for one day for duplicate-result/retry handling.
            await db.execute("DELETE FROM device_jobs WHERE expires_at<? AND status!='pending'", (now - 86400,))
            await db.commit()
        if row is None:
            return {"command": None}
        return {"command": {"id": row["id"], "operation": row["operation"], **json.loads(row["arguments"]), "sap_id": row["sap_id"] or None, "expires_at": datetime.fromtimestamp(row["expires_at"], timezone.utc).isoformat()}}

    async def result(self, owner, device_id, job_id, result):
        encoded = json.dumps(result, ensure_ascii=False, allow_nan=False, sort_keys=True, separators=(",", ":"))
        if len(encoded.encode()) > 500_000:
            raise HTTPException(413, "device_result_too_large")
        async with aiosqlite.connect(self.path) as db:
            db.row_factory = aiosqlite.Row
            await db.execute("BEGIN IMMEDIATE")
            async with db.execute("SELECT * FROM device_jobs WHERE id=? AND owner=? AND device_id=?", (job_id, owner, device_id)) as cursor:
                job = await cursor.fetchone()
            if job is None:
                raise HTTPException(404, "device_job_not_found")
            if job["status"] == "done":
                if job["result"] != encoded:
                    raise HTTPException(409, "device_result_conflict")
                return {"accepted": True, "replayed": True}
            if job["status"] != "pending" or job["expires_at"] <= time.time():
                raise HTTPException(409, "device_job_expired")
            # A successful product response is bound to the immutable job SAP.
            # Only an official-store select job may discover a previously unknown SAP.
            if result.get("done") and not result.get("error"):
                store = result.get("store")
                if not isinstance(store, dict):
                    raise HTTPException(422, "device_store_invalid")
                sap = self.numeric_sap(store.get("sap_id"))
                if type(store.get("id")) is not int or store["id"] != job["store_id"] or sap is None or (job["sap_id"] and sap != job["sap_id"]):
                    raise HTTPException(409, "device_store_mismatch")
                captured_at = result.get("captured_at_ms")
                if type(captured_at) is not int or not job["created_at"] - 60 <= captured_at / 1000 <= time.time() + 60:
                    raise HTTPException(422, "device_timestamp_invalid")
                try:
                    identity = envelope_identity(result, expected_transport="https_device_poll")
                except ProvenanceInvalid as exc:
                    raise HTTPException(422, str(exc)) from exc
                if not job["sap_id"]:
                    if result.get("done") is not True:
                        raise HTTPException(422, "device_discovery_evidence_invalid")
                    if job["operation"] != "select_store" or self.store_lookup(job["store_id"]) is None:
                        raise HTTPException(409, "device_store_mismatch")
                    evidence = self.discovery_evidence(result, job["store_id"], sap, identity)
                    # Another still-valid binding cannot be overwritten by a
                    # stale job. Discovery and job completion commit together.
                    async with db.execute("SELECT sap_id,expires_at FROM device_store_bindings WHERE owner=? AND device_id=? AND store_id=?", (owner, device_id, job["store_id"])) as cursor:
                        existing = await cursor.fetchone()
                    if existing and existing["expires_at"] > time.time() and existing["sap_id"] != sap:
                        raise HTTPException(409, "device_sap_binding_conflict")
                    await db.execute("""INSERT INTO device_store_bindings(owner,device_id,store_id,sap_id,verified_at,expires_at,job_id,evidence)
                        VALUES(?,?,?,?,?,?,?,?) ON CONFLICT(owner,device_id,store_id) DO UPDATE SET
                        sap_id=excluded.sap_id,verified_at=excluded.verified_at,expires_at=excluded.expires_at,
                        job_id=excluded.job_id,evidence=excluded.evidence""",
                        (owner, device_id, job["store_id"], sap, time.time(), time.time()+86400, job_id, json.dumps(evidence, ensure_ascii=False)))
                if job["operation"] in ("search_products", "get_product"):
                    from .assistant import _extract_products
                    try:
                        products = _extract_products(result, job["operation"], job["store_id"], expected_transport="https_device_poll", expected_sap=job["sap_id"])
                        if job["operation"] == "get_product":
                            expected_id = json.loads(job["arguments"])["product_id"]
                            if not products or any(product["product_id"] != expected_id for product in products):
                                raise UpstreamUnavailable("retailer_product_mismatch")
                    except UpstreamUnavailable as exc:
                        raise HTTPException(422, str(exc)) from exc
            await db.execute("UPDATE device_jobs SET result=?,status='done' WHERE id=?", (encoded, job_id))
            await db.execute("UPDATE devices SET last_seen=? WHERE owner=? AND device_id=?", (time.time(), owner, device_id))
            await db.commit()
        return {"accepted": True, "replayed": False}

    @staticmethod
    def numeric_sap(value):
        if type(value) is int:
            value = str(value)
        return value if isinstance(value, str) and value.isascii() and value.isdigit() and 1 <= len(value) <= 12 and int(value) > 0 else None

    @staticmethod
    def discovery_evidence(result, store_id, sap, identity):
        """Require a real fixed-origin pickup response, never caller-supplied URLs."""
        if not isinstance(result.get("provenance"), dict):
            raise HTTPException(422, "device_discovery_provenance_missing")
        if result.get("origin") != "https://www.perekrestok.ru":
            raise HTTPException(422, "device_discovery_origin_invalid")
        rows = result.get("results")
        matches = [row for row in rows if isinstance(row, dict) and row.get("operation") == "select_store"] if isinstance(rows, list) else []
        if len(matches) != 1:
            raise HTTPException(422, "device_discovery_evidence_missing")
        row = matches[0]
        expected_url = f"https://www.perekrestok.ru/api/customer/1.4.1.0/delivery/mode/pickup/{store_id}"
        if (row.get("response_url") != expected_url or row.get("request_method") != "PUT" or
                row.get("http_status") != 200 or row.get("mode") != "catalog" or
                type(row.get("shop_id")) is not int or row["shop_id"] != store_id or
                DeviceBroker.numeric_sap(row.get("sap_id")) != sap):
            raise HTTPException(422, "device_discovery_evidence_invalid")
        return {"origin": result["origin"], "response_url": expected_url, "request_method": "PUT",
                "shop_id": store_id, "sap_id": sap, "captured_at_ms": result["captured_at_ms"], **identity}

    async def resolved_sap(self, owner, device_id, store_id, store):
        # Two historical directory SAPs stay usable by older clients. Learned
        # values never become global directory facts or cross-device bindings.
        admitted = self.numeric_sap(store.get("sap_id"))
        if admitted is not None:
            return admitted
        async with aiosqlite.connect(self.path) as db:
            async with db.execute("SELECT sap_id FROM device_store_bindings WHERE owner=? AND device_id=? AND store_id=? AND expires_at>?", (owner, device_id, store_id, time.time())) as cursor:
                row = await cursor.fetchone()
        return row[0] if row else None

    async def execute(self, owner, device_id, operation, args):
        if not device_id:
            raise UpstreamUnavailable("device_id_required")
        if operation not in ("select_store", "search_products", "get_product"):
            raise UpstreamUnavailable("device_operation_forbidden")
        store_id = args.get("store_id")
        store = self.store_lookup(store_id) if type(store_id) is int and store_id > 0 else None
        if not store:
            raise UpstreamUnavailable("retailer_store_unsupported")
        allowed = {"store_id"}
        if operation == "search_products":
            allowed |= {"query", "page"}
            if not isinstance(args.get("query"), str) or not 1 <= len(args["query"].strip()) <= 100 or type(args.get("page", 1)) is not int or not 1 <= args.get("page", 1) <= 20:
                raise UpstreamUnavailable("device_arguments_invalid")
        if operation == "get_product":
            allowed.add("product_id")
            if type(args.get("product_id")) is not int or args["product_id"] <= 0:
                raise UpstreamUnavailable("device_arguments_invalid")
        if set(args) - allowed:
            raise UpstreamUnavailable("device_arguments_invalid")
        if not await self.connected(owner, device_id):
            raise UpstreamUnavailable("device_offline")
        key = (owner, device_id)
        lock = self.locks.setdefault(key, asyncio.Lock())
        async with lock:
            sap = await self.resolved_sap(owner, device_id, store_id, store)
            if sap is None and operation != "select_store":
                bootstrap = await self._execute_job(owner, device_id, "select_store", {"store_id": store_id}, "")
                if not bootstrap.get("done") or bootstrap.get("error"):
                    return bootstrap
                sap = await self.resolved_sap(owner, device_id, store_id, store)
                if sap is None:
                    raise UpstreamUnavailable("retailer_store_unverified")
            return await self._execute_job(owner, device_id, operation, args, sap or "")

    async def _execute_job(self, owner, device_id, operation, args, sap):
        now = time.time()
        job_id = str(uuid4())
        async with aiosqlite.connect(self.path) as db:
            await db.execute("BEGIN IMMEDIATE")
            await db.execute("UPDATE device_jobs SET status='expired' WHERE owner=? AND device_id=? AND status='pending' AND expires_at<=?", (owner, device_id, now))
            try:
                await db.execute("INSERT INTO device_jobs(id,owner,device_id,operation,store_id,sap_id,arguments,created_at,expires_at,status) VALUES(?,?,?,?,?,?,?,?,?,'pending')", (job_id, owner, device_id, operation, args["store_id"], sap, json.dumps(args, ensure_ascii=False), now, now + 35))
                await db.commit()
            except aiosqlite.IntegrityError as exc:
                raise UpstreamUnavailable("device_busy") from exc
        try:
            while time.time() < now + 35:
                async with aiosqlite.connect(self.path) as db:
                    async with db.execute("SELECT status,result FROM device_jobs WHERE id=? AND owner=? AND device_id=?", (job_id, owner, device_id)) as cursor:
                        row = await cursor.fetchone()
                if row and row[0] == "done":
                    result = json.loads(row[1])
                    if result.get("done") and not result.get("error"):
                        result.update(envelope_identity(result, expected_transport="https_device_poll"))
                    return result
                await asyncio.sleep(0.25)
            raise UpstreamUnavailable("device_timeout")
        finally:
            async with aiosqlite.connect(self.path) as db:
                await db.execute("UPDATE device_jobs SET status='expired' WHERE id=? AND status='pending'", (job_id,))
                await db.commit()


class BoundDevice:
    def __init__(self, broker, owner, device_id):
        self.broker, self.owner, self.device_id = broker, owner, device_id

    async def call(self, name, args):
        if name == "session_status":
            return {"connected": await self.broker.connected(self.owner, self.device_id)}
        return await self.broker.execute(self.owner, self.device_id, name, args)
