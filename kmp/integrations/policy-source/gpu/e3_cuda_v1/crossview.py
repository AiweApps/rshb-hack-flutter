"""Record cross-view support without changing typed retrieval or its scores."""
from dataclasses import asdict
import math
import numpy as np


def _global_top(query, qids, index, excluded):
    if not qids:
        return None
    values = index.vectors @ np.asarray(query, dtype=np.float32)[qids].T
    for i in np.argsort(-values.max(axis=1), kind='stable'):
        i = int(i)
        if i in excluded:
            continue
        column = int(np.argmax(values[i]))
        ref = index.references[i]
        return dict(slug=ref['slug'], score=float(values[i, column]),
                    reference_index=i, reference_kind=ref['kind'],
                    reference_source_sha256=ref['image_sha256'],
                    query_view_index=qids[column])
    return None


def crossview_evidence(query, views, index, excluded):
    label_qids = [i for i, view in enumerate(views)
                  if view.kind in ('front_label', 'partial_label', 'detected_label')]
    context_qids = [i for i, view in enumerate(views) if view.kind == 'context']
    label_top = _global_top(query, label_qids, index, excluded)
    context_top = _global_top(query, context_qids, index, excluded)
    if label_top:
        label_top['query_view'] = asdict(views[label_top['query_view_index']])
    if context_top:
        context_top['query_view'] = asdict(views[context_top['query_view_index']])
    geometry = 'missing_query_view'
    if label_top and context_top:
        label, context = label_top['query_view'], context_top['query_view']
        lb, cb = label['bbox'], context['bbox']
        same_frame = (label['original_size'] == context['original_size'] and
                      label['coordinate_space'] == context['coordinate_space'])
        finite = (len(lb) == len(cb) == 4 and len(label['original_size']) == 2 and
                  all(isinstance(x, (int, float)) and not isinstance(x, bool) and math.isfinite(x)
                      for x in (*lb, *cb, *label['original_size'])))
        valid = bool(finite and 0 <= cb[0] < cb[2] <= label['original_size'][0] and
                     0 <= cb[1] < cb[3] <= label['original_size'][1] and
                     0 <= lb[0] < lb[2] <= label['original_size'][0] and
                     0 <= lb[1] < lb[3] <= label['original_size'][1])
        contained = bool(valid and cb[0] <= lb[0] and cb[1] <= lb[1] and
                         lb[2] <= cb[2] and lb[3] <= cb[3])
        geometry = ('same_frame_label_within_context' if same_frame and contained else
                    'different_frame_or_label_outside_context')
    same_card = bool(label_top and context_top and label_top['slug'] == context_top['slug'])
    opposite_kind = bool(same_card and
                         label_top['reference_kind'] == 'context' and
                         context_top['reference_kind'] == 'front_label' and
                         label_top['reference_index'] != context_top['reference_index'])
    return dict(policy='same_physical_instance_reciprocal_gallery_kinds_v3',
                label_query_global_top1=label_top,
                context_query_global_top1=context_top,
                query_geometry=geometry,
                same_exact_card=same_card,
                opposite_reference_kind=opposite_kind,
                candidate_slug=label_top['slug'] if same_card and opposite_kind and
                               geometry == 'same_frame_label_within_context' else None,
                gallery_rows=len(index.references),
                excluded_reference_count=len(excluded),
                typed_channels_unchanged=True)
