"""Metadata and byte guards. No model, image decode, network or OCR calls."""
import gzip
import hashlib
import json
import math
from pathlib import Path

from rshb_vine.evaluation.reset_access import check_read

SPACE = 'EXIF-oriented original pixels'
KIND = 'nonwine-gpu-transfer-protocol-v1'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':'), allow_nan=False).encode()


def read_bound(path, expected, *, max_bytes):
    path = Path(path).resolve()
    check_read(path)
    if path.stat().st_size > max_bytes:
        raise ValueError('Bounded file too large: ' + str(path))
    data = path.read_bytes()
    if sha(data) != expected:
        raise ValueError('File SHA mismatch: ' + str(path))
    return data


def json_bound(path, expected, *, decoded_sha=None, max_bytes=64 * 1024 * 1024):
    data = read_bound(path, expected, max_bytes=max_bytes)
    if str(path).endswith('.gz'):
        import io
        with gzip.GzipFile(fileobj=io.BytesIO(data)) as stream:
            decoded = stream.read(max_bytes + 1)
    else:
        decoded = data
    if len(decoded) > max_bytes:
        raise ValueError('Decoded JSON exceeds bound')
    if decoded_sha is not None and sha(decoded) != decoded_sha:
        raise ValueError('Decoded JSON SHA mismatch')
    return json.loads(decoded, parse_constant=lambda x: (_ for _ in ()).throw(ValueError(x)))


def box(value):
    if value is None:
        return None
    if (not isinstance(value, list) or len(value) != 4 or
            any(isinstance(x, bool) or not isinstance(x, (int, float)) or not math.isfinite(x) for x in value) or
            value[2] <= value[0] or value[3] <= value[1]):
        raise ValueError('Ambiguous or nonfinite geometry')
    return list(value)


def geometry_plan(response, binding):
    """Bind each existing contract entry and current request target, never infer neighbours.

    Full-pass entries absent from targets require an explicit root-supplied
    ``full_pass_contract`` row. Coordinates are never synthesized from a label.
    """
    if binding.get('coordinate_space') != SPACE:
        raise ValueError('Geometry coordinate space is not explicit')
    size = binding.get('oriented_size')
    if not isinstance(size, list) or len(size) != 2 or any(type(v) is not int or v <= 0 for v in size):
        raise ValueError('Oriented size missing')
    contract = response.get('target_contract')
    if not isinstance(contract, dict) or contract.get('frame_size') not in (None, size):
        raise ValueError('Current target contract/frame is missing or differs')
    targets = response.get('targets') or []
    target_map = {str(t['instance_id']): t for t in targets}
    if len(target_map) != len(targets):
        raise ValueError('Duplicate current request target')
    entries = [(e, 'bottle') for e in contract.get('bottles') or []]
    observation = contract.get('roi_observation')
    if observation:
        entries.append((observation, 'roi_observation'))
    keys = [(str(e['instance_id']), role) for e, role in entries]
    rows = binding.get('entries') or []
    rows_by_key = {(str(r['contract_instance_id']), r['role']): r for r in rows}
    if len(rows_by_key) != len(rows) or set(rows_by_key) != set(keys) or len(set(keys)) != len(keys):
        raise ValueError('Geometry roster differs from current contract')
    plan = []
    covered = set()
    for entry, role in entries:
        iid = str(entry['instance_id'])
        row = rows_by_key[iid, role]
        source = row['source']
        sid = row.get('source_target_instance_id')
        sid = None if sid is None else str(sid)
        own_bottle, own_label = box(entry.get('bottle_bbox')), box(entry.get('label_bbox'))
        if source == 'roi_pass':
            if entry.get('card_source') != 'roi_pass' or entry.get('roi_pass_instance_id') is None:
                raise ValueError('ROI source is not explicitly linked')
            if sid != str(entry['roi_pass_instance_id']):
                raise ValueError('ROI link differs from geometry binding')
        elif source == 'this_request':
            if entry.get('card_source') != 'this_request' or sid != iid:
                raise ValueError('Current request source mismatch')
        elif source == 'full_pass_contract':
            if sid is not None or entry.get('card_source') != 'this_request' or contract.get('mode') != 'explicit_roi':
                raise ValueError('Full pass geometry lacks an explicit contract basis')
        else:
            raise ValueError('Unsupported geometry source')
        if sid is not None:
            if sid not in target_map:
                raise ValueError('Linked current target is absent')
            target = target_map[sid]
            bottle, label = box(target.get('bottle_bbox')), box(target.get('bbox'))
            # A linked full-pass entry may carry its old geometry. The ROI target
            # is the source of the ROI card and therefore the source of crops.
            if source == 'this_request' and (bottle != own_bottle or label != own_label):
                raise ValueError('Same-instance contract geometry differs')
            for view in (target.get('retrieval') or {}).get('views') or []:
                if view.get('original_size') not in (None, size):
                    raise ValueError('Target view frame differs')
                if view.get('coordinate_space') not in (None, SPACE):
                    raise ValueError('Target view coordinate space differs')
            covered.add(sid)
        else:
            bottle, label = own_bottle, own_label
        if box(row.get('bottle_bbox')) != bottle or box(row.get('label_bbox')) != label:
            raise ValueError('Frozen crop geometry changed')
        plan.append(dict(contract_instance_id=iid, role=role, source=source,
                         source_target_instance_id=sid, bottle_bbox=bottle, label_bbox=label))
    if covered != set(target_map):
        raise ValueError('Current target omitted by geometry bindings')
    return dict(coordinate_space=SPACE, oriented_size=size, entries=plan)
