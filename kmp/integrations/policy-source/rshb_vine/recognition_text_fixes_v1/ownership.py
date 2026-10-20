"""Request-bound OCR ownership before every selector/resolver consumer.

This module does not read images, catalogue names, scores or GT. It preserves
the raw packet and returns a comparison copy plus an auditable line decision.
The caller must use the returned packet for features AND legacy resolution /
public product description, while keeping its request body and raw OCR intact.
"""
from collections import Counter
from copy import deepcopy
import hashlib
import json
import math


RULE = {
    'version': 'request-bound-label-text-ownership-v2',
    'scope': 'one request target; raw OCR and geometry unchanged',
    'foreign': 'exclude only a mapped line wholly in one other label and wholly outside own label and physical bottle',
    'unassigned': 'single explicitly unlocalized target, full-frame context OCR, own non-partial label with an interior text anchor: exclude mapped lines only when strictly disjoint across the upright label width, with request-bound encoder rotation; never call them confirmed foreign',
    'physical': 'preserve text inside an explicitly localized bottle whose box is corroborated by this request instance/localization record, including text outside the label',
    'mapping': 'declared EXIF original or source-crop pixels; inverse discrete CCW 0/90/180/270 using request-bound crop/rotation; supplement polygons recovered only by exact source block ordinal/text/score',
    'unknown': 'retain missing/unsupported mapping, missing/partial label, overlap/boundary lines, ambiguous ownership and uncorroborated physical geometry; text aligned along an unlocalized bottle may belong to another label of that same bottle',
    'preserved': 'raw observations, native scores, provenance, full packet order, images, visual candidates, catalogue, weights and probabilities',
}
LABEL_KINDS = ('detected_label', 'front_label', 'partial_label')
LABEL_CROPS = ('instance_label_crop', 'label_view_crop')


def _digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True,
                                     separators=(',', ':')).encode()).hexdigest()


def _box(value):
    if (not isinstance(value, (list, tuple)) or len(value) != 4 or
            any(isinstance(v, bool) or not isinstance(v, (float, int)) or not math.isfinite(v) for v in value)):
        return None
    x1, y1, x2, y2 = value
    return list(value) if x1 < x2 and y1 < y2 else None


def _checked(value):
    box = _box(value)
    return [math.floor(box[0]), math.floor(box[1]), math.ceil(box[2]), math.ceil(box[3])] if box else None


def _inside(inner, outer):
    return bool(inner and outer and outer[0] <= inner[0] and outer[1] <= inner[1]
                and inner[2] <= outer[2] and inner[3] <= outer[3])


def _disjoint(a, b):
    # Boundary contact stays ambiguous rather than discarding a truncated word.
    return bool(a and b and (a[2] < b[0] or b[2] < a[0] or a[3] < b[1] or b[3] < a[1]))


def _cross_axis_disjoint(a, b, axis):
    if not a or not b or axis not in ('x', 'y'):
        return False
    low, high = (0, 2) if axis == 'x' else (1, 3)
    return a[high] < b[low] or b[high] < a[low]


def _polygon(value):
    if not isinstance(value, (list, tuple)) or len(value) < 3:
        return None
    if any(not isinstance(p, (list, tuple)) or len(p) != 2 or
           any(isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v) for v in p)
           for p in value):
        return None
    return [list(p) for p in value]


def _envelope(points):
    return _box([min(p[0] for p in points), min(p[1] for p in points),
                 max(p[0] for p in points), max(p[1] for p in points)]) if points else None


def _source_block(body, path):
    value = body
    try:
        for piece in path.split('.'):
            value = value[int(piece)] if isinstance(value, list) else value[piece]
    except (ValueError, KeyError, IndexError, TypeError, AttributeError):
        return None
    return value if isinstance(value, dict) else None


