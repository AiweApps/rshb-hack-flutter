"""Frozen PP-OCRv6 Medium ONNX + original PaddleX DB/quad/CTC processing.

Native score is the mean CTC probability of emitted non-blank, deduplicated
characters. It is not Vision confidence and is not calibrated for policy use.
"""
import ctypes
import hashlib
import json
import math
import os
import unicodedata
from pathlib import Path

import numpy as np

from android_native_ops import tensor


_libraries = {}
_dictionaries = {}


def library():
    name = os.environ.get('WINE_ANDROID_GEOMETRY_LIBRARY', 'libwinegeometry.so')
    if name not in _libraries:
        lib = ctypes.CDLL(name)
        if hasattr(lib, 'wg_initialize'):
            lib.wg_initialize.argtypes = []
            lib.wg_initialize.restype = None
            lib.wg_initialize()
        pointer = ctypes.c_void_p
        integer = ctypes.c_int
        lib.wine_ocr_resize_rgb.argtypes = [pointer, integer, integer, integer, integer, pointer]
        lib.wine_ocr_resize_rgb.restype = integer
        lib.wine_ocr_db_boxes.argtypes = [pointer, integer, integer, integer, integer,
                                        ctypes.c_double, ctypes.c_double, ctypes.c_double, integer, pointer, integer]
        lib.wine_ocr_db_boxes.restype = integer
        lib.wine_ocr_warp_rgb.argtypes = [pointer, integer, integer, pointer, ctypes.POINTER(pointer),
                                       ctypes.POINTER(integer), ctypes.POINTER(integer)]
        lib.wine_ocr_warp_rgb.restype = integer
        lib.wine_ocr_free.argtypes = [pointer]
        lib.wine_ocr_free.restype = None
        lib.wine_ocr_error.argtypes = []
        lib.wine_ocr_error.restype = ctypes.c_char_p
        _libraries[name] = lib
    return _libraries[name]


def resize(rgb, width, height):
    rgb = np.ascontiguousarray(rgb, dtype='uint8')
    result = np.empty((height, width, 3), dtype='uint8')
    code = library().wine_ocr_resize_rgb(rgb.ctypes.data, rgb.shape[1], rgb.shape[0], width, height, result.ctypes.data)
    if code != 1:
        raise RuntimeError(f'Native OCR resize failed: {code}: {library().wine_ocr_error()}')
    return result


def boxes(probability, width, height):
    probability = np.ascontiguousarray(probability, dtype='float32')
    if probability.ndim != 2 or not np.isfinite(probability).all():
        raise ValueError('Invalid DB probability map')
    result = np.empty((3000, 4, 2), dtype='float32')
    count = library().wine_ocr_db_boxes(probability.ctypes.data, *probability.shape, width, height,
                                      .2, .45, 1.4, 3000, result.ctypes.data, len(result))
    if not 0 <= count <= len(result):
        raise RuntimeError(f'Native OCR DB failed: {count}')
    # Original PaddleX SortQuadBoxes (10px same-line insertion ordering).
    ordered = sorted(result[:count].tolist(), key=lambda box: (box[0][1], box[0][0]))
    for index in range(len(ordered) - 1):
        for cursor in range(index, -1, -1):
            if abs(ordered[cursor + 1][0][1] - ordered[cursor][0][1]) < 10 and ordered[cursor + 1][0][0] < ordered[cursor][0][0]:
                ordered[cursor], ordered[cursor + 1] = ordered[cursor + 1], ordered[cursor]
            else:
                break
    return ordered


def crop(rgb, quad):
    quad = np.ascontiguousarray(quad, dtype='float32')
    output = ctypes.c_void_p()
    width, height = ctypes.c_int(), ctypes.c_int()
    code = library().wine_ocr_warp_rgb(rgb.ctypes.data, rgb.shape[1], rgb.shape[0], quad.ctypes.data,
                                     ctypes.byref(output), ctypes.byref(width), ctypes.byref(height))
    if code != 1 or not output.value:
        raise RuntimeError(f'Native OCR quad crop failed: {code}: {library().wine_ocr_error()}')
    try:
        if width.value <= 0 or height.value <= 0 or width.value * height.value > 24_000_000:
            raise ValueError('Native OCR crop size outside bounds')
        return np.frombuffer(ctypes.string_at(output, width.value * height.value * 3), dtype='uint8').reshape(height.value, width.value, 3)
    finally:
        library().wine_ocr_free(output)


def dictionary(backend, role):
    root = str(backend.modelDirectory())
    key = (root, role)
    if key not in _dictionaries:
        manifest = json.loads((Path(root) / 'manifest.json').read_text())
        row = manifest['ocr_dictionaries'][role]
        path = (Path(root) / row['path']).resolve()
        if not path.is_relative_to(Path(root).resolve()) or hashlib.sha256(path.read_bytes()).hexdigest() != row['sha256']:
            raise ValueError('OCR character dictionary changed')
        chars = json.loads(path.read_text())
        if not isinstance(chars, list) or len(chars) != row['count'] or chars[0] != 'blank' or chars[-1] != ' ':
            raise ValueError('OCR character dictionary contract changed')
        _dictionaries[key] = chars
    return _dictionaries[key]


