"""Apply category verdicts to a copy of current outputs, without re-selection.

The existing public view reads contract cards and active targets' ranked rows.
Rejected target rows are diagnostic history in our block, never active targets.
Explicit stage/frozen/raw evidence remains untouched.
"""
from copy import deepcopy

from .contract import canonical, sha

BLOCK = 'nonwine_context_gpu_v1'
DECISION = 'not_wine'
REASON = 'nonwine_beverage_type'
AGGREGATES = ('product_resolution', 'selected_product_output', 'selection_score')
PRODUCT_SCALARS = ('slug', 'best_candidate', 'probability_correct', 'product_id',
                   'representative_slug', 'exact_slug', 'selection_score')
PRODUCT_LISTS = ('ranked_candidates', 'product_candidates', 'related_catalog_slugs', 'alternatives')


def prepare_views(image, plan):
    """Yield existing frozen crop recipes as RGB384 images, one physical entry.

    The caller binds the original bytes/EXIF/source response before calling.
    This helper does not infer a box or substitute a full-frame image. The
    tensor-level processor remains the frozen classifier's processor.
    """
    from PIL import ImageOps
    if list(image.size) != plan['oriented_size'] or image.mode != 'RGB':
        raise ValueError('Decoded source frame/mode differs from bound plan')
    for row in plan['entries']:
        views = []
        for kind, key in (('bottle', 'bottle_bbox'), ('label', 'label_bbox')):
            box = row[key]
            if box is None:
                continue
            # Exact frozen nonwine_local_v1.runtime._crop, not the B3
            # floor/ceil recipe and not a new detector/context fallback.
            x0, y0, x1, y1 = [int(round(v)) for v in box]
            x0, y0 = max(0, x0), max(0, y0)
            x1, y1 = min(image.width, x1), min(image.height, y1)
            if x1 - x0 < 8 or y1 - y0 < 8:
                continue
            crop = image.crop((x0, y0, x1, y1))
            converted = None
            try:
                converted = crop.convert('RGB')
                square = ImageOps.pad(converted, (384, 384), color='white')
            finally:
                if converted is not None:
                    converted.close()
                crop.close()
            recipe = dict(policy='frozen-nonwine-round-clip-pad-v1', kind=kind, bbox=list(box),
                          rounded_clipped_bbox=[x0, y0, x1, y1], original_size=list(image.size),
                          coordinate_space=plan['coordinate_space'], minimum_crop_size=8,
                          pad_size=[384, 384], pad_color='white', pillow_pad_defaults=True)
            views.append(dict(kind=kind, image=square, recipe=recipe, recipe_sha256=sha(canonical(recipe)),
                              rgb_sha256=sha(square.tobytes()), size=[384, 384]))
        yield row, views


def active_output_projection(response):
    """Exact current product consumers, excluding explicitly raw/history data.

    Root can additionally compare the native gateway.build_view outputs with
    the same catalog. OCR ablation compares this projection and verdicts, while
    raw-field preservation and original SHA are verified separately.
    """
    def resolution(value):
        value = deepcopy(value)
        if isinstance(value, dict):
            vintage = value.get('vintage')
            if isinstance(vintage, dict):
                vintage.pop('observations', None)  # same-instance raw OCR, not a product output
        return value

    projected = {key: deepcopy(response.get(key)) for key in
                 ('decision', *PRODUCT_SCALARS, *PRODUCT_LISTS, 'requires_target_selection', 'reasons') if key in response}
    projected['targets'] = []
    for target in response.get('targets') or []:
        retrieval = target.get('retrieval') or {}
        row = {key: deepcopy(target.get(key)) for key in
               ('instance_id', 'parent_id', 'bbox', 'bottle_bbox', 'context_bbox', 'kind', 'candidate_identity', 'product_candidates') if key in target}
        row['product_resolution'] = resolution(target.get('product_resolution'))
        row['retrieval'] = {key: deepcopy(retrieval.get(key)) for key in
                            ('decision', *PRODUCT_SCALARS, *PRODUCT_LISTS, 'candidate_union', 'requires_target_selection', 'reasons') if key in retrieval}
        projected['targets'].append(row)
    for key in AGGREGATES:
        value = response.get(key)
        if key == 'product_resolution' and isinstance(value, dict):
            value = deepcopy(value)
            for row in value.get('targets') or []:
                if 'resolution' in row:
                    row['resolution'] = resolution(row['resolution'])
        projected[key] = deepcopy(value)
    contract = response.get('target_contract') or {}
    projected['target_contract'] = {key: deepcopy(contract.get(key)) for key in
                                    ('policy', 'mode', 'roi', 'bottles_scope', 'frame_size', 'central',
                                     'addressed_instance_id', 'roi_match', 'roi_observation',
                                     'addressed_physical_linkage', 'published', 'bottles', 'bottle_count',
                                     'primary_instance_id', 'primary_basis', 'primary_confirmed',
                                     'selectable_bottles', 'suggested_card', 'requires_target_selection') if key in contract}
    if 'catalog_additions' in response:
        projected['catalog_additions.related_catalog_slugs'] = deepcopy((response['catalog_additions'] or {}).get('related_catalog_slugs'))
    return projected


