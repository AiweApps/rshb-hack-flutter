"""Stage3 ProductID03 relation graph over validated stage1 facts and stage2 source admission.

Every same-producer product pair is compared by metadata; frozen-01 edges, their effective QA
and cached catalogue-competitor nominations are reused. Nothing here is fit-admitted.
"""
from __future__ import annotations

import difflib
import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path

from rshb_vine.candidate_discriminators import GENERIC_WORDS, _plain_tokens, canonical_tokens
from rshb_vine.catalog_training_data_v2 import source_admission
from rshb_vine.catalog_training_data_v2.table import BROADER, TRUSTED, VERIFIED, load_validated_stage1
from rshb_vine.intraline_visual_v1.negative_overlay import NegativeOverlay

ROOT = Path(__file__).resolve().parents[2]
SCHEMA = "catalog-training-data-v2-stage3-pairs-v1"
OUT = ROOT / "data/catalog-training-data-v2/stage3"
RUN = ROOT / "runs/catalog-training-data-v2/stage3"
STAGE1 = ("data/catalog-training-data-v2/stage1/items.jsonl", "data/catalog-training-data-v2/stage1/manifest.json",
          "runs/catalog-training-data-v2/stage1/validation.json")
STAGE2 = tuple("data/catalog-training-data-v2/stage2/" + n for n in
               ("source-ledger.jsonl", "pair-ledger.jsonl", "gap-queue.json", "summary.json"))
COMPETITORS = ("runs/catalogue-competitors-v2/pairs.jsonl", "runs/catalogue-competitors-v2/summary.json",
               "runs/catalogue-competitors-v2/root-review.json")
REFS = source_admission.REFS
SITE_COVERAGE = "runs/site-catalog-audit-20260921/coverage.json"
IDENTITY_BUNDLE = "data/product-identity-v1/snapshot-03-candidate/manifest.json"
IDENTITY_REGISTRY = "data/product-identity-v1/snapshot-03-candidate/registry.json"
IDENTITY_LINKS = "data/identity-link-review-v1/successor-v6/product-identity-links-v6-candidate.json"
INPUTS = (*STAGE1, *STAGE2, *COMPETITORS, REFS, source_admission.MASK, SITE_COVERAGE, IDENTITY_BUNDLE, IDENTITY_REGISTRY, IDENTITY_LINKS)
CODE = ("rshb_vine/catalog_training_data_v2/pairs.py", "rshb_vine/catalog_training_data_v2/schedule.py",
        "rshb_vine/catalog_training_data_v2/preparation.py", "scripts/catalog_pairs_v2.py",
        "rshb_vine/catalog_training_data_v2/table.py", "rshb_vine/catalog_training_data_v2/site_metadata.py",
        "rshb_vine/catalog_training_data_v2/source_admission.py", "rshb_vine/candidate_discriminators.py",
        "rshb_vine/intraline_visual_v1/negative_overlay.py", "rshb_vine/io.py")

SET_ATTRS = ("wine_color", "sweetness", "sparkling_style", "wine_type")
DECISIVE = SET_ATTRS + ("product_name",)
SUPPORT_ONLY = ("grapes",)
SITE_PRECEDENCE_ATTRS = SET_ATTRS
SPELLING_RATIO = 0.75
CONTEXT_ATTRS = ("region", "reference_year", "catalog_vintage", "series")
VISUAL = ("B0_context", "B0_front_label", "B3_context", "B3_front_label")
CROSS_PRODUCER_RANK_BOUND = 5
# Old frozen-01 relations/decisions that stay masked regardless of new metadata.
KEEP_MASK = {"identity_hold", "vintage_or_edition_hold", "catalogue_indistinguishable_hold", "qa_overlay_masked",
             "negative_not_allowed_source_hold", "negative_qa_effective_hold", "negative_qa_shown_reference_unjoined"}
RESOLVABLE = {"unknown_no_affirmative_difference", "negative_approved_not_qa_shown",
              "negative_qa_shown_source_not_admitted", "negative_qa_reviewed_product_outside_pool"}
NEGATIVE = {"negative_legacy_pair_qa", "negative_metadata_supported"}
UNKNOWN_IDENTITY_HOLD = {"year_variant": "vintage_only_held"}


def sha256(path: Path):
    return source_admission.sha256(path) if path.is_file() else None


def pins(rels):
    return {rel: sha256(ROOT / rel) for rel in rels}


def digest_obj(obj):
    return hashlib.sha256(json.dumps(obj, ensure_ascii=False, sort_keys=True).encode()).hexdigest()


def pair_key(a, b):
    return (a, b) if a < b else (b, a)


def order_key(*parts):
    return hashlib.sha256("|".join(parts).encode()).hexdigest()


