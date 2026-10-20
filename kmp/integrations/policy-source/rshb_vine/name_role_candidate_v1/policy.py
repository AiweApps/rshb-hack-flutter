"""One model-free role correction after the current literal-name stages.

Frozen modules, observation packets, candidate pools and trained scores are not
patched. Corrections re-enter the native ranker, resolver and I stage before
the unchanged crossview, T, guard and layout stages.
"""
from copy import deepcopy

from rshb_vine.adagum_gunko_general_v1.policy import _rerun_identity
from rshb_vine.learned_selection_features import _candidate_key
from rshb_vine.ocr_candidate_repair_v1.selection import _relabel
from rshb_vine.producer_role_v2 import roles as R
from rshb_vine.system_selection_v4 import features as V4, text
from rshb_vine.systemic_ranking_v2 import evidence as E
from rshb_vine.systemic_ranking_v2.selection import feature_digest

from .decimal_literals import find_decimal_literals
from .producer_roles import classify_producer_line


RULE = {
    'version': 'complete-decimal-and-grape-producer-role-v2',
    'position': 'after source_shared_names_v1, before b3_crossview',
    'decimal': 'Suppress a numeric name-token read only when every matching occurrence '
        'of that observation is inside a proved complete decimal unequal to the single '
        'catalogue-name decimal. Keep claim tokens and other observations/readers. '
        'Equal, mixed, unaligned, missing or ambiguous literals stay unchanged.',
    'producer': 'A multi-token line completely covered by exact/homoglyph typed grape '
        'spans is ineligible only for the producer role. Single-token and mixed lines '
        'stay ambiguous/eligible. Use current alias/origin/ownership/anchor rules.',
    'preserved': 'OCR/provenance, name/grape roles of producer-filtered lines, unrelated '
        'numbers and years, visual features, weights, pool, registry, resolver, I/T/guard/layout',
    'inactive': 'Return the same evaluated packet; no evidence or numeric recomputation is published.',
}
NAME_FEATURES = ('name.read_w', 'name.read_g.v', 'name.read_g.p', 'name.exclusive_w')


def raw_commercial_name(registry, slug):
    """Recover punctuation only from a raw claim bound to the native value."""
    profile = registry.claims.get(slug)
    values, status, unknown = V4._claim_values(profile, 'commercial_name')
    card_raw = registry.cards[slug].get('raw_metadata', {}).get('Название вина', '')
    if not values:
        if profile and (unknown or status in ('conflict', 'unresolved', 'ambiguous')):
            return None
        return dict(value=card_raw, origin='native_card_raw_fallback') if card_raw else None
    if len(set(values)) != 1 or unknown or status in ('conflict', 'unresolved', 'ambiguous'):
        return None
    role = (profile.get('roles') or {}).get('commercial_name') or {}
    raw_values, sources = [], []
    for claim in role.get('claims') or []:
        if claim.get('normalized') != values:
            return None
        raw = claim.get('raw') or {}
        candidates = [raw.get('value'), (raw.get('source') or {}).get('raw'),
                      (claim.get('source') or {}).get('raw')]
        candidates = [value for value in candidates if isinstance(value, str) and value.strip()]
        if not candidates or any(text.base_norm(value) != values[0] for value in candidates):
            return None
        raw_values += candidates
        sources.append(claim.get('source') or raw.get('source'))
    if not raw_values:
        return None
    literal_sets = {tuple(literal.value for literal in find_decimal_literals(value)) for value in raw_values}
    if len(literal_sets) != 1:
        return None
    return dict(value=raw_values[0], origin='source_bound_raw_commercial_claim',
                normalized=values[0], sources=sources)


def _literal_positions(raw):
    """Map token positions only after exact native-token alignment of raw pieces."""
    tokens = text.tokenize(raw)
    positions = {}
    literals = find_decimal_literals(raw)
    for literal in literals:
        prefix = text.tokenize(raw[:literal.start])
        parts = text.tokenize(literal.raw)
        start, end = len(prefix), len(prefix) + len(parts)
        if ([t.forms for t in tokens[start:end]] != [t.forms for t in parts] or
                len(parts) != 2 or not all(t.forms[0].isdigit() for t in parts)):
            return None
        for index in range(start, end):
            positions[index] = literal.value
    return tokens, positions