def apply_verdicts(response, plan, verdicts, *, published_source_target_instance_id):
    """Return a new response; OCR/text never participates in this decision.

    ``verdicts`` uses (contract_instance_id, role) tuple keys and contains the
    frozen category rule's full-precision result. Publication ownership must be
    explicit even when another target happens to publish the same card.
    """
    if BLOCK in response or 'view' in response:
        raise ValueError('Require an unmodified raw current response, not a cached public view')
    before = sha(canonical(response))
    wanted = {(r['contract_instance_id'], r['role']) for r in plan['entries']}
    if set(verdicts) != wanted:
        raise ValueError('Verdict roster differs from geometry plan')
    for value in verdicts.values():
        if type(value.get('reject')) is not bool or type(value.get('bottle_context')) is not bool:
            raise ValueError('Incomplete category verdict')
        if value['reject'] and not value['bottle_context']:
            raise ValueError('Label-only rejection is forbidden')
    targets = response.get('targets') or []
    target_map = {str(t['instance_id']): t for t in targets}
    owner = published_source_target_instance_id
    owner = None if owner is None else str(owner)
    if response.get('best_candidate') is not None:
        if owner not in target_map or (target_map[owner].get('retrieval') or {}).get('best_candidate') != response['best_candidate']:
            raise ValueError('Published card ownership is not exact')
    elif owner is not None:
        raise ValueError('Owner supplied for absent published card')
    by_target = {}
    rejected_contract = []
    for row in plan['entries']:
        key = row['contract_instance_id'], row['role']
        verdict = verdicts[key]
        sid = row['source_target_instance_id']
        if sid is not None:
            if sid in by_target and by_target[sid] != verdict:
                raise ValueError('One current target has conflicting verdicts')
            by_target[sid] = verdict
        if verdict['reject']:
            rejected_contract.append(key)
    if set(by_target) != set(target_map):
        raise ValueError('Current target verdict missing')
    rejected = {sid for sid, v in by_target.items() if v['reject']}
    output = deepcopy(response)
    block = output['target_contract']
    history = dict(parent_response_canonical_sha256=before, parent_published={},
                   rejected_targets=[], withdrawn_contract_cards=[], parent_product_outputs={})
    history['parent_published'] = {k: deepcopy(response.get(k)) for k in
                                   ('decision', *PRODUCT_SCALARS, *PRODUCT_LISTS, 'requires_target_selection') if k in response}
    output['targets'] = [t for t in output.get('targets') or [] if str(t['instance_id']) not in rejected]
    history['rejected_targets'] = [deepcopy(t) for t in targets if str(t['instance_id']) in rejected]
    entries = [(e, 'bottle') for e in block.get('bottles') or []]
    if block.get('roi_observation'):
        entries.append((block['roi_observation'], 'roi_observation'))
    for entry, role in entries:
        key = str(entry['instance_id']), role
        if key not in rejected_contract:
            continue
        history['withdrawn_contract_cards'].append(deepcopy(entry))
        for name in ('card', 'product_id', 'full_pass_card', 'full_pass_product_id',
                     'representative_slug', 'exact_slug', 'probability_correct', 'selection_score'):
            if name in entry:
                entry[name] = None
        for name in ('alternatives', 'ranked_candidates', 'product_candidates'):
            if name in entry:
                entry[name] = []
        entry['target_decision'] = DECISION
        entry['confirmed'] = False
        entry['reasons'] = list(entry.get('reasons') or []) + [REASON]
    withdrawn = owner in rejected if owner is not None else False
    all_rejected = bool(targets) and len(rejected) == len(targets)
    if withdrawn or all_rejected:
        for name in PRODUCT_SCALARS:
            if name in output:
                output[name] = None
        for name in PRODUCT_LISTS:
            if name in output:
                output[name] = []
        output['decision'] = DECISION if all_rejected else 'insufficient_evidence'
        output['requires_target_selection'] = len(output['targets']) > 1
    if rejected or rejected_contract:
        output['reasons'] = list(output.get('reasons') or []) + [REASON]
    for name in AGGREGATES:
        value = output.get(name)
        if value is None:
            continue
        if name == 'selection_score' and not isinstance(value, dict):
            # Current bcb scalar belongs to the exact global published owner;
            # it was already cleared above if that owner was rejected.
            if owner is None:
                raise ValueError('Global selection score has no exact published owner')
            continue
        if not isinstance(value, dict) or not isinstance(value.get('targets'), list):
            raise ValueError('Unrecognized current product aggregate: ' + name)
        if withdrawn or all_rejected:
            history['parent_product_outputs'][name] = deepcopy(value)
            output[name] = None
        elif rejected:
            removed = [r for r in value['targets'] if str(r.get('instance_id')) in rejected]
            if removed:
                history['parent_product_outputs'][name] = dict(targets=deepcopy(removed))
                value['targets'] = [r for r in value['targets'] if str(r.get('instance_id')) not in rejected]
    # UnifiedRecognition.refresh_aliases derives this list ONLY from global
    # best_candidate, not from the union of physical targets. A rejected
    # unpublished neighbour therefore must not clear the retained owner's list.
    # Per-target related lists of rejected objects left with their removed rows.
    if (withdrawn or all_rejected) and isinstance(output.get('catalog_additions'), dict):
        value = output['catalog_additions']
        history['parent_product_outputs']['catalog_additions.related_catalog_slugs'] = deepcopy(value.get('related_catalog_slugs'))
        value['related_catalog_slugs'] = []
    primary = str(block.get('primary_instance_id'))
    if any(str(e['instance_id']) == primary and (str(e['instance_id']), role) in rejected_contract for e, role in entries):
        block['suggested_card'] = None
    bottles = block.get('bottles') or []
    if bottles and all((str(e['instance_id']), 'bottle') in rejected_contract for e in bottles) and block.get('primary_basis') != 'explicit_roi':
        block.update(primary_instance_id=None, primary_basis='no_wine_target', suggested_card=None,
                     requires_target_selection=False)
        for entry in bottles:
            entry['primary'] = False
    history['parent_contract_published'] = deepcopy(block.get('published'))
    history['parent_result_targets_digest'] = block.get('result_targets_digest')
    if rejected or rejected_contract:
        block['published'] = dict(card=output.get('best_candidate'), decision=output.get('decision'),
                                  slug=output.get('slug'), source=BLOCK)
    # Existing contract digest uses rshb_vine.io.digest, whose canonical
    # encoding intentionally differs from the byte/canonical SHA audit above.
    from rshb_vine.io import digest
    if rejected:
        block['result_targets_digest'] = digest(output['targets'])
    output[BLOCK] = dict(policy='nonwine-context-v2-frozen-gpu-transfer', calibrated=False, fit=False,
                        parent_profile_checksum=block.get('profile_checksum'),
                        rejected_instance_ids=sorted(rejected),
                        rejected_contract_entries=[dict(instance_id=i, role=r) for i, r in sorted(rejected_contract)],
                        status='all_targets_not_wine' if all_rejected else 'published_card_withdrawn' if withdrawn else
                        'nonwine_entries_removed' if rejected_contract else 'unchanged',
                        verdicts=[dict(instance_id=i, role=r, verdict=deepcopy(v)) for (i, r), v in sorted(verdicts.items())],
                        history=history, no_neighbour_replacement=True,
                        raw_stage_diagnostics_preserved=True, runtime_integration=False)
    if sha(canonical(response)) != before:
        raise RuntimeError('Input response was mutated')
    return output
