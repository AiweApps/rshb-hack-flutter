"""Stage3/4 build, CPU consumer and admission guard. Data-preparation validity only; never fit admission."""
from __future__ import annotations

import json
from collections import Counter, defaultdict
from pathlib import Path

from rshb_vine.catalog_training_data_v2 import pairs, schedule
from rshb_vine.catalog_training_data_v2.pairs import NEGATIVE, ROOT, digest_obj, sha256
from rshb_vine.catalog_training_data_v2.source_admission import MASK, REFS, jsonl, read
from rshb_vine.intraline_visual_v1.negative_overlay import NegativeOverlay

MANIFEST = schedule.OUT / "manifest.json"
CONSUMER = schedule.RUN / "consumer-receipt.json"
ADMISSION = schedule.RUN / "admission.json"
REPORT_JSON = pairs.RUN / "report.json"
REPORT_MD = pairs.RUN / "report.md"
OLD_REAL_MANIFEST_REL = "runs/b3-v2-runpod-v1/signature-prep-v1/manifest-for-root-signature.json"
IN_BATCH_POLICY = "only listed negative is a loss negative; any other in-batch product needs an eligible stage3 edge"


def stage4_rules():
    return {"tiers": schedule.TIERS, "quota": schedule.QUOTA,
            "anchor": "every stage2-admitted source anchors >=1 presentation; selected pair assigned to less-loaded endpoint (per admitted source)",
            "views": "anchor kind alternates front_label/context per source; negative uses same kind; positive alternates cross-source (if any) and same-source other view",
            "order": "stratified by producer: fractional position (i+0.5)/n_producer, ties by digest; order does not balance loss share",
            "loss_weighting": "unimplemented trainer contract: choose and validate producer/product weights when merging real and canonical branches",
            "not": "not a step count, epoch count or trainer budget; 5680/64 not reused"}


def output_rows(path):
    with open(path) as handle:
        return [json.loads(line) for line in handle]


def old_real_branch():
    """Account for the prior real-photo fit branch without admitting it into this cycle."""
    source = ROOT / OLD_REAL_MANIFEST_REL
    rows = json.loads(source.read_text())["rows"]
    fit = [r for r in rows if r["role"] == "encoder_fit"]
    real = [r for r in fit if r["asset_role"] == "query"]
    canonical = [r for r in fit if r["asset_role"] == "reference"]
    return {"manifest_path": OLD_REAL_MANIFEST_REL, "manifest_sha256": sha256(source),
            "prior_fit_rows": len(fit), "prior_real_query_view_rows": len(real),
            "prior_real_unique_source_sha256": len({r["source_sha256"] for r in real}),
            "prior_real_anchor_product_ids": len({r["product_id"] for r in real}),
            "prior_real_acceptable_product_ids": len({p for r in real for p in r["acceptable_product_ids"]}),
            "prior_canonical_reference_view_rows": len(canonical),
            "status": "pinned_prior_fit_branch_not_merged_or_read_by_stage4_trainer"}


def build():
    s3 = pairs.build()
    m3 = pairs.write(s3)
    s4 = schedule.build(s3)
    outputs = schedule.write(s4)
    manifest = {"schema_version": schedule.SCHEMA, "status": "proposed_single_coverage_cycle_not_training_evidence",
                "fit_admitted": False, "stage3_manifest_sha256": sha256(pairs.OUT / "manifest.json"),
                "stage3_digests": {k: m3[k] for k in ("edges_sha256", "products_sha256", "positives_sha256")},
                "code_pins": pairs.pins(pairs.CODE), "input_pins": {**m3["input_pins"], OLD_REAL_MANIFEST_REL: sha256(ROOT / OLD_REAL_MANIFEST_REL)},
                "upstream": s3["upstream"], "legacy_real_branch": old_real_branch(),
                "rules": stage4_rules(),
                "summary": s4["summary"], "outputs": outputs, **schedule.digests(s4)}
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=1))
    receipt = consume()
    report(s3, s4, receipt)
    return manifest, receipt


