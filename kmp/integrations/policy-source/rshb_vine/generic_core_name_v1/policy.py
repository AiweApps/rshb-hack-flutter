"""Remove generic cross-script matches from core commercial-name coverage only.

This stage runs after the existing producer and reader-preservation stages and
before crossview and the discriminator. It uses the released tokeniser, lexicon,
catalogue weights, feature caps, ranker and resolver. It does not alter OCR.
"""
from collections import Counter

from rshb_vine.learned_selection_features import _candidate_key
from rshb_vine.ocr_candidate_repair_v1.selection import _relabel
from rshb_vine.system_selection_v4 import features as V4, text
from rshb_vine.systemic_ranking_v2 import evidence as E
from rshb_vine.systemic_ranking_v2.selection import feature_digest


NAME_FEATURES = ('name.read_w', 'name.read_g.v', 'name.read_g.p',
                 'name.exclusive_w', 'name.fuzzy_w')
RULE = {
    'version': 'generic-core-name-query-match-v1',
    'scope': 'commercial-name core token coverage only',
    'excluded': 'query token in the existing generic vocabulary matched to a core name token only as translit/fuzzy',
    'preserved': 'exact/homoglyph, typed name atoms, full name phrase, producer, series, visual, typed, weights and pool',
    'position': 'pre_guard after producer_role/reader_preservation and before b3_crossview',
}


class _NameIndex:
    """Read-only view of one target's local index; no module-global patching."""

    def __init__(self, index, filter_core, generic, filtered, preserved):
        self.index = index
        self.lines = index.lines
        self.filter_core = filter_core
        self.generic = generic
        self.filtered = filtered
        self.preserved = preserved

    def matches(self, claim):
        original = self.index.matches(claim)
        if not self.filter_core:
            for line_id in original:
                for token in self.lines[line_id]['tokens']:
                    kind = text.token_match(token, claim)
                    if token.forms[0] in self.generic and kind in ('translit', 'fuzzy'):
                        self.preserved[(token.forms[0], claim, kind)] += 1
            return original
        kept = {}
        for line_id, previous_kind in original.items():
            kinds = []
            for token in self.lines[line_id]['tokens']:
                kind = text.token_match(token, claim)
                if kind is None:
                    continue
                if token.forms[0] in self.generic and kind in ('translit', 'fuzzy'):
                    key = (token.forms[0], claim, kind)
                    self.filtered[key] += 1
                    continue
                kinds.append(kind)
            if kinds:
                kept[line_id] = min(kinds, key=V4.KIND_RANK.__getitem__)
            elif previous_kind in ('exact', 'homoglyph'):
                raise RuntimeError('Core-name gate lost a literal or homoglyph match')
        return kept


def _link_rows(counter):
    return [dict(query_token=q, claim=c, kind=k, count=n)
            for (q, c, k), n in sorted(counter.items())]


def _member_coverage(index, grades, tokens, core, weight, generic, filtered, preserved):
    """E._coverage with the core/atom choice tied to each token object.

    A name may contain the same normalised word both as a typed atom and as a
    core token. The released matcher accepts only a claim string, so keeping
    the member's token objects alive here avoids ambiguous string lookup.
    """
    total = sum(weight(token) for token in tokens)
    out = {'cover': 0., 'read_w': 0., 'fuzzy_w': 0., 'tokens': [],
           **{f'read_g.{reader}': 0. for reader in E.READERS}}
    if not tokens or total <= 0:
        return out
    for token in tokens:
        is_core = any(token is part for part in core)
        view = _NameIndex(index, is_core, generic, filtered, preserved)
        grade, fuzzy, lines = E._token_reads(view, grades, token)
        value = weight(token)
        read = any(grade.values())
        out['cover'] += value * read / total
        out['read_w'] += value * read
        out['fuzzy_w'] += value * fuzzy
        for reader in E.READERS:
            out[f'read_g.{reader}'] += value * grade[reader]
        out['tokens'].append({'token': token.forms[0], 'weight': round(value, 4),
                              'grades': grade, 'fuzzy_only': fuzzy, 'lines': lines})
    return out


