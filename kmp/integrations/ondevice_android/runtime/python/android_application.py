"""Android owner around the exact admitted outer/control/11-stage policy.

Only model and OCR callbacks change platform. No HTTP fallback or saved answer.
"""
import gc
import gzip
import hashlib
import json
import os
from pathlib import Path
import sys
import time
import traceback

_scanner = None
_root = None


def initialize(root, geometry_library, android_manifest_sha):
    global _root, _scanner
    root = Path(root).resolve()
    if _root is not None:
        if root != _root:
            raise ValueError('A policy update requires an app restart')
        return
    sys.dont_write_bytecode = True
    os.environ['WINE_POLICY_DATA_ROOT'] = str(root)
    os.environ['WINE_CONTROL_DATA_ROOT'] = str(root)
    os.environ['WINE_GEOMETRY_LIBRARY'] = geometry_library
    os.environ['WINE_ANDROID_GEOMETRY_LIBRARY'] = geometry_library
    os.environ['OPENBLAS_NUM_THREADS'] = '1'
    os.environ['OMP_NUM_THREADS'] = '1'
    sys.path.insert(0, str(root))
    from full_control import NativeFullScanner
    _scanner = NativeFullScanner(root)
    _scanner.publication.profile = 'ondevice-android-experimental-v1:' + android_manifest_sha
    _root = root


class AndroidCalls:
    def __init__(self, backend):
        self.backend = backend
        self.deadline = time.monotonic() + 180
        self.audit, self.responses = [], []

    def invoke(self, image, operation):
        maximum = 96_000_000 if operation == 2 else 24_000_000
        if image.mode != 'RGB' or image.width * image.height > maximum:
            raise ValueError('Bounded EXIF-oriented RGB required')
        if len(self.audit) >= 256 or time.monotonic() > self.deadline:
            raise TimeoutError('Native request budget exhausted')
        self.backend.checkCancelled()
        data = image.tobytes()
        digest = hashlib.sha256(data).hexdigest()
        start = time.monotonic()
        # Keep full-resolution RGB in Python/native memory. A96MP internal
        # canvas alone exceeds many Android Java heaps; Java consumes only the
        # small, source-derived inference tensor prepared by this exact adapter.
        from android_native_ops import invoke
        result = json.loads(invoke(self.backend, data, image.width, image.height, operation))
        elapsed = time.monotonic() - start
        self.backend.checkCancelled()
        if not result.get('ok'):
            raise RuntimeError('Native Android callback failed: ' + result.get('error', 'unknown'))
        if result['size'] != list(image.size) or result['operation'] != operation or result['rgb_sha256'] != digest:
            raise ValueError('Native consumed a different crop/operation')
        self.audit.append(dict(operation=operation, size=list(image.size), rgb_sha256=digest,
                               elapsed_seconds=elapsed))
        self.responses.append(result)
        return result['output']


def run(root, geometry_library, android_manifest_sha, photo_path, roi_json, output, backend):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    report = dict(kind='wine-android-full-policy-request-v1', HTTP=0, fit=False,
                  independent_accuracy=False, android_manifest_sha256=android_manifest_sha)
    try:
        setup = time.monotonic()
        initialize(root, geometry_library, android_manifest_sha)
        report['setup_seconds'] = time.monotonic() - setup
        data = Path(photo_path).read_bytes()
        if not data or len(data) > 20 * 1024 * 1024:
            raise ValueError('Invalid photo size')
        calls = AndroidCalls(backend)
        def progress(packet):
            backend.publishGeometry(json.dumps(packet, ensure_ascii=False, allow_nan=False))
        calls.on_geometry = progress
        result = _scanner.recognize(data, calls, output / 'category', json.loads(roi_json))
        # The preserved iOS policy labels its producers Apple/CoreML. Record the
        # actual producer here without changing any selection or scoring rule.
        result.update(native_execution='Android_ONNXRuntime_PaddleOCR_V6_V5_script_route',
                      secondary_reader='PaddleOCR V6/V5 Cyrillic script route (different from Apple Vision)',
                      main_KMM_integrated=True)
        (output / 'evidence.json.gz').write_bytes(gzip.compress(
            json.dumps(result, ensure_ascii=False, allow_nan=False).encode(), mtime=0))
        report.update(ok=True, view=result['view'], native_callbacks=len(calls.audit),
                      native_calls=calls.audit, source_sha256=hashlib.sha256(data).hexdigest(),
                      policy_manifest_sha256=result['policy_manifest_sha256'],
                      outer_request_wrappers_complete=result['outer_request_wrappers_complete'],
                      recognition_seconds=result['elapsed_seconds'])
    except Exception as error:
        report.update(ok=False, error=str(error), traceback=traceback.format_exc())
    finally:
        report['wall_seconds'] = time.monotonic() - started
        gc.collect()
    (output / 'outcome.json').write_text(json.dumps(report, ensure_ascii=False, allow_nan=False))
    return json.dumps(report, ensure_ascii=False, allow_nan=False)


def release():
    global _scanner, _root
    _scanner, _root = None, None
    gc.collect()
