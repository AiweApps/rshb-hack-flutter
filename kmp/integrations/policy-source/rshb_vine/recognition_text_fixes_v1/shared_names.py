"""Keep source-shared words as real reads without calling them SKU-exclusive.

Run after the released generic/typed name stages and before B3 crossview, style
guard and discriminator. Only exclusive name contributions change. Distinctive
nonshared words, ordinary name support, typed roles and OCR are preserved.
"""
from copy import deepcopy
import math

from rshb_vine.adagum_gunko_general_v1.policy import _entity_key
from rshb_vine.learned_selection_features import _candidate_key
from rshb_vine.ocr_candidate_repair_v1.selection import _relabel
from rshb_vine.system_selection_v4 import text
from rshb_vine.systemic_ranking_v2 import evidence as E
from rshb_vine.systemic_ranking_v2.selection import feature_digest


RULE = {
    'version': 'source-confirmed-shared-name-exclusivity-v1',
    'source': 'complete source-confirmed literal front-label transcriptions, profile-pinned SHA',
    'effect': 'subtract only actually-read exclusive token contributions shared by another source label of the same producer',
    'preserved': 'nonshared exclusive atoms, full name support/coverage, typed roles, pool, learned weights, OCR and resolver policy',
    'identity': 'card-local source witnesses do not create product or exact SKU identity',
    'position': 'pre_guard after typed_name_alias_v1, before b3_crossview',
}


class SharedNamesStage:
    trace_key = 'source_shared_names_v1'
    position = 'pre_guard'

    def __init__(self, registry):
        self.registry = registry
        self.identity = dict(stage=self.trace_key, rule=RULE, registry=dict(registry.identity))

    def apply(self, selection, out, call, request):
        ids = list(out['candidate_ids'])
        base = out['base']
        if ids != [candidate['candidate_id'] for candidate in base['candidates']]:
            raise RuntimeError('Shared-name stage received another candidate pool')
        if out.get('raw_proposal') is None or out.get('proposal') is None:
            raise RuntimeError('Shared-name stage needs the actual systemic proposal')
        existing = out.get(self.trace_key)
        if existing is not None:
            if existing['registry_sha256'] != self.registry.sha256:
                raise RuntimeError('Shared-name registry changed during target evaluation')
            if existing['after']['feature_digest'] != out['feature_digest']:
                raise RuntimeError('Name features rebuilt after shared-name evidence; rerun complete evaluate')
            return out
        inner = selection.inner
        per, products = {}, {}
        for candidate in base['candidates']:
            cid = candidate['candidate_id']
            per[cid], _ = E._members(candidate, inner.context)
            products[cid] = {inner.identity.product_id(slug) for slug in candidate['card_slugs']}
        claimed = {cid: {token.skeletons[0] for member in members.values() for token in member['name']}
                   for cid, members in per.items()}
        atoms = {cid: {key for member in members.values() for token in member['atoms']
                       if (key := _entity_key(inner.context.lexicon, (token,))) is not None}
                 for cid, members in per.items()}
        aliases = (out.get('typed_name_alias_v1') or {}).get('links') or []
        rows, evidence, removals, changes = [], [], [], []
        for index, candidate in enumerate(base['candidates']):
            cid = candidate['candidate_id']
            rivals = [other for other in per if other != cid and not products[other] & products[cid]]
            rival_tokens = set().union(*(claimed[other] for other in rivals)) if rivals else set()
            rival_atoms = set().union(*(atoms[other] for other in rivals)) if rivals else set()
            names = deepcopy(out['evidence'][index]['name'])
            for name in names:
                slug = name['slug']
                member = per[cid][slug]
                if [row['token'] for row in name['tokens']] != [token.forms[0] for token in member['name']]:
                    raise RuntimeError('Shared-name stage lost exact name token order')
                before, after = 0., 0.
                for row, token in zip(name['tokens'], member['name']):
                    if not any(row['grades'].values()) or token.skeletons[0] in rival_tokens:
                        continue
                    links = [link for link in aliases if link['candidate_id'] == cid and
                             link['slug'] == slug and link['claim_token'] == token.forms[0]]
                    if any(link['kind'] == 'core_name_glyph_fuzzy' for link in links):
                        continue
                    if any(link['kind'] == 'typed_grape_atom' and link['canonical_grape_key'] in rival_atoms
                           for link in links):
                        continue
                    weight = row['weight']
                    before += weight
                    witnesses = self.registry.witnesses(slug, token.forms[0])
                    if witnesses:
                        removals.append(dict(candidate_id=cid, slug=slug, token=token.forms[0],
                                             contribution=weight, lines=list(row['lines']),
                                             reader_grades=dict(row['grades']), witnesses=witnesses))
                    else:
                        after += weight
                if not math.isclose(before, name['exclusive'], rel_tol=0., abs_tol=1e-10):
                    raise RuntimeError('Shared-name stage does not reproduce prior exclusivity: ' + cid)
                name['exclusive'] = after
            old = out['rows'][index]
            expected = E._cap(max((name['exclusive'] for name in out['evidence'][index]['name']), default=0.))
            if not math.isclose(expected, old['name.exclusive_w'], rel_tol=0., abs_tol=1e-10):
                raise RuntimeError('Shared-name evidence and original feature differ')
            value = E._cap(max((name['exclusive'] for name in names), default=0.))
            updated = dict(old, **{'name.exclusive_w': value})
            if value != old['name.exclusive_w']:
                changes.append(dict(candidate_id=cid, features={'name.exclusive_w': [old['name.exclusive_w'], value]}))
            rows.append(updated)
            evidence.append(dict(out['evidence'][index], name=names))
        trace = dict(rule=RULE, registry_sha256=self.registry.sha256,
                     instance_id=str(call['raw_visual']['instance_id']),
                     applied=bool(removals), numeric_changed=bool(changes), changes=changes,
                     removed_shared_exclusive_contributions=removals,
                     before=dict(raw=out['raw_proposal']['representative_slug'],
                                 selected=out['proposal']['representative_slug'], feature_digest=out['feature_digest']))
        if removals:
            out['evidence_before_source_shared_names'] = out['evidence']
            out['evidence'] = evidence
        if changes:
            out['rows_before_source_shared_names'] = out['rows']
            out['raw_proposal_before_source_shared_names'] = out['raw_proposal']
            out['proposal_before_source_shared_names'] = out['proposal']
            out['rows'] = rows
            out['feature_digest'] = feature_digest(rows, ids)
            raw = inner._propose(base, out['v4'], rows, call['control_slug'])
            injected = {_candidate_key(slug, selection.registry.cards)
                        for slug in out['ocr_candidate_injection']['injected']}
            _relabel(raw, injected)
            out['raw_proposal'] = raw
            resolver = selection.legacy.resolver
            if not hasattr(resolver, 'frozen'):
                raise RuntimeError('Shared-name stage requires the current I resolver')
            out['proposal'] = resolver.frozen.resolve(base, raw)
            stage = next((stage for stage in selection.stages if stage.trace_key == 'cross_script_identity'), None)
            if stage is None:
                raise RuntimeError('Shared-name stage requires the current I stage')
            out['cross_script_identity_before_source_shared_names'] = out.get('cross_script_identity')
            out = stage.apply(selection, out, call, request)
        trace['after'] = dict(raw=out['raw_proposal']['representative_slug'],
                              selected=out['proposal']['representative_slug'], feature_digest=out['feature_digest'])
        out[self.trace_key] = trace
        return out
