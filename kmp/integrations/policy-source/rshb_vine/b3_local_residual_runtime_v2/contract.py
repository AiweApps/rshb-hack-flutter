"""Read-only readiness. No model loading, gallery fitting, or runtime activation."""
from pathlib import Path
import hashlib
import json
import numpy as np

from rshb_vine.io import local_path, read_json, read_jsonl, seal, sha256, verify

OLD_PACKAGE = 'rshb_vine/b3_local_residual_runtime_v1'
PACKAGE = 'rshb_vine/b3_local_residual_runtime_v2'
SOURCES = (OLD_PACKAGE+'/__init__.py', OLD_PACKAGE+'/contract.py', OLD_PACKAGE+'/encoder.py',
           OLD_PACKAGE+'/runtime.py', OLD_PACKAGE+'/http.py', OLD_PACKAGE+'/readout.py',
           OLD_PACKAGE+'/environment.py', 'scripts/run_b3_local_residual_runtime.py',
           PACKAGE+'/__init__.py', PACKAGE+'/contract.py', PACKAGE+'/crossview.py', PACKAGE+'/selection.py',
           PACKAGE+'/runtime.py', PACKAGE+'/http.py', PACKAGE+'/readout.py',
           PACKAGE+'/replay_saved.py', PACKAGE+'/selector_replay_saved.py',
           'scripts/run_b3_local_residual_runtime_v2.py')
CATALOG_DESCRIPTOR = 'runs/catalog-refresh-20261001/runtime-build-v1/descriptor-v3.json'
E_MANIFEST = 'runs/b3-local-residual-20261013/analytic-fit-E-v1/encoder-manifest.json'
E_RECEIPT = 'runs/b3-local-residual-20261013/evaluation-E-v1/receipt.json'
E_VECTORS = 'runs/b3-local-residual-20261013/evaluation-E-v1/E-vectors.npy'
E_MEMBERS = 'runs/b3-local-residual-20261013/evaluation-E-v1/E-membership.jsonl'
ROSTER = 'runs/b3-detail-learning-preparation-20261012/recipe-A/closed-recipe-v3/all4314-inference-training-retention-cue-role-ledger.jsonl'
BASE_SEAL = 'runs/b3-detail-frozen-experiment-20261011/root-full-actual-v2/bank-seal.json'
PRIOR_E_TARGETS = 'runs/b3-local-residual-http-20261013/paired-readout-v3/E-target246.jsonl'
CURRENT = 'config/recognition-current.json'
KIND = 'b3-local-residual-full-http-protocol-v2'


def checked(root, pins):
    for path, expected in pins.items():
        if sha256(local_path(root, path)) != expected:
            raise ValueError('Pinned input changed: '+path)


