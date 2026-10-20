"""Original category decision and public mapper, consuming real native B0 vectors.

Prepare returns exact PIL RGB384 inputs, never reused wine-gate embeddings.
Complete binds every vector to its source bytes, recipe and policy response.
No model construction, OCR, fitting, HTTP or neighbour re-selection occurs here.
"""
import ast
from copy import deepcopy
import gzip
import hashlib
import json
from pathlib import Path
import sys
from types import SimpleNamespace

import numpy as np


def sha(data):
    return hashlib.sha256(data).hexdigest()


def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':'), allow_nan=False).encode()


def read_json(path):
    path = Path(path)
    data = path.read_bytes()
    return json.loads(gzip.decompress(data) if path.suffix == '.gz' else data)


class CategoryPublication:
    def __init__(self, root):
        self.root = Path(root).resolve()
        self.manifest_bytes = (self.root / 'policy-manifest.json').read_bytes()
        self.manifest = json.loads(self.manifest_bytes)
        # This entry can be used without unpickling the wine selector. Validate
        # the complete package before importing the original frozen functions.
        for name, expected in self.manifest['files'].items():
            path = (self.root / name).resolve(strict=True)
            if not path.is_relative_to(self.root) or sha(path.read_bytes()) != expected:
                raise ValueError('Category/publication source differs: ' + name)
        from mobile_imports import InferenceImports
        self.import_guard = InferenceImports(self.root)
        sys.meta_path.insert(0, self.import_guard)
        from gpu.nonwine_context_gpu_v1.classifier import load_text_cache, FROZEN_SOURCES
        from rshb_vine.nonwine_local_v1.classifier import CATEGORIES
        config = json.loads((self.root / 'live/category.json').read_text())
        spec = config['text_cache']
        spec['path'] = str(self.root / 'live/category-text.json.gz')
        prompts = [(c, p) for c, items in CATEGORIES.items() for p in items]
        text, cache = load_text_cache(spec, prompts)
        self.scorer = SimpleNamespace(text=text, prompts=prompts,
                                      scale=cache['logit_scale'], bias=cache['logit_bias'])
        # Retain the exact original post-encoder function statements. Only the
        # externally executed vision part is excluded; no math is re-authored.
        source = self.root / 'rshb_vine/nonwine_local_v1/classifier.py'
        if sha(source.read_bytes()) != FROZEN_SOURCES['rshb_vine/nonwine_local_v1/classifier.py']:
            raise ValueError('Frozen category math source changed')
        tree = ast.parse(source.read_bytes())
        cls = next(n for n in tree.body if isinstance(n, ast.ClassDef) and n.name == 'BeverageClassifier')
        method = next(n for n in cls.body if isinstance(n, ast.FunctionDef) and n.name == 'classify')
        starts = [i for i, n in enumerate(method.body) if isinstance(n, ast.Assign) and
                  len(n.targets) == 1 and isinstance(n.targets[0], ast.Name) and n.targets[0].id == 'rows']
        if len(starts) != 1 or not isinstance(method.body[-1], ast.Return):
            raise ValueError('Frozen category postprocessing boundary differs')
        body = deepcopy(method.body[starts[0]:])
        function = ast.FunctionDef(name='score', args=ast.arguments(posonlyargs=[],
            args=[ast.arg(arg='self'), ast.arg(arg='vectors')], kwonlyargs=[], kw_defaults=[], defaults=[]),
            body=body, decorator_list=[])
        module = ast.fix_missing_locations(ast.Module(body=[function], type_ignores=[]))
        namespace = dict(np=np, CATEGORIES=CATEGORIES)
        exec(compile(module, str(source), 'exec'), namespace)
        self.score = namespace['score']
        self.math_ast_sha256 = sha(ast.dump(ast.Module(body=body, type_ignores=[]), include_attributes=False).encode())
        self.cards = json.loads((self.root / 'live/cards.json').read_text())
        self.profile = 'ondevice-experimental-v2:' + sha(self.manifest_bytes)

    def card(self, slug):
        return deepcopy(self.cards.get(slug)) if isinstance(slug, str) else None

    def prepare(self, response, data, directory, *, owner, binding=None, roi=None):
        from rshb_vine.preprocessing import decode
        from rshb_vine.target_contract_v2.contract import build
        from rshb_vine.nonwine_gpu_transfer_v1.contract import geometry_plan, SPACE
        from rshb_vine.nonwine_gpu_transfer_v1.transfer import prepare_views
        image, _ = decode(data)
        result = deepcopy(response)
        if 'view' in result or 'nonwine_context_gpu_v1' in result:
            raise ValueError('Category requires an unpublished/unfiltered raw response')
        if binding is None:
            result['target_contract'] = build(result, roi=roi)
            entries = list(result['target_contract']['bottles'])
            if result['target_contract'].get('roi_observation'):
                raise ValueError('An unlinked ROI needs an explicit source binding')
            binding = dict(coordinate_space=SPACE, oriented_size=list(image.size), entries=[])
            targets = {str(t['instance_id']): t for t in result.get('targets') or []}
            for entry in entries:
                sid = str(entry.get('roi_pass_instance_id') or entry['instance_id'])
                target = targets[sid]
                binding['entries'].append(dict(contract_instance_id=str(entry['instance_id']), role='bottle',
                    source=entry['card_source'], source_target_instance_id=sid,
                    bottle_bbox=target.get('bottle_bbox'), label_bbox=target.get('bbox')))
        plan = geometry_plan(result, binding)
        if len(plan['entries']) > 16:
            raise ValueError('Category physical roster exceeds request budget')
        result['target_contract']['profile_checksum'] = self.profile
        directory = Path(directory)
        directory.mkdir(exist_ok=False, parents=True)
        inputs = []
        for row, views in prepare_views(image, plan):
            for view in views:
                name = 'category-%02d.rgb' % len(inputs)
                rgb = view['image'].tobytes();view['image'].close()
                (directory / name).write_bytes(rgb)
                inputs.append(dict(file=name, instance_id=row['contract_instance_id'], role=row['role'],
                    kind=view['kind'], size=view['size'], rgb_sha256=view['rgb_sha256'],
                    recipe=view['recipe'], recipe_sha256=view['recipe_sha256']))
        image.close()
        state = dict(kind='native-category-prepared-v1', image_sha256=sha(data),
            policy_manifest_sha256=sha(self.manifest_bytes), native_assets_sha256=self.manifest['native_assets_sha256'],
            response=result, plan=plan, inputs=inputs, owner=owner, max_forwards=32,
            math_ast_sha256=self.math_ast_sha256)
        state['request_sha256'] = sha(canonical(state))
        (directory / 'prepared.json').write_bytes(canonical(state))
        return state

    def complete(self, prepared_path, packet, data):
        from rshb_vine.nonwine_context_v2.classifier import decide
        from rshb_vine.nonwine_gpu_safe_categories_v1.policy import project_verdicts
        from rshb_vine.nonwine_gpu_transfer_v1.transfer import apply_verdicts
        from wine_scanner.application import build_view
        from wine_scanner.contracts import inspect_image
        state = read_json(prepared_path)
        request_sha = state.pop('request_sha256')
        if sha(canonical(state)) != request_sha or sha(data) != state['image_sha256']:
            raise ValueError('Category request/source changed')
        if (state['kind'] != 'native-category-prepared-v1' or
                state['policy_manifest_sha256'] != sha(self.manifest_bytes) or
                state['math_ast_sha256'] != self.math_ast_sha256 or
                packet['kind'] != 'native-coreml-category-vectors-v1' or
                packet['request_sha256'] != request_sha or
                packet['native_assets_sha256'] != self.manifest['native_assets_sha256']):
            raise ValueError('Category model/policy ownership differs')
        if not isinstance(packet['vectors'], list) or len(packet['vectors']) != len(state['inputs']):
            raise ValueError('Category vector roster differs')
        crops = {(r['contract_instance_id'], r['role']): {} for r in state['plan']['entries']}
        for spec, observed in zip(state['inputs'], packet['vectors']):
            path = Path(prepared_path).parent / spec['file']
            if path.name != spec['file'] or sha(path.read_bytes()) != spec['rgb_sha256']:
                raise ValueError('Prepared RGB file changed')
            for key in ('file', 'instance_id', 'role', 'kind', 'rgb_sha256', 'recipe_sha256'):
                if observed[key] != spec[key]:
                    raise ValueError('Category feature/crop binding differs: ' + key)
            vector = np.asarray(observed['features'], dtype=np.float32)
            if vector.shape != (768,) or not np.isfinite(vector).all() or abs(float(np.linalg.norm(vector)) - 1) > 1e-4:
                raise ValueError('Expected finite normalized actual B0 feature vector')
            row = self.score(self.scorer, vector.astype('float64')[None, :])[0]
            crops[spec['instance_id'], spec['role']][spec['kind']] = row
        verdicts = {}
        for key, values in crops.items():
            reject, rule, reason = decide(values)
            verdicts[key] = dict(reject=reject, v1_rule=rule, reason=reason,
                bottle_context='bottle' in values, crops=values, calibrated=False)
        projected = project_verdicts(verdicts)
        result = apply_verdicts(state['response'], state['plan'], projected,
                               published_source_target_instance_id=state['owner'])
        view = build_view(result, self, inspect_image(data, 'native-photo.jpg'))
        return dict(kind='native-category-publication-result-v1', result=result, view=view,
            request_sha256=request_sha, input_image_sha256=sha(data),
            category_math_ast_sha256=self.math_ast_sha256, category_forwards=len(state['inputs']),
            original_category_decision=True, original_public_mapper=True,
            HTTP=0, fit=False, full_scanner_complete=False, early_pipeline_parity='pending')