def consume(schedule_path=None):
    """CPU consumer: iterates every scheduled presentation and checks identities, masks and closure."""
    path = Path(schedule_path) if schedule_path else schedule.OUT / "schedule.jsonl"
    edges = {(e["product_a03"], e["product_b03"]): e for e in jsonl(str((pairs.OUT / "edges.jsonl").relative_to(ROOT)))}
    products = {p["product03"]: p for p in jsonl(str((pairs.OUT / "products.jsonl").relative_to(ROOT)))}
    selection = {tuple(r["pair_key03"]): r for r in jsonl(str((schedule.OUT / "selection.jsonl").relative_to(ROOT)))}
    positives = jsonl(str((pairs.OUT / "positives.jsonl").relative_to(ROOT)))
    allowed_cross = {(r["product03"], frozenset(r["source_sha256"])) for r in positives
                     if r["kind"] == "cross_source_same_product_positive"}
    identity_links = {g["product_id"]: g for g in read(pairs.IDENTITY_LINKS)["groups"] if g.get("verified")}
    registry = read(pairs.IDENTITY_REGISTRY)
    registry_products = {p["product_id"]: p for p in registry["products"]}
    registry_references = {(r["image_sha256"], slug, pid) for r in registry["reference_images"]
                           for slug in r["card_slugs"] for pid in r["product_ids"]}
    ledger = {r["original_sha256"]: r for r in jsonl("data/catalog-training-data-v2/stage2/source-ledger.jsonl")}
    refs = read(REFS)
    overlay = NegativeOverlay(ROOT / MASK)
    views = {}
    for sha, r in ledger.items():
        for v in r["B3_references"]:
            ref = refs[v["reference_index"]]
            if v["join_ok"] and ref["image_sha256"] == sha and ref["kind"] == v["kind"] and list(ref["bbox"]) == list(v["bbox"]):
                views[f"{sha}:{v['kind']}:{v['reference_index']}"] = (sha, v["kind"], r["product03"])
    admitted = {s for s, r in ledger.items() if r["consumers"]["encoder_known_catalog"]["decision"] == "admitted_candidate"}
    nonnegative = defaultdict(set)
    for key, e in edges.items():
        if e["decision"] in schedule.NONNEGATIVE_MASK or (e["decision"] in NEGATIVE and e.get("trainable_exclusion")):
            nonnegative[key[0]].add(key[1])
            nonnegative[key[1]].add(key[0])
    errors = []
    anchor_src, any_src, prod_exp, producer_exp, pair_exp = Counter(), Counter(), Counter(), Counter(), Counter()
    pos_kinds, neg_evidence, neg_tier = Counter(), Counter(), Counter()
    n = 0
    with open(path) as handle:
        for line in handle:
            p = json.loads(line)
            if p["presentation_index"] != n:
                errors.append(f"index gap at {n}")
            n += 1
            a, pos, neg = p["anchor"], p["positive"], p["negative"]

            def check_view(role, item, product):
                v = views.get(item["view_id"])
                if v is None or v[0] != item["source_sha256"] or v[2] != product or (role == "anchor" and v[1] != item["kind"]):
                    errors.append(f"{p['presentation_index']}:{role}:view_join")
                if item["source_sha256"] not in admitted:
                    errors.append(f"{p['presentation_index']}:{role}:source_not_admitted")
                return v
            va = check_view("anchor", a, a["product03"])
            vp = check_view("positive", pos, a["product03"])
            if pos["kind"] == "same_source_view_positive":
                if pos["source_sha256"] != a["source_sha256"] or pos.get("independent_photo") is not False or (va and vp and va[1] == vp[1]):
                    errors.append(f"{p['presentation_index']}:same_source_positive_contract")
            elif pos["kind"] == "cross_source_same_product_positive":
                if (pos["source_sha256"] == a["source_sha256"] or pos.get("independent_photo") is not None
                        or pos.get("capture_independence") != "not_established_different_source_sha_only"
                        or (a["product03"], frozenset((a["source_sha256"], pos["source_sha256"]))) not in allowed_cross):
                    errors.append(f"{p['presentation_index']}:cross_source_positive_contract")
            else:
                errors.append(f"{p['presentation_index']}:unknown_positive_kind")
            if pos.get("loss_use") != "positive_pull" or p.get("in_batch_policy") != IN_BATCH_POLICY:
                errors.append(f"{p['presentation_index']}:loss_policy")
            if a["product03"] not in products or p.get("producer") != (products[a["product03"]]["producers"] or ["unknown"])[0]:
                errors.append(f"{p['presentation_index']}:anchor_product_or_producer")
            for s in {a["source_sha256"], pos["source_sha256"]}:
                any_src[s] += 1
            anchor_src[a["source_sha256"]] += 1
            prod_exp[a["product03"]] += 1
            producer_exp[p["producer"]] += 1
            pos_kinds[pos["kind"]] += 1
            if neg:
                key = tuple(neg["pair_key03"])
                e = edges.get(key)
                if (e is None or a["product03"] not in key or neg["product03"] not in key or neg["product03"] == a["product03"]
                        or e["decision"] not in NEGATIVE or e.get("trainable_exclusion") or not selection.get(key, {}).get("selected")
                        or key in overlay.pairs or neg["product03"] in p["anchor_nonnegative_products03"]
                        or neg.get("loss_use") != "negative_push" or neg.get("decision") != (e or {}).get("decision")
                        or neg.get("negative_evidence") != (e or {}).get("negative_evidence")
                        or neg.get("tier") != schedule.TIERS.get((e or {}).get("producer_relationship"))
                        or neg.get("decisive_attributes") != (e or {}).get("decisive_attributes")):
                    errors.append(f"{p['presentation_index']}:negative_contract")
                check_view("negative", neg, neg["product03"])
                if e and e["decision"] == "negative_legacy_pair_qa":
                    expected = schedule.legacy_qa_provenance(e, a["product03"], a["source_sha256"],
                                                             neg["product03"], neg["source_sha256"], products, identity_links,
                                                             registry_products, registry_references)
                    if neg.get("legacy_qa_provenance") != expected:
                        errors.append(f"{p['presentation_index']}:legacy_qa_transfer_provenance")
                elif neg.get("legacy_qa_provenance") is not None:
                    errors.append(f"{p['presentation_index']}:unexpected_legacy_qa_provenance")
                if views.get(neg["view_id"], (None, None))[1] != a["kind"]:
                    errors.append(f"{p['presentation_index']}:negative_kind")
                pair_exp[key] += 1
                any_src[neg["source_sha256"]] += 1
                prod_exp[neg["product03"]] += 1
                neg_evidence[neg["negative_evidence"]] += 1
                neg_tier[neg["tier"]] += 1
            elif p["negative_absent_reason"] != "no_eligible_selected_negative_for_product":
                errors.append(f"{p['presentation_index']}:negative_absent_without_reason")
            if set(p["anchor_nonnegative_products03"]) != nonnegative[a["product03"]] - ({neg["product03"]} if neg else set()):
                errors.append(f"{p['presentation_index']}:nonnegative_mask_drift")
    unanchored = sorted(admitted - set(anchor_src))
    selected = [k for k, r in selection.items() if r["selected"]]
    unpresented = [k for k in selected if not pair_exp.get(k)]
    held_in_schedule = sorted(set(any_src) - admitted)
    if unanchored:
        errors.append(f"unanchored_admitted_sources:{len(unanchored)}")
    if unpresented:
        errors.append(f"selected_pairs_not_presented:{len(unpresented)}")
    if held_in_schedule:
        errors.append(f"held_sources_in_schedule:{len(held_in_schedule)}")
    if not pair_exp:
        errors.append("zero_selected_pair_exposures")
    active = sorted(products)
    producers = sorted({(p["producers"] or ["unknown"])[0] for p in products.values()})
    admitted_products = [pid for pid, p in products.items() if p["n_admitted_sources"]]
    receipt = {"kind": "catalog-training-data-v2-stage4-cpu-consumer-v1", "schedule_sha256": sha256(path),
               "presentations_iterated": n, "errors": errors[:50], "n_errors": len(errors), "passed": not errors,
               "admitted_sources": len(admitted), "admitted_sources_anchored": len(admitted) - len(unanchored),
               "selected_pairs": len(selected), "selected_pairs_presented": len(selected) - len(unpresented),
               "positive_kinds": dict(pos_kinds), "negative_evidence": dict(neg_evidence), "negative_tiers": dict(neg_tier),
               "presentations_without_negative": n - sum(pair_exp.values()),
               "exposure": {"anchor_per_admitted_source": schedule.exposure_stats(anchor_src, sorted(admitted)),
                            "any_role_per_admitted_source": schedule.exposure_stats(any_src, sorted(admitted)),
                            "per_admitted_product": schedule.exposure_stats(prod_exp, admitted_products),
                            "anchor_per_producer": schedule.exposure_stats(producer_exp, producers),
                            "per_selected_pair": schedule.exposure_stats(pair_exp, selected)},
               "producer_skew": _skew(producer_exp, products),
               "products_total": len(active), "fit_admitted": False,
               "limits": ["CPU identity/mask/closure check only; no pixels decoded, no trainer run",
                          "mixed_train.py hardcodes 5680 steps and the old canonical/loss schema; it cannot consume this cycle or merge the real branch safely"]}
    if schedule_path is None:
        CONSUMER.parent.mkdir(parents=True, exist_ok=True)
        CONSUMER.write_text(json.dumps(receipt, ensure_ascii=False, indent=1))
    return receipt


