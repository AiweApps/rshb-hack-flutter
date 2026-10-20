"""Stage2 per-source admission for the known-catalogue encoder, separate from ranker CV.

Reads only pinned ledgers/receipts and gallery original bytes; never opens query
or protected pixels, never infers with a model and never mutates roles.
"""
from __future__ import annotations

import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path

from rshb_vine.intraline_visual_v1.negative_overlay import NegativeOverlay

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "data/catalog-training-data-v2/stage2"
PRE = ROOT / "runs/known-catalog-intraline-v2/preflight"
SCHEMA = "catalog-training-data-v2-stage2-source-admission-v1"

LEDGER = "data/expanded-ranker-data-v2/source-ledger.jsonl"
MANIFEST = "runs/b3-v2-runpod-v1/signature-prep-v1/manifest-for-root-signature.json"
REG01 = "data/product-identity-v1/snapshot-01/registry.json"
REG03 = "data/product-identity-v1/snapshot-03-candidate/registry.json"
REFS = "runs/b3-v2-evaluation-final/references.json"
HOLDS = "runs/competitor-identity-v3/root-source-holds.json"
PROTECTED = ("data/ranker-corpus-inventory-v1/frozen/priority01/protected-membership.jsonl",
             "data/ranker-corpus-inventory-v1/protected-membership.jsonl")
GAP = "runs/evaluation-admission-v2/unknown-audit/audit.json"
EDGES = "runs/comparison-groups-v1/frozen-01/edges.jsonl"
QA = ("runs/comparison-groups-v1/qa-fit-union-v1/manifest.json",
      "runs/comparison-groups-v1/qa-fit-union-v1/recovered-priority/manifest.json")
MERGED = "runs/comparison-groups-v1/qa-fit-union-v1/merged-qa-frozen-05/merged-pairs.jsonl"
MASK = "runs/comparison-groups-v1/qa-fit-union-v1/qa-card-revision-v1/frozen-01/negative-mask-candidate-v1.json"
CARD_DECISIONS = "runs/comparison-groups-v1/qa-fit-union-v1/qa-card-revision-v1/frozen-01/card-level-decisions.jsonl"
WEB232 = tuple(f"data/evaluation/web232-v1/{s}.json" for s in ("train", "validation", "test", "protected_hold"))
B2 = "runs/known-catalog-intraline-v2/preflight/b2-derivative-audit.json"
B3 = "runs/known-catalog-intraline-v2/preflight/b3-masked-edge-audit.json"
ROOT_VISUAL = "runs/known-catalog-intraline-v2/preflight/root-source-visual-review-v1.json"
MIXED_ADMISSION = "runs/intraline-visual-v1/canonical-mixed-v1/admission-candidate.json"
MIXED_SCHEDULE = "runs/intraline-visual-v1/canonical-mixed-v1/schedule-candidate.json"
DEPENDENCY_CODE = ("rshb_vine/catalog_training_data_v2/source_admission.py", "scripts/catalog_source_admission_v2.py",
                   "rshb_vine/intraline_visual_v1/negative_overlay.py", "rshb_vine/io.py")
RECOVERY_DIRS = ("data/source-media", "data/evaluation-source-recovery-v1/images")
CARD_SCHEMA = "comparison-card-level-decision-v1"
DISTINCT_EVIDENCE = {"distinct_supported", "confirmed_distinct"}
INPUTS = (LEDGER, MANIFEST, REG01, REG03, REFS, HOLDS, *PROTECTED, GAP, EDGES, *QA, MERGED, MASK,
          CARD_DECISIONS, *WEB232, B2, B3, ROOT_VISUAL, MIXED_ADMISSION, MIXED_SCHEDULE)

# Encoder-only lift allowed by root 2026-09-25; ranker CV keeps these.
LIFTED = {"development108_key": "dev108_producer_or_product",
          "internal_selection_component_key": "internal_selection_component",
          "roster_v2:expansion_candidate_outside_split": "outside_ranker_split"}
LIFTED_ROSTER = {"family_development", "product_is_development_positive", "family_outside_ranker_split"}
CONFIRMED_DERIVATIVE = "hold_gallery_from_fit_as_open_query_photo_derivative"
RELATION_DECISION = {"mask_no_affirmative_difference": "unknown_no_affirmative_difference",
                     "mask_identity_relation": "identity_hold",
                     "mask_vintage_or_edition_only": "vintage_or_edition_hold",
                     "mask_catalogue_indistinguishable": "catalogue_indistinguishable_hold"}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def read(rel: str):
    return json.loads((ROOT / rel).read_text())


