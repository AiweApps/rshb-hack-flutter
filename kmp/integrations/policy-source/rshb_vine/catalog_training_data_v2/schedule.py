"""Stage4 proposed single coverage cycle over stage3 relations; not a training budget or evidence of a run."""
from __future__ import annotations

import json
from collections import Counter, defaultdict
from statistics import median

from rshb_vine.catalog_training_data_v2.pairs import NEGATIVE, ROOT, IDENTITY_BUNDLE, IDENTITY_LINKS, IDENTITY_REGISTRY, digest_obj, order_key, pair_key, sha256

SCHEMA = "catalog-training-data-v2-stage4-coverage-cycle-v1"
OUT = ROOT / "data/catalog-training-data-v2/stage4"
RUN = ROOT / "runs/catalog-training-data-v2/stage4"
TIERS = {"same_producer_same_line": "T1_same_line_all", "same_producer_other_line": "T2_same_producer_quota",
         "cross_producer": "T3_cross_producer_visual_quota"}
QUOTA = {"T2_same_producer_quota": 3, "T3_cross_producer_visual_quota": 2}
NONNEGATIVE_MASK = {"masked_hold", "vintage_only_held", "masked_no_affirmative_difference", "requires_review_ambiguous"}


def legacy_qa_provenance(edge, anchor_pid, anchor_source, negative_pid, negative_source, products, identity_links, registry_products, registry_references):
    if edge["decision"] != "negative_legacy_pair_qa":
        return None
    shown = {r["product03"]: r["original_sha256"] for r in edge["legacy_pair_qa_shown"]}
    if set(shown) != {anchor_pid, negative_pid}:
        raise ValueError("Legacy pair QA shown source binding incomplete")
    used = {anchor_pid: anchor_source, negative_pid: negative_source}
    source_index = {pid: {s["original_sha256"]: s["slug"] for s in products[pid]["sources"]} for pid in used}
    transfers = []
    for pid, source in used.items():
        original = shown[pid]
        if source == original:
            basis = "exact_qa_shown_source"
        elif source_index[pid][source] == source_index[pid][original]:
            basis = "same_card_admitted_source"
        else:
            group = identity_links.get(pid)
            bindings = {(r["image_sha256"], r["slug"]) for r in group["reference_bindings"]} if group else set()
            if {(source, source_index[pid][source]), (original, source_index[pid][original])} <= bindings:
                basis = "verified_product_identity_exact_sha_transfer"
            elif (pid in registry_products and registry_products[pid]["identity_status"] == "source_admitted"
                  and registry_products[pid]["cross_card_equivalence"] == "verified_only_listed_members"
                  and {(source, source_index[pid][source], pid), (original, source_index[pid][original], pid)} <= registry_references):
                basis = "active_registry_verified_listed_members_exact_sha_transfer"
            elif edge["decisive_attributes"]:
                basis = "source_backed_metadata_decisive_difference"
            else:
                raise ValueError(f"Legacy QA unproven source transfer: {pid} {original} -> {source}")
        transfers.append({"product03": pid, "shown_sha256": original, "used_sha256": source,
                          "shown_slug": source_index[pid][original], "used_slug": source_index[pid][source],
                          "basis": basis, "identity_link_path": IDENTITY_LINKS if basis == "verified_product_identity_exact_sha_transfer" else None,
                          "active_registry_path": IDENTITY_BUNDLE if basis == "active_registry_verified_listed_members_exact_sha_transfer" else None})
    return {"qa_pointer": edge["legacy_pair_qa_pointer"], "source_transfers": transfers,
            "metadata_decisive_attributes": edge["decisive_attributes"],
            "metadata_claim_pointers": edge["claim_pointers"] if edge["decisive_attributes"] else {}}


def _hardness(e):
    v = e.get("visual") or {}
    rank = v.get("rrf_min_rank") if v.get("rrf_min_rank") is not None else 10 ** 6
    same_attrs = sum(e["comparisons"][a]["relation"] in ("equal", "compatible_specificity")
                     for a in ("wine_color", "sweetness", "sparkling_style", "wine_type"))
    return (rank, -same_attrs, order_key(e["product_a03"], e["product_b03"]))