def _skew(producer_exp, products):
    share = Counter((p["producers"] or ["unknown"])[0] for p in products.values() if p["n_admitted_sources"])
    total_p, total_e = sum(share.values()), sum(producer_exp.values())
    rows = sorted(((producer_exp[k] / total_e) / (share[k] / total_p), k) for k in share if share[k])
    top = sorted(producer_exp.items(), key=lambda kv: -kv[1])[:5]
    return {"presentation_share_over_product_share": {"min": round(rows[0][0], 3), "median": round(median_(r[0] for r in rows), 3),
                                                     "max": round(rows[-1][0], 3), "max_producer": rows[-1][1]},
            "top5_producers_presentation_share": [[k, round(v / total_e, 4), round(share[k] / total_p, 4)] for k, v in top]}


def median_(it):
    v = sorted(it)
    return (v[len(v) // 2] + v[(len(v) - 1) // 2]) / 2


def admission():
    """Pins, fresh upstream validation, full rebuild/replay equality and consumer pass."""
    blocks, checks = [], {}
    manifest = json.loads(MANIFEST.read_text())
    s3m = json.loads((pairs.OUT / "manifest.json").read_text())
    if s3m.get("schema_version") != pairs.SCHEMA or s3m.get("fit_admitted") is not False or manifest.get("schema_version") != schedule.SCHEMA or manifest.get("fit_admitted") is not False:
        blocks.append("manifest_schema_or_fit_flag_invalid")
    if manifest.get("stage3_manifest_sha256") != sha256(pairs.OUT / "manifest.json") or manifest.get("stage3_digests") != {k: s3m.get(k) for k in ("edges_sha256", "products_sha256", "positives_sha256")}:
        blocks.append("stage4_stage3_binding_invalid")
    if s3m.get("code_pins") != pairs.pins(pairs.CODE) or manifest.get("code_pins") != s3m.get("code_pins"):
        blocks.append("code_pin_manifest_invalid")
    if s3m.get("input_pins") != pairs.pins(pairs.INPUTS) or manifest.get("input_pins") != {**s3m.get("input_pins", {}), OLD_REAL_MANIFEST_REL: sha256(ROOT / OLD_REAL_MANIFEST_REL)}:
        blocks.append("input_pin_manifest_invalid")
    if manifest.get("legacy_real_branch") != old_real_branch():
        blocks.append("legacy_real_branch_binding_invalid")
    if s3m.get("rules") != pairs.RULES or manifest.get("rules") != stage4_rules():
        blocks.append("rules_drift")
    drift = [r for r, d in {**manifest["code_pins"], **manifest["input_pins"]}.items() if sha256(ROOT / r) != d]
    checks["pins_unchanged"] = not drift
    if drift:
        blocks.append("pin_drift:" + ",".join(drift))
    out_drift = [n for n, d in {**s3m["outputs"]}.items() if sha256(pairs.OUT / n) != d] + \
                [n for n, d in manifest["outputs"].items() if sha256(schedule.OUT / n) != d]
    if out_drift:
        blocks.append("output_changed_after_build:" + ",".join(out_drift))
    s3 = pairs.build()
    checks["fresh_upstream"] = s3["upstream"]
    if s3["upstream"] != manifest["upstream"]:
        blocks.append("upstream_validation_differs")
    if s3m.get("upstream") != s3["upstream"] or s3m.get("summary") != s3["summary"]:
        blocks.append("stage3_manifest_closure_invalid")
    for k, v in (("edges_sha256", digest_obj(s3["edges"])), ("products_sha256", digest_obj(s3["products"])),
                 ("positives_sha256", digest_obj(s3["positives"]))):
        if s3m[k] != v:
            blocks.append("stage3_rebuild_differs:" + k)
    for name, key in (("edges.jsonl", "edges"), ("products.jsonl", "products"), ("positives.jsonl", "positives")):
        if digest_obj(output_rows(pairs.OUT / name)) != digest_obj(s3[key]):
            blocks.append("stage3_actual_rows_differ:" + name)
    s4 = schedule.build(s3)
    if manifest.get("upstream") != s3["upstream"] or manifest.get("summary") != s4["summary"]:
        blocks.append("stage4_manifest_closure_invalid")
    for k, v in schedule.digests(s4).items():
        if manifest[k] != v:
            blocks.append("stage4_rebuild_differs:" + k)
    for name, key in (("schedule.jsonl", "schedule"), ("selection.jsonl", "selection")):
        if digest_obj(output_rows(schedule.OUT / name)) != digest_obj(s4[key]):
            blocks.append("stage4_actual_rows_differ:" + name)
    invalid_positive = [r for r in s3["positives"] if
                        (r["kind"] == "same_source_view_positive" and
                         (r.get("independent_photo") is not False or len(r["source_sha256"]) != 1)) or
                        (r["kind"] == "cross_source_same_product_positive" and
                         (r.get("independent_photo") is not None or r.get("capture_independence") != "not_established_different_source_sha_only"
                          or len(r["source_sha256"]) != 2 or len(set(r["source_sha256"])) != 2)) or
                        r["kind"] not in ("same_source_view_positive", "cross_source_same_product_positive")]
    if invalid_positive:
        blocks.append(f"positive_provenance_invalid:{len(invalid_positive)}")
    receipt = consume()
    checks["consumer"] = {k: receipt[k] for k in ("passed", "n_errors", "presentations_iterated", "admitted_sources_anchored",
                                                  "selected_pairs_presented")}
    if not receipt["passed"]:
        blocks.append("consumer_failed:" + ";".join(receipt["errors"][:5]))
    overlay = NegativeOverlay(ROOT / MASK)
    bad = [e for e in s3["edges"] if e["decision"] in NEGATIVE and (
        (e["product_a03"], e["product_b03"]) in overlay.pairs or e["negative_evidence"] is None
        or (e["decision"] == "negative_metadata_supported" and not e["decisive_attributes"]))]
    if bad:
        blocks.append(f"invalid_negative_edges:{len(bad)}")
    unknown_identity = [p["product03"] for p in s3["products"] if not p["cards"]]
    if unknown_identity:
        blocks.append("unknown_product_identity")
    result = {"kind": "catalog-training-data-v2-stage34-admission-v1", "data_preparation_valid": not blocks,
              "fit_admitted": False, "blocks": blocks, "checks": checks,
              "stage3_manifest_sha256": sha256(pairs.OUT / "manifest.json"), "stage4_manifest_sha256": sha256(MANIFEST),
              "consumer_receipt_sha256": sha256(CONSUMER),
              "fit_blockers_outside_scope": ["mixed_train.py reader/real-branch merge and new negative/mask/loss contract",
                                             "producer/product loss weighting and measured skew",
                                             "bounded budget/selection protocol and root technical admission"],
              "note": "optional attributes (sparkling_style/label_color/etc.) are comparison opportunities, not required per card"}
    ADMISSION.write_text(json.dumps(result, ensure_ascii=False, indent=1))
    return result


def report(s3, s4, receipt):
    s, sel = s3["summary"], s4["summary"]["selection"]
    out = {"stage3": s, "stage4": s4["summary"], "consumer": receipt}
    REPORT_JSON.parent.mkdir(parents=True, exist_ok=True)
    REPORT_JSON.write_text(json.dumps(out, ensure_ascii=False, indent=1))
    ex = receipt["exposure"]

    def st(x):
        return f"{x['min']}/{x['median']}/{x['max']} (zero {x['zero']}, n={x['n']})" if x else "—"
    lines = [
        "# Catalogue pairs v2 · stage3/4 (candidate, fit_admitted=false)", "",
        f"Products03 {s['products03']}, with admitted source {s['products_with_admitted_source']}; sources {s['sources']}, admitted {s['admitted_sources']}.",
        f"Same-producer possibilities: {s['same_producer_possible_pairs']} ProductID03 pairs ({s['same_producer_possible_card_pairs_active']} active card pairs), {s['producers']} producers.",
        f"Edges all {s['edges_all']}; evaluated {s['edges_evaluated']}; cross-producer outside visual bound (listed, not evaluated) {s['cross_producer_outside_bound_not_evaluated']}.",
        f"Frozen-01 edges {s['frozen01_edges']}; competitors-v2 pairs {s['competitor_pairs']}.", "",
        "## Decisions", "", "| decision | all | same line | same producer other line | cross producer |", "|---|---:|---:|---:|---:|"]
    rel = s["decisions_by_relationship"]
    for d, n in s["decisions"].items():
        lines.append(f"| {d} | {n} | {rel['same_producer_same_line'].get(d, 0)} | {rel['same_producer_other_line'].get(d, 0)} | {rel['cross_producer'].get(d, 0)} |")
    lines += ["", f"Eligible negatives (both sides admitted): {s['eligible_negatives']} — {s['eligible_negatives_by_evidence']}; "
              f"by relationship {s['eligible_negatives_by_relationship']}. Negatives without admitted source: {s['negatives_excluded_no_admitted_source']}.",
              f"Decisive attribute hits (metadata negatives): {s['decisive_attribute_hits_metadata_negatives']}. Grapes are support-only.",
              f"Site precedence applied (card attrs): {s['site_precedence_card_attributes']}; contested kept masked: {s['contested_card_attributes']}.",
              "", "## Frozen-01 before → after", ""]
    lines += [f"- {k}: {v}" for k, v in s["frozen01_before_after"].items()]
    lines += ["", f"Newly resolved to metadata negative: {s['frozen01_resolved_to_metadata_negative']}.", "",
              "## Remaining masks / review (first reason)", ""]
    lines += [f"- {k}: {v}" for k, v in s["remaining_mask_reasons"].items()]
    lines += ["", "## One coverage cycle (proposed, not training evidence)", "",
              f"Eligible {sel['eligible']}, selected {sel['selected']}, unselected eligible {sel['unselected_eligible']} (listed in selection.jsonl).",
              f"Selected by tier {sel['selected_by_tier']} of {sel['eligible_by_tier']}; by evidence {sel['selected_by_evidence']}.",
              f"Presentations {s4['summary']['presentations']}: {s4['summary']['purposes']}.",
              f"Consumer: passed={receipt['passed']}, errors {receipt['n_errors']}; anchored {receipt['admitted_sources_anchored']}/{receipt['admitted_sources']} admitted sources; "
              f"selected pairs presented {receipt['selected_pairs_presented']}/{receipt['selected_pairs']}; without negative {receipt['presentations_without_negative']}.",
              f"Positives: {receipt['positive_kinds']} (cross-source SHA inequality does not establish independent capture).", "",
              "Exposure min/median/max:", "",
              f"- anchor per admitted source: {st(ex['anchor_per_admitted_source'])}",
              f"- any role per admitted source: {st(ex['any_role_per_admitted_source'])}",
              f"- per admitted product: {st(ex['per_admitted_product'])}",
              f"- anchor per producer: {st(ex['anchor_per_producer'])}",
              f"- per selected pair: {st(ex['per_selected_pair'])}",
              f"- producer presentation/product share: {receipt['producer_skew']['presentation_share_over_product_share']}", "",
              "Producer interleaving changes order only. It does not equalize the share of loss. Loss weights still need a trainer contract.",
              "The 3/2 per-product quotas are a coverage proposal, not an optimized duration or training budget.", "",
              "## Prior real-photo branch", "",
              f"Pinned manifest: {OLD_REAL_MANIFEST_REL} ({old_real_branch()['manifest_sha256']}).",
              f"Prior encoder fit: {old_real_branch()['prior_fit_rows']} rows; {old_real_branch()['prior_real_query_view_rows']} real query views over "
              f"{old_real_branch()['prior_real_unique_source_sha256']} unique photos and {old_real_branch()['prior_real_anchor_product_ids']} anchor ProductIDs; "
              f"{old_real_branch()['prior_canonical_reference_view_rows']} reference views.",
              f"The {old_real_branch()['prior_real_acceptable_product_ids']} acceptable ProductIDs are a label-set denominator, "
              "not the 355 anchor-ID denominator. This canonical-only cycle does not merge or discard that branch.", "",
              "## Remaining blocks", "",
              "- fit_admitted=false; root technical admission is required after consumer integration and bounded protocol.",
              "- Metadata negatives carry no new visual review; legacy QA negatives are separately labelled.",
              "- mixed_train.py hardcodes 5680 steps and the old canonical schema/masks/loss columns. A new reader must merge the pinned real-photo branch and honour positive_pull, negative_push, anchor_nonnegative_products03, and in_batch_policy.",
              "- Producer/product loss weighting, cycle count, steps and evaluation budget are not chosen here."]
    REPORT_MD.write_text("\n".join(lines) + "\n")