def _label(views):
    labels = [(view.get('kind'), _checked(view.get('bbox'))) for view in views
              if view.get('kind') in LABEL_KINDS and _checked(view.get('bbox'))]
    distinct = {tuple(box) for _, box in labels}
    if len(distinct) != 1:
        return None, 'missing_or_multiple_labels'
    kind, box = labels[0]
    return box, 'partial_label' if any(k == 'partial_label' for k, _ in labels) else kind


def _physical_box(body, target):
    """A synthetic full-frame context is never physical bottle authority."""
    box = _checked(target.get('bottle_bbox'))
    if target.get('physical_bottle_localized') is not True or not box:
        return None, 'not_explicitly_localized'
    identities = {str(target[k]) for k in ('instance_id', 'parent_id') if target.get(k) is not None}
    for row in body.get('instances') or []:
        if (str(row.get('bottle_id')) in identities and _checked(row.get('bottle_bbox')) == box):
            return box, 'request.instances.bottle_id+bottle_bbox'
    for row in body.get('localization_trace') or []:
        if (str(row.get('parent_id')) in identities and _checked(row.get('bottle_bbox')) == box):
            return box, 'request.localization_trace.parent_id+bottle_bbox'
    return None, 'physical_flag_or_box_not_corroborated_by_request'


def _geometry(raw, body, sid):
    targets = body.get('targets') or []
    matches = [t for t in targets if str(t.get('instance_id')) == sid]
    target = matches[0] if len(matches) == 1 else None
    views = raw.get('views') or []
    sizes = {tuple(v['original_size']) for v in views if isinstance(v.get('original_size'), (list, tuple))
             and len(v['original_size']) == 2}
    size = list(next(iter(sizes))) if len(sizes) == 1 else None
    frame = _box([0, 0, *size]) if size else None
    label, kind = _label(views)
    physical, authority = _physical_box(body, target or {})
    context = _checked((target or {}).get('context_bbox'))
    # A physical flag with missing authority must not enable the unlocalized gate.
    unlocalized = bool(target is not None and target.get('physical_bottle_localized') is False
                       and target.get('bottle_bbox') is None)
    fullframe = bool(len(targets) == 1 and unlocalized and frame and context == frame and
                     label and kind != 'partial_label' and label != frame and _inside(label, frame))
    # The encoder explicitly records its angle in raw_visual. Native runtime
    # treats an omitted target rotation as zero. A conflicting/missing raw
    # angle cannot establish which axis separates neighboring bottles.
    angle = raw.get('rotation_ccw')
    target_angle = (target or {}).get('retrieval_pixel_rotation_ccw', 0)
    axis = None
    if (not isinstance(angle, bool) and angle in (0, 90, 180, 270) and
            not isinstance(target_angle, bool) and angle == target_angle):
        axis = 'x' if angle in (0, 180) else 'y'
    return dict(target=target, label=label, label_kind=kind, physical=physical,
                physical_authority=authority, frame=frame, context=context,
                fullframe_unlocalized=fullframe, target_count=len(targets),
                unassigned_cross_axis=axis, encoder_rotation_ccw=angle)


