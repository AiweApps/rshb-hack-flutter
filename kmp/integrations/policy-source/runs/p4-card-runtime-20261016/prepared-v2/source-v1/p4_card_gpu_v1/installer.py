"""Insert all three P4 rules into the existing five-owner selector graph."""


def captured(function, name):
    function = getattr(function, '__func__', function)
    code, cells = getattr(function, '__code__', None), getattr(function, '__closure__', None)
    if code is None or cells is None or name not in code.co_freevars:
        return None
    return dict(zip(code.co_freevars, cells))[name].cell_contents


def install(graph, source_root, contract):
    # Called only after the sole parent factory has finished Linux bootstrap.
    from recognition_text_fixes_v1.selection import TextFixSelection
    from next_card_fixes_v1 import policy, compound_names
    from p4_source_attributes_v1 import install_graph
    from rshb_vine.reference_additions_v1 import component as D
    from rshb_vine.io import digest

    selector = graph.selection

    def owners():
        return (graph.base.runtime.selection, graph.base.target.inner.selection,
                graph.inner.selection, graph.inner.repair.selection, graph.selection)

    before_order = [stage.trace_key for stage in selector.stages]
    before_identity = digest(selector.identity)
    if (type(selector) is not TextFixSelection or any(x is not selector for x in owners()) or
            before_identity != contract['selection_fingerprint'] or before_order != contract['stage_order'] or
            selector.request is not None or selector._select_scope is not None or selector.request_observations):
        raise RuntimeError('P4 needs exact idle db16 five-owner selector/identity/order')
    raw = D._one(D.holders(graph, ('LabelFirstIndex',)), 'LabelFirstIndex')
    geometry = [s for s in selector.stages if s.trace_key == 'layout_geometry']
    name = [s for s in selector.stages if s.trace_key == 'complete_name_role_v2']
    if (len(raw.references) != 4474 or raw.vectors.shape[0] != 4474 or
            len(geometry) != 1 or len(name) != 1 or name[0].enabled is not True or name[0].audit or
            [s.trace_key for s in selector.stages if s.position == 'post_guard'] != ['layout_geometry']):
        raise RuntimeError('P4 requires actual full4474, released NameRole and native post-guard layout')
    adapters = [obj for obj, _ in D.holders(graph, ('IdentityAdapter',)).get('IdentityAdapter', [])]
    hooks = (graph.recognize, graph.base.runtime._attach_products, graph.base.runtime._describe,
             *(adapter._describe for adapter in adapters))
    if not adapters or any(captured(hook, 'wrapper') is not selector for hook in hooks):
        raise RuntimeError('Cleanup/runtime/late public identity no longer uses the shared selector')
    original_evaluate, original_select = selector.evaluate, selector.select
    if (captured(original_evaluate, 'stage') is not name[0] or
            getattr(captured(original_select, 'own_select'), '__self__', None) is not selector):
        raise RuntimeError('Released NameRole evaluate or native I/T select closure changed')
    context = selector.inner.context
    resolver = selector.legacy.resolver
    guards = (resolver.frozen.guard, resolver.copy.guard)
    lexicon = context.lexicon
    immutable = dict(raw=raw, references=raw.references, vectors=raw.vectors,
        encoder_id=raw.encoder_id, model=selector.model, index=selector.index,
        identity_index=selector.composite_identity, registry=selector.registry,
        public_identity=selector.inner.identity, context=context, resolver=resolver,
        geometry=geometry[0], geometry_verifier=geometry[0].verifier)
    # Source-Sol's full-runtime binder includes early sugar and CatalogueIndex.
    # It must not use the old selector-only/4314 overlay as a fallback.
    attributes = contract['source_attributes']
    sugar_receipt = install_graph(graph, source_root,
        expected_config_sha256=attributes['config_sha256'], config_path=attributes['config_path'])
    if not isinstance(sugar_receipt, dict):
        raise RuntimeError('Full source-attribute installer did not return its owner receipt')
    style = policy.bind(selector, enabled=True)
    compound = compound_names.bind(selector, enabled=True)
    expected_order = list(before_order)
    expected_order.insert(expected_order.index('b3_crossview'), compound_names.TRACE_KEY)
    if expected_order != contract['effective_stage_order']:
        raise RuntimeError('Reviewed P4 insertion order differs')
    # Wrappers delegate to these same pre-existing bound closures; none is rebuilt.
    style_evaluate = captured(selector.evaluate, 'evaluate')
    if (captured(style_evaluate, 'original_evaluate') is not original_evaluate or
            captured(selector.select, 'original_select') is not original_select or
            captured(style_evaluate, 'policy') is not style or
            getattr(selector, policy.TRACE_KEY) is not style):
        raise RuntimeError('P4 failed to retain released NameRole and I/T closure chain')
    if (any(x is not selector for x in owners()) or digest(selector.identity) != before_identity or
            [s.trace_key for s in selector.stages] != expected_order or
            any(s not in selector.stages for s in (name[0], geometry[0])) or
            context.lexicon is not lexicon or (resolver.frozen.guard, resolver.copy.guard) != guards or
            raw.references is not immutable['references'] or raw.vectors is not immutable['vectors'] or
            raw.encoder_id != immutable['encoder_id'] or selector.model is not immutable['model'] or
            selector.index is not immutable['index'] or selector.registry is not immutable['registry'] or
            selector.composite_identity is not immutable['identity_index'] or
            selector.inner.identity is not immutable['public_identity'] or
            selector.inner.context is not context or selector.legacy.resolver is not resolver or
            geometry[0].verifier is not immutable['geometry_verifier'] or
            any(captured(hook, 'wrapper') is not selector for hook in hooks)):
        raise RuntimeError('P4 changed owners, native identity, models or layout')

    def clear():
        style.audit.clear()
        style.guard_audit.clear()
        style.call_evidence.clear()
        compound.audit.clear()

    def clean():
        return (not selector.request_observations and selector.request is None and
            selector._select_scope is None and style.depth == 0 and not style.audit and
            not style.guard_audit and not style.call_evidence and not compound.audit and
            not name[0].audit and context.lexicon is lexicon and
            resolver.frozen.guard is guards[0] and resolver.copy.guard is guards[1])

    checks = dict(five_selector_owners_verified=True, parent_selector_fingerprint=before_identity,
        effective_stage_order=expected_order, source_attributes=sugar_receipt,
        specific_style_color_rule=policy.RULE, complete_name_compound_rule=compound_names.RULE,
        public_identity_owners=len(adapters), I_T_closures_preserved=True,
        request_cleanup_and_late_identity_preserved=True, gallery_rows=4474,
        encoder_id=raw.encoder_id, additional_image_models=0)
    if not clean():
        raise RuntimeError('P4 installer left request-owned state')
    return selector, style, compound, checks, clear, clean