def select(edges):
    eligible = [e for e in edges if e["decision"] in NEGATIVE and not e.get("trainable_exclusion")]
    chosen = {}
    for e in eligible:
        key = (e["product_a03"], e["product_b03"])
        tier = TIERS[e["producer_relationship"]]
        if tier == "T1_same_line_all":
            chosen[key] = ["T1_same_line_all"]
        elif e["decision"] == "negative_legacy_pair_qa":
            chosen[key] = ["legacy_pair_qa_all"]
    by_product = defaultdict(lambda: defaultdict(list))
    for e in eligible:
        tier = TIERS[e["producer_relationship"]]
        if tier in QUOTA:
            for side in ("product_a03", "product_b03"):
                by_product[e[side]][tier].append(e)
    for pid in sorted(by_product):
        for tier, rows in sorted(by_product[pid].items()):
            for e in sorted(rows, key=_hardness)[:QUOTA[tier]]:
                chosen.setdefault((e["product_a03"], e["product_b03"]), []).append(f"{tier}:top{QUOTA[tier]}_hardness_for:{pid}")
    rows = []
    for e in eligible:
        key = (e["product_a03"], e["product_b03"])
        rows.append({"pair_key03": list(key), "tier": TIERS[e["producer_relationship"]], "decision": e["decision"],
                     "negative_evidence": e["negative_evidence"], "selected": key in chosen,
                     "selection_reasons": sorted(set(chosen.get(key, []))) or
                     [f"outside_per_product_quota:{TIERS[e['producer_relationship']]}"],
                     "hardness": list(_hardness(e)[:2])})
    return rows