def _mapped(line, provenance, body, target, ordinal):
    """Return original polygon + transform trace, or an explicit unknown reason."""
    if not isinstance(provenance, dict):
        return None, {'reason': 'provenance_missing'}
    points = _polygon(line.get('polygon'))
    polygon_source = 'merged_observation'
    stage, path = provenance.get('stage'), provenance.get('path')
    block = _source_block(body, path) if isinstance(path, str) else None
    if points is None and stage != 'primary_packet_read' and block:
        rows = block.get('observations') or []
        source = rows[ordinal] if ordinal < len(rows) else None
        if (source and source.get('raw_text') == line.get('raw_text') and source.get('score') == line.get('score')):
            points = _polygon(source.get('polygon'))
            polygon_source = path + '.observations.' + str(ordinal)
    if points is None:
        return None, {'reason': 'polygon_missing_or_unresolved_source_block'}
    space = provenance.get('coordinate_space')
    if space == 'EXIF-oriented original pixels':
        return points, {'coordinate_space': space, 'polygon_source': polygon_source, 'rotation_ccw': 0}
    if space not in ('rotated_bottle_crop_pixels', 'instance_label_crop_pixels', 'label_crop_polygon_omitted'):
        return None, {'reason': 'unsupported_coordinate_space', 'coordinate_space': space}
    crop = _box(provenance.get('crop_bbox'))
    if crop is None:
        return None, {'reason': 'source_crop_missing'}
    # Pillow Image.crop rounds its four supplied edges. Primary checked_box
    # callers already supplied integers; supplemental callers may use floats.
    crop = [int(round(v)) for v in crop]
    if _box(crop) is None:
        return None, {'reason': 'source_crop_rounds_empty'}
    angle = provenance.get('rotation')
    angle_source = 'provenance.rotation'
    if angle is None and target is not None:
        recorded = target.get('retrieval_pixel_rotation_ccw', 0)
        if space == 'instance_label_crop_pixels' and stage == 'primary_packet_read':
            if recorded in (0, 90, 270):
                angle = recorded
                angle_source = 'request.target.retrieval_pixel_rotation_ccw / instance_text_profile'
        elif stage == 'sparse_alternative_read' and path == 'alternative_ocr' and recorded in (0, 90, 180, 270):
            angle = recorded
            angle_source = 'request.target.retrieval_pixel_rotation_ccw / sparse_alternative_ocr_v2'
    if isinstance(angle, bool) or angle not in (0, 90, 180, 270):
        return None, {'reason': 'rotation_unknown_or_unsupported', 'rotation': angle}
    width, height = crop[2] - crop[0], crop[3] - crop[1]
    rw, rh = (height, width) if angle in (90, 270) else (width, height)
    if any(not (0 <= x <= rw and 0 <= y <= rh) for x, y in points):
        return None, {'reason': 'polygon_outside_declared_crop'}
    mapped = []
    for x, y in points:
        x, y = ((width - y, x) if angle == 90 else (y, height - x) if angle == 270 else
                (width - x, height - y) if angle == 180 else (x, y))
        mapped.append([x + crop[0], y + crop[1]])
    return mapped, dict(coordinate_space=space, crop_bbox_pixels=crop, rotation_ccw=angle,
                        rotation_source=angle_source, polygon_source=polygon_source)