def _numeric_read(lines, provenance, claim, value):
    """Native grades from observations that still give this numeric token a valid read."""
    grades = dict.fromkeys(E.READERS, 0.)
    strong_lines, weak_lines, removed = set(), set(), []
    for line in lines:
        for oid in line['observation_ids']:
            raw = line['raw'][line['observation_ids'].index(oid)]
            mapped = _literal_positions(raw)
            if mapped is None:
                tokens, positions = text.tokenize(raw), {}
            else:
                tokens, positions = mapped
            hits = [(index, text.token_match(token, claim)) for index, token in enumerate(tokens)]
            hits = [(index, kind) for index, kind in hits if kind is not None]
            valid = [(index, kind) for index, kind in hits
                     if index not in positions or positions[index] == value]
            invalid = [(index, kind) for index, kind in hits
                       if index in positions and positions[index] != value]
            if invalid:
                removed.append(dict(observation_id=oid, line_id=line['line_id'],
                    raw_text=raw, claim_token=claim, catalogue_decimal=str(value),
                    unequal_decimals=sorted({str(positions[index]) for index, _ in invalid})))
            if any(kind in E.MATCHED for _, kind in valid):
                strong_lines.add(line['line_id'])
                record = provenance[oid]
                score = record.get('native_score')
                if isinstance(score, (int, float)) and not isinstance(score, bool):
                    reader = E.READER_SHORT[E.E1.READER_TAGS[record['reader']]]
                    grades[reader] = max(grades[reader], float(score))
            elif any(kind == 'fuzzy' for _, kind in valid):
                weak_lines.add(line['line_id'])
    return grades, bool(weak_lines and not strong_lines), sorted(strong_lines or weak_lines), removed


def _name_corrections(selection, out, call):
    rows, evidence = [dict(row) for row in out['rows']], deepcopy(out['evidence'])
    inner = selection.inner
    lines = V4._lines(out['base']['query_evidence']['observations'])
    if not any(find_decimal_literals(raw) for line in lines for raw in line['raw']):
        return rows, evidence, []
    index, grades = E._Index(lines), E._line_grades(lines, call['provenance'])
    per, products = {}, {}
    for candidate in out['base']['candidates']:
        cid = candidate['candidate_id']
        per[cid], _ = E._members(candidate, inner.context)
        products[cid] = {inner.identity.product_id(slug) for slug in candidate['card_slugs']}
    claimed = {cid: {token.skeletons[0] for member in members.values() for token in member['name']}
               for cid, members in per.items()}
    audit = []
    for position, candidate in enumerate(out['base']['candidates']):
        cid = candidate['candidate_id']
        rivals = [other for other in per if other != cid and not products[other] & products[cid]]
        rival_tokens = set().union(*(claimed[other] for other in rivals)) if rivals else set()
        changed = False
        for name in evidence[position]['name']:
            slug = name['slug']
            member = per[cid][slug]
            source_name = raw_commercial_name(inner.registry, slug)
            if source_name is None:
                continue
            title = source_name['value']
            literals = find_decimal_literals(title)
            mapped = _literal_positions(title)
            if len(literals) != 1 or mapped is None:
                continue
            title_tokens, decimal_positions = mapped
            literal = literals[0]
            numeric = {title_tokens[p].forms[0] for p in decimal_positions}
            # A repeated integer claim outside the decimal makes this token's
            # catalogue role ambiguous. Keep it, rather than deleting a brand.
            numeric -= {token.forms[0] for p, token in enumerate(title_tokens) if p not in decimal_positions}
            total = sum(inner.stats.name_weight(token) for token in member['name'])
            if total <= 0:
                continue
            if [row['token'] for row in name['tokens']] != [token.forms[0] for token in member['name']]:
                raise RuntimeError('Name-role stage lost current name token order')
            for token, token_row in zip(member['name'], name['tokens']):
                if token.forms[0] not in numeric:
                    continue
                native_grades, native_fuzzy, native_lines = E._token_reads(index, grades, token)
                # Earlier name stages can add a different reading. Such a
                # reading is not ours to remove without an exact source proof.
                if (token_row['grades'] != native_grades or token_row['lines'] != native_lines or
                        token_row['fuzzy_only'] != native_fuzzy):
                    continue
                after, fuzzy, kept, removed = _numeric_read(lines, call['provenance'], token.forms[0], literal.value)
                if not removed or (after == native_grades and kept == native_lines and fuzzy == native_fuzzy):
                    continue
                if fuzzy != native_fuzzy:
                    # Short decimal components cannot be fuzzy under current
                    # tokenizer rules. Do not infer a new fuzzy-number policy.
                    continue
                before = deepcopy(token_row)
                weight = inner.stats.name_weight(token)
                old_read, new_read = any(native_grades.values()), any(after.values())
                name['cover'] += weight * (int(new_read) - int(old_read)) / total
                name['read_w'] += weight * (int(new_read) - int(old_read))
                for reader in E.READERS:
                    name['read_g.' + reader] += weight * (after[reader] - native_grades[reader])
                if token.skeletons[0] not in rival_tokens:
                    name['exclusive'] += token_row['weight'] * (int(new_read) - int(old_read))
                token_row.update(grades=after, lines=kept, fuzzy_only=fuzzy)
                for key in ('cover', 'read_w', 'read_g.v', 'read_g.p', 'exclusive'):
                    if -1e-12 < name[key] < 0:
                        name[key] = 0.
                    if name[key] < 0:
                        raise RuntimeError('Decimal correction removed more than the measured contribution')
                changed = True
                audit.append(dict(candidate_id=cid, slug=slug, catalog_title=title, claim_source=source_name,
                    decimal=literal.raw, before=before, after=deepcopy(token_row), removed_reads=removed))
        if changed:
            names = evidence[position]['name']
            best = max(names, key=E._rank)
            rows[position].update({'name.read_w': E._cap(best['read_w']),
                'name.read_g.v': E._cap(best['read_g.v']), 'name.read_g.p': E._cap(best['read_g.p']),
                'name.exclusive_w': E._cap(max(name['exclusive'] for name in names))})
    return rows, evidence, audit


