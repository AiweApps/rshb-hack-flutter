"""Original primary geometry and split object gate, with explicit native models.

This component retains original label grouping, ownership, ROI and duplicates.
Higher control/refinement wrappers and whole-request rescue remain separate work.
It does not publish a final wine card or claim full server-control equivalence.
"""
import ast
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import time
from types import SimpleNamespace

import numpy as np
from PIL import Image

from native_models import NativeBottleDetector, NativeLabelDetector, NativeEncoder, NativeReader


class _Ownership:
    """Wiring only; the original ownership function owns every decision."""
    def __init__(self, inner):
        self.inner, self.ownership_events = inner, []

    def __getattr__(self, name): return getattr(self.inner, name)

    def detect(self, image):
        from rshb_vine.label_region_ownership import resolve_label_ownership
        result, self.ownership_events = resolve_label_ownership(self.inner.detect(image))
        return result


class OriginalEarlyGeometry:
    def __init__(self, root, session, calls):
        from rshb_vine.bottle_label_localizer import BottleLabelLocalizer
        from rshb_vine.geometry_loop import GeometryLocalizer
        from rshb_vine.label_rescue import LabelRescue
        from rshb_vine.roi_selection import SelectingDetector
        from rshb_vine.b3_only_v1.split import RoleCounters
        from rshb_vine.preprocessing import checked_box
        from rshb_vine.visual_core import View
        root = Path(root)
        config = json.loads((root / 'live/early-geometry.json').read_text())
        bottles = NativeBottleDetector(calls)
        labels = NativeLabelDetector(calls, config['label_model_id'])
        previous = BottleLabelLocalizer(bottles, labels, config['bottle_model_id'],
            max_bottles=config['max_bottles'], merge_parent_labels=config['merge_parent_labels'])
        self.localizer = GeometryLocalizer(previous, config['mode'])
        rescue = LabelRescue(self.localizer, NativeLabelDetector(calls, config['rescue_model_id'], rescue=True))
        if rescue.model_id != config['rescue_localizer_id']:
            raise ValueError('Original geometry/localizer identity differs')
        self.owned = _Ownership(rescue)
        self.detector = SelectingDetector(self.owned)
        self.spec = session.gate
        self.coef = np.asarray(self.spec['coef'])
        self.bias = self.spec['intercept']
        self.gate_encoder = NativeEncoder(calls, arm='B0')
        self.gate_encoder_id = config['gate_encoder_id']
        self.gate_counters = RoleCounters()
        self.base = SimpleNamespace(encoder=NativeEncoder(calls, arm='E', head=session.head),
            index=session.index, encoder_id=session.eid)
        self.reader = NativeReader(calls)
        # The source's initial super-call is the caller's split gate above.
        # Retain the complete original orientation body after that one call.
        source = root / 'rshb_vine/oriented_geometry.py'
        tree = ast.parse(source.read_bytes())
        cls = next(n for n in tree.body if isinstance(n, ast.ClassDef) and n.name == 'OrientedGeometryPipeline')
        method = next(n for n in cls.body if isinstance(n, ast.FunctionDef) and n.name == 'recognize_image')
        if ast.unparse(method.body[0]) != 'result = super().recognize_image(image, roi)':
            raise ValueError('Original orientation boundary changed')
        body = deepcopy(method.body[1:])
        self.orientation_ast_sha256 = hashlib.sha256(ast.dump(ast.Module(body=body, type_ignores=[]), include_attributes=False).encode()).hexdigest()
        function = ast.FunctionDef(name='orient', args=ast.arguments(posonlyargs=[],
            args=[ast.arg(arg='self'), ast.arg(arg='image'), ast.arg(arg='result')],
            kwonlyargs=[], kw_defaults=[], defaults=[]), body=body, decorator_list=[])
        namespace = dict(time=time, Image=Image, View=View, checked_box=checked_box)
        exec(compile(ast.fix_missing_locations(ast.Module(body=[function], type_ignores=[])), str(source), 'exec'), namespace)
        self.orient = namespace['orient']
        self.calls = calls

    def recognize(self, image, roi=None):
        from rshb_vine.b3_only_v1.split import SplitWineObjectStage
        from rshb_vine.preprocessing import checked_box
        if roi is not None: roi = checked_box(roi, image.size)
        self.detector.roi = roi
        try:
            # Original ROI selects the detector parent before the split stage;
            # the historical centre filter is therefore explicitly not reused.
            result = SplitWineObjectStage.recognize_image(self, image, None)
            result['localization_trace'] = deepcopy(self.detector.last_trace)
            result = self.orient(self, image, result)
            result['roi_selection'] = deepcopy(self.detector.selection)
            result['label_ownership'] = deepcopy(self.owned.ownership_events)
            result['native_early_geometry'] = dict(original_primary_methods=True,
                orientation_AST_identical=True, orientation_ast_sha256=self.orientation_ast_sha256,
                remaining=['whole-request bottle rescue', 'instance/variant text and higher control wrappers'],
                full_server_control=False)
            return result
        finally:
            self.detector.roi = None
