"""Read a missing-space commercial name only from one exact whole OCR token.

This is name-role evidence, not a rewritten OCR observation, a grape reading,
a new alias, or a new product identity. The existing native weights and all
resolver/I/T/guard/layout consumers remain responsible for the final card.
"""
from collections import defaultdict
from copy import deepcopy
import math
from types import SimpleNamespace

from rshb_vine.adagum_gunko_general_v1.policy import _entity_key, _rerun_identity
from rshb_vine.learned_selection_features import _candidate_key
from rshb_vine.name_role_candidate_v1.policy import raw_commercial_name
from rshb_vine.ocr_candidate_repair_v1.selection import _relabel
from rshb_vine.system_selection_v4 import features as V4, text
from rshb_vine.systemic_ranking_v2 import evidence as E
from rshb_vine.systemic_ranking_v2.selection import feature_digest

TRACE_KEY = 'complete_catalog_name_compound_v1'
RULE = {
    'version': 'exact-whole-token-complete-commercial-name-v1',
    'condition': 'One WHOLE observed token primary native form equals the concatenation '
                 'of ALL alphabetic tokens of one source-bound complete commercial-name claim. '
                 'Multiple distinct word sequences abstain; matching cards share the same support.',
    'source': 'Existing positive native reader grade from an exact original label-crop observation; '
              'effective and original whole token must agree under native primary normalization.',
    'effect': 'Add only missing name-token reads at per-reader max native grade; native IDF, '
              'rival-product and source-shared exclusivity rules; rerank and rerun frozen resolver/I.',
    'preserved': 'Raw OCR/provenance, original claims, candidate pool, producer/grape/color/sugar/style '
                 'roles, weights, NameRole producer safeguard, I/T/guard and post-guard layout.',
    'never': 'Substring, fuzzy segmentation, invented glyph alias, numeric/year name, private SKU rule, '
             'brand-only selection, context-only reader promotion, or forced winner.',
    'inactive': 'Same native evaluated packet; no added None trace.',
    'position': 'pre_guard after source_shared_names_v1 and complete_name_role_v2, before b3_crossview',
}


def complete_phrases(candidates):
    """Exact literal claims of actual pool members; no corpus or expected-answer lookup."""
    phrases = defaultdict(dict)
    for candidate in candidates:
        registry = SimpleNamespace(cards=candidate['provenance']['cards'],
                                   claims=candidate['provenance']['claims'])
        for slug in candidate['card_slugs']:
            role = registry.claims.get(slug, {}).get('roles', {}).get('commercial_name', {})
            if (role.get('comparison_allowed') is not True or role.get('unknown') is not False or
                    len(role.get('values', [])) != 1):
                continue
            literal = raw_commercial_name(registry, slug)
            if literal is None or literal['origin'] != 'source_bound_raw_commercial_claim':
                continue
            tokens = text.tokenize(literal['value'], drop_years=False)
            if len(tokens) < 2 or any(not token.forms[0].isalpha() for token in tokens):
                continue
            sequence = tuple(token.forms[0] for token in tokens)
            phrases[''.join(sequence)].setdefault(sequence, []).append(dict(
                slug=slug, candidate_id=candidate['candidate_id'], literal=literal))
    return dict(phrases)


def whole_token_links(candidates, observations, provenance=None):
    phrases = complete_phrases(candidates)
    links, ambiguous = [], []
    for index, observation in enumerate(observations):
        for token in text.tokenize(observation.get('raw_text', ''), drop_years=False):
            choices = phrases.get(token.forms[0], {})
            if not choices:
                continue
            if len(choices) != 1:
                ambiguous.append(dict(observation_id=index, raw_text=observation['raw_text'],
                    whole_token=token.raw, word_sequences=[list(key) for key in choices]))
                continue
            sequence, claims = next(iter(choices.items()))
            link = dict(observation_id=index, raw_text=observation['raw_text'], whole_token=token.raw,
                native_primary_form=token.forms[0], complete_catalog_tokens=list(sequence), claims=claims)
            if provenance is not None:
                source = provenance[index]
                score = source.get('native_score')
                box = source.get('crop_bbox')
                exact = any(other.forms[0] == token.forms[0] for other in
                            text.tokenize(source.get('raw_text', ''), drop_years=False))
                link.update(source_whole_token_exact=exact, provenance=deepcopy(source),
                    eligible=bool(exact and source.get('reader') in E.E1.READER_TAGS and
                        source.get('crop_source') == 'label_view_crop' and
                        isinstance(box, list) and len(box) == 4 and isinstance(score, (int, float)) and
                        not isinstance(score, bool) and math.isfinite(score) and score > 0))
            links.append(link)
    return links, ambiguous


