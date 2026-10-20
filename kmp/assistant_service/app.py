"""Local HTTP API for the WineScan assistant prototype."""
import asyncio
from contextlib import asynccontextmanager
import hashlib
import re
import weakref
from typing import Literal
from uuid import UUID

from fastapi import Depends, FastAPI, Header, HTTPException, Query
from pydantic import BaseModel, ConfigDict, Field

from .assistant import WineAssistant, _extract_products, _validated_dinner_text, photo_scan_event, wine_event
from .clients import OpenRouterClient, RetailClient, UpstreamUnavailable
from .config import Settings
from .auth import Authenticator, Principal
from .device import DeviceBroker
from .stores import StoreCatalog
from .wine_catalog import wine_catalog
from .pricing import priced_product, reprice_list
from .provenance import aggregate_identity, envelope_identity, normalize_product, NEUTRAL_SOURCE
from .shopping import (ShoppingInvalid, commit_dinner_selection, current_dinner_option,
                       current_list, replacement_event, restore_meal_metadata, selected_dinner_event)
from .store import SessionStore


class SelectedWine(BaseModel):
    model_config = ConfigDict(extra="forbid")
    slug: str = Field(min_length=1, max_length=200)
    title: str = Field(min_length=1, max_length=200)
    producer: str | None = Field(default=None, max_length=200)
    food_pairings: list[str] | None = Field(default=None, max_length=12)
    uncertain: bool = False


class PhotoWine(BaseModel):
    model_config = ConfigDict(extra="forbid")
    photo_number: int = Field(strict=True, ge=1, le=10)
    wine: SelectedWine


class PhotoScan(BaseModel):
    model_config = ConfigDict(extra="forbid")
    photo_number: int = Field(strict=True, ge=1, le=10)
    status: Literal["found", "unknown", "scan_failed"]


class MessageRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    request_id: UUID
    text: str = Field(min_length=1, max_length=4000)
    store_id: int | None = Field(default=None, strict=True, gt=0)
    selected_wine: SelectedWine | None = None
    photo_wines: list[PhotoWine] = Field(default_factory=list, max_length=30)
    comparison_wines: list[SelectedWine] = Field(default_factory=list, max_length=3)
    photo_scans: list[PhotoScan] = Field(default_factory=list, max_length=10)


class ReplacementRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    request_id: UUID
    old_product_id: int = Field(strict=True, gt=0)
    replacement_product_id: int = Field(strict=True, gt=0)
    packages: int = Field(strict=True, ge=1, le=20)


class DinnerSelectionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    request_id: UUID
    option_id: UUID


class DeviceResultRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    device_id: UUID
    id: UUID
    result: dict


class StoreSelectionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    request_id: UUID
    store_id: int = Field(strict=True, gt=0)


def _snapshot(session: dict) -> dict:
    """Read-time compatibility projection; original SQLite bytes stay untouched."""
    for message in session["messages"]:
        incomplete = None
        for event in message["events"]:
            kind = event.get("type")
            if kind == "wine_card":
                event["data"] = wine_catalog().enrich(event["data"])
            if kind not in ("product_options", "shopping_list", "dinner_options"):
                continue
            data = event["data"]
            data["data_mode"] = "saved_snapshot"
            if kind == "product_options":
                data["products"] = [priced_product(normalize_product(product)) for product in data.get("products", [])]
                data.update(aggregate_identity(data["products"], data))
            elif kind == "shopping_list":
                original_total = data.get("total_kopeks")
                original_counts = [row.get("packages") for row in data.get("items", [])]
                event["data"] = data = reprice_list(restore_meal_metadata(session, data))
                for row in data["items"]:
                    row["product"] = normalize_product(row["product"])
                data.update(aggregate_identity(row["product"] for row in data["items"]))
                if data.get("total_kopeks") is None or data.get("total_kopeks") != original_total or [row.get("packages") for row in data["items"]] != original_counts:
                    incomplete = event
            else:
                options = []
                for option in data.get("options", []):
                    original_option = option
                    option = reprice_list(option)
                    if option.get("total_kopeks") != original_option.get("total_kopeks"):
                        incomplete = event
                    for row in option["items"]:
                        row["product"] = normalize_product(row["product"])
                    option.update(aggregate_identity(row["product"] for row in option["items"]))
                    option["data_mode"] = "saved_snapshot"
                    options.append(option)
                data["options"] = options
                data.update(aggregate_identity(row["product"] for option in options for row in option["items"]))
                if any(option.get("total_kopeks") is None for option in options):
                    incomplete = event
        if incomplete is not None:
            # Old text can contain a package-total computed before units survived
            # the bridge. Suppress that unsupported claim in readout and model history.
            text = _validated_dinner_text(incomplete, "Исторический список")
            message["text"] = text
            for event in message["events"]:
                if event.get("type") == "assistant_text":
                    event["data"]["text"] = text
    return session