def transform(observations, provenance, raw_visual, request_body, instance_id):
    """Return ``(effective observations, effective provenance, ownership trace)``.

    Unknown/partial geometry keeps the line. The explicitly scoped unassigned
    full-frame case is the sole unknown class excluded from identity comparison;
    its text remains in the raw response and in the trace, never labelled foreign.
    """
    if len(observations) != len(provenance):
        raise ValueError('OCR/provenance lengths differ; ownership cannot realign them')
    body, raw, sid = request_body or {}, raw_visual or {}, str(instance_id)
    geometry = _geometry(raw, body, sid)
    label, physical, target = geometry['label'], geometry['physical'], geometry['target']
    ordinals, mapped_rows = Counter(), []
    for line, prov in zip(observations, provenance):
        key = ((prov or {}).get('stage'), (prov or {}).get('path'))
        ordinal = ordinals[key]
        ordinals[key] += 1
        points, mapping = _mapped(line, prov, body, target, ordinal)
        mapped_rows.append((points, mapping))
    anchor = bool(label and any(_inside(_envelope(points), label) and str(line.get('raw_text', '')).strip()
                                for line, (points, _) in zip(observations, mapped_rows)))
    other_labels = []
    for other in body.get('targets') or []:
        if str(other.get('instance_id')) == sid:
            continue
        # Two label/role targets of the same localized bottle are not foreign.
        if target is not None and target.get('parent_id') is not None and other.get('parent_id') == target.get('parent_id'):
            continue
        other_label, other_kind = _label((other.get('retrieval') or {}).get('views') or [])
        if other_label and other_kind != 'partial_label':
            other_labels.append((str(other.get('instance_id')), other_label))
    lines, kept, dropped = [], [], []
    for i, (line, prov, mapped) in enumerate(zip(observations, provenance, mapped_rows)):
        points, mapping = mapped
        envelope = _envelope(points)
        status, action, reason = 'unknown', 'retain', mapping.get('reason', 'no_label_owner')
        crop = _checked((prov or {}).get('crop_bbox'))
        source_bound = bool((prov or {}).get('crop_source') in LABEL_CROPS and _inside(crop, label))
        foreign = [owner for owner, box in other_labels if _inside(envelope, box)]
        if target is None or str(raw.get('instance_id')) != sid:
            reason = 'request_target_binding_missing_or_ambiguous'
        elif source_bound and points is None:
            status, reason = 'owned_source_crop', 'source_crop_inside_target_label_polygon_unavailable'
        elif envelope is None:
            reason = mapping.get('reason', 'polygon_has_no_area')
        elif geometry['frame'] and not _inside(envelope, geometry['frame']):
            reason = 'mapped_polygon_outside_request_frame'
        elif label and _inside(envelope, label) and not foreign:
            status, reason = 'owned_label', 'mapped_line_inside_target_label'
        elif physical and _inside(envelope, physical) and not foreign:
            status, reason = 'owned_bottle_context', 'mapped_line_inside_authoritative_physical_bottle'
        elif target.get('physical_bottle_localized') is True and physical is None and label and _disjoint(envelope, label):
            reason = 'physical_geometry_authority_unknown_preserved'
        elif foreign and label and _disjoint(envelope, label) and (not physical or _disjoint(envelope, physical)):
            if len(foreign) == 1:
                status, action, reason = 'foreign_label', 'exclude', 'mapped_line_has_one_other_request_label_owner'
            else:
                status, reason = 'ambiguous', 'mapped_line_has_multiple_other_label_owners'
        elif foreign or (label and not _disjoint(envelope, label)) or (physical and not _disjoint(envelope, physical)):
            status, reason = 'ambiguous', 'overlap_or_boundary_contact_preserved'
        elif (geometry['fullframe_unlocalized'] and anchor and label and _disjoint(envelope, label)
              and (prov or {}).get('crop_source') == 'bottle_context_crop' and crop == geometry['frame']
              and _cross_axis_disjoint(envelope, label, geometry['unassigned_cross_axis'])):
            status, action, reason = 'unassigned_fullframe_context', 'exclude', 'outside_only_localized_label_of_unlocalized_fullframe_request'
        elif geometry['fullframe_unlocalized'] and label and _disjoint(envelope, label):
            reason = 'same_bottle_long_axis_or_rotation_unknown_preserved'
        else:
            reason = 'outside_label_ownership_unknown_preserved'
        (kept if action == 'retain' else dropped).append(i)
        lines.append(dict(index=i, raw_text=line.get('raw_text'), native_score=line.get('score'),
                          polygon_original=points, original_polygon=deepcopy(line.get('polygon')),
                          provenance=deepcopy(prov), mapping=mapping, status=status, action=action,
                          reason=reason, other_label_owners=foreign))
    effective = [deepcopy(observations[i]) for i in kept]
    scoped_provenance = [deepcopy(provenance[i]) for i in kept]
    trace_geometry = {k: deepcopy(v) for k, v in geometry.items() if k != 'target'}
    trace_geometry['interior_text_anchor'] = anchor
    trace = dict(rule=deepcopy(RULE), instance_id=sid, applied=bool(dropped),
                 input_count=len(observations), output_count=len(effective), retained_indices=kept,
                 excluded_indices=dropped, counts=dict(Counter(row['status'] for row in lines)),
                 raw_digest=_digest(observations), effective_digest=_digest(effective),
                 geometry=trace_geometry, lines=lines, raw_packet_mutated=False,
                 interpretation='geometric identity-comparison scope, not GT or calibrated physical ownership')
    return effective, scoped_provenance, trace
