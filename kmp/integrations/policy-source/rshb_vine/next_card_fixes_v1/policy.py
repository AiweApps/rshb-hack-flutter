"""A complete specific style span owns its tokens before a derived colour.

No spelling, product ID, slug or expected answer is encoded here. Both native
systemic evidence and the native resolver's colour check use the same span
ownership. OCR, source claims, other typed roles and other resolver reasons are
preserved. The policy is scoped to one selector call and restored on failure.
"""
from contextlib import contextmanager
from copy import deepcopy
from threading import RLock

from rshb_vine.resolution.identity import COLOR, compare, values
from rshb_vine.system_selection_v4 import text

TRACE_KEY = 'specific_style_color_span_v1'
RULE = {
    'version': 'specific-style-owns-coextensive-derived-color-v1',
    'condition': 'An exact/homoglyph curated multi-token style alias and an '
                 'exact/homoglyph curated color alias occupy the identical token span.',
    'effect': 'Retain style; remove only the coextensive derived color atom. '
              'Separate explicit color spans remain eligible.',
    'consumers': 'Native v4/E typed evidence and native resolver color check; '
                 'all native ranker/resolver/I/T/guard/layout stages still execute.',
    'preserved': 'Raw OCR/provenance, catalog claims, candidate pool, visual inputs, '
                 'weights, sugar/grape/style/identity/year rules and inactive packets.',
    'scope': 'Instance-local whole select/evaluate; restoration in finally; no module patch.',
}
STRONG = ('exact', 'homoglyph')


def collision_spans(lexicon, tokens):
    """Only coextensive literal curated aliases establish this necessary condition."""
    found = lexicon.entities(tuple(tokens))
    styles = [item for item in found['style']
              if item.get('mapping') == 'alias' and item.get('match_kind') in STRONG
              and item['end'] - item['start'] > 1]
    return [dict(color=deepcopy(color), style=deepcopy(style))
            for color in found['color'] for style in styles
            if color.get('mapping') == 'alias' and color.get('match_kind') in STRONG
            and (color['start'], color['end']) == (style['start'], style['end'])]


def observation_collisions(lexicon, observations):
    result = []
    for index, observation in enumerate(observations):
        tokens = text.tokenize(observation.get('raw_text', ''))
        spans = collision_spans(lexicon, tokens)
        if spans:
            result.append(dict(observation_id=index, raw_text=observation['raw_text'],
                               score=observation.get('score'), collisions=spans))
    return result


class EffectiveTypedLexicon:
    """Delegate claim parsing unchanged; project only observed typed entities."""
    def __init__(self, original):
        self.original = original

    def entities(self, tokens):
        result = self.original.entities(tokens)
        spans = collision_spans(self.original, tokens)
        removed = { (item['color']['start'], item['color']['end'], item['color']['key'])
                    for item in spans }
        result['color'] = [item for item in result['color']
            if (item['start'], item['end'], item['key']) not in removed]
        return result

    def __getattr__(self, name):
        return getattr(self.original, name)


def effective_color_text(lexicon, raw):
    """A functional colour-only view; no other native reader receives this text."""
    tokens = text.tokenize(raw, drop_years=False)
    # The native typed tokenizer drops years for typed entities; years cannot
    # lie within one of these complete aliases. Keep token coordinates local.
    spans = collision_spans(lexicon, tokens)
    if not spans:
        return raw, []
    owned = {index for item in spans
             for index in range(item['color']['start'], item['color']['end'])}
    return ' '.join(token.raw for index, token in enumerate(tokens) if index not in owned), spans


class EffectiveColorGuard:
    """Run the original guard, replacing only its colour check by the shared policy."""
    def __init__(self, original, lexicon, audit):
        self.original, self.lexicon, self.audit = original, lexicon, audit

    def check(self, before, after, observations):
        allowed, reasons = self.original.check(before, after, observations)
        # Preserve the native source-bound additions bypass and same-card path.
        if not after or after == before or after in getattr(self.original, 'added', ()):
            return allowed, reasons
        usable = [item for item in observations if item['score'] >= .85]
        projected, removals = [], []
        for index, item in enumerate(usable):
            raw, spans = effective_color_text(self.lexicon, item['raw_text'])
            projected.append(raw)
            if spans:
                removals.append(dict(usable_observation_index=index, original_text=item['raw_text'],
                    effective_color_text=raw, collisions=spans))
        if not removals:
            return allowed, reasons
        old_seen = set().union(*(values(item['raw_text'], COLOR) for item in usable))
        seen = set().union(*(values(raw, COLOR) for raw in projected))
        expected = values(self.original.fields[after].get('Категория', ''), COLOR)
        prior = 'color:explicit_conflict' in reasons
        actual_prior = compare(old_seen, expected) == 'contradicted'
        if prior != actual_prior:
            raise RuntimeError('Native color guard no longer matches the pinned source contract')
        current = compare(seen, expected) == 'contradicted'
        updated = [reason for reason in reasons if reason != 'color:explicit_conflict']
        if current:
            updated.insert(0, 'color:explicit_conflict')
        self.audit.append(dict(before=before, after=after, removed_color_spans=removals,
            observed_before=sorted(old_seen), observed_effective=sorted(seen),
            expected=sorted(expected), reasons_before=list(reasons), reasons_effective=list(updated)))
        return not updated, updated

    def __getattr__(self, name):
        return getattr(self.original, name)