def jsonl(rel: str):
    return [json.loads(line) for line in (ROOT / rel).read_text().splitlines() if line.strip()]


def pair_key(a: str, b: str) -> tuple[str, str]:
    return (a, b) if a < b else (b, a)


def digest_obj(obj) -> str:
    return hashlib.sha256(json.dumps(obj, ensure_ascii=False, sort_keys=True).encode()).hexdigest()


def pins(rels=INPUTS) -> dict[str, str]:
    return {rel: sha256(ROOT / rel) for rel in rels}


def _bytes(row):
    """Verify the ledger path; otherwise accept only an existing SHA-named local copy that hashes exactly."""
    s, path = row["original_sha256"], ROOT / row["original_path"]
    status = ("sha_verified" if sha256(path) == s else "sha_mismatch") if path.is_file() else "missing_path"
    recovery = None
    if status != "sha_verified":
        tried = sorted(str(c.relative_to(ROOT)) for d in RECOVERY_DIRS for c in (ROOT / d).glob(s + ".*"))
        verified = [c for c in tried if sha256(ROOT / c) == s]
        recovery = {"scanned_dirs": list(RECOVERY_DIRS), "candidates": tried,
                    "verified_copy": verified[0] if verified else None,
                    "status": "recovered_exact_sha_local_copy" if verified else "pending_no_verified_copy",
                    "original_path_unchanged": row["original_path"]}
    return status, recovery


def _effective_qa(key, merged, card, overlay, owner_snapshot, evidence_sha):
    """Latest completed QA per pair. Manifest membership alone is never a completed review."""
    if key in overlay.pairs:
        return {"decision": "hold", "basis": "frozen01_overlay_masked", "reasons": list(overlay.reasons[key])}
    if card is not None:
        problems = [n for n, bad in (
            ("schema", card.get("schema_version") != CARD_SCHEMA), ("key", tuple(card.get("pair_key03") or ()) != key),
            ("owner_snapshot", card.get("owner_snapshot_sha256") != owner_snapshot),
            ("prior_evidence", not card.get("prior_qa_evidence")), ("reason", not card.get("decision_reason")),
            ("binding_error", bool(card.get("source_binding_error_evidence")))) if bad]
        if problems:
            return {"decision": "hold", "basis": "card_level_invalid", "reasons": problems}
        if card["decision"] == "card_distinct_trainable" and card.get("negative_training_decision") == "remove_old_hold":
            return {"decision": "distinct", "basis": "card_level_override", "pair_index": card["pair_index"],
                    "owner_snapshot_sha256": owner_snapshot, "owner_answer": card.get("owner_answer"),
                    "prior_visual_status": card.get("prior_visual_status"), "decision_reason": card["decision_reason"]}
        return {"decision": "hold", "basis": "card_level_" + str(card["decision"]), "reasons": [card.get("negative_training_decision")]}
    if merged is None:
        return {"decision": "hold", "basis": "qa_listed_not_reviewed", "reasons": ["no_merged_or_card_decision"]}
    evidence = merged.get("qa_evidence") or []
    unbound = [e.get("path") for e in evidence if not e.get("path") or not e.get("status")
               or evidence_sha(e["path"]) != e.get("path_sha256")]
    if not evidence or unbound:
        return {"decision": "hold", "basis": "qa_evidence_missing_or_unbound", "reasons": unbound or ["no_evidence"]}
    if merged.get("explicit_source_binding_hold"):
        return {"decision": "hold", "basis": "explicit_source_binding_hold", "reasons": merged.get("reasons", [])}
    if merged.get("negative_mask_candidate"):
        return {"decision": "hold", "basis": "merged_mask_unresolved", "reasons": merged.get("reasons", [])}
    statuses = [e["status"] for e in evidence]
    base = {"decision": "distinct", "evidence": [[e["kind"], e["status"], e["path"]] for e in evidence]}
    if merged.get("visual_status") == "distinct_supported" and not merged.get("reasons") and set(statuses) <= DISTINCT_EVIDENCE:
        return dict(base, basis="merged_visual_distinct_supported")
    last_zoom = max((i for i, e in enumerate(evidence) if e["kind"] == "zoom_amendment"), default=-1)
    if (merged.get("visual_status") == "distinct_supported" and not merged.get("reasons") and last_zoom >= 0
            and evidence[last_zoom]["status"] == "distinct_supported" and set(statuses[last_zoom:]) <= DISTINCT_EVIDENCE):
        return dict(base, basis="merged_zoom_amendment_distinct_supported",
                    superseded_statuses=statuses[:last_zoom])
    src = merged.get("source_statuses") or []
    if (merged.get("source_confirmed_distinct") and src and set(src) == {"confirmed_distinct"}
            and any(e["kind"] == "source_identity_review" and e["status"] == "confirmed_distinct" for e in evidence)):
        return dict(base, basis="merged_source_confirmed_distinct", resolved_visual_status=merged.get("visual_status"))
    return {"decision": "hold", "basis": "qa_incomplete", "reasons": [merged.get("visual_status"), *src]}