def _pointer(slug, attr, entry):
    basis = [entry["claims"][i] for i in entry.get("basis_claims") or [] if i < len(entry["claims"])]
    return {"slug": slug, "attr": attr, "status": entry["status"], "resolution": entry.get("resolution"),
            "claims": [{"source_kind": c.get("source_kind"), "field": c["source"].get("field"),
                        "path": c["source"].get("path"), "sha256": c["source"].get("sha256"),
                        "url": c["source"].get("url"), "raw": c.get("raw")} for c in basis]}


def _site_disagreements(card):
    return sorted(a for a in (*DECISIVE, *SUPPORT_ONLY)
                  if (card["attributes"][a].get("site_enrichment") or {}).get("audit_relation") == "differs_audit_only")


def _card_state(slug, attr, entry, disagreements, site_receipts):
    """Comparison projection of one card attribute; stage1 is never mutated.

    Exact-slug site structured value takes precedence over catalog_asserted for a single disagreeing set
    attribute; several disagreeing fields on one card are a site-identity conflict and stay contested.
    """
    site = entry.get("site_enrichment") or {}
    value = entry.get("components") if attr == "grapes" else entry.get("value")
    if entry["status"] == "conflict":
        return {"state": "conflict", "values": None}
    if not entry.get("comparison_allowed") or entry["status"] not in TRUSTED or not value:
        return {"state": "unknown", "values": None, "status": entry["status"]}
    if site.get("audit_relation") == "differs_audit_only":
        structured = {tuple(sorted(v)) for v in site.get("structured_values") or []}
        receipt = site_receipts.get(slug)
        if entry["status"] in VERIFIED:
            return {"state": "known", "values": sorted(value), "pointer": _pointer(slug, attr, entry),
                    "site_disagreement": {"site_value": site.get("audit_site_value"), "kept": "source_verified_protected"}}
        if (attr in SITE_PRECEDENCE_ATTRS and disagreements == [attr] and len(structured) == 1 and receipt
                and receipt["url"] == site.get("source_url") and site.get("structured_vs_description") in (None, "agree")):
            return {"state": "known", "values": sorted(next(iter(structured))),
                    "pointer": {"slug": slug, "attr": attr, "status": "site_structured_precedence",
                                "claims": [{"source_kind": "site_api_structured", "url": receipt["url"],
                                            "path": receipt["body_path"], "sha256": receipt["sha256"]}]},
                    "precedence": {"rule": "site_structured_exact_slug_over_catalog_asserted",
                                   "old_value": sorted(value), "old_pointer": _pointer(slug, attr, entry)}}
        return {"state": "contested", "values": sorted(value), "site_value": site.get("audit_site_value"),
                "reason": ("unresolved_metadata_conflict_multiple_fields:" + ",".join(disagreements)) if len(disagreements) > 1
                else "site_precedence_not_applicable_to_attr_or_receipt",
                "pointer": _pointer(slug, attr, entry)}
    state = {"state": "known", "values": sorted(value), "pointer": _pointer(slug, attr, entry)}
    if attr == "grapes":
        state["unmapped"] = bool(entry.get("unmapped_components"))
    return state


def _skeleton(token):
    t = token
    for a, b in (("sch", "sh"), ("ph", "f"), ("q", "k"), ("c", "k"), ("x", "ks"), ("w", "v"), ("y", "i"), ("j", "i"),
                 ("ee", "i"), ("oo", "u"), ("ou", "u")):
        t = t.replace(a, b)
    t = "".join(ch for i, ch in enumerate(t) if i == 0 or ch != t[i - 1])
    return t.rstrip("etcsh") or t


def _spelled_in(token, others):
    k = _skeleton(token)
    return any(difflib.SequenceMatcher(None, k, _skeleton(o)).ratio() >= SPELLING_RATIO for o in others)


def _name_tokens(values, producer_tokens):
    toks = {t for v in values or [] for t in canonical_tokens(str(v))[0]}
    distinctive = {t for t in toks if len(t) >= 3 and not t.isdigit() and t not in GENERIC_WORDS
                   and not (t.startswith("zz") and t.endswith("zz")) and t not in producer_tokens}
    grape_atoms = {atom for v in values or [] for _, _, atom, src in canonical_tokens(str(v))[1] if src.endswith(".grapes")}
    return sorted(toks), sorted(distinctive), sorted(grape_atoms)


def site_receipts():
    return {r["slug"]: {"url": r["api_receipt"]["url"], "body_path": r["api_receipt"]["body_path"],
                        "sha256": r["api_receipt"]["sha256"]}
            for r in source_admission.read(SITE_COVERAGE)
            if r.get("api_receipt") and r.get("site_identity_status") != "conflict"}