class GenericCoreNameStage:
    trace_key = 'generic_core_name_v1'
    position = 'pre_guard'
    identity = {'stage': 'generic-core-name-v1-pre-guard', 'rule': RULE}

    def apply(self, selection, out, call, request):
        inner = selection.inner
        base = out['base']
        ids = list(out['candidate_ids'])
        if ids != [c['candidate_id'] for c in base['candidates']]:
            raise RuntimeError('Core-name gate received another candidate pool')
        if out.get('raw_proposal') is None or out.get('proposal') is None:
            raise RuntimeError('Core-name gate needs the released systemic proposal')
        context, stats = inner.context, inner.stats
        lines = V4._lines(base['query_evidence']['observations'])
        index = E._Index(lines)
        if (len(call['provenance']) != len(base['query_evidence']['observations']) or
                any(row is None for row in call['provenance'])):
            raise ValueError('Name gate requires the full original OCR provenance')
        grades = E._line_grades(lines, call['provenance'])
        per, products = {}, {}
        filtered, preserved = Counter(), Counter()
        for candidate in base['candidates']:
            cid = candidate['candidate_id']
            per[cid], _ = E._members(candidate, context)
            products[cid] = {inner.identity.product_id(slug) for slug in candidate['card_slugs']}
        claimed = {cid: {t.skeletons[0] for member in members.values() for t in member['name']}
                   for cid, members in per.items()}
        rows, evidence, changes = [], [], []
        for i, candidate in enumerate(base['candidates']):
            cid = candidate['candidate_id']
            rivals = [other for other in per if other != cid and not products[other] & products[cid]]
            rival_tokens = set().union(*(claimed[other] for other in rivals)) if rivals else set()
            names, frozen_names = [], []
            for slug, member in per[cid].items():
                for target, candidate_mode in ((frozen_names, False), (names, True)):
                    read = (_member_coverage(index, grades, member['name'], member['core'],
                                             stats.name_weight, context.generic, filtered, preserved)
                            if candidate_mode else E._coverage(index, grades, member['name'], stats.name_weight))
                    exclusive = sum(token_row['weight'] for token_row, token in zip(read['tokens'], member['name'])
                                    if any(token_row['grades'].values()) and token.skeletons[0] not in rival_tokens)
                    target.append(dict(read, slug=slug, exclusive=exclusive,
                                       atoms=[token.forms[0] for token in member['atoms']]))
            names_raw = [{key: name[key] for key in
                          ('slug', 'cover', 'read_w', 'exclusive', 'tokens', 'atoms', 'read_g.v', 'read_g.p')}
                         for name in names]
            frozen_raw = [{key: name[key] for key in
                           ('slug', 'cover', 'read_w', 'exclusive', 'tokens', 'atoms', 'read_g.v', 'read_g.p')}
                          for name in frozen_names]
            if frozen_raw != out['evidence'][i]['name']:
                raise RuntimeError('Core-name replay does not reproduce frozen name evidence: ' + cid)
            frozen_best = max(frozen_names, key=E._rank, default=None) or E._coverage(
                index, grades, [], stats.name_weight)
            best = max(names, key=E._rank, default=None) or E._coverage(index, grades, [], stats.name_weight)
            frozen_fields = {
                'name.read_w': E._cap(frozen_best['read_w']),
                'name.read_g.v': E._cap(frozen_best['read_g.v']),
                'name.read_g.p': E._cap(frozen_best['read_g.p']),
                'name.exclusive_w': E._cap(max((name['exclusive'] for name in frozen_names), default=0.)),
                'name.fuzzy_w': E._cap(max((name['fuzzy_w'] for name in frozen_names), default=0.)),
            }
            name_fields = {
                'name.read_w': E._cap(best['read_w']),
                'name.read_g.v': E._cap(best['read_g.v']),
                'name.read_g.p': E._cap(best['read_g.p']),
                'name.exclusive_w': E._cap(max((name['exclusive'] for name in names), default=0.)),
                'name.fuzzy_w': E._cap(max((name['fuzzy_w'] for name in names), default=0.)),
            }
            before = out['rows'][i]
            if any(before[key] != frozen_fields[key] for key in NAME_FEATURES):
                raise RuntimeError('Core-name replay does not reproduce frozen name features: ' + cid)
            after = dict(before, **name_fields)
            difference = {key: [before[key], after[key]] for key in NAME_FEATURES if before[key] != after[key]}
            if difference:
                changes.append(dict(candidate_id=cid, features=difference))
            rows.append(after)
            evidence.append(dict(out['evidence'][i], name=names_raw))
        evidence_changed = evidence != out['evidence']
        trace = dict(rule=RULE, instance_id=str(call['raw_visual']['instance_id']),
                     applied=bool(changes) or evidence_changed,
                     numeric_changed=bool(changes), evidence_changed=evidence_changed,
                     changes=changes,
                     filtered_core_links=_link_rows(filtered),
                     preserved_typed_links=_link_rows(preserved),
                     injection_status=out['ocr_candidate_injection']['status'],
                     injected=list(out['ocr_candidate_injection']['injected']),
                     before=dict(raw=out['raw_proposal']['representative_slug'],
                                 selected=out['proposal']['representative_slug'],
                                 feature_digest=out['feature_digest']))
        if evidence_changed:
            out['evidence_before_generic_core_name'] = out['evidence']
            out['evidence'] = evidence
        if changes:
            out['rows_before_generic_core_name'] = out['rows']
            out['raw_proposal_before_generic_core_name'] = out['raw_proposal']
            out['proposal_before_generic_core_name'] = out['proposal']
            out['rows'] = rows
            out['feature_digest'] = feature_digest(rows, ids)
            injected = {_candidate_key(slug, selection.registry.cards)
                        for slug in out['ocr_candidate_injection']['injected']}
            raw = inner._propose(base, out['v4'], rows, call['control_slug'])
            _relabel(raw, injected)
            out['raw_proposal'] = raw
            # I already ran earlier in the released stage order. Resolve this
            # new raw proposal through the same frozen resolver, then rerun I
            # so its visible trace belongs to the current winner too.
            resolver = selection.legacy.resolver
            if not hasattr(resolver, 'frozen'):
                raise RuntimeError('Current E3 I resolver is not installed')
            out['proposal'] = resolver.frozen.resolve(base, raw)
            cross_script = next((stage for stage in selection.stages
                                 if stage.trace_key == 'cross_script_identity'), None)
            if cross_script is None:
                raise RuntimeError('Current E3 cross-script stage is absent')
            out['cross_script_identity_before_generic_core_name'] = out.get('cross_script_identity')
            out = cross_script.apply(selection, out, call, request)
        trace['after'] = dict(raw=out['raw_proposal']['representative_slug'],
                              selected=out['proposal']['representative_slug'],
                              feature_digest=out['feature_digest'])
        out[self.trace_key] = trace
        return out
