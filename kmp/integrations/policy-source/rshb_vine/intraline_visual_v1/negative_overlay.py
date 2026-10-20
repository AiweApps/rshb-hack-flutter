"""Versioned QA exclusion overlay for *negative* B3 comparisons only.

This is a consumer of the frozen comparison QA contract. A blocked pair is
unknown/held evidence, never an assertion that two ProductIDs are identical.
"""
from __future__ import annotations

import json
from pathlib import Path

from rshb_vine.io import sha256

ROOT = Path(__file__).resolve().parents[2]


def pair_key(a: str, b: str) -> tuple[str, str]:
    return tuple(sorted((a, b)))


class NegativeOverlay:
    def __init__(self, path: Path):
        self.path = Path(path)
        self.sha256 = sha256(self.path)
        doc = json.loads(self.path.read_text())
        if doc.get("schema_version") != "comparison-qa-negative-mask-v1":
            raise ValueError("Unexpected QA negative-mask schema")
        if doc.get("status") != "candidate_root_review":
            raise ValueError("QA negative mask is not the reviewed candidate")
        for rel, digest in doc.get("input_pins", {}).items():
            if sha256(ROOT / rel) != digest:
                raise ValueError("QA negative-mask input changed: " + rel)
        self.pairs = set()
        self.reasons = {}
        for row in doc["blocked_pairs"]:
            a, b = row["product_a03"], row["product_b03"]
            key = pair_key(a, b)
            if a == b or (a, b) != key or key in self.pairs:
                raise ValueError("Duplicate, unordered or self QA negative-mask pair")
            if row.get("pair_key03") != [a, b] or not row.get("pair_indices"):
                raise ValueError("QA negative-mask pair key/index mismatch")
            if not row.get("reasons") or not row.get("qa_evidence"):
                raise ValueError("QA negative mask lacks reason/evidence")
            for evidence in row["qa_evidence"]:
                rel = evidence.get("path")
                if not rel or doc["input_pins"].get(rel) != evidence.get("path_sha256"):
                    raise ValueError("QA negative-mask evidence is not bound by input pins")
            self.pairs.add(key)
            self.reasons[key] = tuple(row["reasons"])
        self.source_shas = set()
        for row in doc.get("blocked_source_shas", []):
            source = row["sha256"]
            if source in self.source_shas or len(source) != 64 or not row.get("reasons") or not row.get("qa_evidence"):
                raise ValueError("Duplicate or unproven QA source hold")
            self.source_shas.add(source)

    def blocked(self, a03: set[str], b03: set[str]) -> bool:
        if not a03 or not b03:
            raise ValueError("QA mask received unresolved ProductID03 mapping")
        return any(pair_key(a, b) in self.pairs for a in a03 for b in b03)

    def inbatch_mask(self, identities, product03, old_mask, step, rows):
        """OR QA holds into old global base mask without altering positives."""
        result = [list(row) for row in old_mask]
        positive_sources = {rows[row_id]["source_sha256"] for row_id in
                            [*step["query_rows"], *step["reference_rows"]]}
        if self.source_shas & positive_sources:
            raise ValueError("Held source SHA appears in unchanged positive presentation")
        for i, a in enumerate(identities):
            for j, b in enumerate(identities):
                if i == j or product03[a] & product03[b]:
                    continue
                ref_source = rows[step["reference_rows"][j]]["source_sha256"]
                if ref_source in self.source_shas or self.blocked(product03[a], product03[b]):
                    result[i][j] = True
        return result

    def mined_owners(self, step, identities, product03, ref03, references, rows, owners):
        """Use -1 as a zero-logit owner for blocked old mined columns."""
        pairs = [(owner, index) for owner, indices in enumerate(step["mined_reference_index"])
                 for index in indices]
        if len(pairs) != len(owners) or any(owner != actual for (owner, _), actual in zip(pairs, owners)):
            raise ValueError("Old mined owner/index order drift")
        result = list(owners)
        for k, (owner, index) in enumerate(pairs):
            anchor = identities[owner]
            negative = ref03[index]
            source = references[index]["image_sha256"]
            query_source = rows[step["query_rows"][owner]]["source_sha256"]
            positive_source = rows[step["reference_rows"][owner]]["source_sha256"]
            if source in (query_source, positive_source) or negative in product03[anchor]:
                raise ValueError("Old mined column violates existing source/identity guard")
            if source in self.source_shas or self.blocked(product03[anchor], {negative}):
                result[k] = -1
        return result
