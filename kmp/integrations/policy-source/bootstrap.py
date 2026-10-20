"""Load the signed source-bound policy state; never construct a model or fit.

The diagnostic entry replays one previously consumed development response. It
does not stand in for a new photo, geometry execution or full scanner acceptance.
"""
import gzip
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import sys
import time
import traceback


def load(root):
    root = Path(root).resolve()
    manifest = json.loads((root / 'policy-manifest.json').read_text())
    for name, expected in manifest['files'].items():
        path = (root / name).resolve()
        if not path.is_relative_to(root) or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            raise ValueError('Bundled policy source/SHA mismatch: ' + name)
    if os.environ.get('WINE_POLICY_DATA_ROOT') != str(root):
        raise ValueError('Native policy data root must match the signed source bundle')
    from mobile_imports import InferenceImports
    imports = InferenceImports(root)
    sys.meta_path.insert(0, imports)
    for name, relative in manifest['private_modules'].items():
        spec = importlib.util.spec_from_file_location(name, root / relative)
        module = importlib.util.module_from_spec(spec);sys.modules[name] = module
        spec.loader.exec_module(module)
    import cloudpickle
    state = cloudpickle.loads(gzip.decompress((root / 'policy.pkl.gz').read_bytes()))
    from rshb_vine.io import digest
    selector = state['selector']
    if (digest(selector.identity) != manifest['selector_identity'] or
            [stage.trace_key for stage in selector.stages] != manifest['stages']):
        raise ValueError('Restored current policy identity/stage order mismatch')
    return selector, imports


def diagnostic(root, destination):
    started=time.monotonic()
    report=dict(kind='ondevice-ios-real-policy-restore-v1',NN=0,OCR=0,SIFT=0,HTTP=0,
                independent_accuracy=False,initial_encoding=dict(filesystem=sys.getfilesystemencoding(),
                    default=sys.getdefaultencoding(),utf8_mode=sys.flags.utf8_mode,environment=os.environ.get('PYTHONUTF8')))
    try:
        selector, imports=load(root)
        from rshb_vine.current4474_saved_replay_v1.replay import select_saved, baseline_parity
        path=Path(root)/'development096.json.gz'
        body=json.loads(gzip.decompress(path.read_bytes()))
        sid=str(body['product_identity_evidence']['targets'][0]['instance_id'])
        selected=select_saved(selector,body,sid)
        parity=baseline_parity(selected,body,sid)
        report.update(status='PASS' if all(parity.values()) else 'PARITY_MISMATCH',parity=parity,
            stages=[stage.trace_key for stage in selector.stages],
            selected=selected['proposal']['representative_slug'],
            registry_cards=len(selector.registry.cards),import_adapters=imports.applied,
            python=sys.version, numpy=sys.modules['numpy'].__version__,
            pillow=sys.modules['PIL'].__version__,opencv=sys.modules['cv2'].__version__,
            filesystem_encoding=sys.getfilesystemencoding(),utf8_mode=sys.flags.utf8_mode)
        (Path(destination).parent/'policy-selected.json.gz').write_bytes(
            gzip.compress(json.dumps(selected,ensure_ascii=False).encode(),mtime=0))
        geometry_root=Path(root)/'geometry-development'
        if geometry_root.exists():
            from geometry_probe import run
            report['geometry']=run(geometry_root,destination)
            report['SIFT']=report['geometry']['SIFT']
            if report['geometry']['status']!='PASS': report['status']='GEOMETRY_MISMATCH'
    except Exception as error:
        report.update(status='ERROR',error=dict(type=type(error).__name__,message=str(error)),
                      traceback=traceback.format_exc())
    report['elapsed_seconds']=time.monotonic()-started
    Path(destination).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