def _query_sources(manifest, slug01, slug03):
    """SHA/ancestor membership of every non-fit B3 manifest role and every web232 split."""
    sources, products, cohorts = defaultdict(set), defaultdict(set), defaultdict(set)
    fit_query = set()
    for row in manifest["rows"]:
        prods = {slug03[s] for p in [row["product_id"], *row.get("acceptable_product_ids", []),
                                     *(row.get("training_group_acceptable_product_ids") or [])]
                 for s in slug01[p] if s in slug03}
        if row["role"] == "encoder_fit":
            if row["asset_role"] == "query":
                fit_query.add(row["source_sha256"])
                fit_query.update(row.get("ancestor_sha256") or [])
            products["encoder_fit"].update(prods)
            continue
        for s in [row["source_sha256"], *(row.get("ancestor_sha256") or [])]:
            sources[s].add("open108:" + row["role"])
        products[row["role"]].update(prods)
    for rel in WEB232:
        split = Path(rel).stem
        for rec in read(rel)["records"]:
            sources[rec["sha256"]].add("web232:" + split)
            cohorts["web232:" + split].add(rec["sha256"])
    return sources, products, fit_query


def build() -> dict:
    pinned = pins()
    ledger = jsonl(LEDGER)
    manifest, refs = read(MANIFEST), read(REFS)
    slug01 = defaultdict(set)
    for card in read(REG01)["cards"]:
        slug01[card["product_id"]].add(card["slug"])
    slug03 = {card["slug"]: card["product_id"] for card in read(REG03)["cards"]}
    qsrc, role_products, fit_query = _query_sources(manifest, slug01, slug03)
    protected = {json.loads(x)["sha256"] for rel in PROTECTED for x in (ROOT / rel).read_text().splitlines() if x.strip()}
    forbidden = set(manifest["forbidden_for_fit_ancestor_sha256"])
    gap_doc = read(GAP)
    gap = set(gap_doc["summary"]["protection_membership_gap"]) | {c["image_sha256"] for c in gap_doc["candidates"]}
    holds = {h["sha256"]: h for h in read(HOLDS)["holds"]}
    overlay = NegativeOverlay(ROOT / MASK)
    owner_snapshot = read(MASK)["owner_journal_snapshot_sha256"]
    mask_sources = overlay.source_shas
    b2, b3, visual = read(B2), read(B3), read(ROOT_VISUAL)
    visual_by_pair = {(r["query_sha256"], r["gallery_sha256"]): r["decision"] for r in visual["rows"]}
    confirmed = {g for (q, g), d in visual_by_pair.items() if d == CONFIRMED_DERIVATIVE}
    sift_by_gallery = defaultdict(list)
    for r in b2["sift_detail_open_only"]:
        item = {"query_sha256": r["query_sha256"], "inliers": r["inliers"], "mae": r["mae"],
                "root_visual": visual_by_pair.get((r["query_sha256"], r["gallery_sha256"]))}
        if item not in sift_by_gallery[r["gallery_sha256"]]:
            sift_by_gallery[r["gallery_sha256"]].append(item)
    dhash_nominations = Counter(r["gallery_sha256"] for r in b2["near_pair_detail_open_only"])
    b2_excluded = b2["excluded_gallery"]
    ref_by_source = defaultdict(list)
    for index, ref in enumerate(refs):
        ref_by_source[ref["image_sha256"]].append(index)
    mixed = read(MIXED_ADMISSION)
    mixed_sources = {c["original_sha256"] for c in mixed["candidates"]}
    schedule = read(MIXED_SCHEDULE)
    mixed_exposure = Counter(step["canonical_source_sha256"] for step in schedule["steps"])

    records, reason_hits, lifted_hits = [], Counter(), Counter()
    seen = set()
    for row in ledger:
        s = row["original_sha256"]
        if s in seen:
            raise ValueError("Duplicate ledger source " + s)
        seen.add(s)
        bytes_status, recovery = _bytes(row)
        views = row["gallery_reference_indices"].get("B3") or []
        joined = []
        for v in views:
            i = v["reference_index"]
            ref = refs[i] if 0 <= i < len(refs) else None
            ok = bool(ref and ref["image_sha256"] == s and slug03.get(ref["slug"]) == row["product03"]
                      and list(ref["bbox"]) == list(v["bbox"]) and ref["kind"] == v["kind"])
            joined.append({"reference_index": i, "kind": v["kind"], "bbox": v["bbox"], "join_ok": ok})
        kinds = Counter(v["kind"] for v in joined if v["join_ok"])
        held, lifted, info = [], [], []
        if bytes_status != "sha_verified" and not (recovery and recovery["verified_copy"]):
            held.append("bytes_" + bytes_status)
        if s in protected: held.append("protected_membership")
        if s in forbidden: held.append("forbidden_fit_ancestor")
        if s in gap: held.append("protection_membership_gap")
        if s in holds: held.append("root_source_hold")
        if s in mask_sources: held.append("qa_mask_source_hold")
        if row["protected_now"]: held.append("protected_now")
        for c in sorted(qsrc.get(s, ())):
            held.append("query_or_ancestor:" + c)
        if s in fit_query: held.append("old_encoder_fit_query_source_or_ancestor")
        if row["roster_v2_status"] == "excluded":
            for r in sorted(set(row["roster_v2_exclusion_reasons"] or [])):
                (lifted if r in LIFTED_ROSTER else held).append("roster:" + r)
        if row["identity_confirmation"] == "unconfirmed": held.append("identity_unconfirmed")
        if row["product03"] in role_products["train_pair_hold"]: held.append("train_pair_hold_product")
        if "product_of_quarantined26_role_conflict_row" in row["decision_reasons"]:
            held.append("quarantine26_product")
        for r in row["decision_reasons"]:
            if r in LIFTED:
                lifted.append(LIFTED[r])
        if s in confirmed:
            held.append("confirmed_open_query_photo_derivative")
        elif s in b2_excluded and "unverifiable_bytes" in b2_excluded[s]:
            held.append("b2_unverifiable_bytes")
        elif sift_by_gallery.get(s):
            unresolved = [x for x in sift_by_gallery[s] if x["root_visual"] is None]
            if unresolved:
                held.append("suspect_hold_sift_nomination_unreviewed")
            else:
                info.append("sift_nomination_root_reviewed_not_duplicate")
        if dhash_nominations.get(s):
            info.append("dhash_nomination_candidates_only")
        if kinds.get("context") != 1 or kinds.get("front_label") != 1 or len(joined) != 2:
            held.append("lacks_two_joined_B3_views")
        held = sorted(set(held))
        for r in held: reason_hits[r] += 1
        for r in set(lifted): lifted_hits[r] += 1
        suspect_only = held == ["suspect_hold_sift_nomination_unreviewed"]
        decision = "admitted_candidate" if not held else ("suspect_hold_provisional" if suspect_only else "held")
        records.append({
            "original_sha256": s, "original_path": row["original_path"], "bytes_status": bytes_status,
            "bytes_recovery": recovery, "product03": row["product03"], "slug": row["slug"], "cards_in_product03": row["cards_in_product03"],
            "frozen_product": row["frozen_product"], "identity_confirmation": row["identity_confirmation"],
            "B3_references": joined, "provenance": {"ledger": LEDGER, "raw_card_fields": row.get("raw_card_fields")},
            "consumers": {
                "encoder_known_catalog": {"decision": decision, "held_reasons": held,
                                          "lifted_encoder_only": sorted(set(lifted)), "info": info},
                "ranker_cv": {"decision": row["decision"], "reasons": row["decision_reasons"],
                              "family_role": row["family_role"], "roster_v2_status": row["roster_v2_status"],
                              "unchanged": True}},
            "derivative_audit": {"sift_open_nominations": sift_by_gallery.get(s, []),
                                 "dhash_open_nominations": dhash_nominations.get(s, 0)},
            "old_mixed_canonical": {"admitted": s in mixed_sources, "schedule_anchor_exposures": mixed_exposure.get(s, 0)},
        })
    admitted = {r["original_sha256"] for r in records if r["consumers"]["encoder_known_catalog"]["decision"] == "admitted_candidate"}
    by_source = {r["original_sha256"]: r for r in records}
    admitted_products = {by_source[s]["product03"] for s in admitted}
    fit_products = admitted_products | role_products["encoder_fit"]

    qa_pairs = {}
    for rel in QA:
        for q in read(rel)["pairs"]:
            qa_pairs[pair_key(q["product_a03"], q["product_b03"])] = q
    merged = {}
    for m in jsonl(MERGED):
        k = pair_key(m["product_a03"], m["product_b03"])
        if k in merged or list(k) != m["pair_key03"]:
            raise ValueError("Duplicate or unordered merged QA key")
        merged[k] = m
    card_dec = {}
    for d in jsonl(CARD_DECISIONS):
        k = tuple(d["pair_key03"])
        if k in card_dec or k != pair_key(*k):
            raise ValueError("Duplicate or unordered card-level decision")
        card_dec[k] = d
    evidence_pins = {}

    def evidence_sha(rel):
        if rel not in evidence_pins:
            evidence_pins[rel] = sha256(ROOT / rel) if (ROOT / rel).is_file() else None
        return evidence_pins[rel]
    b3_rows = {pair_key(r["product_a03"], r["product_b03"]): r for r in b3["rows"]}
    ref_index = defaultdict(list)
    for index, ref in enumerate(refs):
        ref_index[(ref["image_sha256"], ref["slug"], tuple(ref["bbox"]))].append(index)

    pairs, pair_counts = [], Counter()
    for e in jsonl(EDGES):
        key = pair_key(e["product_a03"], e["product_b03"])
        qa, m = qa_pairs.get(key), merged.get(key)
        shown = []
        if qa:
            for side in ("a", "b"):
                ref = qa["reference_" + side]
                idx = ref_index.get((ref["original_sha256"], ref["slug"], tuple(ref["bbox"])), [])
                src = by_source.get(ref["original_sha256"])
                joined_ref = refs[idx[0]] if len(idx) == 1 else None
                claimed_product = qa["product_" + side + "03"]
                normalized_reference_product = slug03.get(joined_ref["slug"]) if joined_ref else None
                binding_ok = bool(src and joined_ref and src["product03"] == claimed_product
                                  and normalized_reference_product == claimed_product)
                shown.append({"product03": qa["product_" + side + "03"], "original_sha256": ref["original_sha256"],
                              "bbox": ref["bbox"], "crop_sha256": ref.get("crop_sha256"),
                              "reference_index": idx[0] if len(idx) == 1 else None,
                              "source_decision": src["consumers"]["encoder_known_catalog"]["decision"] if src else "not_in_ledger",
                              "source_product03": src["product03"] if src else None,
                              "reference_product03": normalized_reference_product,
                              "historical_reference_product_id": joined_ref["product_id"] if joined_ref else None,
                              "product_binding_ok": binding_ok})
        in_pool = set(key) <= fit_products
        eff = _effective_qa(key, m, card_dec.get(key), overlay, owner_snapshot, evidence_sha) if qa else None
        if e["relation"] != "negative_catalogue_distinct":
            decision = RELATION_DECISION[e["relation"]]
        elif not e["negative_allowed"]:
            decision = "negative_not_allowed_source_hold"
        elif key in overlay.pairs:
            decision = "qa_overlay_masked"
        elif not qa:
            decision = "negative_approved_not_qa_shown"
        elif eff["decision"] != "distinct":
            decision = "negative_qa_effective_hold"
        elif any(x["reference_index"] is None for x in shown):
            decision = "negative_qa_shown_reference_unjoined"
        elif any(not x["product_binding_ok"] for x in shown):
            decision = "negative_qa_shown_product_mismatch"
        elif any(x["source_decision"] != "admitted_candidate" for x in shown):
            decision = "negative_qa_shown_source_not_admitted"
        elif not in_pool:
            decision = "negative_qa_reviewed_product_outside_pool"
        else:
            decision = "negative_candidate_not_fit_admitted"
        pair_counts[decision] += 1
        cd = card_dec.get(key)
        pairs.append({"product_a03": key[0], "product_b03": key[1], "relation": e["relation"],
                      "negative_allowed": e["negative_allowed"], "comparison_group_ids": e["comparison_group_ids"],
                      "decision": decision, "both_products_in_encoder_pool": in_pool,
                      "qa": ({"pair_index": qa["pair_index"], "shown": shown,
                              "merged_visual_status": m and m.get("visual_status"),
                              "merged_mask_candidate": m and m.get("negative_mask_candidate"),
                              "card_level_decision": cd and cd["decision"],
                              "effective": eff} if qa else None),
                      "overlay_reasons": list(overlay.reasons.get(key, ())),
                      "b3_class": b3_rows[key]["klass"] if key in b3_rows else None,
                      "masks_are_not_positives": True})

    gap_queue = _gap_queue(records, pairs, b3, b2, visual_by_pair, qsrc, fit_products, admitted_products)
    final = {
        "ledger_sources": len(records), "ledger_products03": len({r["product03"] for r in records}),
        "encoder_decisions_unique_sources": dict(Counter(r["consumers"]["encoder_known_catalog"]["decision"] for r in records)),
        "encoder_admitted_candidate_sources": len(admitted), "encoder_admitted_candidate_products03": len(admitted_products),
        "encoder_fit_real_products03": len(role_products["encoder_fit"]), "encoder_pool_products03_union": len(fit_products),
        "held_reason_hits_not_unique": dict(sorted(reason_hits.items())),
        "encoder_only_lift_hits": dict(sorted(lifted_hits.items())),
        "bytes_status": dict(Counter(r["bytes_status"] for r in records)),
        "ranker_cv_decisions_unchanged": dict(Counter(r["consumers"]["ranker_cv"]["decision"] for r in records)),
        "old_mixed_canonical_sources": len(mixed_sources),
        "old_mixed_canonical_now_not_admitted": sorted(s for s in mixed_sources if s not in admitted),
        "pair_records": len(pairs), "pair_unique_keys": len({(p["product_a03"], p["product_b03"]) for p in pairs}),
        "pair_decisions": dict(sorted(pair_counts.items())),
        "qa_effective_basis_shown_pairs": dict(sorted(Counter(p["qa"]["effective"]["basis"] for p in pairs if p["qa"]).items())),
        "qa_effective_basis_negative_candidates": dict(sorted(Counter(
            p["qa"]["effective"]["basis"] for p in pairs if p["decision"] == "negative_candidate_not_fit_admitted").items())),
        "bytes_recovery": dict(Counter(r["bytes_recovery"]["status"] for r in records if r["bytes_recovery"])),
        "gap_queue_counts": {k: len(v) for k, v in gap_queue.items() if isinstance(v, list)},
        "fit_admitted": False}
    summary = {"schema_version": SCHEMA, "status": "candidate_root_review_required", "fit_admitted": False,
               "input_pins": pinned, "code_pins": pins(DEPENDENCY_CODE), "qa_evidence_pins": dict(sorted(evidence_pins.items())),
               "overlay": {"path": MASK, "sha256": overlay.sha256, "nested_input_pins_validated": True,
                           "owner_journal_snapshot_sha256": owner_snapshot},
               "rules": {"lifted_encoder_only": sorted(LIFTED.values()) + ["roster:family_development"],
                         "hard": "quarantine26, identity/curation/source/QA-mask/pair holds, protected/forbidden/gap/query/ancestor membership, byte mismatch",
                         "b2": "exclude only root-confirmed derivative or unverifiable bytes; unreviewed SIFT nominations suspect_hold_provisional; dHash candidates_only",
                         "pairs": "negative candidate = approved edge + QA shown refs joined to B3 with exact claimed endpoint ProductID matching both reference and source ledger + NegativeOverlay frozen-01 + completed effective QA + every shown source admitted; masks never positives",
                         "bytes": "sha mismatch/missing held unless an existing SHA-named local copy hashes exactly; originals never replaced"},
               "final_counts": final,
               "records_sha256": digest_obj(records), "pairs_sha256": digest_obj(pairs), "gap_queue_sha256": digest_obj(gap_queue)}
    return {"records": records, "pairs": pairs, "gap_queue": gap_queue, "summary": summary}