def _producer_corrections(selection, out, call):
    parent_stage = next(stage for stage in selection.stages if stage.trace_key == 'producer_role')
    roles = parent_stage.roles
    target = R.TargetProducerText(out['base']['query_evidence']['observations'],
        call['provenance'], call.get('other_line_keys', ()), R.FULL)
    excluded = []
    for line in target.lines:
        entities = [entity for entity in selection.inner.context.lexicon.entities(line['tokens'])['grape_blend']
                    if entity.get('match_kind') in ('exact', 'homoglyph')]
        decision = classify_producer_line(line['tokens'], entities)
        if len(line['tokens']) >= 2 and not decision.producer_eligible and line['line_id'] in target.eligible:
            excluded.append(dict(line_id=line['line_id'], raw=line['raw'],
                eligible_observation_ids=list(target.eligible[line['line_id']]), entities=entities))
    if not excluded:
        return None, []
    before = roles.features(out, target, R.FULL)
    for (features, _), row in zip(before, out['rows']):
        if any(features[key] != row[key] for key in R.FEATURES):
            raise RuntimeError('Native producer roles do not reproduce current bcb producer features')
    for line in excluded:
        lid = line['line_id']
        ids = target.eligible.pop(lid)
        target.grades[lid] = dict.fromkeys(E.READERS, 0.)
        target.excluded.setdefault(lid, {}).update({oid: 'complete_grape_only_line' for oid in ids})
    return roles.features(out, target, R.FULL), excluded