def product_facts(items, records, site_receipts):
    by_product = defaultdict(list)
    for item in items:
        if item["active_in_gallery"]:
            by_product[item["product_id"]].append(item)
    sources = defaultdict(list)
    for r in records:
        sources[r["product03"]].append(r)
    products = {}
    for pid in sorted(by_product):
        cards = sorted(by_product[pid], key=lambda i: i["slug"])
        attrs = {}
        for attr in (*DECISIVE, *SUPPORT_ONLY, *CONTEXT_ATTRS, "producer"):
            per_card = [(c["slug"], _card_state(c["slug"], attr, c["attributes"][attr], _site_disagreements(c), site_receipts))
                        for c in cards]
            states = {s["state"] for _, s in per_card}
            known = {tuple(s["values"]) for _, s in per_card if s["state"] == "known"}
            if "conflict" in states or "contested" in states:
                agg = "conflict" if "conflict" in states else "contested"
            elif len(known) > 1:
                agg = "cross_card_conflict"
            elif known:
                agg = "known" if states == {"known"} else "known_partial_cards"
            else:
                agg = "unknown"
            attrs[attr] = {"state": agg, "values": sorted(next(iter(known))) if len(known) == 1 else None,
                           "unmapped": any(s.get("unmapped") for _, s in per_card),
                           "cards": [{"slug": sl, **{k: v for k, v in s.items() if k != "unmapped"}} for sl, s in per_card]}
        producers = sorted({p for c in cards for p in (c["attributes"]["producer"]["value"] or [])})
        producer_tokens = {t for p in producers for t in canonical_tokens(p)[0]}
        # Name atoms may only come from comparable, source-backed commercial titles.
        name_vals = sorted({v for state in attrs["product_name"]["cards"]
                            if state["state"] == "known" for v in state["values"]})
        tokens, distinctive, grape_atoms = _name_tokens(name_vals, producer_tokens)
        srcs = sorted(sources.get(pid, []), key=lambda r: r["original_sha256"])
        admitted = [r for r in srcs if r["consumers"]["encoder_known_catalog"]["decision"] == "admitted_candidate"]
        products[pid] = {
            "product03": pid, "cards": [c["slug"] for c in cards], "producers": producers,
            "product_names": name_vals, "name_tokens": tokens, "line_tokens": distinctive, "attributes": attrs,
            "name_grape_atoms": grape_atoms,
            "plain_name_tokens": sorted({t for v in name_vals for t in _plain_tokens(v)}),
            "identity_status": sorted({c["product_identity_status"] for c in cards}),
            "sources": [{"original_sha256": r["original_sha256"], "slug": r["slug"],
                         "decision": r["consumers"]["encoder_known_catalog"]["decision"],
                         "held_reasons": r["consumers"]["encoder_known_catalog"]["held_reasons"],
                         "views": [{"view_id": f"{r['original_sha256']}:{v['kind']}:{v['reference_index']}",
                                    "kind": v["kind"], "reference_index": v["reference_index"], "bbox": v["bbox"]}
                                   for v in r["B3_references"] if v["join_ok"]]} for r in srcs],
            "admitted_sources": [r["original_sha256"] for r in admitted]}
    return products


def _set_compare(attr, a, b):
    if a["state"] not in ("known", "known_partial_cards") or b["state"] not in ("known", "known_partial_cards"):
        return {"relation": "not_comparable", "a_state": a["state"], "b_state": b["state"]}
    x, y = set(a["values"]), set(b["values"])
    if x == y:
        return {"relation": "equal", "values": sorted(x)}
    if attr == "grapes":
        if a["unmapped"] or b["unmapped"]:
            return {"relation": "unmapped_component_not_decisive", "a": sorted(x), "b": sorted(y)}
        return {"relation": "disjoint" if not x & y else "partial_overlap_not_decisive", "a": sorted(x), "b": sorted(y)}
    compatible = any(u == v or u in BROADER.get(v, ()) or v in BROADER.get(u, ()) for u in x for v in y)
    return {"relation": "compatible_specificity" if compatible else "differs", "a": sorted(x), "b": sorted(y)}