def readiness(root):
    """Prove row/reader/processor/head binding using existing committed receipts."""
    from rshb_vine.catalog_refresh_runtime_v1 import build
    from rshb_vine.b3_local_residual_v1.head import CompactResidualHead
    from rshb_vine.b3_local_residual_runtime_v1.environment import info, SOURCE,PLAN,BINARY
    root = Path(root).resolve()
    descriptor = build.load(root, CATALOG_DESCRIPTOR)
    gallery_path = descriptor['build']+'/gallery.json'
    gallery = verify(read_json(root/gallery_path))
    refs = gallery['references']; roster = read_jsonl(root/ROSTER)
    if len(refs) != len(roster) or len(refs) != 4314:
        raise ValueError('Exact all4314 source roster required')
    for i, (ref, row) in enumerate(zip(refs, roster)):
        reader = row['reader']
        if (row['reference_id'] != f'G:{i:04d}' or reader['reference_index'] != i or
            any(ref[key] != reader[other] for key, other in (
                ('image_sha256', 'source_sha256'), ('bbox', 'bbox'), ('kind', 'kind'),
                ('original_size', 'original_size'), ('coordinate_space', 'coordinate_space')))):
            raise ValueError('Gallery source/geometry order changed: '+str(i))
    e = read_json(root/E_MANIFEST); receipt = read_json(root/E_RECEIPT)
    if receipt['status'] != 'PASS_EVALUATION_NN_COMPLETE_NO_RELEASE' or receipt['counter']['committed'] != 4768:
        raise ValueError('Completed immutable E actual evaluation required')
    checked(root, {str(Path(E_RECEIPT).parent/name):h for name,h in receipt['output_pins'].items()})
    checked(root, {e['backbone_path']+'/model.safetensors':e['backbone_sha256'],
                   e['backbone_path']+'/preprocessor_config.json':e['processor_sha256'],
                   e['head_path']:e['head_sha256'], e['head_code_path']:e['head_code_sha256']})
    if receipt['membership']['E']['model_sha256'] != sha256(root/E_MANIFEST):
        raise ValueError('E composite identity differs from actual gallery receipt')
    vectors = np.load(root/E_VECTORS, allow_pickle=False)
    members = read_jsonl(root/E_MEMBERS)
    if vectors.dtype != np.float32 or vectors.shape != (4768,768) or len(members) != 4768:
        raise ValueError('Actual complete E gallery/query/stress bank required')
    for i, (row, member) in enumerate(zip(roster, members)):
        if (member['row'] != i or member['input_id'] != row['reference_id'] or
            member['feature_sha256'] != hashlib.sha256(vectors[i].tobytes()).hexdigest() or
            member['RGB384_sha256'] != row['actual_RGB384_sha256'] or
            member['tensor_sha256'] != row['actual_tensor_sha256']):
            raise ValueError('Actual E membership/pixel/feature binding differs: '+str(i))
    base = read_json(root/BASE_SEAL)
    checked(root, {base['global_bank']['path']:base['global_bank']['sha256']})
    b = np.load(local_path(root,base['global_bank']['path']),allow_pickle=False)
    if b.shape != (4560,768) or b.dtype != np.float32:
        raise ValueError('Exact baseline4314 gallery bank required')
    for i,(row,member) in enumerate(zip(roster,base['gallery_records'])):
        old=member['record']
        if old['reference_id'] != row['reference_id'] or member['bank_row'] != i+246 or old['reader'] != row['reader']:
            raise ValueError('Actual baseline reader order differs: '+str(i))
    # The E bank was produced by this exact universal feature function.
    base_e_path=str(Path(E_VECTORS).parent/'actual-frozen-C-base-vectors.npy')
    base_e=np.load(root/base_e_path,allow_pickle=False)
    head=CompactResidualHead.load(root/e['head_path'])
    if not np.array_equal(head.apply(base_e[:4314]),vectors[:4314]):
        raise ValueError('E actual all4314 differs from same frozen C+head')
    parent_encoder='runs/catalog-training-data-v2/stage5/evaluator/actual-fit-v1/B4343/encoder'
    if sha256(root/(parent_encoder+'/model.safetensors')) != base['model_sha256']:
        raise ValueError('Baseline actual bank/model mismatch')
    if sha256(root/(parent_encoder+'/preprocessor_config.json')) != e['processor_sha256']:
        raise ValueError('Baseline/E processor differs')
    native_environment=info(root)
    paths=[*SOURCES,SOURCE,PLAN,BINARY,CATALOG_DESCRIPTOR, E_MANIFEST,E_RECEIPT,E_VECTORS,E_MEMBERS,ROSTER,BASE_SEAL,
           PRIOR_E_TARGETS,
           base_e_path,CURRENT,gallery_path,descriptor['build']+'/vectors.npy',base['global_bank']['path'],
           *[e['backbone_path']+'/'+n for n in ('model.safetensors','config.json','preprocessor_config.json')],
           *[parent_encoder+'/'+n for n in ('model.safetensors','config.json','preprocessor_config.json')],
           e['head_path'],e['head_code_path']]
    pins={p:sha256(local_path(root,p)) for p in paths}
    pins.update(descriptor['pins_sha256']);pins.update(descriptor['sources_sha256'])
    return seal(dict(kind='b3-local-residual-full-http-readiness-v2',status='READY_METADATA_NO_NN',
        source_pins=pins,code_pins={p:pins[p] for p in SOURCES},
        parent_profile_checksum=verify(read_json(root/CURRENT))['checksum'],
        catalogue_descriptor_checksum=descriptor['checksum'],gallery=gallery_path,gallery_rows=4314,
        current_release_gallery_rows=4210,extra_views=104,extra_cards=52,Phantom_rows_retained=[4206,4207,4208,4209],
        gallery_source_geometry_all4314_exact=True, E_actual_head_all4314_exact=True,
        baseline_bank=base['global_bank'],baseline_gallery_offset=246,
        baseline_encoder=parent_encoder,baseline_model_sha256=base['model_sha256'],
        E_manifest=E_MANIFEST,E_composite_sha256=sha256(root/E_MANIFEST),E_gallery=E_VECTORS,
        E_backbone_sha256=e['backbone_sha256'],E_head_sha256=e['head_sha256'],
        processor_sha256=e['processor_sha256'],NN=0,model_loads=0,fit=0,OCR=0,
        native_OCR_environment=native_environment,
        limits='Known development; exact edition and identity holds unchanged; private4314 catalogue successor over F12'))


def protocol(root, path):
    doc=read_json(local_path(root,path))
    if doc.get('kind') != KIND or doc.get('execution_admitted') is not False:
        raise ValueError('Explicit prospective root fullHTTP protocol required')
    checked(root,doc['pins'])
    ready=readiness(root)
    if ready['checksum'] != doc['readiness_checksum']:
        raise ValueError('Protocol does not bind exact reviewed readiness')
    return doc,ready
