"""Fresh native tensors/OCR -> original current4474 selection and publication.

The caller supplies real Core ML outputs, request bytes and source geometry.
No saved response is substituted, no training/model imports or HTTP are allowed.
Early-control parity remains a separate requirement; this entry labels its own
native producer and does not pretend its supplied candidates came from 8175.
"""
from copy import deepcopy
import gzip
import hashlib
import json
from pathlib import Path
import time

import numpy as np


class LivePolicySession:
    def __init__(self, root):
        from bootstrap import load
        self.root = Path(root)
        self.manifest = json.loads((self.root / 'policy-manifest.json').read_text())
        if self.manifest['kind'] != 'ondevice-current4474-live-policy-assets-v1':
            raise ValueError('Full live-policy assets required; diagnostic packet is not a runtime')
        self.selector, self.imports = load(root)
        from rshb_vine.visual_core import LabelFirstIndex
        from rshb_vine.reference_conflicts_v1.runtime import ConflictFilteredIndex
        from gpu.e3_cuda_v1.head import CompactResidualHead
        self.references = json.loads((self.root / 'live/references.json').read_text())
        self.gate = json.loads((self.root / 'live/object-gate.json').read_text())
        parameters = json.loads((self.root / 'live/head.json').read_text())
        self.head = CompactResidualHead(**{k: parameters[k] for k in ('centers', 'radii', 'coefficients')})
        vectors = np.fromfile(self.root / 'live/vectors-f32.bin', dtype='<f4').reshape(-1, 768)
        self.eid = self.manifest['encoder_id']
        raw = LabelFirstIndex(vectors, self.references, self.eid)
        # The selector owns the original guard's bound injection_conflict method.
        # Reuse that same validated owner, not the bound method as a fake guard.
        guard = getattr(self.selector.conflicts, '__self__', None)
        from rshb_vine.reference_conflicts_v1.guard import ReferenceConflicts
        from rshb_vine.io import verify
        if type(guard) is not ReferenceConflicts: raise ValueError('Original conflict guard owner missing')
        verify(guard.config)
        self.index = ConflictFilteredIndex(raw, guard)
        if len(raw.references) != 4474 or sorted(self.index.drop) != self.manifest['excluded_rows']:
            raise ValueError('Current4474 reference-conflict consumers differ')
        verifier = next(s for s in self.selector.stages if s.trace_key == 'layout_geometry').verifier
        if verifier.references != self.references or len(verifier.paths) != 4474:
            raise ValueError('Layout and retrieval reference metadata differ')
        self.calls = 0

    def recognize(self, packet, data):
        from rshb_vine.io import digest
        from rshb_vine.preprocessing import decode, checked_box
        from rshb_vine.visual_core import View
        from rshb_vine.recognition_repair_v2.composition import Request
        from rshb_vine.selected_product_output import publish_selected_products
        from rshb_vine.product_first.year_evidence import describe_year
        from gpu.e3_cuda_v1.crossview import crossview_evidence
        started = time.monotonic()
        if (packet['kind'] != 'native-coreml-vision-policy-input-v1' or
                hashlib.sha256(data).hexdigest() != packet['image_sha256'] or
                packet['assets_manifest_sha256'] != self.manifest['native_assets_sha256']):
            raise ValueError('Native producer source/pixel binding differs')
        image, _ = decode(data)
        if list(image.size) != packet['frame_size']:
            raise ValueError('Native and Python EXIF-oriented dimensions differ')
        rows = packet['targets']
        if len(rows) > 16 or len({r['instance_id'] for r in rows}) != len(rows):
            raise ValueError('Native target roster is oversized or ambiguous')
        if packet['roi'] is not None:
            checked_box(packet['roi'], image.size)
        if self.selector.current_result is not None or self.selector.request is not None:
            raise ValueError('Another native request owns the policy session')
        result = dict(targets=[], decision='no_target', best_candidate=None,
                      ranked_candidates=[], instance_text={'targets': []}, localization_trace=[],
                      native_policy_input=dict(kind=packet['kind'], source_sha256=packet['image_sha256'],
                          native_assets_sha256=packet['assets_manifest_sha256'],
                          early_pipeline=packet['early_pipeline']))
        evidence = []
        for row in rows:
            sid = row['instance_id']
            context, label = (checked_box(row[k], image.size) for k in ('context_bbox', 'label_bbox'))
            angle = row['rotation_ccw']
            if angle not in (0, 90, 270): raise ValueError('Unsupported native rotation')
            features = np.asarray(row['backbone_features'], dtype=np.float32)
            if features.shape != (2, 768): raise ValueError('Expected exact context/label backbone pair')
            query = self.head.apply(features)
            gate_vector = np.asarray(row['B0_context'], dtype=np.float32)
            if gate_vector.shape != (768,) or not np.isfinite(gate_vector).all():
                raise ValueError('Expected finite original B0 context-only gate input')
            score = float(1 / (1 + np.exp(-np.clip(np.dot(gate_vector.astype(np.float64), self.gate['coef']) + self.gate['intercept'], -40, 40))))
            if score < self.gate['threshold']:
                raise ValueError('Native producer supplied a target rejected by the original object gate')
            views = [View('context', context, 'native_detected_context', True, list(image.size)),
                     View('detected_label', label, 'native_detected_label', None, list(image.size))]
            retrieval = self.index.search(query, views, self.eid)
            retrieval['crossview_evidence'] = crossview_evidence(query, views, self.index._index, self.index.drop)
            target = dict(instance_id=sid, bbox=label, context_bbox=context,
                          parent_id=sid if row['physical'] else 'closeup-' + str(sid), kind='detected_label',
                          bottle_bbox=context if row['physical'] else None, physical_bottle_localized=row['physical'],
                          retrieval_pixel_rotation_ccw=angle, retrieval=retrieval,
                          native_B0_gate=dict(score=score, threshold=self.gate['threshold']))
            result['targets'].append(target)
            if row['physical']: result['localization_trace'].append(dict(parent_id=sid, bottle_bbox=context))
            observed = [dict(raw_text=o['text'], score=o['score'], polygon=o['polygon'], order=i)
                        for i, o in enumerate(row['ocr_observations'])]
            plane_size = row['ocr_plane_size']
            if any(len(o['polygon']) != 4 or any(len(p) != 2 or not np.isfinite(p).all() or
                    not (0 <= p[0] <= plane_size[0] and 0 <= p[1] <= plane_size[1]) for p in o['polygon']) for o in observed):
                raise ValueError('Original Vision quadrilaterals must belong to the declared OCR plane')
            text = dict(instance_id=sid, observations=observed, bbox=row['ocr_bbox'],
                        bbox_original=row['ocr_bbox'], rotation_ccw=angle,
                        polygon_coordinate_space='rotated_bottle_crop_pixels' if len(rows) == 1 else 'instance_label_crop_pixels',
                        reader='apple_vision_revision3_accurate_ru_en')
            result['instance_text']['targets'].append(text)
            if len(rows) == 1: result['variant_text'] = text
            evidence.append(dict(instance_id=sid,
                raw_visual=dict(instance_id=sid, views=deepcopy(retrieval['views']), rotation_ccw=angle,
                                arms={'B3': dict(encoder_id=self.eid, retrieval=deepcopy(retrieval))}),
                observations=observed, control_slug=retrieval['best_candidate'],
                control_candidates=deepcopy(retrieval['ranked_candidates'])))
        if len(rows) == 1:
            result.update(best_candidate=result['targets'][0]['retrieval']['best_candidate'], decision='uncertain')
        elif rows: result['decision'] = 'ambiguous_target'
        selector = self.selector
        selector.records.clear(); selector.request_observations.clear()
        selector.current_result = result
        selector.request = Request(result, data)  # Real request pixels, including triggered SIFT.
        selections, traces = {}, []
        try:
            for item in evidence:
                sid = item['instance_id']
                audit_before = {stage.trace_key: len(getattr(stage, 'audit', [])) for stage in selector.stages}
                selected = selector.select(**{k: item[k] for k in ('control_slug', 'raw_visual', 'observations', 'control_candidates')})
                selections[sid] = selected
                trace = deepcopy(selected['systemic_ranking_v2'])
                expected = [s.trace_key for s in selector.stages]
                stage_traces = trace['recognition_repair_v2']['stages']
                optional = {'complete_name_role_v2', 'complete_catalog_name_compound_v1'}
                execution = []
                for stage in selector.stages:
                    key = stage.trace_key
                    audit = deepcopy(getattr(stage, 'audit', [])[audit_before[key]:])
                    present = key in stage_traces and stage_traces[key] is not None
                    # The released NameRole/compound binders intentionally remove
                    # their trace on an exact no-op. Their original enabled audit
                    # is the authoritative proof that this stage still ran.
                    passthrough = key in optional and bool(audit) and all(
                        a.get('enabled') is True and a.get('applied') is False and
                        a.get('exact_packet_passthrough') is True for a in audit)
                    if not present and not passthrough:
                        raise ValueError('Live policy stage has neither trace nor executed passthrough audit: ' + key)
                    execution.append(dict(stage=key, position=stage.position, trace_present=present,
                                          passthrough_audit=audit if not present else []))
                if list(stage_traces) != [key for key in expected if key in stage_traces]:
                    raise ValueError('Current native stage trace order differs')
                trace['native_stage_execution'] = execution
                traces.append(trace)
            published = publish_selected_products(result, selections)
            # Refresh target-local year and all global aliases from final publication.
            for target, item in zip(published['targets'], evidence):
                sid = target['instance_id']; proposal = selections[sid]['proposal']
                target['product_resolution'] = describe_year(proposal, item['observations'], selector.registry.claims,
                    dict(kind='same_instance_ocr', instance_id=sid))
                target['product_candidates'] = selector.registry.group_ranked_cards(target['retrieval']['ranked_candidates'])
            if len(published['targets']) == 1:
                published['retrieval'] = deepcopy(published['targets'][0]['retrieval'])
            published['selected_product_output'].update(requires_alias_refresh=False, requires_product_year_refresh=False)
            self.calls += 1
            return dict(kind='native-current4474-live-policy-result-v1', result=published, traces=traces,
                selector_identity=self.manifest['selector_identity'], policy_stages=[s.trace_key for s in selector.stages],
                original_request_sha256=packet['image_sha256'], calls=self.calls, HTTP=0, training=False,
                early_pipeline_parity='pending', full_scanner_complete=False,
                elapsed_seconds=time.monotonic()-started, import_adapters=self.imports.applied)
        finally:
            selector.current_result = selector.request = None
            selector.request_observations.clear(); selector.records.clear()
            for stage in selector.stages:
                if hasattr(stage, 'audit'): stage.audit.clear()
            style = getattr(selector, 'recognition_text_fixes_v1', None)
            if style is not None:
                style.audit.clear(); style.guard_audit.clear(); style.call_evidence.clear()


_session = None

def run(root, packet_path, image_path, destination):
    global _session
    if _session is None: _session = LivePolicySession(root)
    packet = json.loads(Path(packet_path).read_text())
    report = _session.recognize(packet, Path(image_path).read_bytes())
    Path(destination).write_bytes(gzip.compress(json.dumps(report, ensure_ascii=False).encode(), mtime=0))
