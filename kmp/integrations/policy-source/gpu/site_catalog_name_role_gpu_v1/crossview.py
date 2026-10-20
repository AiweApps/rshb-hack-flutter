"""Released GPU cross-view policy with row count bound to the live E gallery.

The implementation follows b3_local_residual_runtime_v3.selection.CrossViewStage;
only the frozen literal 4314 is replaced by the verified actual row count.
"""

from copy import deepcopy

from adagum_gunko_general_v1.policy import StyleOnlyVisualGuardStage
from e3_cuda_v1.selection import CrossViewStage
from rshb_vine.systemic_ranking_v2.evidence import CONTRADICTION_FEATURES


class SiteCatalogStyleGuardStage(StyleOnlyVisualGuardStage):
    """Run the unchanged source-bound style rule against the extended gallery.

    The frozen rule checks a literal 4314 in its in-flight cross-view evidence.
    Project that one field only for this call, and restore the actual row count
    even when the frozen rule raises. Its references and all other inputs stay
    the exact live objects from the released selector.
    """

    def __init__(self, parent, gallery_rows):
        if type(parent) is not StyleOnlyVisualGuardStage or gallery_rows <= 4314:
            raise ValueError('Exact released style guard and extended gallery required')
        self.references = parent.references
        self.gallery_rows = gallery_rows
        if len(self.references) != gallery_rows:
            raise ValueError('Style guard does not hold the live extended gallery')

    def apply(self, selection, out, call, request):
        if len(self.references) != self.gallery_rows:
            raise RuntimeError('Style guard gallery changed after installation')
        target = request.target(str(call['raw_visual']['instance_id'])) if request is not None else None
        cross = ((target or {}).get('retrieval') or {}).get('crossview_evidence')
        if not cross:
            return super().apply(selection, out, call, request)
        if not isinstance(cross, dict) or cross.get('gallery_rows') != self.gallery_rows:
            raise RuntimeError('Style guard received evidence from another gallery')
        cross['gallery_rows'] = 4314
        try:
            return super().apply(selection, out, call, request)
        finally:
            cross['gallery_rows'] = self.gallery_rows


class SiteCatalogCrossViewStage(CrossViewStage):
    def __init__(self, gallery_rows):
        if not isinstance(gallery_rows, int) or gallery_rows <= 4314:
            raise ValueError("Extended gallery row count required")
        self.gallery_rows = gallery_rows

    def apply(self, selection, out, call, request):
        raw_visual = call['raw_visual']
        evidence = (raw_visual.get('arms', {}).get('B3', {}).get('retrieval', {})
                    .get('crossview_evidence'))
        trace = {'stage': self.identity['stage'], 'instance_id': str(raw_visual['instance_id']),
                 'applied': False, 'action': 'no_crossview_evidence',
                 'evidence': deepcopy(evidence) if evidence else None}
        out[self.trace_key] = trace
        if not evidence or not evidence.get('candidate_slug'):
            return out
        label = evidence['label_query_global_top1']
        context = evidence['context_query_global_top1']
        if (not evidence.get('same_exact_card') or not evidence.get('opposite_reference_kind')
                or label['slug'] != context['slug'] or evidence.get('gallery_rows') != self.gallery_rows
                or label['reference_kind'] != 'context' or context['reference_kind'] != 'front_label'
                or label['reference_index'] == context['reference_index']
                or not evidence.get('typed_channels_unchanged')):
            raise ValueError('Cross-view evidence does not satisfy the declared policy')
        if not out.get('raw_proposal') or not out['raw_proposal']['ranked_candidates']:
            trace['action'] = 'empty_learned_proposal'
            return out
        slug = evidence['candidate_slug']
        matches = [i for i, candidate in enumerate(out['base']['candidates'])
                   if slug in candidate['card_slugs']]
        if len(matches) != 1:
            trace.update(action='candidate_absent_or_ambiguous_in_existing_pool', pool_matches=matches)
            return out
        index = matches[0]
        candidate = out['base']['candidates'][index]
        current = out['raw_proposal']['ranked_candidates'][0]
        candidate_raw = next(row for row in out['raw_proposal']['ranked_candidates']
                             if row['candidate_id'] == candidate['candidate_id'])
        if candidate_raw['representative_slug'] != slug:
            trace.update(action='corroborated_card_not_published_representative',
                         representative_slug=candidate_raw['representative_slug'])
            return out
        trace.update(candidate_id=candidate['candidate_id'], product_id=candidate['product_id'],
                     learned_rank=candidate_raw['rank'], incumbent_id=current['candidate_id'])
        if candidate['candidate_id'] == current['candidate_id']:
            trace['action'] = 'learned_winner_already_corroborated'
            return out
        current_index = current['input_pool_index']
        challenger = out['rows'][index]
        incumbent = out['rows'][current_index]
        worse = {name: challenger[name] for name in CONTRADICTION_FEATURES
                 if challenger[name] > incumbent[name]}
        stronger_text = {name: incumbent[name] for name in ('name.exclusive_w', 'prod.read_w')
                         if incumbent[name] > challenger[name]}
        if worse or stronger_text:
            trace.update(action='existing_text_counterevidence',
                         challenger_extra_contradictions=worse,
                         incumbent_stronger_text=stronger_text)
            return out
        raw = deepcopy(out['raw_proposal'])
        for row in raw['ranked_candidates']:
            row['learned_rank'] = row.get('learned_rank', row['rank'])
        raw['ranked_candidates'].sort(key=lambda row: row['candidate_id'] != candidate['candidate_id'])
        for rank, row in enumerate(raw['ranked_candidates'], 1):
            row['rank'] = rank
            row['order_source'] = 'reciprocal_crossview' if rank == 1 else 'learned_score_order'
        top = raw['ranked_candidates'][0]
        raw.update(candidate_id=top['candidate_id'], product_id=top['product_id'],
                   representative_slug=top['representative_slug'], best_candidate=top['representative_slug'],
                   representative_source=top['representative_source'], score=top['score'], score_margin=None,
                   order_source='reciprocal_crossview', reason='reciprocal_crossview_corroboration',
                   exact_slug=None, probability=None, release_admitted=False,
                   crossview_evidence=deepcopy(evidence))
        resolved = selection.legacy.resolver.resolve(out['base'], raw)
        trace['resolver'] = resolved['existing_evidence_resolution']
        if resolved.get('candidate_id') != candidate['candidate_id']:
            trace['action'] = 'existing_resolver_rejected'
            return out
        out['raw_proposal_before_crossview'] = out['raw_proposal']
        out['proposal_before_crossview'] = out['proposal']
        out['raw_proposal'], out['proposal'] = raw, resolved
        trace.update(applied=True, action='promoted_through_existing_resolver',
                     selected=resolved['representative_slug'])
        return out