def _name_compare(pa, pb):
    if pa["attributes"]["product_name"]["state"] not in ("known", "known_partial_cards") or pb["attributes"]["product_name"]["state"] not in ("known", "known_partial_cards"):
        return {"relation": "not_comparable", "reason": "commercial_title_not_source_backed_on_both_sides"}
    if pa["attributes"]["product_name"]["state"] in ("conflict", "contested", "cross_card_conflict"):
        return {"relation": "not_comparable", "reason": "a_" + pa["attributes"]["product_name"]["state"]}
    if pb["attributes"]["product_name"]["state"] in ("conflict", "contested", "cross_card_conflict"):
        return {"relation": "not_comparable", "reason": "b_" + pb["attributes"]["product_name"]["state"]}
    if pa["name_tokens"] == pb["name_tokens"]:
        return {"relation": "equal", "tokens": pa["name_tokens"]}
    only_a = sorted(t for t in set(pa["line_tokens"]) - set(pb["line_tokens"]) if not _spelled_in(t, pb["plain_name_tokens"]))
    only_b = sorted(t for t in set(pb["line_tokens"]) - set(pa["line_tokens"]) if not _spelled_in(t, pa["plain_name_tokens"]))
    sym = set(pa["name_tokens"]) ^ set(pb["name_tokens"])
    grape_a = sorted(set(pa["name_grape_atoms"]) - set(pb["name_grape_atoms"]))
    grape_b = sorted(set(pb["name_grape_atoms"]) - set(pa["name_grape_atoms"]))
    detail = {"distinctive_only_a": only_a, "distinctive_only_b": only_b, "name_grape_only_a": grape_a, "name_grape_only_b": grape_b}
    if (only_a and only_b) or (grape_a and grape_b):
        return {"relation": "differs", **detail}
    if only_a or only_b:
        return {"relation": "one_sided_extra_name_token_not_decisive", **detail}
    if set(pa["line_tokens"]) ^ set(pb["line_tokens"]):
        return {"relation": "spelling_or_transliteration_variant_not_decisive",
                "tokens": sorted(set(pa["line_tokens"]) ^ set(pb["line_tokens"]))}
    if sym and all(t.isdigit() for t in sym):
        return {"relation": "number_or_year_only", "tokens": sorted(sym)}
    return {"relation": "generic_or_attribute_token_only_not_decisive", "tokens": sorted(sym)}


def compare(pa, pb):
    out = {a: _set_compare(a, pa["attributes"][a], pb["attributes"][a]) for a in (*SET_ATTRS, *SUPPORT_ONLY)}
    out["product_name"] = _name_compare(pa, pb)
    for a in CONTEXT_ATTRS:
        x, y = pa["attributes"][a], pb["attributes"][a]
        out[a] = ({"relation": "equal" if x["values"] == y["values"] else "differs_context_only", "a": x["values"], "b": y["values"]}
                  if x["state"] == "known" and y["state"] == "known" else {"relation": "not_comparable"})
    return out


def _decisive(cmp):
    return sorted(a for a in DECISIVE if cmp[a]["relation"] in ("differs", "disjoint"))


def _supporting(cmp):
    return sorted(a for a in SUPPORT_ONLY if cmp[a]["relation"] == "disjoint")


def _contested(pa, pb):
    return sorted({a for a in DECISIVE for p in (pa, pb) if p["attributes"][a]["state"] in ("contested", "conflict", "cross_card_conflict")})


def _claim_pointers(pa, pb, attrs):
    return {a: {"a": [c.get("pointer") for c in pa["attributes"][a]["cards"] if c.get("pointer")],
                "b": [c.get("pointer") for c in pb["attributes"][a]["cards"] if c.get("pointer")]} for a in attrs}


def _visual(comp):
    if not comp:
        return None
    ranks = [min(comp["visual"][ch]["rank_ab"], comp["visual"][ch]["rank_ba"]) for ch in VISUAL if ch in comp["visual"]]
    return {"min_channel_rank": min(ranks) if ranks else None, "channels_rank_le10": sum(r <= 10 for r in ranks),
            "rrf_min_rank": min(comp["visual_rrf"]["rank_ab"], comp["visual_rrf"]["rank_ba"]),
            "strong_visual": comp["strong_visual"], "competitor_class": comp["class"],
            "competitor_unknown_reasons": comp.get("unknown_reasons") or [], "channels": comp["visual"]}


def _competitors(product_ids):
    rows = {}
    with open(ROOT / COMPETITORS[0]) as handle:
        for line in handle:
            c = json.loads(line)
            key = pair_key(c["a"], c["b"])
            if key in rows or c["a"] == c["b"]:
                raise ValueError("Duplicate or self competitor pair")
            if not set(key) <= product_ids:
                raise ValueError("Competitor pair outside active ProductID03 set")
            rows[key] = {"class": c["class"], "same_producer": c["same_producer"], "strong_visual": c["strong_visual"],
                         "unknown_reasons": c.get("unknown_reasons"), "visual": c["visual"], "visual_rrf": c["visual_rrf"],
                         "sources": c["sources"], "owner_not_merged": c.get("owner_not_merged")}
    return rows