def script_class(text):
    cyrillic = latin = other = False
    for char in unicodedata.normalize('NFKC', text):
        if not char.isalpha():
            continue
        name = unicodedata.name(char, '')
        if name.startswith('CYRILLIC'):
            cyrillic = True
        elif name.startswith('LATIN'):
            latin = True
        else:
            other = True
    if cyrillic:
        return 'CYR'
    if other:
        return 'OTHER'
    return 'LAT' if latin else 'NONE'


def normalize(text):
    text = unicodedata.normalize('NFKC', text).upper().replace('Ё', 'Е')
    return ' '.join(''.join(char if char.isalnum() else ' ' for char in text).split())


def fuse_line(v5, v6):
    # Frozen source pilot: rshb_vine/ocr_v5_v6_v1/reader.py:fuse_line.
    s5, s6 = script_class(v5['text']), script_class(v6['text'])
    v5_empty, v6_empty = not normalize(v5['text']), not normalize(v6['text'])
    if s5 == 'CYR':
        return v5, 'v5_has_cyrillic'
    if s5 == 'LAT' and s6 == 'LAT' and not v6_empty:
        return v6, 'both_latin'
    if v5_empty and not v6_empty and s6 == 'LAT':
        return v6, 'v5_empty'
    return v5, 'default_v5'


def recognize(backend, line, role, chars):
    line_h, line_w = line.shape[:2]
    max_ratio = max(320 / 48, line_w / line_h)
    padded_w = min(int(48 * max_ratio), 3200)
    resized_w = padded_w if int(48 * max_ratio) > 3200 else min(math.ceil(48 * line_w / line_h), padded_w)
    bgr = resize(line, resized_w, 48)[:, :, ::-1].astype('float32')
    normalized = (bgr.transpose(2, 0, 1) / np.float32(255) - np.float32(.5)) / np.float32(.5)
    values = np.zeros((1, 3, 48, padded_w), dtype='float32')
    values[0, :, :, :resized_w] = normalized
    outputs = tensor(backend, role, values)
    if len(outputs) != 1:
        raise ValueError('OCR recognizer output contract changed')
    probabilities = next(iter(outputs.values()))
    if probabilities.ndim != 3 or probabilities.shape[0] != 1 or probabilities.shape[2] != len(chars):
        raise ValueError('OCR CTC shape differs from pinned dictionary')
    if not np.isfinite(probabilities).all() or np.min(probabilities) < 0 or np.max(probabilities) > 1:
        raise ValueError('OCR CTC output is not probabilities')
    ids = probabilities[0].argmax(axis=-1)
    scores = probabilities[0].max(axis=-1)
    selection = np.ones(len(ids), dtype='bool')
    selection[1:] = ids[1:] != ids[:-1]
    selection &= ids != 0
    text = ''.join(chars[index] for index in ids[selection])
    score = float(np.mean(scores[selection])) if selection.any() else 0.
    return {'text': text, 'score': score, 'reader': role}


def read(backend, image):
    dictionaries = {role: dictionary(backend, role) for role in ('ocr-rec', 'ocr-cyrillic')}
    rgb = np.ascontiguousarray(image, dtype='uint8')
    detector_rgb = rgb
    if image.width + image.height < 64:
        detector_rgb = np.zeros((max(32, image.height), max(32, image.width), 3), dtype='uint8')
        detector_rgb[:image.height, :image.width] = rgb
    detector_h, detector_w = detector_rgb.shape[:2]
    ratio = min(1., 960 / max(detector_w, detector_h))
    width = max(round(int(detector_w * ratio) / 32) * 32, 32)
    height = max(round(int(detector_h * ratio) / 32) * 32, 32)
    # PP-OCRv6 model config requires BGR; do not borrow encoder RGB normalization.
    values = resize(detector_rgb, width, height)[:, :, ::-1].astype('float32')
    # PaddleX NormalizeImage applies alpha then beta in-place, with an FP32
    # rounding between the operations. Algebraic rearrangement changes pixels.
    for channel, (mean, std) in enumerate(zip([.485, .456, .406], [.229, .224, .225])):
        values[:, :, channel] *= (1. / 255.) / std
        values[:, :, channel] += -mean / std
    outputs = tensor(backend, 'ocr-det', values.transpose(2, 0, 1)[None])
    if len(outputs) != 1:
        raise ValueError('OCR detector output contract changed')
    probability = next(iter(outputs.values()))
    if probability.ndim != 4 or probability.shape[:2] != (1, 1):
        raise ValueError('OCR detector shape contract changed')
    result = []
    for quad in boxes(probability[0, 0], image.width, image.height):
        line = crop(rgb, quad)
        v5 = recognize(backend, line, 'ocr-cyrillic', dictionaries['ocr-cyrillic'])
        v6 = recognize(backend, line, 'ocr-rec', dictionaries['ocr-rec'])
        chosen, reason = fuse_line(v5, v6)
        if not chosen['text']:
            continue
        points = np.asarray(quad, dtype='float32')
        result.append({**chosen, 'polygon': quad,
                       'bbox': [float(points[:, 0].min()), float(points[:, 1].min()),
                                float(points[:, 0].max()), float(points[:, 1].max())],
                       'fusion_rule': 'script-route-v1', 'selection_reason': reason,
                       'alternatives': [v5, v6], 'confidence_kind': 'native_ctc_mean'})
    return result
