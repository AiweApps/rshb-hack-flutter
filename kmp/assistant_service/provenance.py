"""Retail source identity. Runtime envelopes are strict; historical reads are explicit."""
from copy import deepcopy
import json

NEUTRAL_SOURCE = "perekrestok_webview"
LEGACY_ANDROID_SOURCE = "perekrestok_android_webview"
PAIRS = {"android": "android_webview", "ios": "wkwebview"}
TRANSPORTS = frozenset({"https_device_poll", "local_mcp"})


class ProvenanceInvalid(ValueError):
    pass


def _provenance(value, *, expected_transport=None, legacy=False):
    if not isinstance(value, dict):
        if legacy and value is None:
            return {"platform": "android", "adapter": "android_webview", "transport": expected_transport,
                    "contract_version": 1, "inferred": True}
        raise ProvenanceInvalid("retailer_provenance_missing")
    platform, adapter, transport = value.get("platform"), value.get("adapter"), value.get("transport")
    if not isinstance(platform, str) or platform not in PAIRS or PAIRS[platform] != adapter or type(value.get("contract_version")) is not int or value["contract_version"] != 1:
        raise ProvenanceInvalid("retailer_provenance_invalid")
    if legacy and platform != "android":
        raise ProvenanceInvalid("retailer_legacy_platform_mismatch")
    if transport is None and legacy and value.get("inferred") is True:
        transport = expected_transport
    elif not isinstance(transport, str) or transport not in TRANSPORTS:
        raise ProvenanceInvalid("retailer_transport_invalid")
    if expected_transport is not None and transport != expected_transport:
        raise ProvenanceInvalid("retailer_transport_mismatch")
    result = {"platform": platform, "adapter": adapter, "transport": transport, "contract_version": 1}
    if legacy or value.get("inferred") is True:
        result["inferred"] = True
    return result


def envelope_identity(raw: dict, expected_transport=None) -> dict:
    source = raw.get("source")
    if source not in (NEUTRAL_SOURCE, LEGACY_ANDROID_SOURCE):
        raise ProvenanceInvalid("retailer_source_mismatch")
    legacy = source == LEGACY_ANDROID_SOURCE
    provenance = _provenance(raw.get("provenance"), expected_transport=expected_transport, legacy=legacy)
    # Unknown historical transport remains explicit. Do not invent local_mcp for
    # old remote Android records that used the same legacy source literal.
    output_source = LEGACY_ANDROID_SOURCE if legacy and provenance["transport"] is None else NEUTRAL_SOURCE
    return {"source": output_source, "provenance": provenance}


def normalize_product(record: dict) -> dict:
    result = dict(record)
    result.update(envelope_identity(record))
    return result


def is_retail_product(record: dict) -> bool:
    try:
        envelope_identity(record)
        return True
    except (ProvenanceInvalid, TypeError, AttributeError):
        return False


def aggregate_identity(products, fallback=None) -> dict:
    """A meal can contain several producer platforms; preserve every constituent."""
    values = {}
    for product in products:
        identity = envelope_identity(product)
        provenance = identity["provenance"]
        values[json.dumps(provenance, sort_keys=True)] = deepcopy(provenance)
    if not values and fallback:
        if fallback.get("source") not in (NEUTRAL_SOURCE, LEGACY_ANDROID_SOURCE):
            raise ProvenanceInvalid("retailer_source_mismatch")
        prior = fallback.get("constituent_provenance")
        if not isinstance(prior, list):
            value = fallback.get("provenance")
            prior = [value] if isinstance(value, dict) else [envelope_identity(fallback)["provenance"]]
        for value in prior:
            historical = isinstance(value, dict) and value.get("inferred") is True and value.get("transport") is None
            provenance = _provenance(value, legacy=historical or fallback.get("source") == LEGACY_ANDROID_SOURCE)
            values[json.dumps(provenance, sort_keys=True)] = deepcopy(provenance)
    constituents = [values[key] for key in sorted(values)]
    result = {"source": NEUTRAL_SOURCE, "constituent_provenance": constituents}
    if len(constituents) == 1:
        result["provenance"] = deepcopy(constituents[0])
    return result


def is_retail_aggregate(record: dict) -> bool:
    if record.get("source") == LEGACY_ANDROID_SOURCE:
        return is_retail_product(record)
    if record.get("source") != NEUTRAL_SOURCE:
        return False
    values = record.get("constituent_provenance")
    if values is None:
        return is_retail_product(record)
    if not isinstance(values, list):
        return False
    try:
        for value in values:
            historical = isinstance(value, dict) and value.get("inferred") is True and value.get("transport") is None
            _provenance(value, legacy=historical)
        return True
    except ProvenanceInvalid:
        return False
