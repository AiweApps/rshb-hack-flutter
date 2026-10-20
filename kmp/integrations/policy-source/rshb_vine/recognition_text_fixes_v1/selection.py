"""One request-bound selector for replay and live HTTP consumers.

The original request/OCR packet is retained for provenance and physical geometry.
Only the comparison packet is scoped. Both old103 and the current 5c/I/T/guard
path, including the public product description, receive that scoped packet.
"""
from copy import copy, deepcopy

from rshb_vine.adagum_gunko_general_v1.selection import AdagumGunkoSelection
from rshb_vine.interaction_ranker_v1.source import trace_result
from rshb_vine.recognition_repair_v2.composition import Request
from rshb_vine.systemic_ranking_v2.selection import attach

from .ownership import RULE as OWNERSHIP_RULE, transform
from .shared_name_registry import SharedNameRegistry
from .shared_names import SharedNamesStage


TRACE_KEY = 'recognition_text_fixes_v1'


class TextFixSelection(AdagumGunkoSelection):
    """Copy the precise released selector and rebind its I/T closures locally."""

    def __init__(self, parent, references, catalog, *, ownership=True, shared_names=True,
                 shared_names_sha256='6c0459a244c4497e806c3caecec386d9a07b4ba695237ef7efe929a279567a8e'):
        if type(parent) is not AdagumGunkoSelection:
            raise ValueError('Text fixes require the exact f223 selector')
        self.__dict__.update(copy(parent.__dict__))
        if ('evaluate' not in self.__dict__ or 'select' not in self.__dict__ or
                tuple(self.components) != ('A', 'B', 'D', 'M', 'I')):
            raise RuntimeError('Released I/T closures or component recipe differ')
        del self.__dict__['evaluate']
        del self.__dict__['select']
        self.ownership_enabled = bool(ownership)
        self.shared_names_enabled = bool(shared_names)
        self.shared_names_registry = SharedNameRegistry(
            self.root, references, catalog, expected_sha256=shared_names_sha256)
        stages = list(self.stages)
        keys = [stage.trace_key for stage in stages]
        if (keys.count('b3_crossview') != 1 or 'source_shared_names_v1' in keys or
                keys.index('typed_name_alias_v1') >= keys.index('b3_crossview')):
            raise RuntimeError('Released f223 stage order differs')
        if self.shared_names_enabled:
            stages.insert(keys.index('b3_crossview'), SharedNamesStage(self.shared_names_registry))
        self.stages = tuple(stages)
        self._select_scope = None
        self.request_observations = {}
        self.last_effective_observations = None
        self.last_ownership = None
        self.last_shared_names = None
        self.current_result, self.records, self.request = None, [], None
        self.identity = dict(parent.identity, **{TRACE_KEY: {
            'version': 'physical-text-and-source-shared-names-v1',
            'ownership_enabled': self.ownership_enabled,
            'shared_names_enabled': self.shared_names_enabled,
            'ownership': OWNERSHIP_RULE,
            'shared_names': self.shared_names_registry.identity,
        }}, stage_order=[stage.trace_key for stage in self.stages])
        from rshb_vine.decision_consistency_v1.composition import _with_call_history
        from rshb_vine.atlas_text_repair_v1.composition import TRACE_KEY as ATLAS_KEY
        self.evaluate = _with_call_history(self.evaluate, self.legacy.resolver,
                                           'cross_script_identity')
        own_select = self.select
        proposer = self.composite_identity
        atlas_identity = self.identity['atlas_text_repair']

        def select_with_atlas(**kwargs):
            proposer.last_trace = None
            result = own_select(**kwargs)
            if proposer.last_trace is None:
                raise RuntimeError('Text fixes bypassed T proposer')
            result['systemic_ranking_v2'][ATLAS_KEY] = dict(
                deepcopy(proposer.last_trace), identity=atlas_identity)
            return result

        self.select = select_with_atlas

    def _body(self):
        if self.request is not None:
            return self.request.result
        if self.current_result is not None:
            return self.current_result
        raise RuntimeError('Text ownership needs a request-bound body')

    def _scope(self, observations, provenance, raw_visual):
        if self.ownership_enabled:
            return transform(observations, provenance, raw_visual, self._body(),
                             str(raw_visual['instance_id']))
        return observations, provenance, {
            'rule': OWNERSHIP_RULE, 'enabled': False, 'applied': False,
            'instance_id': str(raw_visual['instance_id']),
            'input_count': len(observations), 'output_count': len(observations),
        }

    def evaluate(self, **call):
        if self._select_scope is not None:
            scope = self._select_scope
            if (str(call['raw_visual']['instance_id']) != scope['instance_id'] or
                    call['observations'] != scope['observations']):
                raise RuntimeError('Live evaluation does not match its scoped request')
            observations, provenance, trace = (scope['observations'], scope['provenance'],
                                               scope['trace'])
        else:
            observations, provenance, trace = self._scope(
                call['observations'], call['provenance'], call['raw_visual'])
        effective_call = dict(call, observations=observations, provenance=provenance)
        out = super().evaluate(**effective_call)
        self.last_effective_observations = deepcopy(out.get('effective_observations', observations))
        self.last_ownership = deepcopy(trace)
        self.last_shared_names = deepcopy(out.get('source_shared_names_v1'))
        if self.shared_names_enabled and self.last_shared_names is None:
            raise RuntimeError('Shared-name stage was bypassed')
        out['instance_text_ownership_v1'] = self.last_ownership
        out[TRACE_KEY] = {
            'identity': self.identity[TRACE_KEY],
            'ownership': self.last_ownership,
            'shared_names': self.last_shared_names,
        }
        return out

    def select(self, **kwargs):
        """Scope before select so all inherited public description paths agree."""
        if self._select_scope is not None:
            raise RuntimeError('Nested live text-fix selection is unsupported')
        body = self._body()
        sid = str(kwargs['raw_visual']['instance_id'])
        provenance, raw_report = trace_result(body, sid, kwargs['observations'])
        observations, provenance, trace = self._scope(
            kwargs['observations'], provenance, kwargs['raw_visual'])
        self._select_scope = dict(instance_id=sid, observations=observations,
                                  provenance=provenance, trace=trace)
        self.last_ownership, self.last_shared_names = None, None
        try:
            result = super().select(**dict(kwargs, observations=observations))
            if self.last_ownership is None:
                raise RuntimeError('Ownership stage did not publish a trace')
            record = result['systemic_ranking_v2']
            # The published raw packet is unchanged. Its old trace report must
            # continue to describe that packet; the comparison scope is explicit.
            record['trace_report'] = raw_report
            record['instance_text_ownership_v1'] = deepcopy(self.last_ownership)
            record[TRACE_KEY] = dict(identity=self.identity[TRACE_KEY],
                                    ownership=deepcopy(self.last_ownership),
                                    shared_names=deepcopy(self.last_shared_names))
            if self.last_shared_names is not None:
                record['source_shared_names_v1'] = deepcopy(self.last_shared_names)
            if self.last_ownership.get('applied'):
                self.request_observations[sid] = deepcopy(self.last_effective_observations)
            return result
        finally:
            self._select_scope = None