def build(stage3):
    edges, products = stage3["edges"], {p["product03"]: p for p in stage3["products"]}
    selection = select(edges)
    edge_by_key = {(e["product_a03"], e["product_b03"]): e for e in edges}
    selected = [tuple(r["pair_key03"]) for r in selection if r["selected"]]
    sources = {pid: [s for s in p["sources"] if s["decision"] == "admitted_candidate"] for pid, p in products.items()}
    allowed_cross = defaultdict(set)
    from rshb_vine.catalog_training_data_v2.source_admission import read
    identity_links = {g["product_id"]: g for g in read(IDENTITY_LINKS)["groups"] if g.get("verified")}
    registry = read(IDENTITY_REGISTRY)
    registry_products = {p["product_id"]: p for p in registry["products"]}
    registry_references = {(r["image_sha256"], slug, pid) for r in registry["reference_images"]
                           for slug in r["card_slugs"] for pid in r["product_ids"]}
    for row in stage3["positives"]:
        if row["kind"] == "cross_source_same_product_positive":
            a, b = row["source_sha256"]
            allowed_cross[(row["product03"], a)].add(b)
            allowed_cross[(row["product03"], b)].add(a)
    nonneg = defaultdict(set)
    for e in edges:
        if e["decision"] in NONNEGATIVE_MASK or (e["decision"] in NEGATIVE and e.get("trainable_exclusion")):
            nonneg[e["product_a03"]].add(e["product_b03"])
            nonneg[e["product_b03"]].add(e["product_a03"])
    load = Counter()
    assigned = defaultdict(list)
    for key in sorted(selected, key=lambda k: (TIERS[edge_by_key[k]["producer_relationship"]], order_key(*k))):
        a, b = key
        anchor = min((a, b), key=lambda p: (load[p] / len(sources[p]), order_key(p, *key)))
        load[anchor] += 1
        assigned[anchor].append(key)
    touching = defaultdict(list)
    for key in selected:
        for p in key:
            touching[p].append(key)
    counters = Counter()
    presentations = []
    for pid in sorted(products):
        adm = sources[pid]
        if not adm:
            continue
        jobs = [(k, "selected_pair_presentation") for k in sorted(assigned[pid], key=lambda k: order_key(*k))]
        reuse = sorted(touching[pid], key=lambda k: order_key(pid, *k))
        while len(jobs) < len(adm):
            k = reuse[(len(jobs)) % len(reuse)] if reuse else None
            jobs.append((k, "source_anchor_coverage_reuse" if k else "source_anchor_coverage_no_eligible_negative"))
        for i, (key, purpose) in enumerate(jobs):
            src = adm[i % len(adm)]
            c = counters[src["original_sha256"]]
            counters[src["original_sha256"]] += 1
            views = {v["kind"]: v for v in src["views"]}
            kind = "front_label" if c % 2 == 0 else "context"
            other = [s for s in adm if s["original_sha256"] in allowed_cross[(pid, src["original_sha256"] )]]
            if other and c % 2 == 0:
                pos_src = other[c // 2 % len(other)]
                pos = {"kind": "cross_source_same_product_positive", "independent_photo": None,
                       "capture_independence": "not_established_different_source_sha_only",
                       "source_sha256": pos_src["original_sha256"],
                       "view_id": {v["kind"]: v for v in pos_src["views"]}[kind]["view_id"]}
            else:
                pos = {"kind": "same_source_view_positive", "independent_photo": False,
                       "source_sha256": src["original_sha256"],
                       "view_id": views["context" if kind == "front_label" else "front_label"]["view_id"]}
            neg, neg_reason = None, None
            if key:
                other_pid = key[1] if key[0] == pid else key[0]
                nsrcs = sources[other_pid]
                e = edge_by_key[key]
                nsrc = nsrcs[counters["neg:" + other_pid] % len(nsrcs)]
                counters["neg:" + other_pid] += 1
                neg = {"product03": other_pid, "source_sha256": nsrc["original_sha256"],
                       "view_id": {v["kind"]: v for v in nsrc["views"]}[kind]["view_id"], "pair_key03": list(key),
                       "decision": e["decision"], "negative_evidence": e["negative_evidence"],
                       "tier": TIERS[e["producer_relationship"]], "decisive_attributes": e["decisive_attributes"],
                       "legacy_qa_provenance": legacy_qa_provenance(e, pid, src["original_sha256"], other_pid,
                                                                    nsrc["original_sha256"], products, identity_links,
                                                                    registry_products, registry_references),
                       "loss_use": "negative_push"}
            else:
                neg_reason = "no_eligible_selected_negative_for_product"
            presentations.append({
                "producer": (products[pid]["producers"] or ["unknown"])[0], "purpose": purpose,
                "anchor": {"product03": pid, "source_sha256": src["original_sha256"], "view_id": views[kind]["view_id"],
                           "kind": kind},
                "positive": dict(pos, loss_use="positive_pull"), "negative": neg, "negative_absent_reason": neg_reason,
                "anchor_nonnegative_products03": sorted(nonneg[pid] - ({neg["product03"]} if neg else set())),
                "in_batch_policy": "only listed negative is a loss negative; any other in-batch product needs an eligible stage3 edge"})
    by_producer = defaultdict(list)
    for p in presentations:
        p["_key"] = order_key(p["anchor"]["view_id"], p["positive"]["view_id"], (p["negative"] or {}).get("view_id", ""))
        by_producer[p["producer"]].append(p)
    ordered = []
    for prod, rows in by_producer.items():
        rows.sort(key=lambda p: p["_key"])
        for i, p in enumerate(rows):
            ordered.append(((i + 0.5) / len(rows), p["_key"], p))
    ordered.sort(key=lambda t: (t[0], t[1]))
    schedule = []
    for i, (_, _, p) in enumerate(ordered):
        del p["_key"]
        schedule.append({"presentation_index": i, **p})
    unselected = [r for r in selection if not r["selected"]]
    summary = {"selection": {"eligible": len(selection), "selected": len(selected), "unselected_eligible": len(unselected),
                             "selected_by_tier": dict(Counter(r["tier"] for r in selection if r["selected"])),
                             "eligible_by_tier": dict(Counter(r["tier"] for r in selection)),
                             "selected_by_evidence": dict(Counter(r["negative_evidence"] for r in selection if r["selected"])),
                             "quota": QUOTA, "t1_same_line": "all eligible same-line pairs selected (no cap)",
                             "legacy_pair_qa": "all eligible legacy QA negatives selected"},
               "presentations": len(schedule), "purposes": dict(Counter(p["purpose"] for p in schedule))}
    return {"schedule": schedule, "selection": selection, "summary": summary}


def exposure_stats(counter, universe):
    vals = [counter.get(u, 0) for u in universe]
    if not vals:
        return None
    return {"n": len(vals), "min": min(vals), "median": median(vals), "max": max(vals), "zero": sum(v == 0 for v in vals)}


def write(result):
    OUT.mkdir(parents=True, exist_ok=True)
    RUN.mkdir(parents=True, exist_ok=True)
    outputs = {}
    for name, rows in (("schedule.jsonl", result["schedule"]), ("selection.jsonl", result["selection"])):
        with open(OUT / name, "w") as f:
            for r in rows:
                f.write(json.dumps(r, ensure_ascii=False, sort_keys=True) + "\n")
        outputs[name] = sha256(OUT / name)
    return outputs


def digests(result):
    return {"schedule_sha256": digest_obj(result["schedule"]), "selection_sha256": digest_obj(result["selection"])}


__all__ = ["build", "write", "digests", "exposure_stats", "pair_key", "SCHEMA", "OUT", "RUN"]