class SpecificStyleColorPolicy:
    def __init__(self, selection, enabled=True):
        self.selection, self.enabled = selection, bool(enabled)
        self.lock, self.depth = RLock(), 0
        self.audit, self.guard_audit = [], []
        self.capture_evidence, self.call_evidence = False, []
        self.identity = dict(stage=TRACE_KEY, rule=RULE)

    @contextmanager
    def scoped(self, call):
        # Select calls evaluate recursively; both use the same request scope.
        with self.lock:
            if self.depth:
                self.depth += 1
                try:
                    yield None
                finally:
                    self.depth -= 1
                return
            lexicon = self.selection.inner.context.lexicon
            observations = call['observations']
            if self.enabled:
                from rshb_vine.interaction_ranker_v1.source import trace_result
                provenance = call.get('provenance')
                if provenance is None:
                    provenance, _ = trace_result(self.selection._body(),
                        str(call['raw_visual']['instance_id']), observations)
                observations, _, _ = self.selection._scope(observations, provenance, call['raw_visual'])
            collisions = observation_collisions(lexicon, observations) if self.enabled else []
            if not collisions:
                yield None
                return
            resolver = self.selection.legacy.resolver
            guards = []
            for owner in (resolver.frozen, resolver.copy):
                guards.append((owner, owner.guard))
            self.depth = 1
            self.guard_audit = []
            self.selection.inner.context.lexicon = EffectiveTypedLexicon(lexicon)
            for owner, guard in guards:
                owner.guard = EffectiveColorGuard(guard, lexicon, self.guard_audit)
            trace = dict(rule=RULE, enabled=True, applied=True, collisions=collisions,
                         functional_resolver_color_projection=True)
            try:
                yield trace
            finally:
                self.selection.inner.context.lexicon = lexicon
                for owner, guard in guards:
                    owner.guard = guard
                self.depth = 0
                trace['resolver_color_calls'] = deepcopy(self.guard_audit)
                self.audit.append(deepcopy(trace))


def bind(selection, *, enabled=True):
    """Wrap one current selector instance, without replacing any of its owners."""
    from rshb_vine.recognition_text_fixes_v1.selection import TextFixSelection
    if type(selection) is not TextFixSelection or hasattr(selection, TRACE_KEY):
        raise RuntimeError('Specific style/color policy needs one unmodified bcb selector instance')
    if not hasattr(selection.legacy.resolver, 'copy'):
        raise RuntimeError('Current native I resolver is required')
    policy = SpecificStyleColorPolicy(selection, enabled)
    original_evaluate, original_select = selection.evaluate, selection.select

    def evaluate(**call):
        with policy.scoped(call) as trace:
            out = original_evaluate(**call)
            if policy.capture_evidence:
                policy.call_evidence.append(deepcopy(dict(
                    instance_id=str(call['raw_visual']['instance_id']),
                    candidate_ids=out['candidate_ids'], rows=out['rows'], evidence=out['evidence'],
                    query=out['query'], raw_proposal=out['raw_proposal'], proposal=out['proposal'],
                    feature_digest=out['feature_digest'], discriminator_guard=out.get('discriminator_guard'),
                    stages=(out.get('recognition_repair_v2') or {}).get('stages'))))
        if trace is not None:
            out[TRACE_KEY] = deepcopy(trace)
        return out

    def select(**call):
        with policy.scoped(call) as trace:
            result = original_select(**call)
            if trace is not None:
                record = result['systemic_ranking_v2']
                record[TRACE_KEY] = deepcopy(trace)
                record[TRACE_KEY]['resolver_color_calls'] = deepcopy(policy.guard_audit)
            return result

    selection.evaluate, selection.select = evaluate, select
    setattr(selection, TRACE_KEY, policy)
    return policy