class CompleteNameCompoundStage:
    trace_key = TRACE_KEY
    position = 'pre_guard'
    identity = dict(stage=TRACE_KEY, rule=RULE)

    def __init__(self, enabled=True):
        self.enabled, self.audit = bool(enabled), []

    def apply(self, selection, out, call, request):
        if not self.enabled:
            self.audit.append(dict(enabled=False, applied=False))
            return out
        observations = out['base']['query_evidence']['observations']
        if len(call['provenance']) != len(observations) or any(p is None for p in call['provenance']):
            raise RuntimeError('Complete compound name requires exact native observation provenance')
        links, ambiguous = whole_token_links(out['base']['candidates'], observations, call['provenance'])
        eligible = [link for link in links if link['eligible']]
        if not eligible:
            self.audit.append(dict(enabled=True, applied=False, ambiguous=ambiguous,
                                   excluded_links=links, exact_packet_passthrough=True))
            return out
        inner = selection.inner
        lines = V4._lines(observations)
        line_by_observation = {oid: line['line_id'] for line in lines for oid in line['observation_ids']}
        per, products = {}, {}
        for candidate in out['base']['candidates']:
            cid = candidate['candidate_id']
            per[cid], _ = E._members(candidate, inner.context)
            products[cid] = {inner.identity.product_id(slug) for slug in candidate['card_slugs']}
        claimed = {cid: {token.skeletons[0] for member in members.values() for token in member['name']}
                   for cid, members in per.items()}
        atoms = {cid: {key for member in members.values() for token in member['atoms']
                       if (key := _entity_key(inner.context.lexicon, (token,))) is not None}
                 for cid, members in per.items()}
        rows, evidence = [dict(row) for row in out['rows']], deepcopy(out['evidence'])
        reads = []
        for index, candidate in enumerate(out['base']['candidates']):
            candidate_changed, fuzzy_changed = False, False
            cid = candidate['candidate_id']
            rivals = [other for other in per if other != cid and not products[other] & products[cid]]
            rival_tokens = set().union(*(claimed[other] for other in rivals)) if rivals else set()
            rival_atoms = set().union(*(atoms[other] for other in rivals)) if rivals else set()
            for name in evidence[index]['name']:
                slug = name['slug']
                member = per[cid][slug]
                own = [link for link in eligible if any(c['candidate_id'] == cid and c['slug'] == slug
                                                       for c in link['claims'])]
                if not own:
                    continue
                tokens = member['name']
                if [r['token'] for r in name['tokens']] != [t.forms[0] for t in tokens]:
                    raise RuntimeError('Compound support lost native name token order')
                total = sum(inner.stats.name_weight(token) for token in tokens)
                if total <= 0:
                    continue
                for token, row in zip(tokens, name['tokens']):
                    supporting = [link for link in own if token.forms[0] in link['complete_catalog_tokens']]
                    if not supporting:
                        continue
                    grades = dict(row['grades'])
                    ids = set(row['lines']) if any(row['grades'].values()) else set()
                    for link in supporting:
                        source = link['provenance']
                        reader = E.READER_SHORT[E.E1.READER_TAGS[source['reader']]]
                        grades[reader] = max(grades[reader], float(source['native_score']))
                        ids.add(line_by_observation[link['observation_id']])
                    if grades == row['grades']:
                        continue
                    candidate_changed = True
                    before = deepcopy(row)
                    weight = inner.stats.name_weight(token)
                    old_read, new_read = any(row['grades'].values()), any(grades.values())
                    name['cover'] += weight * (int(new_read) - int(old_read)) / total
                    name['read_w'] += weight * (int(new_read) - int(old_read))
                    for reader in E.READERS:
                        name['read_g.' + reader] += weight * (grades[reader] - row['grades'][reader])
                    atom = _entity_key(inner.context.lexicon, (token,))
                    source_shared = selection.shared_names_registry.witnesses(slug, token.forms[0])
                    exclusive = (token.skeletons[0] not in rival_tokens and
                                 (atom is None or atom not in rival_atoms) and not source_shared)
                    if exclusive:
                        name['exclusive'] += row['weight'] * (int(new_read) - int(old_read))
                    fuzzy_changed = fuzzy_changed or row['fuzzy_only']
                    row.update(grades=grades, lines=sorted(ids), fuzzy_only=False)
                    reads.append(dict(candidate_id=cid, slug=slug, token=token.forms[0], before=before,
                        after=deepcopy(row), source_links=deepcopy(supporting),
                        new_exclusive_eligible=exclusive, shared_source_witnesses=source_shared))
            if not candidate_changed:
                continue
            names = evidence[index]['name']
            best = max(names, key=E._rank)
            rows[index].update({'name.read_w': E._cap(best['read_w']),
                'name.read_g.v': E._cap(best['read_g.v']), 'name.read_g.p': E._cap(best['read_g.p']),
                'name.exclusive_w': E._cap(max(name['exclusive'] for name in names))})
            if fuzzy_changed:
                def fuzzy_mass(values):
                    return max(sum(inner.stats.name_weight(token) for token, token_row in
                        zip(per[cid][name['slug']]['name'], name['tokens']) if token_row['fuzzy_only'])
                        for name in values)
                if E._cap(fuzzy_mass(out['evidence'][index]['name'])) != out['rows'][index]['name.fuzzy_w']:
                    raise RuntimeError('Native fuzzy name scalar cannot be reconstructed from exact evidence')
                rows[index]['name.fuzzy_w'] = E._cap(fuzzy_mass(names))
        changes = [dict(candidate_id=cid, features={key: [before[key], after[key]]
                       for key in before if before[key] != after[key]})
                   for cid, before, after in zip(out['candidate_ids'], out['rows'], rows) if before != after]
        applied = evidence != out['evidence']
        trace = dict(rule=RULE, enabled=True, applied=applied, changes=changes, reads=reads,
            ambiguous=ambiguous, excluded_links=[link for link in links if not link['eligible']],
            exact_packet_passthrough=not applied)
        if not applied:
            self.audit.append(deepcopy(trace))
            return out
        if any(not key.startswith('name.') for item in changes for key in item['features']):
            raise RuntimeError('Compound name changed a non-name feature')
        trace['before'] = dict(raw=out['raw_proposal']['representative_slug'],
            selected=out['proposal']['representative_slug'], feature_digest=out['feature_digest'])
        out['evidence'] = evidence
        if changes:
            out['rows'] = rows
            out['feature_digest'] = feature_digest(rows, out['candidate_ids'])
            raw = inner._propose(out['base'], out['v4'], rows, call['control_slug'])
            _relabel(raw, {_candidate_key(slug, selection.registry.cards)
                           for slug in out['ocr_candidate_injection']['injected']})
            out['raw_proposal'] = raw
            out = _rerun_identity(selection, out, call, request)
        trace['after'] = dict(raw=out['raw_proposal']['representative_slug'],
            selected=out['proposal']['representative_slug'], feature_digest=out['feature_digest'])
        out[self.trace_key] = trace
        self.audit.append(deepcopy(trace))
        return out


def bind(selection, *, enabled=True):
    from rshb_vine.recognition_text_fixes_v1.selection import TextFixSelection
    from .policy import TRACE_KEY as STYLE_KEY
    keys = [stage.trace_key for stage in selection.stages]
    if (type(selection) is not TextFixSelection or not hasattr(selection, STYLE_KEY) or
            keys.count('complete_name_role_v2') != 1 or TRACE_KEY in keys or
            keys.index('source_shared_names_v1') >= keys.index('complete_name_role_v2') or
            keys[keys.index('complete_name_role_v2') + 1] != 'b3_crossview'):
        raise RuntimeError('Compound requires exact accepted NameRole + style parent')
    stages = list(selection.stages)
    stage = CompleteNameCompoundStage(enabled)
    stages.insert(keys.index('b3_crossview'), stage)
    selection.stages = tuple(stages)
    evaluate = selection.evaluate

    def evaluated(**call):
        out = evaluate(**call)
        traces = (out.get('recognition_repair_v2') or {}).get('stages') or {}
        if traces.get(TRACE_KEY) is None:
            traces.pop(TRACE_KEY, None)
        return out

    selection.evaluate = evaluated
    return stage
