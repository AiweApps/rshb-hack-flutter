"""Deterministic replacement of one saved shopping-list row."""
import json
from copy import deepcopy
from datetime import datetime, timezone
import uuid

import aiosqlite

from .assistant import SNAPSHOT_MAX_AGE, STORE_DIRECTORY, _extract_products
from .clients import RetailClient, UpstreamUnavailable
from .store import SessionStore
from .pricing import priced_product, priced_row
from .provenance import aggregate_identity, is_retail_aggregate, is_retail_product, normalize_product


class ShoppingInvalid(Exception):
    def __init__(self, code: str, status: int = 409):
        self.code = code
        self.status = status
        super().__init__(code)


def current_dinner_option(session: dict, source_message_id: str, option_id: str) -> tuple[dict, dict]:
    latest = None
    source = None
    for message in reversed(session["messages"]):
        if message["role"] != "assistant":
            continue
        for event in message["events"]:
            if event.get("type") != "dinner_options":
                continue
            if latest is None:
                latest = message["id"]
            if message["id"] == source_message_id:
                source = event.get("data")
        if source is not None:
            break
    if source is None:
        raise ShoppingInvalid("dinner_options_not_found", 404)
    if latest != source_message_id:
        raise ShoppingInvalid("dinner_options_stale")
    store_id = source.get("store_id") if isinstance(source, dict) else None
    if STORE_DIRECTORY.get(store_id) is None or store_id != session["store_id"] or not is_retail_aggregate(source):
        raise ShoppingInvalid("shopping_store_changed")
    options = source.get("options")
    if not isinstance(options, list) or not 2 <= len(options) <= 3:
        raise ShoppingInvalid("dinner_options_invalid")
    option = next((item for item in options if isinstance(item, dict) and item.get("id") == option_id), None)
    if option is None:
        raise ShoppingInvalid("dinner_option_not_found", 404)
    rows = option.get("items")
    if not isinstance(rows, list) or not 2 <= len(rows) <= 12:
        raise ShoppingInvalid("dinner_option_invalid")
    now = datetime.now(timezone.utc)
    seen = set()
    for row in rows:
        product = row.get("product") if isinstance(row, dict) else None
        if not isinstance(product, dict):
            raise ShoppingInvalid("dinner_option_invalid")
        product_id = product.get("product_id")
        price = product.get("price_kopeks")
        packages = row.get("packages")
        if (type(product_id) is not int or product_id <= 0 or product_id in seen or
                product.get("store_id") != store_id or not is_retail_product(product) or
                (price is not None and (type(price) is not int or not 0 <= price <= 1_000_000_000)) or
                product.get("balance_state") == "none" or
                type(packages) is not int or not 1 <= packages <= 20):
            raise ShoppingInvalid("dinner_option_invalid")
        checked_at = product.get("checked_at")
        try:
            age = now - datetime.fromisoformat(checked_at.replace("Z", "+00:00"))
        except (AttributeError, TypeError, ValueError):
            raise ShoppingInvalid("dinner_option_invalid") from None
        if not 0 <= age.total_seconds() <= SNAPSHOT_MAX_AGE.total_seconds():
            raise ShoppingInvalid("dinner_option_expired")
        seen.add(product_id)
    return source, option


def selected_dinner_event(source_message_id: str, option: dict, store_id: int) -> tuple[str, dict]:
    rows = []
    total = 0
    unknown_price = False
    for row in option["items"]:
        product = priced_product(normalize_product(row["product"]))
        packages = row["packages"]
        rebuilt = priced_row(product, packages, str(row.get("recipe_quantity") or "")[:60])
        line_total = rebuilt["line_total_kopeks"]
        if line_total is None:
            unknown_price = True
        else:
            total += line_total
        rows.append(rebuilt)
    checked_at = min(row["product"]["checked_at"] for row in rows)
    event = {"type": "shopping_list", "data": {
        "dinner_title": option["title"], "servings": option["servings"],
        "preparation_minutes": option.get("preparation_minutes"),
        "explanation": option.get("explanation"), "dish_type": option.get("dish_type"),
        "pricing_status": "incomplete_price_basis" if unknown_price else "verified_lots",
        "items": rows, "total_kopeks": None if unknown_price else total,
        "currency": "RUB", "store_id": store_id,
        **aggregate_identity(row["product"] for row in rows), "data_mode": "saved_snapshot",
        "checked_at": checked_at, "source_message_id": source_message_id,
        "selected_option_id": option["id"],
    }}
    text = f"Выбран ужин «{option['title']}». Список составлен по сохранённым данным магазина. Перед покупкой проверьте цены."
    return text, event