def decide(key, pa, pb, old, comp, overlay):
    cmp = compare(pa, pb)
    decisive, contested, supporting = _decisive(cmp), _contested(pa, pb), _supporting(cmp)
    old_decision = old["decision"] if old else None
    reasons, evidence = [], None
    if key in overlay.pairs:
        decision, reasons = "masked_hold", ["qa_overlay_masked", *overlay.reasons[key]]
    elif old_decision in KEEP_MASK:
        decision = "vintage_only_held" if old_decision == "vintage_or_edition_hold" else "masked_hold"
        reasons = ["frozen01:" + old_decision]
    elif old_decision == "negative_qa_shown_product_mismatch" and not decisive:
        decision, reasons = "masked_hold", ["frozen01:negative_qa_shown_product_mismatch_no_independent_metadata"]
    elif comp and comp["class"] == "unknown_identity":
        rs = comp.get("unknown_reasons") or ["unknown_identity"]
        decision = "vintage_only_held" if set(rs) == {"year_variant"} else "masked_hold"
        reasons = ["competitors_v2_unknown_identity:" + r for r in rs]
    elif old_decision == "negative_candidate_not_fit_admitted":
        shown = old["qa"]["shown"]
        source_sets = {key[0]: {s["original_sha256"] for s in pa["sources"]},
                       key[1]: {s["original_sha256"] for s in pb["sources"]}}
        invalid_shown = [r for r in shown if r["original_sha256"] not in source_sets.get(r["product03"], set())]
        if invalid_shown:
            if decisive:
                decision, evidence = "negative_metadata_supported", "metadata_supported_no_new_visual_review"
                reasons = ["legacy_qa_shown_source_product_mismatch_not_used", *["decisive:" + a for a in decisive]]
            else:
                decision, evidence = "masked_hold", None
                reasons = ["legacy_qa_shown_source_product_mismatch_no_independent_metadata"]
        else:
            decision, evidence = "negative_legacy_pair_qa", "legacy_pair_qa_supported"
            reasons = ["frozen01_effective_qa:" + old["qa"]["effective"]["basis"]]
            if not decisive:
                reasons.append("current_metadata_has_no_decisive_difference_qa_retained")
    elif decisive:
        decision, evidence = "negative_metadata_supported", "metadata_supported_no_new_visual_review"
        reasons = ["decisive:" + a for a in decisive] + ["supporting_only:" + a for a in supporting]
        if old_decision:
            reasons.append("resolves_frozen01:" + old_decision)
    elif contested:
        decision, reasons = "requires_review_ambiguous", ["contested_or_conflicting_attribute:" + a for a in contested]
    elif cmp["product_name"]["relation"] == "number_or_year_only" or (
            cmp["reference_year"]["relation"] == "differs_context_only" or cmp["catalog_vintage"]["relation"] == "differs_context_only"):
        decision, reasons = "vintage_only_held", ["only_year_or_number_difference"]
    else:
        nondecisive = sorted(a for a, c in cmp.items() if c["relation"] not in ("equal", "not_comparable"))
        if nondecisive:
            decision, reasons = "requires_review_ambiguous", (["supporting_only_no_decisive:" + a for a in supporting]
                                                              + ["non_decisive_difference:" + a for a in nondecisive if a not in supporting])
        else:
            decision, reasons = "masked_no_affirmative_difference", ["no_affirmative_difference_equal_metadata_not_merged"]
        if old_decision:
            reasons.append("frozen01:" + old_decision + "_unresolved")
    exclusion = None
    if decision in NEGATIVE:
        missing = [s for s, p in (("a", pa), ("b", pb)) if not p["admitted_sources"]]
        if missing:
            exclusion = "no_admitted_source:" + ",".join(missing)
    precedence = sorted(a for a in decisive for p in (pa, pb) for c in p["attributes"][a]["cards"] if c.get("precedence"))
    return {"decision": decision, "negative_evidence": evidence, "reasons": reasons, "decisive_attributes": decisive,
            "legacy_pair_qa_shown": (old["qa"]["shown"] if decision == "negative_legacy_pair_qa" else None),
            "legacy_pair_qa_pointer": ({"path": STAGE2[1], "sha256": sha256(ROOT / STAGE2[1]),
                                        "pair_key03": list(key), "effective": old["qa"]["effective"],
                                        "shown": old["qa"]["shown"]} if decision == "negative_legacy_pair_qa" else None),
            "supporting_attributes": supporting, "contested_attributes": contested, "comparisons": cmp,
            "site_precedence_used_for": sorted(set(precedence)),
            "claim_pointers": _claim_pointers(pa, pb, sorted(set(decisive) | set(contested) | set(supporting))),
            "trainable_exclusion": exclusion}


def _relationship(pa, pb):
    same = bool(set(pa["producers"]) & set(pb["producers"]))
    if not same:
        return "cross_producer"
    return "same_producer_same_line" if set(pa["line_tokens"]) & set(pb["line_tokens"]) else "same_producer_other_line"