def _open_query_paths():
    paths = {row["source_sha256"]: row["source_path"] for row in read(MANIFEST)["rows"] if row["role"] != "encoder_fit"}
    for split in ("train", "validation"):
        for rec in read(f"data/evaluation/web232-v1/{split}.json")["records"]:
            path = rec["image_path"]
            if not (ROOT / path).is_file():
                found = sorted((ROOT / "data/evaluation-source-recovery-v1/images").glob(rec["sha256"] + ".*"))
                path = str(found[0].relative_to(ROOT)) if found else None
            paths[rec["sha256"]] = path
    return paths


def _gap_queue(records, pairs, b3, b2, visual_by_pair, qsrc, fit_products, admitted_products):
    by_source = {r["original_sha256"]: r for r in records}
    qpaths = _open_query_paths()
    sift = []
    seen = set()
    for r in b2["sift_detail_open_only"]:
        k = (r["query_sha256"], r["gallery_sha256"])
        if k in seen:
            continue
        seen.add(k)
        g = by_source.get(r["gallery_sha256"])
        cohorts = sorted(qsrc.get(r["query_sha256"], ())) or ["open_register_or_intake"]
        if any(c in ("web232:test", "web232:protected_hold") for c in cohorts):
            raise ValueError("Closed query appears in open-only SIFT detail")
        sift.append({"query_sha256": r["query_sha256"], "query_cohorts": cohorts, "gallery_sha256": r["gallery_sha256"],
                     "gallery_path": g and g["original_path"], "gallery_product03": g and g["product03"],
                     "inliers": r["inliers"], "mae": r["mae"], "root_visual": visual_by_pair.get(k),
                     "strong_mae_lt5": r["mae"] < 5, "query_path_open_only": qpaths.get(r["query_sha256"])})
    mixed_exposed = [{"original_sha256": r["original_sha256"], "product03": r["product03"],
                      "schedule_anchor_exposures": r["old_mixed_canonical"]["schedule_anchor_exposures"],
                      "encoder_decision": r["consumers"]["encoder_known_catalog"]["decision"],
                      "held_reasons": r["consumers"]["encoder_known_catalog"]["held_reasons"]}
                     for r in records if r["old_mixed_canonical"]["admitted"] and
                     r["consumers"]["encoder_known_catalog"]["decision"] != "admitted_candidate"]
    no_source_products = sorted({r["product03"] for r in records} - admitted_products)
    a_rows = [dict(r, attribution_required=True) for r in b3["rows"] if r["klass"].startswith("A_")]
    b_rows = [dict(r, source_review_gallery_only=True) for r in b3["rows"] if r["klass"].startswith("B_")]
    return {"sift_open_pairs_for_root_visual_review": sift,
            "unverifiable_bytes": [r["original_sha256"] for r in records
                                   if "b2_unverifiable_bytes" in r["consumers"]["encoder_known_catalog"]["held_reasons"]
                                   or r["bytes_status"] != "sha_verified"],
            "bytes_recovery_pending": [{"original_sha256": r["original_sha256"], **r["bytes_recovery"]} for r in records
                                       if r["bytes_recovery"] and not r["bytes_recovery"]["verified_copy"]],
            "qa_effective_hold_pairs": [{"pair_key03": [p["product_a03"], p["product_b03"]], "pair_index": p["qa"]["pair_index"],
                                         "effective": p["qa"]["effective"]} for p in pairs
                                        if p["qa"] and p["qa"]["effective"]["decision"] != "distinct"],
            "old_mixed_canonical_exposed_now_held": mixed_exposed,
            "products_without_admitted_source": no_source_products,
            "b3_class_A_requires_source_attribution": a_rows,
            "b3_class_B_gallery_source_review_candidates": b_rows,
            "negative_approved_not_qa_shown": [[p["product_a03"], p["product_b03"]] for p in pairs
                                               if p["decision"] == "negative_approved_not_qa_shown"],
            "limits": ["no query/protected pixels opened", "B2 findings are nominations unless root-confirmed",
                       "B3 classes are not negatives", "not fit-admitted"]}


