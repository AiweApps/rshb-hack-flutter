"""Original full control with explicit real Core ML / Apple Vision owners.

The trusted metadata carries the original inner control graph and request cache. Only
NN/OCR/index execution is rebound here. No model constructor, HTTP or saved scan
response participates in a fresh request. An admitted outer snapshot also carries
the original release entrypoints and their front-label/canvas/atlas/N scopes.
"""
from contextlib import contextmanager
from copy import deepcopy
import json
import os
from pathlib import Path
import time

from native_models import NativeBottleDetector, NativeLabelDetector, NativeEncoder, NativeReader


class _CrossViewIndex:
    def __init__(self, index): self.index = index
    def __getattr__(self, name): return getattr(self.index, name)
    def search(self, query, views, encoder_id):
        from gpu.e3_cuda_v1.crossview import crossview_evidence
        result = self.index.search(query, views, encoder_id)
        result['crossview_evidence'] = crossview_evidence(query, views, self.index._index, self.index.drop)
        return result


class NativeControlSession:
    def __init__(self, root, policy, calls):
        from control_snapshot import load
        from rshb_vine.b3_only_v1.split import guard_b0_encoder
        self.root, self.policy, self.calls = Path(root).resolve(), policy, calls
        manifest = policy.manifest
        snapshot = manifest.get('control_snapshot')
        if not snapshot or snapshot['current4474'] is not True:
            raise ValueError('Full control requires the admitted current4474 snapshot')
        if os.environ.get('WINE_CONTROL_DATA_ROOT') != str(self.root):
            raise ValueError('Control data root must match the validated policy package')
        self.encoders = {'E_encoder': NativeEncoder(calls, arm='E', head=policy.head),
                         'B0_gate_encoder': NativeEncoder(calls, arm='B0')}
        guard_b0_encoder(self.encoders['B0_gate_encoder'])
        self.index = _CrossViewIndex(policy.index)
        self.reader = NativeReader(calls)
        self.bottles = NativeBottleDetector(calls)
        self.bound = []
        early = json.loads((self.root/'live/early-geometry.json').read_text())
        label_roles = {early['label_model_id']: {}, early['rescue_model_id']: dict(rescue=True),
            'e84b2f8c2930df233115af39362af3174ed7c20ebee42e47d72347192f139919': dict(fullframe=True)}

        def bind(spec):
            role = spec['role']
            if role in self.encoders:
                expected = policy.eid if role == 'E_encoder' else early['gate_encoder_id']
                if spec['encoder_id'] != expected: raise ValueError('Control encoder identity differs')
                value = self.encoders[role]
            elif role in ('E_raw_index','E_filtered_index'):
                if spec['encoder_id'] != policy.eid or spec['rows'] != 4474:
                    raise ValueError('Control index space/rows differ')
                value = policy.index._index if role == 'E_raw_index' else self.index
            elif role == 'Apple_Vision_reader': value = self.reader
            elif role in ('bottle_detector','low_bottle_detector'):
                if spec['size'] != {'height':640,'width':640}: raise ValueError('Control bottle input differs')
                value = self.bottles if role == 'bottle_detector' else self.low_detector(self.bottles)
            elif role == 'label_detector':
                if spec['model_id'] not in label_roles: raise ValueError('Unknown original label weights')
                value = NativeLabelDetector(calls, spec['model_id'], **label_roles[spec['model_id']])
            elif role == 'current_policy_selector':
                if spec['parent_profile'] != snapshot['parent_profile']: raise ValueError('Outer selector lineage differs')
                value = policy.selector
            elif role == 'current_policy_registry':
                path = spec['source_path']
                if path.endswith('.selection.composite_identity.registry'):
                    value = policy.selector.composite_identity.registry
                elif path.endswith('.selection.extra[0][1].inner.identity'):
                    value = policy.selector.extra[0][1].inner.identity
                elif path.endswith('.target.inner.parent.adapter.candidate'):
                    value = deepcopy(policy.selector.extra[0][1].inner.identity)
                else: raise ValueError('Unknown outer registry responsibility: '+path)
            else: raise ValueError('Unbound full control role: '+role)
            self.bound.append(deepcopy(spec))
            return value

        state, self.restored = load(self.root/snapshot['path'], bind_slot=bind)
        self.control, self.cache = state['control'], state['cache']
        self.graph = state.get('graph')
        if self.restored['current4474'] is not True or not self.cache._capture_retrieval:
            raise ValueError('Current control/request cache binding differs')
        self.core = self.control.expanded.core
        if (self.core.encoder._cache is not self.cache or self.core.encoder._encoder is not self.encoders['E_encoder'] or
                self.cache._owners.get(policy.eid) is not self.encoders['E_encoder']):
            raise ValueError('Shared native E/cache ownership differs')
        instance = self.core.parent.parent.parent
        if instance.gate_encoder._encoder is not self.encoders['B0_gate_encoder']:
            raise ValueError('B0 gate lost its separate native owner')
        self.busy = False

    def observe_geometry(self,data):
        """Observe the original detector result before gate/OCR, without changing it."""
        callback=getattr(self.calls,'on_geometry',None)
        if callback is None:return
        from rshb_vine.preprocessing import decode,checked_box
        from rshb_vine.label_first_pipeline import consolidate_regions
        import hashlib
        source,_=decode(data)
        size=source.size;fingerprint=hashlib.sha256(source.tobytes()).digest();source.close()
        detector=self.core.parent.parent.parent.detector
        original=detector.detect
        def detect(image):
            regions=original(image)
            # Orphan/rotated/canvas crops have their own coordinate plane. Never
            # show them as rectangles on the original user photograph.
            if image.size==size and hashlib.sha256(image.tobytes()).digest()==fingerprint:
                consolidated,_=consolidate_regions(deepcopy(regions));parents={}
                for i,row in enumerate(consolidated):
                    key=str(row.get('parent_id','closeup-'+str(i)))
                    item=parents.setdefault(key,dict(bottle=None,labels=[]))
                    if 'context_bbox' in row and not row.get('unlocalized',False):item['bottle']=checked_box(row['context_bbox'],size)
                    if row.get('kind','detected_label')=='detected_label':item['labels'].append(checked_box(row['bbox'],size))
                def box(v):return None if v is None else dict(zip(('x1','y1','x2','y2'),v))
                rows=[]
                for key,item in parents.items():
                    labels=item['labels'];label=None if not labels else [min(b[0] for b in labels),min(b[1] for b in labels),max(b[2] for b in labels),max(b[3] for b in labels)]
                    rows.append(dict(id=key,number=len(rows)+1,bottle_box=box(item['bottle']),label_box=box(label)))
                if len(rows)<=16:callback(dict(stage='labels',frame_size=list(size),regions=rows))
            return regions
        detector.detect=detect

    def low_detector(self, parent):
        if not isinstance(parent, NativeBottleDetector) or parent.calls is not self.calls or parent.low:
            raise ValueError('Low bottle retry must reuse this request native RT-DETR owner')
        value = NativeBottleDetector(self.calls, low=True)
        value.parent = parent
        return value

    @contextmanager
    def native_factories(self):
        # The original rescue method creates this NN-only adapter dynamically.
        # Preserve its complete method body and restore the binding on every exit.
        import rshb_vine.bottle_rescue as rescue
        original = rescue.LowBottleDetector
        if original.__module__ != 'rshb_vine.bottle_rescue':
            raise ValueError('Another request owns the native detector factory')
        owner = self
        class LowBottleDetector(NativeBottleDetector):
            # Keep a real class: TrustedRegionLocalizer uses isinstance against
            # this factory while an injected atlas pass suppresses NN detection.
            def __init__(self, parent):
                if not isinstance(parent,NativeBottleDetector) or parent.calls is not owner.calls or parent.low:
                    raise ValueError('Low bottle retry belongs to another native owner')
                super().__init__(owner.calls,low=True)
                self.parent = parent
        rescue.LowBottleDetector = LowBottleDetector
        try: yield
        finally: rescue.LowBottleDetector = original

    @contextmanager
    def recognize(self, data, roi=None):
        if self.busy: raise ValueError('Full native control already owns a request')
        self.busy = True
        started = time.monotonic()
        try:
            with self.native_factories(), self.cache.request(enabled=True) as request:
                result = self.control.recognize(data, roi)
                # Caller consumes raw evidence within this same cache scope.
                yield result, request, time.monotonic()-started
        finally: self.busy = False

    def close(self):
        self.graph = self.control = self.cache = self.core = None
        self.encoders.clear()

    @contextmanager
    def recognize_outer(self, data, roi=None):
        if self.graph is None or self.busy: raise ValueError('An idle original outer graph is required')
        self.busy = True
        try:
            with self.native_factories():
                # This entry owns all original per-pass cache and request scopes.
                yield self.graph.recognize(data,roi)
        finally: self.busy = False