def build():
    manifest1, stored1, items = load_validated_stage1(ROOT)
    stage2 = source_admission.validate()
    records = source_admission.jsonl(STAGE2[0])
    old_pairs = {pair_key(p["product_a03"], p["product_b03"]): p for p in source_admission.jsonl(STAGE2[1])}
    overlay = NegativeOverlay(ROOT / source_admission.MASK)
    receipts = site_receipts()
    products = product_facts(items, records, receipts)
    pids = set(products)
    comps = _competitors(pids)
    by_producer = defaultdict(list)
    for pid, p in products.items():
        for prod in p["producers"]:
            by_producer[prod].append(pid)
    nominations = defaultdict(set)
    for prod, members in by_producer.items():
        members = sorted(set(members))
        for i, a in enumerate(members):
            for b in members[i + 1:]:
                nominations[(a, b)].add("same_producer_enumeration")
    for key, old in old_pairs.items():
        if not set(key) <= pids:
            raise ValueError("Frozen-01 edge outside active products")
        nominations[key].add("frozen01_edge")
    cross_outside = 0
    for key, c in comps.items():
        v = _visual(c)
        if c["same_producer"]:
            nominations[key].add("competitors_v2_within_producer_lists")
        elif c["strong_visual"] or (v["min_channel_rank"] or 999) <= CROSS_PRODUCER_RANK_BOUND:
            nominations[key].add("competitors_v2_cross_producer_visual_secondary")
        else:
            nominations[key].add("competitors_v2_cross_producer_outside_bound")
    edges = []
    for key in sorted(nominations):
        a, b = key
        pa, pb, old, comp = products[a], products[b], old_pairs.get(key), comps.get(key)
        noms = sorted(nominations[key])
        rel = _relationship(pa, pb)
        if noms == ["competitors_v2_cross_producer_outside_bound"]:
            cross_outside += 1
            edges.append({"product_a03": a, "product_b03": b, "nominations": noms, "producer_relationship": rel,
                          "decision": "excluded_not_evaluated", "reasons": ["cross_producer_visual_rank_outside_secondary_bound"],
                          "visual": {"min_channel_rank": _visual(comp)["min_channel_rank"], "strong_visual": comp["strong_visual"]},
                          "before": None, "fit_admitted": False})
            continue
        d = decide(key, pa, pb, old, comp, overlay)
        before = ({"stage2_decision": old["decision"], "relation": old["relation"],
                   "qa_basis": old["qa"]["effective"]["basis"] if old.get("qa") else None} if old else None)
        edges.append({"product_a03": a, "product_b03": b, "nominations": noms, "producer_relationship": rel,
                      "producers": {"a": pa["producers"], "b": pb["producers"]},
                      "line_tokens_shared": sorted(set(pa["line_tokens"]) & set(pb["line_tokens"])),
                      **d, "visual": _visual(comp),
                      "sources": {s: {"admitted": p["admitted_sources"],
                                      "held": [{"sha256": x["original_sha256"], "reasons": x["held_reasons"]}
                                               for x in p["sources"] if x["decision"] != "admitted_candidate"]}
                                  for s, p in (("a", pa), ("b", pb))},
                      "before": before, "transition": f"{before['stage2_decision'] if before else 'absent'}->{d['decision']}",
                      "masks_are_not_positives": True, "fit_admitted": False})
    positives, excluded_positives = _positives(products)
    ledger_products = _product_ledger(products, edges, positives, excluded_positives)
    card_producers = Counter(tuple(i["attributes"]["producer"]["value"] or []) for i in items if i["active_in_gallery"])
    summary = _summary(products, edges, positives, by_producer, cross_outside, comps, old_pairs)
    summary["cross_source_positives_excluded_conflicting_card_claims"] = len(excluded_positives)
    summary["same_producer_possible_card_pairs_active"] = sum(n * (n - 1) // 2 for n in card_producers.values())
    summary["site_precedence_card_attributes"] = dict(Counter(
        a for p in products.values() for a, st in p["attributes"].items() for c in st["cards"] if c.get("precedence")))
    summary["contested_card_attributes"] = dict(Counter(
        a + ":" + c.get("reason", "") for p in products.values() for a, st in p["attributes"].items()
        for c in st["cards"] if c["state"] == "contested"))
    return {"edges": edges, "products": ledger_products, "positives": positives, "summary": summary,
            "upstream": {"stage1_items_sha256": stored1["items_sha256"], "stage1_revision": stored1["revision"],
                         "stage2_summary_sha256": stage2["summary_sha256"], "stage2_status": stage2["status"]}}


def _positives(products):
    rows = []
    excluded = []
    verified = {}
    for group in source_admission.read(IDENTITY_LINKS)["groups"]:
        if group.get("verified"):
            verified[group["product_id"]] = {(r["image_sha256"], r["slug"]) for r in group["reference_bindings"]}
    registry = source_admission.read(IDENTITY_REGISTRY)
    for product in registry["products"]:
        if product["identity_status"] == "source_admitted" and product["cross_card_equivalence"] == "verified_only_listed_members":
            pid = product["product_id"]
            verified.setdefault(pid, set()).update((r["image_sha256"], slug) for r in registry["reference_images"]
                if pid in r["product_ids"] for slug in r["card_slugs"] if slug in product["card_slugs"])
    for pid, p in products.items():
        adm = [s for s in p["sources"] if s["decision"] == "admitted_candidate"]
        for s in adm:
            kinds = {v["kind"]: v for v in s["views"]}
            if len(kinds) == 2:
                rows.append({"product03": pid, "kind": "same_source_view_positive", "independent_photo": False,
                             "a_view": kinds["front_label"]["view_id"], "b_view": kinds["context"]["view_id"],
                             "source_sha256": [s["original_sha256"]]})
        for i, s in enumerate(adm):
            for t in adm[i + 1:]:
                conflicts = _cross_source_claim_conflicts(p, s["slug"], t["slug"])
                exact_reviewed = {(s["original_sha256"], s["slug"]), (t["original_sha256"], t["slug"])} <= verified.get(pid, set())
                if conflicts and not exact_reviewed:
                    excluded.append({"product03": pid, "source_sha256": [s["original_sha256"], t["original_sha256"]],
                                     "cards": [s["slug"], t["slug"]], "reason": "contradictory_typed_claims_across_cards",
                                     "attributes": conflicts})
                    continue
                rows.append({"product03": pid, "kind": "cross_source_same_product_positive", "independent_photo": None,
                             "capture_independence": "not_established_different_source_sha_only",
                             "metadata_conflicts_preserved": conflicts,
                             "identity_review": (IDENTITY_BUNDLE if exact_reviewed else None),
                             "source_sha256": [s["original_sha256"], t["original_sha256"]],
                             "cards": sorted({s["slug"], t["slug"]})})
    return rows, excluded


def _cross_source_claim_conflicts(product, slug_a, slug_b):
    if slug_a == slug_b:
        return []
    conflicts = []
    for attr in SET_ATTRS:
        cards = {c["slug"]: c for c in product["attributes"][attr]["cards"]}
        a, b = cards.get(slug_a), cards.get(slug_b)
        if a and b and _set_compare(attr, a, b)["relation"] == "differs":
            conflicts.append(attr)
    return conflicts


def _product_ledger(products, edges, positives, excluded_positives):
    per = defaultdict(Counter)
    for e in edges:
        for side in ("product_a03", "product_b03"):
            per[e[side]]["nominated"] += 1
            per[e[side]]["decision:" + e["decision"]] += 1
            if e["decision"] in NEGATIVE and not e.get("trainable_exclusion"):
                per[e[side]]["eligible_negative"] += 1
                per[e[side]]["eligible_negative:" + e["producer_relationship"]] += 1
    pos = Counter((r["product03"], r["kind"]) for r in positives)
    out = []
    for pid, p in products.items():
        c = per[pid]
        reasons = []
        if not p["admitted_sources"]:
            reasons.append("no_admitted_source:" + ";".join(sorted({h for s in p["sources"] for h in s["held_reasons"]})))
        if not c["eligible_negative"]:
            reasons.append("no_eligible_negative_neighbour")
        out.append({"product03": pid, "cards": p["cards"], "producers": p["producers"], "product_names": p["product_names"],
                    "line_tokens": p["line_tokens"], "identity_status": p["identity_status"],
                    "n_sources": len(p["sources"]), "n_admitted_sources": len(p["admitted_sources"]),
                    "sources": p["sources"],
                    "attributes": {a: {k: v for k, v in s.items()} for a, s in p["attributes"].items()},
                    "coverage": dict(sorted(c.items())),
                    "positives": {"same_source_view": pos[(pid, "same_source_view_positive")],
                                  "cross_source": pos[(pid, "cross_source_same_product_positive")],
                                  "excluded_cross_source": [r for r in excluded_positives if r["product03"] == pid]},
                    "gap_reasons": reasons, "fit_admitted": False})
    return out


def _summary(products, edges, positives, by_producer, cross_outside, comps, old_pairs):
    evaluated = [e for e in edges if e["decision"] != "excluded_not_evaluated"]
    trans = Counter(e["transition"] for e in evaluated if e["before"])
    resolved = Counter(e["before"]["stage2_decision"] for e in evaluated
                       if e["before"] and e["decision"] == "negative_metadata_supported")
    eligible = [e for e in evaluated if e["decision"] in NEGATIVE and not e["trainable_exclusion"]]
    same_prod_possible = sum(len(set(m)) * (len(set(m)) - 1) // 2 for m in by_producer.values())
    return {
        "products03": len(products), "products_with_admitted_source": sum(bool(p["admitted_sources"]) for p in products.values()),
        "sources": sum(len(p["sources"]) for p in products.values()),
        "admitted_sources": sum(len(p["admitted_sources"]) for p in products.values()),
        "producers": len(by_producer), "same_producer_possible_pairs": same_prod_possible,
        "competitor_pairs": len(comps), "frozen01_edges": len(old_pairs),
        "edges_all": len(edges), "edges_evaluated": len(evaluated), "cross_producer_outside_bound_not_evaluated": cross_outside,
        "nomination_counts": dict(Counter(n for e in edges for n in e["nominations"])),
        "decisions": dict(sorted(Counter(e["decision"] for e in evaluated).items())),
        "decisions_by_relationship": {r: dict(sorted(Counter(e["decision"] for e in evaluated if e["producer_relationship"] == r).items()))
                                      for r in ("same_producer_same_line", "same_producer_other_line", "cross_producer")},
        "eligible_negatives": len(eligible),
        "eligible_negatives_by_evidence": dict(Counter(e["negative_evidence"] for e in eligible)),
        "eligible_negatives_by_relationship": dict(Counter(e["producer_relationship"] for e in eligible)),
        "negatives_excluded_no_admitted_source": sum(1 for e in evaluated if e["decision"] in NEGATIVE and e["trainable_exclusion"]),
        "decisive_attribute_hits_metadata_negatives": dict(Counter(a for e in evaluated if e["decision"] == "negative_metadata_supported"
                                                                   for a in e["decisive_attributes"])),
        "frozen01_before_after": dict(sorted(trans.items())),
        "frozen01_resolved_to_metadata_negative": dict(resolved),
        "remaining_mask_reasons": dict(sorted(Counter(e["reasons"][0] for e in evaluated
                                                      if e["decision"] in ("masked_hold", "vintage_only_held",
                                                                           "masked_no_affirmative_difference",
                                                                           "requires_review_ambiguous")).items())),
        "positives": dict(Counter(r["kind"] for r in positives)),
        "fit_admitted": False}


def write(result):
    OUT.mkdir(parents=True, exist_ok=True)
    RUN.mkdir(parents=True, exist_ok=True)
    outputs = {}
    for name, rows in (("edges.jsonl", result["edges"]), ("products.jsonl", result["products"]),
                       ("positives.jsonl", result["positives"])):
        with open(OUT / name, "w") as f:
            for r in rows:
                f.write(json.dumps(r, ensure_ascii=False, sort_keys=True) + "\n")
        outputs[name] = sha256(OUT / name)
    manifest = {"schema_version": SCHEMA, "status": "candidate_root_review_required", "fit_admitted": False,
                "input_pins": pins(INPUTS), "code_pins": pins(CODE), "upstream": result["upstream"],
                "rules": RULES, "summary": result["summary"], "outputs": outputs,
                "edges_sha256": digest_obj(result["edges"]), "products_sha256": digest_obj(result["products"]),
                "positives_sha256": digest_obj(result["positives"])}
    (OUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=1))
    return manifest


RULES = {
    "graph": "all same-producer ProductID03 pairs (stage1 producer) + frozen-01 edges + competitors-v2 within-producer lists; "
             f"cross-producer competitors only if strong_visual or min visual rank <= {CROSS_PRODUCER_RANK_BOUND}, rest listed as excluded_not_evaluated",
    "negative_legacy_pair_qa": "stage2 negative_candidate_not_fit_admitted (effective QA distinct, shown sources admitted)",
    "negative_metadata_supported": "no old/overlay/identity mask; >=1 decisive difference among color/sugar/style/type (brut-family compatibility respected), "
                                   "bilateral distinctive commercial-title tokens or bilateral typed grape atoms in source-backed titles; grape composition lists support only; no new visual review claimed",
    "masked": "overlay, frozen-01 identity/indistinguishable/source/QA holds, competitors unknown_identity, equal metadata (never merged)",
    "vintage_only_held": "frozen-01 vintage/edition holds, year_variant, or only year/number/context-year differences",
    "requires_review_ambiguous": "contested site-vs-catalogue or cross-card conflicting decisive attribute, or only non-decisive differences (ABV ignored, partial grapes, generic name words, region)",
    "contested_precedence": "catalog_asserted value with site audit differs_audit_only is masked for new negatives; source_verified kept",
    "trainable": "negative with >=1 stage2-admitted source on both sides",
}