async def commit_dinner_selection(
    store: SessionStore, session_id: str, source_message_id: str, store_id: int,
    request_id: str, request_hash: str, text: str, event: dict,
) -> tuple[str, dict | None]:
    """Serialize selection against a newer dinner proposal in SQLite."""
    message_id = str(uuid.uuid4())
    async with aiosqlite.connect(store.path) as db:
        db.row_factory = aiosqlite.Row
        await db.execute("BEGIN IMMEDIATE")
        try:
            async with db.execute("SELECT 1 FROM sessions WHERE id=? AND owner=?", (session_id, store.owner)) as cursor:
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
                    async with db.execute("SELECT id,events_json FROM messages WHERE session_id=? AND role='assistant' ORDER BY rowid DESC", (session_id,)) as cursor:
                        rows = await cursor.fetchall()
                    latest = next((row["id"] for row in rows
                                   for item in json.loads(row["events_json"])
                                   if item.get("type") == "dinner_options"), None)
                    if latest != source_message_id:
                        outcome, chosen_id = "stale", None
                    else:
                        await db.execute(
                            "INSERT INTO messages(id,session_id,role,text,events_json,request_id,request_hash) VALUES (?,?,?,?,?,?,?)",
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
    session = await store.get(session_id)
    assert session is not None
    return outcome, next(message for message in session["messages"] if message["id"] == chosen_id)


def restore_meal_metadata(session: dict, data: dict) -> dict:
    """Recover old replacement metadata from its own same-store ancestry on read."""
    result = deepcopy(data)
    source_id = result.get("source_message_id")
    seen = set()
    for _ in range(20):
        if not source_id or source_id in seen:
            break
        seen.add(source_id)
        message = next((m for m in session.get("messages", []) if m.get("id") == source_id and m.get("role") == "assistant"), None)
        if message is None:
            break
        parent = next((e.get("data") for e in message.get("events", []) if e.get("type") == "shopping_list"), None)
        if parent is None:
            proposal = next((e.get("data") for e in message.get("events", []) if e.get("type") == "dinner_options"), None)
            if not isinstance(proposal, dict) or proposal.get("store_id") != result.get("store_id"):
                break
            parent = next((option for option in proposal.get("options", []) if option.get("id") == result.get("selected_option_id")), None)
            if not isinstance(parent, dict):
                break
        elif not isinstance(parent, dict) or parent.get("store_id") != result.get("store_id"):
            break
        for key in ("selected_option_id", "explanation", "preparation_minutes", "dish_type"):
            if result.get(key) is None and parent.get(key) is not None:
                result[key] = parent[key]
        source_id = parent.get("source_message_id")
    return result


def current_list(session: dict, source_message_id: str) -> dict:
    latest_message_id = None
    source = None
    for message in reversed(session["messages"]):
        if message["role"] != "assistant":
            continue
        event = next((item for item in message["events"] if item.get("type") == "shopping_list"), None)
        if event is None:
            continue
        if latest_message_id is None:
            latest_message_id = message["id"]
        if message["id"] == source_message_id:
            source = event.get("data")
            break
    if source is None:
        raise ShoppingInvalid("shopping_list_not_found", 404)
    source = restore_meal_metadata(session, source)
    if latest_message_id != source_message_id:
        raise ShoppingInvalid("shopping_list_stale")
    store_id = source.get("store_id") if isinstance(source, dict) else None
    if STORE_DIRECTORY.get(store_id) is None or store_id != session["store_id"]:
        raise ShoppingInvalid("shopping_store_changed")
    rows = source.get("items")
    if not isinstance(rows, list) or not 1 <= len(rows) <= 12:
        raise ShoppingInvalid("shopping_list_invalid")
    seen = set()
    for row in rows:
        if not isinstance(row, dict) or not isinstance(row.get("product"), dict):
            raise ShoppingInvalid("shopping_list_invalid")
        product = row["product"]
        product_id = product.get("product_id")
        packages = row.get("packages")
        if type(product_id) is not int or product_id <= 0 or product_id in seen or product.get("store_id") != store_id or type(packages) is not int or not 1 <= packages <= 20:
            raise ShoppingInvalid("shopping_list_invalid")
        seen.add(product_id)
    return source


async def live_product(retailer: RetailClient, product_id: int, store_id: int) -> dict:
    raw = await retailer.call("get_product", {"product_id": product_id, "store_id": store_id})
    products = _extract_products(raw, "get_product", store_id,
                                 expected_transport="local_mcp" if isinstance(retailer, RetailClient) else None,
                                 filter_ingredients=True)
    product = next((item for item in products if item["product_id"] == product_id), None)
    if product is None:
        raise ShoppingInvalid("product_not_found")
    price = product["price_kopeks"]
    if price is None or price > 1_000_000_000:
        raise ShoppingInvalid("price_unknown")
    if product["balance_state"] == "none":
        raise ShoppingInvalid("product_unavailable")
    return product


async def replacement_event(
    retailer: RetailClient,
    source: dict,
    source_message_id: str,
    old_product_id: int,
    replacement_product_id: int,
    packages: int,
) -> tuple[str, dict]:
    rows = source["items"]
    old_row = next((row for row in rows if row["product"]["product_id"] == old_product_id), None)
    if old_row is None:
        raise ShoppingInvalid("old_product_not_in_list")
    if old_product_id == replacement_product_id or any(row["product"]["product_id"] == replacement_product_id for row in rows):
        raise ShoppingInvalid("replacement_already_in_list")
    store_id = source["store_id"]
    fresh = {}
    for row in rows:
        product_id = row["product"]["product_id"]
        if product_id != old_product_id:
            fresh[product_id] = await live_product(retailer, product_id, store_id)
    fresh[replacement_product_id] = await live_product(retailer, replacement_product_id, store_id)
    new_rows = []
    total = 0
    unknown_price = False
    for row in rows:
        product_id = row["product"]["product_id"]
        replacing = product_id == old_product_id
        product = fresh[replacement_product_id if replacing else product_id]
        quantity = packages if replacing else row["packages"]
        rebuilt = priced_row(product, quantity, str(row.get("recipe_quantity") or "")[:60])
        line_total = rebuilt["line_total_kopeks"]
        if line_total is None:
            unknown_price = True
        else:
            total += line_total
        new_rows.append(rebuilt)
    validated_at = datetime.now(timezone.utc).isoformat()
    data = {
        "dinner_title": source.get("dinner_title") or "",
        "servings": source.get("servings"),
        "items": new_rows,
        "total_kopeks": None if unknown_price else total,
        "pricing_status": "incomplete_price_basis" if unknown_price else "verified_lots",
        "currency": "RUB",
        "store_id": store_id,
        **aggregate_identity(row["product"] for row in new_rows),
        "store_binding": "session_context",
        "data_mode": "live_catalog",
        "validated_at": validated_at,
        "source_message_id": source_message_id,
        "replaced_product_id": old_product_id,
        "replacement_product_id": replacement_product_id,
    }
    for key in ("selected_option_id", "explanation", "preparation_minutes", "dish_type"):
        if key in source:
            data[key] = source[key]
    rubles, kopeks = divmod(total, 100)
    price_text = "Полный итог и бюджет не подтверждены: неизвестна единица цены, лот или достаточное для рецепта количество части товаров." if unknown_price else f"Сумма лотов магазина: {rubles},{kopeks:02d} ₽."
    if any(row.get("quantity_adjusted") for row in new_rows):
        price_text += " Количество лотов увеличено до массы, нужной для рецепта."
    text = f"Заменил «{old_row['product']['title']}» на «{fresh[replacement_product_id]['title']}». {price_text}"
    return text, {"type": "shopping_list", "data": data}