def write(result: dict) -> dict:
    OUT.mkdir(parents=True, exist_ok=True)
    with open(OUT / "source-ledger.jsonl", "w") as f:
        for r in result["records"]:
            f.write(json.dumps(r, ensure_ascii=False, sort_keys=True) + "\n")
    with open(OUT / "pair-ledger.jsonl", "w") as f:
        for p in result["pairs"]:
            f.write(json.dumps(p, ensure_ascii=False, sort_keys=True) + "\n")
    (OUT / "gap-queue.json").write_text(json.dumps(result["gap_queue"], ensure_ascii=False, indent=1))
    summary = dict(result["summary"])
    summary["outputs"] = {name: sha256(OUT / name) for name in ("source-ledger.jsonl", "pair-ledger.jsonl", "gap-queue.json")}
    (OUT / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=1))
    return summary


def validate() -> dict:
    summary = json.loads((OUT / "summary.json").read_text())
    if summary.get("schema_version") != SCHEMA or summary.get("fit_admitted") is not False:
        raise ValueError("Unexpected summary schema or fit admission")
    for block in ("input_pins", "code_pins", "qa_evidence_pins"):
        pinned = summary[block]
        if block == "code_pins" and set(pinned) != set(DEPENDENCY_CODE):
            raise ValueError("Dependency code pin set changed")
        drift = sorted(rel for rel, d in pinned.items() if (sha256(ROOT / rel) if (ROOT / rel).is_file() else None) != d)
        if drift:
            raise ValueError(block + " drifted: " + ", ".join(drift))
    for name, digest in summary["outputs"].items():
        if sha256(OUT / name) != digest:
            raise ValueError("Output changed after build: " + name)
    rebuilt = build()
    for key in ("records_sha256", "pairs_sha256", "gap_queue_sha256", "final_counts", "rules", "input_pins",
                "code_pins", "qa_evidence_pins", "overlay"):
        if rebuilt["summary"][key] != summary[key]:
            raise ValueError("Closure recompute differs: " + key)
    records, pairs, fc = rebuilt["records"], rebuilt["pairs"], rebuilt["summary"]["final_counts"]
    ledger_shas = [r["original_sha256"] for r in jsonl(LEDGER)]
    if len(records) != len(ledger_shas) or [r["original_sha256"] for r in records] != ledger_shas:
        raise ValueError("Source ledger must cover every ledger original exactly once")
    if sum(fc["encoder_decisions_unique_sources"].values()) != fc["ledger_sources"]:
        raise ValueError("Decision counts do not reconcile")
    hard_prefix = ("protected", "forbidden", "protection_membership_gap", "root_source_hold", "query_or_ancestor",
                   "quarantine26", "identity_unconfirmed", "bytes_", "confirmed_open", "b2_unverifiable",
                   "qa_mask_source_hold", "train_pair_hold")
    unverifiable = set(rebuilt["gap_queue"]["unverifiable_bytes"])
    for r in records:
        enc = r["consumers"]["encoder_known_catalog"]
        rec = r["bytes_recovery"]
        if r["bytes_status"] == "sha_verified":
            if rec is not None:
                raise ValueError("Recovery recorded for verified bytes " + r["original_sha256"])
        elif rec is None or (rec["verified_copy"] is None) != ("bytes_" + r["bytes_status"] in enc["held_reasons"]):
            raise ValueError("Byte integrity hold/recovery inconsistent " + r["original_sha256"])
        elif rec["verified_copy"] and sha256(ROOT / rec["verified_copy"]) != r["original_sha256"]:
            raise ValueError("Recovered copy does not hash to source " + r["original_sha256"])
        if (r["bytes_status"] != "sha_verified") != (r["original_sha256"] in unverifiable) and "b2_unverifiable_bytes" not in enc["held_reasons"]:
            raise ValueError("Unverifiable-bytes queue incomplete " + r["original_sha256"])
        if enc["decision"] == "admitted_candidate" and enc["held_reasons"]:
            raise ValueError("Admitted source carries hold " + r["original_sha256"])
        if enc["decision"] != "admitted_candidate" and not enc["held_reasons"]:
            raise ValueError("Held source without explicit reason " + r["original_sha256"])
        if enc["decision"] == "suspect_hold_provisional" and any(h.startswith(hard_prefix) for h in enc["held_reasons"]):
            raise ValueError("Hard hold hidden as provisional " + r["original_sha256"])
        if not r["consumers"]["ranker_cv"]["unchanged"]:
            raise ValueError("Ranker CV role mutated")
    allowed = {"card_level_override", "merged_visual_distinct_supported", "merged_source_confirmed_distinct",
               "merged_zoom_amendment_distinct_supported"}
    overlay = NegativeOverlay(ROOT / MASK)
    for p in pairs:
        if p["decision"] != "negative_candidate_not_fit_admitted":
            continue
        qa = p["qa"]
        if p["relation"] != "negative_catalogue_distinct" or not qa or p["overlay_reasons"] or \
                (p["product_a03"], p["product_b03"]) in overlay.pairs:
            raise ValueError("Masked or unshown pair became negative candidate")
        if qa["effective"]["decision"] != "distinct" or qa["effective"]["basis"] not in allowed:
            raise ValueError("Negative candidate lacks completed effective QA")
        if any(x["source_decision"] != "admitted_candidate" or x["reference_index"] is None or not x["product_binding_ok"]
               or x["source_product03"] != x["product03"] or x["reference_product03"] != x["product03"] for x in qa["shown"]):
            raise ValueError("Negative candidate shows non-admitted, unjoined or not_in_ledger source")
    dicaspico = [p for p in pairs if (p["product_a03"], p["product_b03"]) in overlay.pairs]
    if len(dicaspico) != len(overlay.pairs) or any(p["decision"] != "qa_overlay_masked" for p in dicaspico):
        raise ValueError("Overlay-masked pair not preserved")
    return {"status": "valid", "summary_sha256": sha256(OUT / "summary.json"), "final_counts": fc}
