"""Real native OpenCV transfer on fixed development image crops, not UI tests."""
import hashlib
import json
from pathlib import Path
from types import SimpleNamespace
import numpy as np
import cv2


def run(root,destination):
    root=Path(root);packet=json.loads((root/'geometry-probe.json').read_text())
    from rshb_vine.geometric_reference_probe_v1 import POLICY
    from rshb_vine.geometric_reference_probe_v1.layout import correspond,CRITERIA,layout_pass,assessable
    if packet['policy']!=POLICY or packet['criteria']!=CRITERIA or len(packet['cases'])!=3:
        raise ValueError('Exact finite geometry recipe/roster required')
    gate=packet['gates'];rows=[];features={}
    def delta(a,b):return float(np.max(np.abs(a-b))) if a.shape==b.shape and a.size else (0.0 if a.shape==b.shape else None)
    def compare(actual,expected):
        discrete=['query_features','reference_features','reference_size','ratio_matches','unique_matches','unique_inliers','homography_plausible']
        discrete_ok=all(actual[k]==expected[k] for k in discrete)
        continuous=['hull_query','hull_reference','span_query','span_reference','inlier_pairs','homography']
        continuous_ok=set(actual)==set(expected) and all((k in actual)==(k in expected) and
            (k not in actual or bool(np.allclose(actual[k],expected[k],
                atol=gate['homography_atol'] if k=='homography' else gate['layout_float_atol'],rtol=0))) for k in continuous)
        return dict(passed=bool(discrete_ok and continuous_ok),discrete_exact=discrete_ok,continuous_within_gate=continuous_ok)
    for case in packet['cases']:
        path=root/case['packet']
        if hashlib.sha256(path.read_bytes()).hexdigest()!=case['packet_sha256']:raise ValueError('Geometry dev packet SHA changed')
        actual={};all_ok=True;live={};export={}
        with np.load(path,allow_pickle=False) as arrays:
            for prefix in ['query','reference']:
                gray=cv2.cvtColor(arrays[prefix+'_rgb'],cv2.COLOR_RGB2GRAY)
                keypoints,descriptors=cv2.SIFT_create(nfeatures=POLICY['sift_nfeatures']).detectAndCompute(gray,None)
                xy=np.asarray([p.pt for p in keypoints],dtype=np.float32).reshape(-1,2)
                descriptor=descriptors if descriptors is not None else np.empty((0,128),np.float32)
                metadata=np.asarray([(k.size,k.angle,k.response,k.octave) for k in keypoints],np.float32).reshape(-1,4)
                live[prefix]=dict(size=gray.shape[::-1],keypoints=keypoints,descriptors=descriptors)
                for name,value in [('xy',xy),('metadata',metadata),('descriptors',descriptor)]: export[prefix+'_'+name]=value
                error=delta(xy,arrays[prefix+'_xy'])
                passed=(np.array_equal(gray,arrays[prefix+'_gray']) and error is not None
                    and error<=gate['keypoint_maxabs'] and np.array_equal(descriptor,arrays[prefix+'_descriptors']))
                actual[prefix]=dict(gray_exact=np.array_equal(gray,arrays[prefix+'_gray']),keypoints=len(keypoints),
                    keypoint_maxabs=error,descriptor_exact=np.array_equal(descriptor,arrays[prefix+'_descriptors']),
                    descriptor_maxabs=delta(descriptor,arrays[prefix+'_descriptors']),passed=passed)
                if prefix+'_metadata' in arrays:
                    actual[prefix]['metadata_maxabs']=delta(metadata,arrays[prefix+'_metadata'])
                if descriptor.shape==arrays[prefix+'_descriptors'].shape:
                    actual[prefix]['descriptor_changed_values']=int(np.count_nonzero(descriptor!=arrays[prefix+'_descriptors']))
                    actual[prefix]['descriptor_changed_rows']=int(np.count_nonzero(np.any(descriptor!=arrays[prefix+'_descriptors'],axis=1)))
                all_ok=all_ok and passed
            def supplied(prefix):
                gray=arrays[prefix+'_gray'];desc=arrays[prefix+'_descriptors']
                return dict(size=gray.shape[::-1],descriptors=desc if len(desc) else None,
                    keypoints=tuple(SimpleNamespace(pt=tuple(map(float,row))) for row in arrays[prefix+'_xy']))
            transferred=correspond(supplied('query'),supplied('reference'));expected=case['expected']
            live_result=correspond(live['query'],live['reference'])
            actual['correspondence']=dict(compare(transferred,expected),actual=transferred)
            actual['live_correspondence']=dict(compare(live_result,expected),actual=live_result,
                layout_pass=bool(layout_pass(live_result)),source_layout_pass=bool(layout_pass(expected)))
            all_ok=all_ok and actual['correspondence']['passed'] and actual['live_correspondence']['passed']
            features[case['id']]=live
        np.savez_compressed(Path(destination).parent/f"geometry-actual-{case['id']}.npz",**export)
        rows.append(dict(id=case['id'],passed=bool(all_ok),transfer=actual))
    controls=[]
    for control in packet.get('consumer_controls',[]):
        query=features[control['query_id']][control['query_plane']]
        reference=features[control['reference_id']]['reference']
        actual=correspond(query,reference);parity=compare(actual,control['expected'])
        decision_equal=(bool(layout_pass(actual))==control['layout_pass'] and bool(assessable(actual,query))==control['assessable'])
        controls.append(dict(query_id=control['query_id'],query_plane=control['query_plane'],reference_id=control['reference_id'],
            parity=parity,actual=actual,layout_pass=bool(layout_pass(actual)),decisions_equal=decision_equal,
            passed=parity['passed'] and decision_equal))
    controls_ok=len(controls)==9 and all(c['passed'] for c in controls)
    return dict(status='PASS' if all(r['passed'] for r in rows) and controls_ok else 'TRANSFER_MISMATCH',
                cases=rows,consumer_controls=controls,consumer_controls_pass=controls_ok,
                consumer_parity=controls_ok and all(r['transfer']['live_correspondence']['passed'] for r in rows),
                NN=0,OCR=0,HTTP=0,SIFT=6,independent_accuracy=False)
