"""Install the two general stages on the exact released 2df selector owner."""
from copy import copy,deepcopy

from rshb_vine.generic_core_name_v1.selection import GenericCoreNameSelection
from rshb_vine.recognition_repair_v2.composition import Request
from rshb_vine.systemic_ranking_v2.selection import attach

from .policy import RULE,TypedNameAliasStage,StyleOnlyVisualGuardStage


class AdagumGunkoSelection(GenericCoreNameSelection):
    def __init__(self,parent,references):
        if type(parent) is not GenericCoreNameSelection:
            raise ValueError('New candidate requires exact released 2df selector')
        self.__dict__.update(copy(parent.__dict__))
        if ('evaluate' not in self.__dict__ or 'select' not in self.__dict__ or
                tuple(self.components)!=('A','B','D','M','I') or self.composite_identity is None):
            raise RuntimeError('Current 2df I/T closures or recipe differ')
        keys=[s.trace_key for s in self.stages]
        core=['cross_script_identity','producer_role','reader_preservation',
              'generic_core_name_v1','b3_crossview']
        if keys not in (core,['cross_script_identity','producer_role','reader_preservation',
                             'layout_geometry','generic_core_name_v1','b3_crossview']):
            raise RuntimeError('Current 2df stage order differs')
        del self.__dict__['evaluate'];del self.__dict__['select']
        stages=list(self.stages)
        at=keys.index('b3_crossview')
        stages.insert(at,TypedNameAliasStage())
        stages.insert(at+2,StyleOnlyVisualGuardStage(references))
        self.stages=tuple(stages)
        self.current_result,self.records,self.request=None,[],None
        self.last_trace,self.last_text,self.last_core_name=None,None,None
        self.last_typed_alias,self.last_style_guard=None,None
        self.identity=dict(parent.identity,adagum_gunko_general_v1=RULE,
                           stage_order=[stage.trace_key for stage in self.stages])
        from rshb_vine.decision_consistency_v1.composition import _with_call_history
        from rshb_vine.atlas_text_repair_v1.composition import TRACE_KEY
        self.evaluate=_with_call_history(self.evaluate,self.legacy.resolver,'cross_script_identity')
        own_select=self.select
        proposer=self.composite_identity
        atlas_identity=self.identity['atlas_text_repair']
        def select_with_atlas(**kwargs):
            proposer.last_trace=None
            result=own_select(**kwargs)
            if proposer.last_trace is None:
                raise RuntimeError('New candidate did not execute T proposer')
            result['systemic_ranking_v2'][TRACE_KEY]=dict(deepcopy(proposer.last_trace),identity=atlas_identity)
            return result
        self.select=select_with_atlas

    def select(self,**kwargs):
        self.last_typed_alias=None;self.last_style_guard=None
        result=super().select(**kwargs)
        if self.last_typed_alias is None or self.last_style_guard is None:
            raise RuntimeError('New stages did not publish selector traces')
        record=result['systemic_ranking_v2']
        record['typed_name_alias_v1']=dict(deepcopy(self.last_typed_alias),identity=RULE)
        record['style_only_visual_guard_v1']=dict(deepcopy(self.last_style_guard),identity=RULE)
        return result

    def evaluate(self,**call):
        out=super().evaluate(**call)
        self.last_typed_alias=out.get('typed_name_alias_v1')
        self.last_style_guard=out.get('style_only_visual_guard_v1')
        if self.last_typed_alias is None or self.last_style_guard is None:
            raise RuntimeError('New stages were bypassed')
        return out


def install_selection(graph):
    """Replace all five selector owners; keep parent request lock and OCR path."""
    parent=graph.selection
    runtime=graph.base.runtime
    owners=(runtime.selection,graph.base.target.inner.selection,
            graph.inner.selection,graph.inner.repair.selection,parent)
    if any(owner is not parent for owner in owners):
        raise RuntimeError('Current 2df selector owners differ')
    from rshb_vine.reference_additions_v1 import component as D
    raw=D._one(D.holders(graph,('LabelFirstIndex',)),'LabelFirstIndex')
    wrapper=AdagumGunkoSelection(parent,raw.references)
    attach(runtime,wrapper)
    original=runtime._attach_products
    def hooked(result,data,control_seconds):
        wrapper.request=Request(result,data)
        try:
            return original(result,data,control_seconds)
        finally:
            wrapper.request=None
    runtime._attach_products=hooked
    graph.base.target.inner.selection=wrapper
    graph.inner.selection=wrapper
    graph.inner.repair.selection=wrapper
    graph.selection=wrapper
    if any(owner is not wrapper for owner in (
            runtime.selection,graph.base.target.inner.selection,
            graph.inner.selection,graph.inner.repair.selection,graph.selection)):
        raise RuntimeError('New candidate did not reach all five 2df selector owners')
    return wrapper
