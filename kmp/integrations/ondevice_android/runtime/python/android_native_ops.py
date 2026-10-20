"""Pillow preparation and original detector selection for Android ONNX NN outputs.

The caller supplies EXIF-oriented RGB. No models, external OCR services or images
are obtained over the network. The Java owner enforces each forward budget.
"""
import hashlib
import base64
import json
import math

import numpy as np
from PIL import Image, ImageOps


def tensor(backend, role, values):
    values = np.ascontiguousarray(values, dtype='<f4')
    data = values.tobytes()
    result = json.loads(str(backend.runTensor(role, data, json.dumps(list(values.shape)))))
    if (result.get('role') != role or result.get('shape') != list(values.shape)
            or result.get('input_sha256') != hashlib.sha256(data).hexdigest()):
        raise ValueError('Native ONNX consumed another tensor/role/shape')
    return {key: (np.frombuffer(base64.b64decode(row['data_base64']), dtype='<f4') if 'data_base64' in row
                  else np.asarray(row['data'], dtype='float32')).reshape(row['shape'])
            for key, row in result['outputs'].items()}


def nchw(image, normalized=False):
    values = np.asarray(image, dtype='float32').transpose(2, 0, 1)[None] / np.float32(255)
    return (values - np.float32(.5)) / np.float32(.5) if normalized else values


def nms(rows, threshold):
    kept = []
    for row in sorted(rows, key=lambda r: -r['score']):
        a = row['bbox']
        for other in kept:
            b = other['bbox']
            intersection = max(0., min(a[2], b[2]) - max(a[0], b[0])) * max(0., min(a[3], b[3]) - max(a[1], b[1]))
            area = (a[2] - a[0]) * (a[3] - a[1]) + (b[2] - b[0]) * (b[3] - b[1])
            if intersection / max(1., area - intersection) > threshold:
                break
        else:
            kept.append(row)
    return kept


def bottles(backend, image, low=False):
    with image.resize((640, 640), Image.Resampling.BILINEAR) as resized:
        raw = tensor(backend, 'bottle', nchw(resized))
    logits, boxes = raw['logits'], raw['boxes'].reshape(-1, 4)
    if logits.ndim != 3 or logits.shape[0] != 1 or logits.shape[2] != 80 or len(boxes) != logits.shape[1]:
        raise ValueError('Unexpected frozen RT-DETR output')
    # Stable descending flattened order matches the frozen class-aware top300.
    flat = logits.ravel()
    top = np.argsort(-flat, kind='stable')[:300]
    found = []
    for index in top:
        if index % logits.shape[2] != 39:
            continue
        score = float(1 / (1 + np.exp(-flat[index])))
        if score <= (.2 if low else .4):
            continue
        cx, cy, width, height = boxes[index // logits.shape[2]].astype('float64') * [image.width, image.height, image.width, image.height]
        box = [max(0., cx - width / 2), max(0., cy - height / 2), min(image.width, cx + width / 2), min(image.height, cy + height / 2)]
        if box[2] > box[0] and box[3] > box[1]:
            found.append({'bbox': box, 'score': score})
    return nms(found, .6)


def labels(backend, image, role):
    # Same dimensions and integer centering as the frozen SSD LetterboxTransform.
    scale = 320 / max(image.size)
    width, height = max(1, round(image.width * scale)), max(1, round(image.height * scale))
    left, top = (320 - width) // 2, (320 - height) // 2
    square = Image.new('RGB', (320, 320), 'white')
    try:
        with image.resize((width, height), Image.Resampling.BILINEAR) as resized:
            square.paste(resized, (left, top))
        raw = tensor(backend, role, nchw(square))
    finally:
        square.close()
    logits, boxes = raw['logits'].reshape(-1, 2), raw['boxes'].reshape(-1, 4)
    if len(logits) != len(boxes):
        raise ValueError('Unexpected frozen SSD output')
    scores = 1 / (1 + np.exp(logits[:, 0] - logits[:, 1]))
    candidates = []
    for index in np.argsort(-scores, kind='stable'):
        score = float(scores[index])
        if score < .3:
            continue
        box = np.clip(boxes[index], 0., 320.).astype('float64').tolist()
        if box[2] > box[0] and box[3] > box[1]:
            candidates.append({'bbox': box, 'score': score})
    kept = nms(candidates[:300], .55)[:300]
    found = []
    sx, sy = width / image.width, height / image.height
    for row in kept:
        a = row['bbox']
        box = [max(0., (a[0] - left) / sx), max(0., (a[1] - top) / sy),
               min(image.width, (a[2] - left) / sx), min(image.height, (a[3] - top) / sy)]
        if box[2] > box[0] and box[3] > box[1]:
            found.append({'bbox': box, 'detector_score': row['score']})
    return found


def invoke(backend, rgb, width, height, operation):
    try:
        maximum = 96_000_000 if operation == 2 else 24_000_000
        width, height, operation = int(width), int(height), int(operation)
        if width <= 0 or height <= 0 or width * height > maximum:
            raise ValueError('Invalid bounded RGB image')
        data = bytes(rgb)
        if len(data) != width * height * 3:
            raise ValueError('Invalid RGB byte count')
        with Image.frombytes('RGB', (width, height), data) as image:
            if operation in (0, 1):
                output = bottles(backend, image, low=operation == 1)
            elif operation in (2, 3, 7):
                output = labels(backend, image, {2: 'label', 3: 'label-rescue', 7: 'label-fullframe'}[operation])
            elif operation in (4, 5):
                if image.size != (384, 384):
                    raise ValueError('Python encoder adapter must supply original RGB384 pad')
                raw = tensor(backend, 'encoder-B0' if operation == 4 else 'encoder-E', nchw(image, True))
                vector = raw['features'].reshape(-1)
                if vector.shape != (768,) or not np.isfinite(vector).all():
                    raise ValueError('Invalid encoder features')
                output = vector.tolist()
            elif operation == 6:
                from android_ocr import read
                output = read(backend, image)
            else:
                raise ValueError('Unknown native operation')
        return json.dumps({'ok': True, 'operation': operation, 'size': [width, height],
                           'rgb_sha256': hashlib.sha256(data).hexdigest(), 'output': output}, allow_nan=False)
    except Exception as error:
        return json.dumps({'ok': False, 'error': f'{type(error).__name__}: {error}'})
