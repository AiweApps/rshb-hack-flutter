"""Explicit native Core ML/Vision adapters for the original Python algorithms.

Only NN/OCR execution crosses this boundary. RGB bytes, model operation and output
are bound on both sides. The caller owns one serialized 180s/256-call request.
"""
import ctypes
import hashlib
import json
import time
from types import SimpleNamespace

import numpy as np


class NativeCalls:
    def __init__(self, call_address, free_address):
        if any(type(v) is not int or v <= 0 for v in (call_address, free_address)):
            raise ValueError('Native function addresses must come from the current process owner')
        self.call = ctypes.CFUNCTYPE(ctypes.c_void_p, ctypes.POINTER(ctypes.c_uint8),
            ctypes.c_int32, ctypes.c_int32, ctypes.c_int32)(call_address)
        self.free = ctypes.CFUNCTYPE(None, ctypes.c_void_p)(free_address)
        self.deadline = time.monotonic() + 180
        self.audit = []
        self.responses = []

    def invoke(self, image, operation):
        # The original zero-target canvas doubles both dimensions before its
        # primary SSD call. Public photo decode stays capped at24MP; only this
        # internal primary-label operation may carry the bounded4x pixel plane.
        maximum = 96_000_000 if operation == 2 else 24_000_000
        if image.mode != 'RGB' or image.width * image.height > maximum:
            raise ValueError('Native adapter requires bounded EXIF-oriented RGB')
        if len(self.audit) >= 256 or time.monotonic() > self.deadline:
            raise TimeoutError('Native request budget exhausted')
        data = image.tobytes()
        rgb_sha = hashlib.sha256(data).hexdigest()
        # c_char_p retains these immutable bytes during the synchronous callback;
        # avoid another full-size ctypes buffer copy of a camera photograph.
        pointer = self.call(ctypes.cast(ctypes.c_char_p(data), ctypes.POINTER(ctypes.c_uint8)),
                            image.width, image.height, operation)
        if not pointer:
            raise RuntimeError('Native model callback returned no result')
        try:
            result = json.loads(ctypes.string_at(pointer))
        finally:
            self.free(pointer)
        if result.get('ok') is not True:
            raise RuntimeError('Native model execution failed: ' + result.get('error', 'unknown'))
        if result['size'] != list(image.size) or result['rgb_sha256'] != rgb_sha or result['operation'] != operation:
            raise ValueError('Native model consumed another source/crop/operation')
        self.audit.append(dict(operation=operation, size=list(image.size), rgb_sha256=rgb_sha))
        self.responses.append(result)
        return result['output']


class NativeBottleDetector:
    def __init__(self, calls, *, low=False):
        self.calls, self.low = calls, low
        self.processor = SimpleNamespace(size={'height': 640, 'width': 640})
        self.proposal_count = 0

    def detect(self, image):
        if self.processor.size != {'height': 640, 'width': 640}:
            raise ValueError('Native RT-DETR export is bound to the original 640 input')
        rows = self.calls.invoke(image, 1 if self.low else 0)
        self.proposal_count = len(rows)
        return rows[:16] if self.low else rows


class NativeLabelDetector:
    def __init__(self, calls, model_id, *, rescue=False, fullframe=False):
        if rescue and fullframe: raise ValueError('One label model role required')
        self.calls, self.model_id, self.rescue, self.fullframe = calls, model_id, rescue, fullframe

    def detect(self, image):
        return [dict(row, source='automatic_main_label', model_id=self.model_id)
                for row in self.calls.invoke(image, 7 if self.fullframe else 3 if self.rescue else 2)]


class NativeEncoder:
    def __init__(self, calls, *, arm, head=None):
        if arm not in ('B0', 'E') or (arm == 'E') != (head is not None):
            raise ValueError('Original E head required only for the E encoder')
        self.calls, self.arm, self.head = calls, arm, head

    def encode(self, images):
        # PIL owns exact encoder pad preparation, as it does in the original
        # runtime. Native 384->384 must stay identity (checked at the boundary).
        from PIL import ImageOps
        rows = []
        for image in images:
            square = ImageOps.pad(image.convert('RGB'), (384, 384), color='white')
            try: vector = np.asarray(self.calls.invoke(square, 4 if self.arm == 'B0' else 5), dtype='float32')
            finally: square.close()
            if vector.shape != (768,) or not np.isfinite(vector).all():
                raise ValueError('Native image feature shape/values differ')
            rows.append(vector)
        result = np.asarray(rows, dtype='float32').reshape(-1, 768)
        return self.head.apply(result) if self.head is not None and len(rows) else result


class NativeReader:
    def __init__(self, calls): self.calls = calls

    def read(self, image):
        return [dict(raw_text=r['text'], score=r['score'], polygon=r['polygon'], order=i)
                for i, r in enumerate(self.calls.invoke(image, 6))]