class NativeFullScanner:
    """One fresh image through original control, selector and public mapper."""
    def __init__(self, root):
        from live_selection import LivePolicySession
        from category_publication import CategoryPublication
        self.policy = LivePolicySession(root)
        self.publication = CategoryPublication(root)

    def recognize(self, data, calls, directory, roi=None):
        from rshb_vine.recognition_runtime import RecognitionRuntime
        from rshb_vine.recognition_repair_v2.composition import Request
        from category_publication import sha
        from PIL import Image
        started = time.monotonic()
        owner = NativeControlSession(self.policy.root, self.policy, calls)
        owner.observe_geometry(data)
        selector = self.policy.selector
        if selector.current_result is not None or selector.request is not None:
            raise ValueError('Another full scanner request owns the selector')
        traces = []
        original_select = selector.select

        class ObservedSelection:
            # This only observes the real selector. All choices, features and
            # publishing still come from their original implementations.
            def __getattr__(self, name): return getattr(selector, name)
            def select(self, **arguments):
                before = {s.trace_key: len(getattr(s,'audit',[])) for s in selector.stages}
                selected = original_select(**arguments)
                trace = deepcopy(selected['systemic_ranking_v2'])
                stages = trace['recognition_repair_v2']['stages']
                expected = [s.trace_key for s in selector.stages]
                if list(stages) != [k for k in expected if k in stages]:
                    raise ValueError('Full scanner stage order differs')
                executed = []
                for stage in selector.stages:
                    key = stage.trace_key
                    audit = deepcopy(getattr(stage,'audit',[])[before[key]:])
                    present = key in stages and stages[key] is not None
                    noop = key in ('complete_name_role_v2','complete_catalog_name_compound_v1') and bool(audit) and all(
                        a.get('enabled') is True and a.get('applied') is False and a.get('exact_packet_passthrough') is True for a in audit)
                    if not present and not noop: raise ValueError('Full scanner stage did not execute: '+key)
                    executed.append(dict(stage=key,position=stage.position,trace_present=present,passthrough_audit=audit if not present else []))
                trace['native_stage_execution'] = executed
                traces.append(trace)
                return selected

        original_attach = None
        runtime = None
        try:
            if owner.graph is not None:
                from rshb_vine.io import digest
                runtime = owner.graph.base.runtime
                original_attach = runtime._attach_products
                raw_passes = {}
                def attach(result, data, seconds):
                    raw_passes[digest(result)] = deepcopy(result)
                    return original_attach(result,data,seconds)
                runtime._attach_products = attach
                selector.select = ObservedSelection().select
                with owner.recognize_outer(data,roi) as selected:
                    key = selected['product_identity_evidence']['source_control_digest']
                    if key not in raw_passes: raise ValueError('Outer result lost its exact control pass')
                    raw_control = raw_passes[key]
                    cache = selected['recognition_runtime']['visual_memo']
            else:
                with owner.recognize(data, roi) as (control, memo, control_seconds):
                    raw_control = deepcopy(control)
                    if control.get('decision') == 'invalid_image': raise ValueError('Invalid source image')
                    selector.current_result = control
                    selector.request = Request(control, data)
                    runtime = RecognitionRuntime.__new__(RecognitionRuntime)
                    runtime.control, runtime.registry = owner.control, selector.registry
                    runtime.mode, runtime.selection = 'candidate_service', ObservedSelection()
                    runtime.arms = {'B3': (owner.core.eid, owner.core.encoder, owner.core.index)}
                    # Run the exact original consumer, including target_evidence,
                    # raw visual reuse, selected_product_output, year and aliases.
                    selected = runtime._attach_products(control, data, control_seconds)
                    cache = memo.snapshot()
            published_owner = None
            if selected.get('best_candidate') is not None:
                matches = [str(t['instance_id']) for t in selected.get('targets',[]) if
                    t['retrieval'].get('best_candidate') == selected['best_candidate']]
                if len(matches) != 1: raise ValueError('Published card has no unique physical owner')
                published_owner = matches[0]
            prepared = self.publication.prepare(selected, data, directory, owner=published_owner, roi=roi)
            vectors = []
            for spec in prepared['inputs']:
                image = Image.frombytes('RGB', (384,384), (Path(directory)/spec['file']).read_bytes())
                try: features = calls.invoke(image,4)
                finally: image.close()
                vectors.append({k:spec[k] for k in ('file','instance_id','role','kind','rgb_sha256','recipe_sha256')} | dict(features=features))
            packet = dict(kind='native-coreml-category-vectors-v1',request_sha256=prepared['request_sha256'],
                native_assets_sha256=self.policy.manifest['native_assets_sha256'],vectors=vectors)
            published = self.publication.complete(Path(directory)/'prepared.json',packet,data)
            return dict(kind='native-full-control-current4474-result-v1', result=published['result'],view=published['view'],
                raw_control=raw_control,traces=traces,request_cache=cache,native_roles=owner.bound,
                native_calls=calls.audit,native_responses=calls.responses,
                input_image_sha256=sha(data),policy_manifest_sha256=sha((self.policy.root/'policy-manifest.json').read_bytes()),
                original_control=True,original_selection_consumer=True,original_category_publication=True,
                secondary_reader='Apple Vision (original secondary caller used Paddle; parity unproven)',
                native_execution='saved_observations_replay' if getattr(calls,'replay_only',False) else 'CoreML_AppleVision',
                HTTP=0,fit=False,outer_request_wrappers_complete=owner.graph is not None,
                main_KMM_integrated=False,elapsed_seconds=time.monotonic()-started)
        finally:
            selector.select = original_select
            if original_attach is not None: runtime._attach_products = original_attach
            if selector.request is not None and selector.request._image is not None: selector.request._image.close()
            selector.current_result = selector.request = None
            selector.request_observations.clear();selector.records.clear()
            for stage in selector.stages:
                if hasattr(stage,'audit'): stage.audit.clear()
            style = getattr(selector,'recognition_text_fixes_v1',None)
            if style is not None:
                style.audit.clear();style.guard_audit.clear();style.call_evidence.clear()
            owner.close()
