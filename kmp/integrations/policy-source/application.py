"""Main-app local entrypoint. Real native models only; no HTTP or stored answer."""
import gc
import json
import os
from pathlib import Path

_scanner = None
_root = None


def run(root, photo_path, roi_json, output, call_address, free_address):
    global _scanner, _root
    from full_control import NativeFullScanner
    from native_models import NativeCalls
    root, output = Path(root).resolve(), Path(output)
    if _root is not None and root != _root: raise ValueError('Policy update requires an app restart')
    if _scanner is None:
        _scanner = NativeFullScanner(root)
        _root = root
    data = Path(photo_path).read_bytes()
    if not data or len(data) > 20*1024*1024: raise ValueError('Invalid photo size')
    roi = json.loads(roi_json)
    calls = NativeCalls(call_address,free_address)
    def progress(packet):
        # Atomic request-private file; Swift observes it under the same scan ID.
        path=output/'geometry.json';temporary=output/'geometry.new'
        temporary.write_text(json.dumps(packet,ensure_ascii=False,separators=(',',':'),allow_nan=False))
        os.replace(temporary,path)
    calls.on_geometry = progress
    result = _scanner.recognize(data,calls,output/'category',roi)
    outcome = dict(ok=True,view=result['view'],native_callbacks=len(calls.audit),
        policy_manifest_sha256=result['policy_manifest_sha256'],HTTP=0,
        outer_request_wrappers_complete=result['outer_request_wrappers_complete'])
    (output/'outcome.json').write_text(json.dumps(outcome,ensure_ascii=False,allow_nan=False))
    del result,calls,data
    gc.collect()  # Original outer callbacks contain request-local reference cycles.


def release():
    global _scanner
    _scanner = None
    gc.collect()