def install_selection(graph, references, catalog, **options):
    """Install at every released owner; preserve its lock, models and raw OCR."""
    parent, runtime = graph.selection, graph.base.runtime

    def owners():
        return (runtime.selection, graph.base.target.inner.selection,
                graph.inner.selection, graph.inner.repair.selection, graph.selection)

    if any(owner is not parent for owner in owners()):
        raise RuntimeError('Released f223 selectors are not one shared owner')
    wrapper = TextFixSelection(parent, references, catalog, **options)
    attach(runtime, wrapper)
    original = runtime._attach_products
    original_describe = runtime._describe

    def scoped_describe(slug, observations, sid):
        # RecognitionRuntime refreshes years after publishing the selected
        # card. That later consumer must not read the excluded raw context.
        effective = wrapper.request_observations.get(str(sid))
        return original_describe(slug, effective if effective is not None else observations, sid)

    runtime._describe = scoped_describe
    # The identity adapter runs after RecognitionRuntime and also describes
    # the selected card from the raw evidence packet. Bind that real consumer
    # to the same request scope, without rewriting the evidence itself.
    from rshb_vine.reference_additions_v1 import component as D
    adapters = D.holders(graph, ('IdentityAdapter',)).get('IdentityAdapter') or []
    if not adapters:
        raise RuntimeError('Released public identity projection was not found')
    for adapter, _ in adapters:
        if adapter.candidate.checksum != wrapper.inner.identity.checksum:
            raise RuntimeError('Public identity adapter has another catalogue snapshot')
        original_identity_describe = adapter._describe

        def bind_describe(original):
            def described(slug, observations, sid):
                effective = wrapper.request_observations.get(str(sid))
                return original(slug, effective if effective is not None else observations, sid)
            return described

        adapter._describe = bind_describe(original_identity_describe)

    def hooked(result, data, control_seconds):
        wrapper.request_observations.clear()
        wrapper.request = Request(result, data)
        try:
            return original(result, data, control_seconds)
        finally:
            wrapper.request = None

    runtime._attach_products = hooked
    graph.base.target.inner.selection = wrapper
    graph.inner.selection = wrapper
    graph.inner.repair.selection = wrapper
    graph.selection = wrapper
    if any(owner is not wrapper for owner in owners()):
        raise RuntimeError('Text fixes missed a released selector owner')
    # Keep the cache through the later IdentityAdapter.project, including each
    # native ROI/full pass. Clear it at the outer request boundary, even on an
    # exception. The request lock protects the instance-local selector state.
    from threading import RLock
    request_lock = RLock()
    original_recognize = graph.recognize

    def recognize(*args, **kwargs):
        with request_lock:
            wrapper.request_observations.clear()
            try:
                return original_recognize(*args, **kwargs)
            finally:
                wrapper.request_observations.clear()

    graph.recognize = recognize
    return wrapper
