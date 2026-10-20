"""Bind the core-name stage to every consumer of the actual E3 GPU selector."""
from copy import copy, deepcopy

from rshb_vine.ocr_candidate_repair_v1 import discriminator as D
from rshb_vine.ocr_candidate_repair_v1.selection import OcrCandidateSelection
from rshb_vine.recognition_repair_v2.composition import RepairSelectionV2
from rshb_vine.text_evidence_repair_v2.composition import TextEvidenceSelectionV2

from .policy import GenericCoreNameStage, RULE


class _CandidateBoundary(RepairSelectionV2):
    """Keep the released pre-guard, guard and post-guard order."""

    def evaluate(self, **call):
        out = OcrCandidateSelection.evaluate(self, **call)
        out = self._run('pre_guard', out, call)
        out = D.apply(out, self.legacy.resolver, self.index.profile)
        out = self._run('post_guard', out, call)
        self.last_trace = {
            'adapter': 'recognition-repair-v2-selection',
            'instance_id': str(call['raw_visual']['instance_id']),
            'stages': {stage.trace_key: out.get(stage.trace_key) for stage in self.stages},
        }
        out['recognition_repair_v2'] = self.last_trace
        return out


class GenericCoreNameSelection(TextEvidenceSelectionV2, _CandidateBoundary):
    """Instance-local successor of E3's A+B+D+M+I/T selector."""

    def __init__(self, parent):
        if type(parent) is not TextEvidenceSelectionV2:
            raise ValueError('Core-name candidate needs the exact E3 TextEvidenceSelectionV2')
        self.__dict__.update(copy(parent.__dict__))
        if ('evaluate' not in self.__dict__ or 'select' not in self.__dict__ or
                self.composite_identity is None or
                tuple(self.components) != ('A', 'B', 'D', 'M', 'I')):
            raise ValueError('Actual E3 I/T closures or component recipe differ')
        stages = list(self.stages)
        pre = [stage.trace_key for stage in stages if stage.position == 'pre_guard']
        if pre != ['cross_script_identity', 'producer_role', 'reader_preservation', 'b3_crossview']:
            raise ValueError('Actual E3 pre-guard stage order differs')
        post = [stage.trace_key for stage in stages if stage.position == 'post_guard']
        if post not in ([], ['layout_geometry']):
            raise ValueError('E3 post-guard stage order differs')
        if any(stage.trace_key == 'name_roles' for stage in stages):
            raise ValueError('Name-role component C requires separate policy support')
        # The old I and T functions in __dict__ capture their prior instance.
        # Remove both and bind them to this successor before the graph serves.
        del self.__dict__['evaluate']
        del self.__dict__['select']
        at = next(i for i, stage in enumerate(stages) if stage.trace_key == 'b3_crossview')
        self.core_name_stage = GenericCoreNameStage()
        stages.insert(at, self.core_name_stage)
        self.stages = tuple(stages)
        self.current_result, self.records, self.request = None, [], None
        self.last_trace, self.last_text, self.last_core_name = None, None, None
        self.identity = dict(parent.identity, generic_core_name_v1=RULE,
                             stage_order=[stage.trace_key for stage in self.stages])
        from rshb_vine.decision_consistency_v1.composition import _with_call_history
        from rshb_vine.atlas_text_repair_v1.composition import TRACE_KEY
        self.evaluate = _with_call_history(self.evaluate, self.legacy.resolver, 'cross_script_identity')
        own_select = self.select
        proposer = self.composite_identity
        atlas_identity = self.identity['atlas_text_repair']

        def select_with_atlas(**kwargs):
            proposer.last_trace = None
            result = own_select(**kwargs)
            if proposer.last_trace is None:
                raise RuntimeError('Core-name candidate did not execute T proposer')
            result['systemic_ranking_v2'][TRACE_KEY] = dict(deepcopy(proposer.last_trace),
                                                             identity=atlas_identity)
            return result

        self.select = select_with_atlas

    def select(self, **kwargs):
        self.last_core_name = None
        result = super().select(**kwargs)
        if self.last_core_name is None:
            raise RuntimeError('Core-name candidate did not publish a selector trace')
        result['systemic_ranking_v2']['generic_core_name_v1'] = dict(
            deepcopy(self.last_core_name), identity=self.identity['generic_core_name_v1'])
        return result

    def evaluate(self, **call):
        out = super().evaluate(**call)
        self.last_core_name = out.get('generic_core_name_v1')
        if self.last_core_name is None:
            raise RuntimeError('Core-name stage was bypassed')
        return out


def install_selection(graph):
    """Install at the same five E3 owners before app construction."""
    from rshb_vine.recognition_repair_v2.composition import Request
    from rshb_vine.systemic_ranking_v2.selection import attach

    parent = graph.selection
    runtime = graph.base.runtime
    owners = (runtime.selection, graph.base.target.inner.selection,
              graph.inner.selection, graph.inner.repair.selection, parent)
    if any(owner is not parent for owner in owners):
        raise ValueError('E3 selector owners are not one shared object')
    wrapper = GenericCoreNameSelection(parent)
    attach(runtime, wrapper)
    original = runtime._attach_products

    def hooked(result, data, control_seconds):
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
    if any(owner is not wrapper for owner in (
            runtime.selection, graph.base.target.inner.selection,
            graph.inner.selection, graph.inner.repair.selection, graph.selection)):
        raise RuntimeError('Core-name candidate did not reach every E3 selector owner')
    return wrapper