class NameRoleStage:
    trace_key = 'complete_name_role_v2'
    position = 'pre_guard'
    identity = dict(stage='complete-name-role-v2', rule=RULE)

    def __init__(self, enabled=True):
        self.enabled = bool(enabled)
        self.audit = []

    def apply(self, selection, out, call, request):
        if not self.enabled:
            self.audit.append(dict(enabled=False, applied=False, exact_packet_passthrough=True))
            return out
        rows, evidence, decimal = _name_corrections(selection, out, call)
        producer, excluded = _producer_corrections(selection, out, call)
        producer_detail = []
        if producer is not None:
            for index, (row, (fields, detail)) in enumerate(zip(rows, producer)):
                if any(row[key] != fields[key] for key in R.FEATURES):
                    own = detail['own']
                    old = evidence[index]
                    producer_detail.append(dict(candidate_id=out['candidate_ids'][index],
                        before=dict(producer=deepcopy(old['producer']),
                                    producer_rival=deepcopy(old['producer_rival'])), after=deepcopy(detail)))
                    tokens = [dict(token=token['token'], weight=token['weight'], grades=token['grades'],
                        lines=token['lines'], fuzzy_only=token['status'] == 'fuzzy_only')
                        for token in own['tokens']]
                    old['producer'] = {key: own[key] for key in ('form', 'cover', 'read_w', 'read_g.v', 'read_g.p')}
                    old['producer']['tokens'] = tokens
                    old['producer_rival'] = {reader: ({'form': rival['form'], 'read_g': rival['read_g']}
                        if rival else None) for reader, rival in detail['rival'].items()}
                row.update(fields)
        changes = [dict(candidate_id=cid, features={key: [before[key], after[key]]
                    for key in before if before[key] != after[key]})
                   for cid, before, after in zip(out['candidate_ids'], out['rows'], rows)
                   if before != after]
        evidence_changed = evidence != out['evidence']
        trace = dict(rule=RULE, enabled=True, applied=bool(changes) or evidence_changed,
            feature_changed=bool(changes),
            decimal_feature_changed=any(any(key.startswith('name.') for key in item['features']) for item in changes),
            producer_feature_changed=any(any(key.startswith('prod.') for key in item['features']) for item in changes),
            decimal=decimal, grape_only_lines=excluded,
            producer_evidence=producer_detail, changes=changes,
            exact_packet_passthrough=not changes and not evidence_changed)
        self.audit.append(deepcopy(trace))
        if not trace['applied']:
            return out
        trace['before'] = dict(raw=out['raw_proposal']['representative_slug'],
            selected=out['proposal']['representative_slug'], feature_digest=out['feature_digest'])
        if evidence_changed:
            out['evidence'] = evidence
        if changes:
            out['rows'] = rows
            out['feature_digest'] = feature_digest(rows, out['candidate_ids'])
            raw = selection.inner._propose(out['base'], out['v4'], rows, call['control_slug'])
            _relabel(raw, {_candidate_key(slug, selection.registry.cards)
                           for slug in out['ocr_candidate_injection']['injected']})
            out['raw_proposal'] = raw
            out = _rerun_identity(selection, out, call, request)
        trace['after'] = dict(raw=out['raw_proposal']['representative_slug'],
            selected=out['proposal']['representative_slug'], feature_digest=out['feature_digest'])
        out[self.trace_key] = trace
        return out


def bind(selection, *, enabled=True):
    """Bind only this new selector instance; all frozen module objects stay intact."""
    from rshb_vine.recognition_text_fixes_v1.selection import TextFixSelection
    if type(selection) is not TextFixSelection:
        raise RuntimeError('Name-role candidate requires the exact current bcb text-fix selector')
    stages = list(selection.stages)
    keys = [stage.trace_key for stage in stages]
    at = keys.index('source_shared_names_v1') + 1
    if keys[at] != 'b3_crossview' or NameRoleStage.trace_key in keys:
        raise RuntimeError('Current bcb stage order differs')
    stage = NameRoleStage(enabled)
    stages.insert(at, stage)
    selection.stages = tuple(stages)
    evaluate = selection.evaluate

    def evaluated(**call):
        out = evaluate(**call)
        # Native composition lists every stage. An inactive candidate must not
        # add an artificial None trace to an otherwise identical bcb packet.
        stages = (out.get('recognition_repair_v2') or {}).get('stages') or {}
        if stages.get(stage.trace_key) is None:
            stages.pop(stage.trace_key, None)
        return out

    selection.evaluate = evaluated
    return stage
