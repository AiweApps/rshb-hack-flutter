"""Reconstruct the actual E3 selector consumer from saved, model-free inputs."""
from collections import defaultdict
from copy import deepcopy

from rshb_vine.io import read_json, read_jsonl, sha256


def build_selection(root, references, catalog, descriptor):
    """Use the released 5c0be / A+B+D+M+I / T / catalogue-D source path."""
    from rshb_vine.atlas_text_repair_v1 import composition as T
    from rshb_vine.b3_only_v1 import runtime as B3
    from rshb_vine.b3_local_residual_runtime_v3.selection import CrossViewStage
    from rshb_vine.catalog_refresh_runtime_v1.runtime import extend_registry
    from rshb_vine.decision_consistency_v1 import composition as I
    from rshb_vine.ocr_candidate_repair_v1.guarded import GuardedOcrCandidateSelection
    from rshb_vine.ocr_candidate_repair_v1.injection import CatalogPhraseIndex
    from rshb_vine.recognition_repair_v2.composition import RepairSelectionV2
    from rshb_vine.recognition_repair_v2.producer import ProducerRoleStage
    from rshb_vine.reference_additions_v1 import component as D
    from rshb_vine.reference_conflicts_v1.guard import ReferenceConflicts
    from rshb_vine.release_b0_b3_http_v1 import profile as F
    from rshb_vine.system_selection_v4 import text
    from rshb_vine.systemic_ranking_v2.selection import SystemicSelection
    from rshb_vine.text_evidence_repair_v1 import producer_names as P
    from rshb_vine.text_evidence_repair_v2.composition import TextEvidenceSelectionV2
    from .selection import VisualAgreementSelection

    inner = SystemicSelection.from_profile(root, model_path=F.MODEL_PATH, public='systemic')
    profile = read_json(root / 'config/release-next-v1-profile.json')
    prior_additions = read_json(root / profile['release_next']['components']['D']['path'])
    prior_slugs = set(prior_additions['added_slugs'])
    base_rows = prior_additions['constants']['parent_rows']
    parent_rows = read_json(root / descriptor['build'] / 'gallery.json')['parent_rows']
    if (prior_additions['rows'] != parent_rows or parent_rows - base_rows != 4 or
            prior_slugs != {ref['slug'] for ref in references[base_rows:parent_rows]}):
        raise ValueError('Released predecessor gallery additions differ from E3 parent rows')
    ranker = B3.ablate(inner.ranker)
    if ranker['checksum'] != profile['ablated_ranker_checksum']:
        raise ValueError('E3 selector ranker differs from the released 5c0be profile')
    inner.use_ranker(ranker)
    guarded = GuardedOcrCandidateSelection(root, inner, ReferenceConflicts(root).injection_conflict)
    repair = RepairSelectionV2(guarded, [ProducerRoleStage(root, inner), CrossViewStage()])
    recipe = read_json(root / 'config/text-evidence-release-v2-profile.json')['text_evidence']
    base = TextEvidenceSelectionV2(repair, recipe['recipe'], recipe['tables'])
    if tuple(base.components) != ('A', 'B', 'D', 'M'):
        raise ValueError('E3 text evidence recipe differs from A+B+D+M')
    selection = I.compose(base, ('I',))
    T.attach(selection, root)
    composite = selection.index.proposer
    short = composite.parent
    frozen = selection.index.frozen
    # The released catalogue installer validates the frozen B table before it
    # mutates the registry; its source checksum deliberately binds the old roster.
    table = P.load_table(root, short.context, short.registry, short.table_checksum)

    source_sha = sha256(root / descriptor['catalog'])
    catalog = deepcopy(catalog)
    added = set(descriptor['added_slugs'])
    old_catalog = {row['slug']: row for row in read_jsonl(
        root / 'data/catalog-additions-20260921/catalog.jsonl')}
    for row in catalog:
        if row['slug'] in added:
            if row['slug'] in old_catalog and old_catalog[row['slug']].get('excluded_from_retrieval'):
                raise ValueError('Existing excluded card cannot be readmitted')
            row['excluded_from_retrieval'] = False
    for registry in (inner.registry, inner.identity):
        extend_registry(registry, catalog, references, source_sha)
    inner.context.lexicon = text.TypedLexicon(catalog, root)
    inner.context.source_checksums['catalog_refresh_candidate'] = source_sha

    eligible = sorted(set(composite.eligible) | prior_slugs | added)
    phrase = CatalogPhraseIndex(inner, eligible)
    frozen.entries.clear()
    frozen.entries.update(phrase.entries)
    frozen.profiles_cache.clear()
    frozen.checksum = phrase.checksum
    rebuilt = P.ShortProducerIndex(frozen, table)
    short.short, short.checksum = rebuilt.short, rebuilt.checksum
    composite.eligible = frozenset(eligible)
    composite.universe = sorted(set(composite.universe) | added)
    generic = {text.skeleton(value) for value in composite.context.generic}
    by_token = defaultdict(set)
    for slug in composite.universe:
        composite.cards[slug] = composite._card(slug, generic)
        for token in composite.cards[slug]['producer_tokens']:
            by_token[token].add(slug)
    composite.entries, composite.census = {}, {}
    for slug in eligible:
        row = composite._entry(slug, by_token)
        composite.census[slug] = row
        if row['status'] == 'admitted':
            composite.entries[slug] = composite.cards[slug]
    composite.checksum = D._composite_checksum(composite)
    selection.index.checksum = D._producer_checksum(selection.index)
    selection.identity['atlas_text_repair'].update(
        composite_checksum=composite.checksum, index_checksum=selection.index.checksum,
        frozen_index_checksum=frozen.checksum, composite_entries=len(composite.entries))
    candidate = VisualAgreementSelection(selection, references)
    return selection, candidate