def _read_message(session: dict, message_id: str) -> dict:
    # Read projection needs the full owned history to recover old replacement
    # selection metadata from its source_message_id ancestry.
    return next(message for message in _snapshot(session)["messages"] if message["id"] == message_id)


def _store_discovery(text: str, store_id: int | None, catalog) -> tuple[str, list[dict]] | None:
    lowered = text.casefold().replace("ё", "е")
    named = bool(re.search(r"перекрест|я (?:сейчас )?в магазин|магазин на|магазине на|бакинск|гоголевск", lowered))
    if named and (store_id is None or re.search(r"^я |нахож|бакинск|гоголевск|на улице| на \w+|смен|друг|адрес|ростов|таганрог|азов", lowered)):
        candidates = catalog.search(text, limit=5)
        if candidates:
            answer = "Нашёл магазины. Подтвердите нужный адрес, чтобы искать товары в его каталоге."
            return answer, [{"type": "assistant_text", "data": {"text": answer}}, {"type": "store_candidates", "data": {"stores": candidates, "requires_confirmation": True}}]
        answer = "Не нашёл этот адрес в справочнике. Укажите город, улицу и дом или определите место. До подтверждения нового магазина не буду искать товары в прежнем."
        return answer, [{"type": "assistant_text", "data": {"text": answer}}, {"type": "location_request", "data": {"reason": "store_not_found"}}]
    return None


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or Settings.from_env()
    base_store = SessionStore(settings.database_path)
    auth = Authenticator(settings)
    catalog = StoreCatalog()
    wines = wine_catalog()
    broker = DeviceBroker(settings.database_path, catalog.get)
    model = OpenRouterClient(settings.openrouter_key, settings.openrouter_model)
    retailer = RetailClient(settings.mcp_script, settings.mcp_python)
    session_locks = weakref.WeakValueDictionary()

    def session_lock(session_id):
        return session_locks.setdefault(session_id, asyncio.Lock())

    def retail_for(principal, device_id):
        return retailer if settings.retailer_mode == "legacy_local" else broker.bound(principal.subject, str(device_id) if device_id else None)

    @asynccontextmanager
    async def lifespan(_app: FastAPI):
        if settings.auth_mode not in ("legacy_local", "verify", "trusted_proxy"):
            raise RuntimeError("WINE_ASSISTANT_AUTH_MODE must be verify, trusted_proxy or legacy_local")
        if settings.auth_mode == "legacy_local" and len(settings.access_token) < 24:
            raise RuntimeError("Legacy local mode needs WINE_ASSISTANT_TOKEN of at least 24 characters")
        if settings.auth_mode == "verify" and not settings.auth_verify_url:
            raise RuntimeError("Set AUTH_VERIFY_URL for server-verified identities")
        if settings.auth_mode == "trusted_proxy" and len(settings.gateway_secret) < 32:
            raise RuntimeError("Trusted proxy mode needs WINE_ASSISTANT_GATEWAY_SECRET of at least 32 characters")
        if settings.retailer_mode not in ("device", "legacy_local"):
            raise RuntimeError("WINE_ASSISTANT_RETAILER_MODE must be device or legacy_local")
        if settings.auth_mode != "legacy_local" and settings.retailer_mode == "legacy_local":
            raise RuntimeError("Shared legacy retailer is forbidden with account authentication")
        await base_store.initialize()
        await broker.initialize()
        try:
            yield
        finally:
            await retailer.close()
            await model.close()
            await auth.close()

    app = FastAPI(title="WineScan assistant", version="0.1.0", lifespan=lifespan, docs_url=None, redoc_url=None)

    async def authorize(authorization: str | None = Header(default=None), x_assistant_gateway: str | None = Header(default=None), x_auth_subject: str | None = Header(default=None)) -> Principal:
        return await auth.verify(authorization, x_assistant_gateway, x_auth_subject)

    async def owned_store(principal: Principal = Depends(authorize)) -> SessionStore:
        return base_store.scoped(principal.subject)

    @app.get("/v1/me")
    async def me(principal: Principal = Depends(authorize)) -> dict:
        return {"subject": principal.subject, "account_kind": principal.account_kind}

    # Search must precede the slug route: "search" is not a product identifier.
    @app.get("/v1/wines/search", dependencies=[Depends(authorize)])
    async def search_wines(query: str = Query(min_length=1, max_length=200),
                           limit: int = Query(default=10, ge=1, le=30)) -> dict:
        cards, total = wines.search(query, limit)
        return {"wines": cards, "total": total, "snapshot": wines.snapshot,
                "catalog_sha256": wines.sha256}

    @app.get("/v1/wines/{slug}", dependencies=[Depends(authorize)])
    async def wine_details(slug: str) -> dict:
        card = wines.get(slug)
        if card is None:
            raise HTTPException(status_code=404, detail="wine_not_found")
        return card

    @app.get("/v1/device/commands")
    async def device_commands(device_id: UUID, principal: Principal = Depends(authorize)) -> dict:
        return await broker.poll(principal.subject, str(device_id))

    @app.post("/v1/device/results")
    async def device_result(request: DeviceResultRequest, principal: Principal = Depends(authorize)) -> dict:
        return await broker.result(principal.subject, str(request.device_id), str(request.id), request.result)

    @app.get("/v1/stores/search", dependencies=[Depends(authorize)])
    async def search_stores(query: str = Query(min_length=1, max_length=200), limit: int = Query(default=5, ge=1, le=10)) -> dict:
        return {"stores": catalog.search(query, limit=limit)}

    @app.get("/v1/stores/nearby", dependencies=[Depends(authorize)])
    async def nearby_stores(latitude: float = Query(ge=-90, le=90), longitude: float = Query(ge=-180, le=180), limit: int = Query(default=5, ge=1, le=10), max_distance_metres: int = Query(default=50000, ge=1, le=100000)) -> dict:
        return {"stores": catalog.nearby(latitude, longitude, limit=limit, max_distance_metres=max_distance_metres)}

    @app.get("/v1/health", dependencies=[Depends(authorize)])
    async def health() -> dict:
        return {"ok": True, "model_configured": bool(settings.openrouter_key and settings.openrouter_model), "retailer_configured": settings.retailer_mode == "device" or settings.mcp_script.is_file(), "auth_mode": settings.auth_mode, "retailer_mode": settings.retailer_mode}

    @app.post("/v1/sessions", dependencies=[Depends(authorize)])
    async def create_session(store: SessionStore = Depends(owned_store)) -> dict:
        return await store.create()

    @app.get("/v1/sessions", dependencies=[Depends(authorize)])
    async def list_sessions(store: SessionStore = Depends(owned_store)) -> dict:
        return {"sessions": await store.list()}

    @app.get("/v1/sessions/{session_id}", dependencies=[Depends(authorize)])
    async def get_session(session_id: UUID, store: SessionStore = Depends(owned_store)) -> dict:
        session = await store.get(str(session_id))
        if session is None:
            raise HTTPException(status_code=404, detail="session_not_found")
        return _snapshot(session)

    @app.post("/v1/sessions/{session_id}/store")
    async def confirm_store(session_id: UUID, request: StoreSelectionRequest, store: SessionStore = Depends(owned_store)) -> dict:
        session_key, request_key = str(session_id), str(request.request_id)
        request_hash = hashlib.sha256(("store:" + request.model_dump_json()).encode()).hexdigest()
        async with session_lock(session_key):
            if await store.get(session_key) is None:
                raise HTTPException(404, "session_not_found")
            prior, _ = await store.find_request(session_key, request_key)
            if prior:
                if prior["request_hash"] != request_hash or prior["role"] != "assistant":
                    raise HTTPException(409, "request_id_conflict")
                return {"message": _read_message(await store.get(session_key), prior["id"]), "replayed": True}
            selected = catalog.get(request.store_id)
            if selected is None:
                raise HTTPException(422, "store_not_supported")
            text = "Выбран магазин: " + selected["name"] + ", " + selected["address"] + ". Подключение каталога проверю при поиске товаров."
            event = {"type": "store_selected", "data": {"store": selected, "confirmed": True}}
            message = await store.confirm_store(session_key, request.store_id, request_key, request_hash, text, event)
            return {"message": message, "replayed": False}

    @app.post("/v1/sessions/{session_id}/messages", dependencies=[Depends(authorize)])
    async def send_message(session_id: UUID, request: MessageRequest, store: SessionStore = Depends(owned_store), principal: Principal = Depends(authorize), x_device_id: UUID | None = Header(default=None)) -> dict:
        session_key = str(session_id)
        request_key = str(request.request_id)
        async with session_lock(session_key):
            session = await store.get(session_key)
            if session is None:
                raise HTTPException(status_code=404, detail="session_not_found")
            existing_user, existing_answer = await store.find_request(session_key, request_key)
            wine_events = []
            if request.selected_wine:
                wine_events.append(wine_event(request.selected_wine.model_dump(), selected=True))
            wine_events.extend(wine_event(item.wine.model_dump(), photo_number=item.photo_number)
                               for item in request.photo_wines)
            for item in request.comparison_wines:
                event = wine_event(item.model_dump(), comparison=True)
                if event:
                    wine_events.append(event)
            wine_events = [event for event in wine_events if event is not None]
            photo_events = [photo_scan_event(item.photo_number, item.status) for item in request.photo_scans]
            # Keep idempotent replay compatible with requests saved before these fields existed.
            excluded = {name for name in ("photo_wines", "photo_scans", "comparison_wines") if not getattr(request, name)}
            hash_json = request.model_dump_json(exclude=excluded)
            if settings.retailer_mode == "device":
                hash_json += ":device:" + (str(x_device_id) if x_device_id else "none")
            request_hash = hashlib.sha256(hash_json.encode()).hexdigest()
            if existing_user:
                if existing_user["role"] != "user" or existing_user["request_hash"] != request_hash:
                    raise HTTPException(status_code=409, detail="request_id_conflict")
                if existing_answer:
                    return {"message": _read_message(session, existing_answer["id"]), "replayed": True}
            # A completed, identical request returns its historical answer even if
            # the selected store changed later. Context checks apply only before
            # starting/resuming work, never before a durable idempotent replay.
            if request.store_id is not None and catalog.get(request.store_id) is None:
                raise HTTPException(422, "store_not_supported")
            if settings.auth_mode != "legacy_local" and request.store_id is not None and request.store_id != session["store_id"]:
                raise HTTPException(status_code=409, detail="store_context_changed")
            if existing_user:
                user = existing_user
            else:
                if request.store_id is not None:
                    if settings.auth_mode == "legacy_local" and not session.get("store_pending"):
                        await store.set_store(session_key, request.store_id)
                user = await store.append(session_key, "user", request.text, photo_events + wine_events,
                                          request_id=request_key, request_hash=request_hash)
            session = await store.get(session_key)
            assert session is not None
            session = _snapshot(session)
            user = next(message for message in session["messages"] if message["id"] == user["id"])
            effective_store = None if session.get("store_pending") else session["store_id"]
            history = [m for m in session["messages"] if m["id"] != user["id"]]
            current_photo_events = [e for e in user["events"] if e.get("type") in ("photo_scan", "wine_card")]
            assistant = WineAssistant(model, retail_for(principal, x_device_id))
            discovery = _store_discovery(user["text"], effective_store, catalog)
            if discovery and any(event["type"] == "store_candidates" or event["data"].get("reason") == "store_not_found" for event in discovery[1]):
                await store.mark_store_pending(session_key)
            try:
                if discovery:
                    answer, events = discovery
                else:
                    answer, events = await asyncio.wait_for(assistant.reply(history, user["text"], effective_store,
                                                                      current_photo_events), timeout=150)
            except asyncio.TimeoutError:
                answer = "Помощник не успел ответить. История сохранена; попробуйте позже."
                events = [
                    {"type": "assistant_text", "data": {"text": answer}},
                    {"type": "assistant_status", "data": {"status": "unavailable", "reason": "assistant_timeout"}},
                ]
            saved = await store.append(session_key, "assistant", answer, events, reply_to=user["id"])
            return {"message": saved, "replayed": False}

    @app.post("/v1/sessions/{session_id}/dinners/{source_message_id}/select", dependencies=[Depends(authorize)])
    async def select_dinner(session_id: UUID, source_message_id: UUID, request: DinnerSelectionRequest, store: SessionStore = Depends(owned_store)) -> dict:
        session_key, source_key, request_key = str(session_id), str(source_message_id), str(request.request_id)
        request_hash = hashlib.sha256((source_key + ":" + request.model_dump_json()).encode()).hexdigest()
        async with session_lock(session_key):
            session = await store.get(session_key)
            if session is None:
                raise HTTPException(status_code=404, detail="session_not_found")
            prior, _ = await store.find_request(session_key, request_key)
            if prior:
                if prior["role"] != "assistant" or prior["request_hash"] != request_hash:
                    raise HTTPException(status_code=409, detail="request_id_conflict")
                return {"message": _read_message(session, prior["id"]), "replayed": True}
            try:
                source, option = current_dinner_option(session, source_key, str(request.option_id))
                text, event = selected_dinner_event(source_key, option, source["store_id"])
            except ShoppingInvalid as exc:
                raise HTTPException(status_code=exc.status, detail=exc.code) from exc
            outcome, saved = await commit_dinner_selection(
                store, session_key, source_key, source["store_id"], request_key,
                request_hash, text, event,
            )
            if outcome == "conflict":
                raise HTTPException(status_code=409, detail="request_id_conflict")
            if outcome == "stale":
                raise HTTPException(status_code=409, detail="dinner_options_stale")
            assert saved is not None
            return {"message": saved if outcome == "saved" else _read_message(await store.get(session_key), saved["id"]), "replayed": outcome == "replay"}

    @app.get("/v1/sessions/{session_id}/shopping/{source_message_id}/candidates", dependencies=[Depends(authorize)])
    async def replacement_candidates(session_id: UUID, source_message_id: UUID, query: str = Query(min_length=1, max_length=100), store: SessionStore = Depends(owned_store), principal: Principal = Depends(authorize), x_device_id: UUID | None = Header(default=None)) -> dict:
        query = query.strip()
        if not query:
            raise HTTPException(status_code=422, detail="query_empty")
        session_key, source_key = str(session_id), str(source_message_id)
        session = await store.get(session_key)
        if session is None:
            raise HTTPException(status_code=404, detail="session_not_found")
        try:
            source = current_list(session, source_key)
            store_id = source["store_id"]
            raw = await retail_for(principal, x_device_id).call("search_products", {"query": query, "store_id": store_id, "page": 1})
            candidates = _extract_products(raw, "search_products", store_id, expected_transport="local_mcp" if settings.retailer_mode == "legacy_local" else "https_device_poll", ingredient_query=query, filter_ingredients=True)
            again = await store.get(session_key)
            assert again is not None
            current_list(again, source_key)
        except ShoppingInvalid as exc:
            raise HTTPException(status_code=exc.status, detail=exc.code) from exc
        except UpstreamUnavailable as exc:
            raise HTTPException(status_code=503, detail=str(exc)) from exc
        return {"source_message_id": source_key, "store_id": store_id, "query": query, "products": candidates, **aggregate_identity(candidates, envelope_identity(raw, expected_transport="local_mcp" if settings.retailer_mode == "legacy_local" else "https_device_poll")), "data_mode": "live_catalog"}

    @app.post("/v1/sessions/{session_id}/shopping/{source_message_id}/replace", dependencies=[Depends(authorize)])
    async def replace_product(session_id: UUID, source_message_id: UUID, request: ReplacementRequest, store: SessionStore = Depends(owned_store), principal: Principal = Depends(authorize), x_device_id: UUID | None = Header(default=None)) -> dict:
        session_key, source_key, request_key = str(session_id), str(source_message_id), str(request.request_id)
        request_hash = hashlib.sha256((source_key + ":" + request.model_dump_json() + (":device:" + (str(x_device_id) if x_device_id else "none") if settings.retailer_mode == "device" else "")).encode()).hexdigest()
        async with session_lock(session_key):
            session = await store.get(session_key)
            if session is None:
                raise HTTPException(status_code=404, detail="session_not_found")
            prior, _ = await store.find_request(session_key, request_key)
            if prior:
                if prior["role"] != "assistant" or prior["request_hash"] != request_hash:
                    raise HTTPException(status_code=409, detail="request_id_conflict")
                return {"message": _read_message(session, prior["id"]), "replayed": True}
            try:
                source = current_list(session, source_key)
                text, event = await asyncio.wait_for(
                    replacement_event(
                        retail_for(principal, x_device_id), source, source_key, request.old_product_id,
                        request.replacement_product_id, request.packages,
                    ), timeout=150,
                )
            except ShoppingInvalid as exc:
                raise HTTPException(status_code=exc.status, detail=exc.code) from exc
            except UpstreamUnavailable as exc:
                raise HTTPException(status_code=503, detail=str(exc)) from exc
            except asyncio.TimeoutError as exc:
                raise HTTPException(status_code=503, detail="retailer_timeout") from exc
            outcome, saved = await store.commit_replacement(
                session_key, source_key, source["store_id"], request_key, request_hash,
                text, event,
            )
            if outcome == "conflict":
                raise HTTPException(status_code=409, detail="request_id_conflict")
            if outcome == "stale":
                raise HTTPException(status_code=409, detail="shopping_list_stale")
            assert saved is not None
            return {"message": saved if outcome == "saved" else _read_message(await store.get(session_key), saved["id"]), "replayed": outcome == "replay"}

    @app.get("/v1/retailer/status", dependencies=[Depends(authorize)])
    async def retailer_status(principal: Principal = Depends(authorize), x_device_id: UUID | None = Header(default=None)) -> dict:
        try:
            status = await retail_for(principal, x_device_id).call("session_status", {})
            return {"connected": status.get("connected") is True, "source": NEUTRAL_SOURCE, "production_ready": False}
        except UpstreamUnavailable as exc:
            return {"connected": False, "source": NEUTRAL_SOURCE, "production_ready": False, "reason": str(exc)}

    return app


app = create_app()
