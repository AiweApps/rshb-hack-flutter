"""Offline, provenance-bearing store directory. It never claims live stock or GPS proof."""
from __future__ import annotations

from copy import deepcopy
from datetime import datetime
import json
import math
from pathlib import Path
import re

DEFAULT_CATALOG = Path(__file__).with_name("catalogs") / "perekrestok.json"
_STOP = {"я", "мы", "в", "во", "на", "у", "с", "со", "из", "по", "это", "этот", "том", "тут", "магазин", "магазине", "нахожусь", "находится", "найди", "рядом", "адрес", "улица", "ул", "дом", "д", "г", "город", "россия", "ро", "тц"}


def _tokens(text: str) -> list[str]:
    return re.findall(r"[a-zа-я0-9]+", text.casefold().replace("ё", "е"))


def _stem(token: str) -> str:
    if token.startswith("перекрест"):
        return "перекресток"
    if len(token) >= 6:
        return re.sub(r"(?:ская|ской|скую|ское|ский|ского|скому|ском|ские|ских|ая|ой|ую|ый|ого|ому|ом|ые|ых)$", "", token)
    return token


def _validated(record: dict) -> dict:
    if not isinstance(record, dict) or type(record.get("id")) is not int or record["id"] <= 0:
        raise ValueError("store id must be a positive integer")
    for key in ("chain", "name", "address", "city", "source_url", "updated_at", "coordinate_source", "coordinate_precision"):
        if not isinstance(record.get(key), str) or not record[key].strip():
            raise ValueError(f"store {record['id']}: missing {key}")
    if record["chain"] != "perekrestok" or record["source_url"] != f"https://www.perekrestok.ru/shops/shop/{record['id']}":
        raise ValueError("unsupported chain or mismatched official shop URL")
    if record.get("mode") != "catalog_snapshot":
        raise ValueError("directory record must be catalog_snapshot")
    timestamp = datetime.fromisoformat(record["updated_at"].replace("Z", "+00:00"))
    if timestamp.tzinfo is None:
        raise ValueError("updated_at must include timezone")
    if not isinstance(record.get("aliases", []), list) or any(not isinstance(alias, str) for alias in record.get("aliases", [])):
        raise ValueError("aliases must be text values")
    lat, lon = record.get("latitude"), record.get("longitude")
    if (lat is None) != (lon is None):
        raise ValueError("coordinates must both be present or absent")
    if lat is not None:
        _validate_point(lat, lon)
        if record["coordinate_precision"] == "unknown":
            raise ValueError("coordinates require declared precision")
    elif record["coordinate_precision"] != "unknown":
        raise ValueError("missing coordinates require unknown precision")
    sap = record.get("sap_id")
    if sap is not None and (not isinstance(sap, str) or not sap.isdigit()):
        raise ValueError("sap_id must be a numeric string or null")
    if type(record.get("catalog_verified")) is not bool:
        raise ValueError("catalog_verified must be explicit")
    return deepcopy(record)


def _validate_point(latitude: float, longitude: float) -> None:
    if isinstance(latitude, bool) or isinstance(longitude, bool) or not isinstance(latitude, (int, float)) or not isinstance(longitude, (int, float)) or not math.isfinite(latitude) or not math.isfinite(longitude) or not -90 <= latitude <= 90 or not -180 <= longitude <= 180:
        raise ValueError("invalid latitude/longitude")


def _distance(a: float, b: float, c: float, d: float) -> int:
    p, q = math.radians(c - a), math.radians(d - b)
    h = math.sin(p / 2) ** 2 + math.cos(math.radians(a)) * math.cos(math.radians(c)) * math.sin(q / 2) ** 2
    return round(2 * 6_371_000 * math.asin(min(1, math.sqrt(h))))


class StoreCatalog:
    def __init__(self, path: str | Path | None = None):
        document = json.loads(Path(path or DEFAULT_CATALOG).read_text(encoding="utf-8"))
        if document.get("schema_version") != 1 or not isinstance(document.get("stores"), list):
            raise ValueError("unsupported store catalog schema")
        self._stores = [_validated(row) for row in document["stores"]]
        self._by_id = {row["id"]: row for row in self._stores}
        if len(self._by_id) != len(self._stores):
            raise ValueError("duplicate store id")

    def get(self, store_id: int) -> dict | None:
        row = self._by_id.get(store_id)
        return deepcopy(row) if row else None

    def all(self) -> list[dict]:
        return deepcopy(sorted(self._stores, key=lambda row: row["id"]))

    @property
    def store_sap(self) -> dict[int, str]:
        return {row["id"]: row["sap_id"] for row in self._stores if row.get("sap_id")}

    def search(self, query: str, limit: int = 5) -> list[dict]:
        """Search actual address/name tokens; an unknown address never selects a default."""
        if not isinstance(query, str) or not query.strip() or len(query) > 500:
            return []
        raw_tokens = {t for t in _tokens(query) if t not in _STOP}
        tokens = [_stem(t) for t in _tokens(query) if t not in _STOP]
        if not tokens:
            return []
        # An explicitly named city constrains the address search. Stemmed
        # shopping-centre/street names must not turn Азовский into city Азов.
        mentioned_city_tokens = {
            tuple(t for t in _tokens(row["city"]) if t not in _STOP)
            for row in self._stores
            if (city_tokens := {t for t in _tokens(row["city"]) if t not in _STOP})
            and city_tokens <= raw_tokens
        }
        if mentioned_city_tokens:
            most_specific = max(map(len, mentioned_city_tokens))
            mentioned_city_tokens = {city for city in mentioned_city_tokens if len(city) == most_specific}
        result = []
        for row in self._stores:
            if mentioned_city_tokens and tuple(t for t in _tokens(row["city"]) if t not in _STOP) not in mentioned_city_tokens:
                continue
            haystack = " ".join((row["name"], row["address"], row["city"], " ".join(row.get("aliases", []))))
            candidates = {_stem(t) for t in _tokens(haystack)}
            hits = sum(t in candidates for t in tokens)
            # House number / store id is restrictive, never fuzzy.
            numbers = [t for t in tokens if t.isdigit()]
            if numbers and not all(t in candidates or t == str(row["id"]) for t in numbers):
                continue
            substantive = [t for t in tokens if t != "перекресток"]
            if hits and (not substantive or any(t in candidates for t in substantive)):
                result.append((hits / len(tokens), hits, row))
        result.sort(key=lambda item: (-item[0], -item[1], item[2]["id"]))
        return [deepcopy(row) for _, _, row in result[:max(0, min(int(limit), 10))]]

    def nearby(self, latitude: float, longitude: float, limit: int = 5, max_distance_metres: float = 50_000) -> list[dict]:
        """Distance to known coordinates only. Approximate coordinates remain labelled."""
        _validate_point(latitude, longitude)
        if not isinstance(max_distance_metres, (int, float)) or not math.isfinite(max_distance_metres) or max_distance_metres <= 0 or max_distance_metres > 100_000:
            raise ValueError("radius must be between 0 and 100000 metres")
        rows = []
        for row in self._stores:
            if row.get("latitude") is None:
                continue
            distance = _distance(latitude, longitude, row["latitude"], row["longitude"])
            if distance <= max_distance_metres:
                rows.append(dict(deepcopy(row), distance_metres=distance, requires_confirmation=True))
        return sorted(rows, key=lambda row: (row["distance_metres"], row["id"]))[:max(0, min(int(limit), 10))]


STORE_SAP = StoreCatalog().store_sap
