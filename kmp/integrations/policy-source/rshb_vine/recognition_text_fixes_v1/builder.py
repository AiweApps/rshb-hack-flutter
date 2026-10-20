"""Model-free reconstruction of the exact f223 catalogue/selection consumer."""
from copy import deepcopy
from contextlib import contextmanager
from pathlib import Path

from rshb_vine.adagum_gunko_general_v1.selection import AdagumGunkoSelection
from rshb_vine.b3_local_residual_runtime_v3 import contract as C
from rshb_vine.generic_core_name_v1.selection import GenericCoreNameSelection
from rshb_vine.io import read_json, read_jsonl, verify
from rshb_vine.positive_variant_text import PositiveVariantText
from rshb_vine.product_evidence_resolution import product_text
from rshb_vine.visual_agreement_v1.builder import build_selection

from .selection import TextFixSelection


PARENT_PROFILE = 'f223d7cf4d18a92f2a295410f43337e214b72ecacf26c5a5191db3115af2754f'


@contextmanager
def replaying_source_scope(body):
    """Restore N's recorded request context, not a new geometry decision."""
    from rshb_vine.existing_target_parent_v1 import runtime as N
    receipt = (body.get('release_next_v1') or {}).get('existing_target_parent') or {}
    added = receipt.get('recovered') or []
    if not added:
        yield
        return
    original = receipt.get('original_target_ids') or []
    ids = [str(target['instance_id']) for target in body.get('targets') or []]
    if not original or ids != original + added:
        raise ValueError('Recorded N request target scope cannot be reconstructed')
    token = N._REQUEST.set(dict(added=list(added), original_target_ids=list(original), layout_scope=[]))
    try:
        yield
    finally:
        N._REQUEST.reset(token)


def build_selectors(root, *, geometry=True, **options):
    """Keep the already-verified catalogue-refresh guard/positive/identity path.

    The SIFT stage uses the exact source/reference metadata of the released
    catalogue refresh. It is CPU geometry, and does not load an image model.
    """
    root = Path(root)
    descriptor = read_json(root / C.CATALOG_DESCRIPTOR)
    catalog = read_jsonl(root / descriptor['catalog'])
    references = verify(read_json(root / descriptor['build'] / 'gallery.json'))['references']
    if len(references) != 4314:
        raise ValueError('Text fixes require the released 4314-view gallery')
    selection, _ = build_selection(root, references, catalog, descriptor)
    resolver, frozen = selection.legacy.resolver, selection.legacy.resolver.frozen
    by_slug = {row['slug']: row for row in catalog}
    for slug in descriptor['added_slugs']:
        by_slug[slug]['excluded_from_retrieval'] = False
        frozen.guard.fields[slug] = {'Винодельня': by_slug[slug]['fields'].get('Винодельня', '')}
        frozen.identity.catalog[slug] = dict(by_slug[slug]['fields'])
    allowed = set(frozen.positive.items) | {row['slug'] for row in references}
    positive = []
    for row in catalog:
        if row['slug'] in allowed:
            item = deepcopy(row)
            for key in ('Винодельня', 'Название вина', 'Сорт винограда'):
                item['fields'][key] = product_text(item['fields'].get(key, ''))
            positive.append(item)
    frozen.positive = PositiveVariantText(positive, allowed)
    resolver.copy.guard, resolver.copy.positive = frozen.guard, frozen.positive
    resolver.copy.identity = resolver.identity
    if geometry:
        from rshb_vine.recognition_repair_v2.geometry import GeometryStage
        from rshb_vine.reference_additions_v1 import component as D
        from rshb_vine.reference_conflicts_v1.guard import ReferenceConflicts
        from rshb_vine.io import sha256
        from rshb_vine.io import digest
        import hashlib
        import numpy as np
        stage = GeometryStage(root, selection.registry)
        from rshb_vine.existing_target_parent_v1.runtime import OriginalScopeGeometry
        scope_keeper = OriginalScopeGeometry(stage)
        stage.apply = scope_keeper.apply
        verifier = stage.verifier
        base_rows = len(verifier.references)
        if references[:base_rows] != verifier.references:
            raise ValueError('Released SIFT gallery prefix differs')
        for index, reference in enumerate(references[base_rows:], base_rows):
            path = reference.get('image_path')
            if not path:
                raise ValueError('Appended SIFT reference has no frozen source path')
            verifier.paths[index] = path
        verifier.references = deepcopy(references)
        excluded = ReferenceConflicts(root).excluded_references(references)
        verifier.excluded = {item['reference_index']: item for item in excluded}
        gallery_path = root / descriptor['build'] / 'gallery.json'
        gallery = read_json(gallery_path)
        # The live Linux E3 installer updates this metadata after the catalogue
        # refresh. Reusing the Mac gallery fingerprint silently changes lineage.
        bundle_root = root / 'runs/e3-cuda-port-20261013/bundle-v3'
        bundle = read_json(bundle_root / 'bundle.json')
        vector_path = bundle_root / bundle['assets']['E_vectors']
        spec = bundle['files'][bundle['assets']['E_vectors']]
        expected_vector_sha = spec['sha256'] if isinstance(spec, dict) else spec
        if sha256(vector_path) != expected_vector_sha:
            raise ValueError('Released E gallery-vector bytes changed')
        vectors = np.load(vector_path, allow_pickle=False, mmap_mode='r')[:4314]
        gpu_profile = read_json(root / 'config/e3-gpu-production-v1-profile.json')
        encoder_id = gpu_profile['e3_ownership']['encoder_id']
        verifier.gallery = dict(path=descriptor['build'] + '/gallery.json',
            parent_sha256=sha256(gallery_path), checksum=digest(dict(references=references,
            encoder_id=encoder_id, vectors=hashlib.sha256(vectors.tobytes()).hexdigest())))
        verifier.identity = D._verifier_identity(verifier, verifier.registry)
        stage.identity['verifier_identity'] = verifier.identity
        at = next(index for index, item in enumerate(selection.stages)
                  if item.trace_key == 'b3_crossview')
        stages = list(selection.stages)
        stages.insert(at, stage)
        selection.stages = tuple(stages)
        selection.identity['stage_order'] = [item.trace_key for item in stages]
    parent = AdagumGunkoSelection(GenericCoreNameSelection(selection), references)
    candidate = TextFixSelection(parent, references, catalog, **options)
    return parent, candidate, references, catalog, descriptor
