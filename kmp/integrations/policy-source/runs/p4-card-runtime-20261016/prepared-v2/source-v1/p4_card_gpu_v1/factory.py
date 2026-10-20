"""Source-sealed P4 over the exact db16/E4474 parent; one image graph only.

Module imports and source validation use stdlib only. Prediction imports belong
after parent.factory(), which owns E3/Linux provenance bootstrap. The original
parent recognizes and performs safe-category refusal/publication last. This
wrapper changes only release lineage after that call, never its cards or ranks.
"""
import gzip
import hashlib
import importlib
import importlib.util
import json
import os
from pathlib import Path, PurePosixPath
import time

PARENT = 'db16be1b09da6c4207991f7143e44d6bc77e0949e299e2ec5e5db224f0158466'
PARENT_SOURCE = 'bdcc07d1ab591b02e6cb5c43327a0e740216ea6bac237373b9f9410197f46d9e'
PARENT_FACTORY_SHA = '8651bbd64031689c43fa4b7720e4e33dd5e013d0ac8aafae20e960245701662b'
RESET_ACCESS_SHA = '4f5a440adb7b89bbec50c8b5b4a5b0a70913054eaf7d9e5195279813931d4b69'
KIND = 'wine-scanner-p4-card-gpu-v1'
SOURCE_KIND = 'wine-p4-card-gpu-source-v1'
NONWINE_POLICY = 'nonwine-gpu-safe-categories-v1'
OWN_FILES = frozenset('p4_card_gpu_v1/' + name for name in
                      ('__init__.py', '__main__.py', 'factory.py', 'installer.py'))
POLICY_FILES = frozenset('next_card_fixes_v1/' + name for name in
                         ('__init__.py', 'policy.py', 'compound_names.py'))
LOCAL_POLICY_SHA = {
    'next_card_fixes_v1/policy.py': '9ea97446e05635d2ba33b720e65b26a5dec03ec65478672dbf674277bdf04009',
    'next_card_fixes_v1/compound_names.py': 'cadebe5a51a932aef02aad33d22055968fd0911b3746762cf4768ce998ad6a47',
}
IMPORT_REPLACEMENTS = {
    'next_card_fixes_v1/policy.py': [
        ['from rshb_vine.recognition_text_fixes_v1.selection import TextFixSelection',
         'from recognition_text_fixes_v1.selection import TextFixSelection']],
    'next_card_fixes_v1/compound_names.py': [
        ['from rshb_vine.adagum_gunko_general_v1.policy import _entity_key, _rerun_identity',
         'from adagum_gunko_general_v1.policy import _entity_key, _rerun_identity'],
        ['from rshb_vine.recognition_text_fixes_v1.selection import TextFixSelection',
         'from recognition_text_fixes_v1.selection import TextFixSelection'],
        ['from rshb_vine.name_role_candidate_v1.policy import raw_commercial_name',
         'from name_role_candidate_v1.policy import raw_commercial_name']],
}
_guard = None


def required(name):
    value = os.environ.get(name)
    if not value:
        raise RuntimeError('Missing required ' + name)
    return value


def sha(path):
    value = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1 << 20), b''):
            value.update(block)
    return value.hexdigest()


def canonical(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True,
        separators=(',', ':'), allow_nan=False).encode()).hexdigest()


def check_read(path):
    global _guard
    if _guard is None:
        # File loading avoids importing rshb_vine before the parent E3 factory.
        guard_path = Path(required('WINE_SCANNER_CORE_ROOT')) / 'rshb_vine/evaluation/reset_access.py'
        if guard_path.is_symlink() or sha(guard_path) != RESET_ACCESS_SHA:
            raise RuntimeError('Exact frozen RESET reader guard required')
        spec = importlib.util.spec_from_file_location('_p4_reset_access', guard_path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        _guard = module.check_read
    _guard(Path(path))


def read(path):
    path = Path(path)
    check_read(path)
    data = path.read_bytes()
    return json.loads(gzip.decompress(data) if path.suffix == '.gz' else data)


def sealed(doc):
    if doc.get('checksum') != canonical({k: v for k, v in doc.items() if k != 'checksum'}):
        raise RuntimeError('Descriptor checksum differs')
    return doc


def bundle_file(root, name, item):
    rel = PurePosixPath(name)
    original = root / name
    path = original.resolve(strict=True)
    if (rel.is_absolute() or '..' in rel.parts or original.is_symlink() or
            not path.is_relative_to(root) or not path.is_file() or
            path.stat().st_size != item['bytes'] or sha(path) != item['sha256']):
        raise RuntimeError('Source byte/path changed: ' + name)
    return path


def verify_source():
    root = Path(required('WINE_P4_SOURCE_ROOT')).resolve(strict=True)
    if Path(__file__).resolve().parent != root / 'p4_card_gpu_v1':
        raise RuntimeError('P4 factory import escapes sealed source root')
    manifest_path = root / 'source-manifest.json'
    manifest_sha = required('WINE_P4_SOURCE_MANIFEST_SHA256')
    if sha(manifest_path) != manifest_sha:
        raise RuntimeError('P4 source manifest differs')
    manifest = read(manifest_path)
    if manifest.get('kind') != SOURCE_KIND:
        raise RuntimeError('P4 source manifest kind differs')
    files = manifest['files']
    if (not OWN_FILES | POLICY_FILES <= set(files) or
            not {'p4_source_attributes_v1/__init__.py'} <= set(files) or
            any(not name.endswith('.py') or name.split('/')[0] not in
                ('p4_card_gpu_v1', 'next_card_fixes_v1', 'p4_source_attributes_v1') for name in files)):
        raise RuntimeError('P4 runtime source closure differs')
    evidence = manifest.get('evidence_files', {})
    if set(files) & set(evidence):
        raise RuntimeError('P4 evidence overlaps runtime sources')
    for name, item in {**files, **evidence}.items():
        bundle_file(root, name, item)
    entries = list(root.rglob('*'))
    if (any(path.is_symlink() for path in entries) or
            {path.relative_to(root).as_posix() for path in entries
             if path.is_file() and '__pycache__' not in path.parts} !=
            set(files) | set(evidence) | {'source-manifest.json'}):
        raise RuntimeError('P4 bundle has extra/missing files')
    adapters = manifest['deployment_adapters']
    if set(adapters) != set(IMPORT_REPLACEMENTS):
        raise RuntimeError('Only declared P4 import adapters are allowed')
    for name, replacements in IMPORT_REPLACEMENTS.items():
        adapter = adapters[name]
        if adapter['original_sha256'] != LOCAL_POLICY_SHA[name] or adapter['replacements'] != replacements:
            raise RuntimeError('Frozen P4 policy/import transformation differs')
        data = (root / name).read_bytes()
        for before, after in reversed(replacements):
            if data.count(after.encode()) != 1:
                raise RuntimeError('P4 import adapter inverse is ambiguous')
            data = data.replace(after.encode(), before.encode(), 1)
        if hashlib.sha256(data).hexdigest() != LOCAL_POLICY_SHA[name]:
            raise RuntimeError('P4 policy contains changes beyond exact import adapters')
    contract = manifest['parent_contract']
    parent = sealed(contract['descriptor'])
    if (contract['profile_checksum'] != PARENT or parent['checksum'] != PARENT or
            contract['source_manifest_sha256'] != PARENT_SOURCE or
            parent.get('kind') != 'wine-scanner-name-role-gpu-site-catalog-v1' or
            parent.get('site_catalog_gallery_rows') != 4474 or
            contract['factory_module'] != 'site_catalog_name_role_gpu_v1.factory' or
            contract['factory_name'] != 'factory' or
            contract['source_files'].get(contract['factory_file']) != PARENT_FACTORY_SHA or
            contract['source_files'].get(contract['source_manifest_path']) != PARENT_SOURCE or
            required('WINE_SCNR_SOURCE_MANIFEST_SHA256') != PARENT_SOURCE or
            required('WINE_SCNR_OVERLAY_ROOT') != contract['core_root']):
        raise RuntimeError('Exact released db16/sourcebdcc/E4474 parent required')
    if set(contract['rules']) != {'specific_style_color', 'complete_name_compound', 'source_verified_sugar'}:
        raise RuntimeError('P4 must contain all three reviewed rules')
    for name, expected in contract['source_files'].items():
        if sha(name) != expected:
            raise RuntimeError('Frozen parent source changed: ' + name)
    parent_source = read(contract['source_manifest_path'])
    if parent_source.get('expected_profile_checksum') != PARENT:
        raise RuntimeError('Parent source does not bind the released descriptor')
    for name, item in parent_source['files'].items():
        bundle_file(Path(contract['source_manifest_path']).parent, name, item)
    spec = importlib.util.find_spec(contract['factory_module'])
    if spec is None or spec.origin is None or Path(spec.origin).resolve() != Path(contract['factory_file']).resolve():
        raise RuntimeError('Parent factory import resolves outside released source')
    for package in ('next_card_fixes_v1', 'p4_source_attributes_v1'):
        spec = importlib.util.find_spec(package)
        if spec is None or spec.origin is None or Path(spec.origin).resolve() != root / package / '__init__.py':
            raise RuntimeError('P4 policy/API import escapes sealed bundle: ' + package)
    # Source-Sol API is stdlib-only; it validates exact source/ledger/4474
    # bindings here, before the parent is allowed to load its first model.
    from p4_source_attributes_v1 import validate_sources
    attributes = contract['source_attributes']
    attribute_receipt = validate_sources(root, attributes,
        expected_config_sha256=attributes['config_sha256'])
    source = dict(root=str(root), manifest_sha256=manifest_sha, parent_profile_checksum=PARENT,
        parent_source_manifest_sha256=PARENT_SOURCE, source_attributes=attribute_receipt)
    return root, manifest, source


def descriptor_for(parent, source, contract):
    if sealed(parent) != contract['descriptor'] or parent['checksum'] != PARENT:
        raise RuntimeError('P4 descriptor parent differs')
    value = {k: v for k, v in parent.items() if k != 'checksum'}
    value.update(kind=KIND, parent_profile_checksum=PARENT,
        p4_parent_source_manifest_sha256=PARENT_SOURCE,
        p4_source_manifest_sha256=source['manifest_sha256'],
        p4_parent_selection_fingerprint=contract['selection_fingerprint'],
        p4_rules=contract['rules'], effective_stage_order=contract['effective_stage_order'],
        p4_source_attribute_config_sha256=contract['source_attributes']['config_sha256'],
        validation='source_sealed_three_P4_rules_pending_current_runtime_HTTP_and_rollback')
    value['checksum'] = canonical(value)
    if value['checksum'] == PARENT:
        raise RuntimeError('P4 release identity did not distinguish its parent')
    return value


def model_free(action):
    root, manifest, source = verify_source()
    module = importlib.import_module(manifest['parent_contract']['factory_module'])
    parent = module.model_free(action)
    if parent.get('models_loaded') is not False or parent.get('status') != 'MODEL_FREE_READY':
        raise RuntimeError('Actual db16 model-free parent preflight failed')
    descriptor = descriptor_for(manifest['parent_contract']['descriptor'], source, manifest['parent_contract'])
    if descriptor['checksum'] != required('WINE_P4_EXPECTED_PROFILE_SHA256'):
        raise RuntimeError('P4 prospective profile differs')
    return dict(status='MODEL_FREE_READY', descriptor=descriptor, source=source,
        parent=parent, models_loaded=False, additional_image_models=0)


def factory():
    root, manifest, source = verify_source()
    contract = manifest['parent_contract']
    descriptor = descriptor_for(contract['descriptor'], source, contract)
    if descriptor['checksum'] != required('WINE_P4_EXPECTED_PROFILE_SHA256'):
        raise RuntimeError('P4 reviewed descriptor differs before model loading')
    started = time.monotonic()
    module = importlib.import_module(contract['factory_module'])
    parent, parent_app, parent_receipt = module.factory()
    if (parent.descriptor != contract['descriptor'] or parent.profile['checksum'] != PARENT or
            Path(parent.root).resolve() != Path(contract['core_root']).resolve()):
        raise RuntimeError('Loaded graph is not the exact released db16 parent')
    # No rshb prediction imports precede the parent's own bootstrap.
    from .installer import install
    import threading
    selector, style, compound, checks, clear, clean = install(parent.graph, root, contract)
    if (checks['specific_style_color_rule'] != contract['rules']['specific_style_color'] or
            checks['complete_name_compound_rule'] != contract['rules']['complete_name_compound']):
        raise RuntimeError('Loaded P4 rules differ from reviewed source identity')
    startup_seconds = time.monotonic() - started

    class Pipeline:
        def __init__(self):
            self.root, self.graph, self.parent = parent.root, parent.graph, parent
            self.descriptor = self.profile = descriptor
            self.manifest = dict(checksum=descriptor['checksum'],
                runtime_descriptor_checksum=descriptor['checksum'], parent_runtime=PARENT)
            self.lock = threading.Lock()

        def __getattr__(self, name):
            return getattr(parent, name)

        def recognize(self, data, roi=None, bottles='addressed'):
            if not self.lock.acquire(blocking=False):
                from nonwine_gpu_production_v1.factory import InferenceBusy
                raise InferenceBusy('Inference busy')
            try:
                if not clean():
                    raise RuntimeError('P4 request scope was not clean at admission')
                try:
                    result = parent.recognize(data, roi, bottles)
                    if result.get('decision') == 'invalid_image':
                        return result
                    nonwine = result.get('nonwine_gpu_production_v1') or {}
                    site = result.get('site_catalog_name_role_gpu_v1') or {}
                    if (nonwine.get('policy') != NONWINE_POLICY or
                            nonwine.get('status') not in ('applied', 'kept_parent') or
                            (nonwine['status'] == 'applied' and nonwine.get('publication_status') != 'projected') or
                            site.get('profile_checksum') != PARENT or site.get('gallery_rows') != 4474 or
                            site.get('source_manifest_sha256') != PARENT_SOURCE):
                        raise RuntimeError('Final db16/ERR20 publication was bypassed')
                    # Raw refused-target diagnostics are preserved by the parent.
                    # Never compare their roster to active SKU targets or republish them.
                    records = (result.get('systemic_ranking_v2') or {}).get('targets') or []
                    if records and not compound.audit:
                        raise RuntimeError('P4 evaluate stage was bypassed by native ranker')
                    for key in ('target_contract', 'catalog_refresh_v1'):
                        block = result.get(key)
                        if isinstance(block, dict):
                            if block.get('profile_checksum') != PARENT:
                                raise RuntimeError('Parent final public profile changed')
                            block.update(p4_parent_profile_checksum=PARENT,
                                profile_checksum=descriptor['checksum'], runtime_checksum=descriptor['checksum'])
                    core = result['wine_scanner_core']
                    if core.get('composite_descriptor_checksum') != PARENT:
                        raise RuntimeError('Parent core identity changed')
                    core['composite_descriptor_checksum'] = descriptor['checksum']
                    result['p4_card_gpu_v1'] = dict(profile_checksum=descriptor['checksum'],
                        parent_profile_checksum=PARENT, source=source, gallery_rows=4474,
                        stage_order=checks['effective_stage_order'],
                        rule_call_count=len(compound.audit), style_scope_count=len(style.audit),
                        source_attributes=checks['source_attributes'],
                        nonwine_policy_preserved=NONWINE_POLICY, image_models_added=0,
                        OCR_unchanged=True, calibrated=False)
                    return result
                finally:
                    clear()
                    if not clean():
                        raise RuntimeError('P4 request/lexicon/guard state survived publication or failure')
            finally:
                self.lock.release()

        def status(self):
            return dict(descriptor=descriptor, parent=parent.status(), source=source,
                graph_checks=checks, request_scope_clear=clean(), gallery_rows=4474,
                parent_factory_calls=1, additional_image_models=0,
                startup_seconds=startup_seconds)

    pipeline = Pipeline()

    def app_factory(p):
        app = parent_app(p)
        routes = [r for r in app.router.routes if getattr(r, 'path', None) == '/health/ready']
        if len(routes) != 1:
            raise RuntimeError('Actual db16 category readiness producer is ambiguous')
        parent_ready = routes[0].endpoint
        app.router.routes.remove(routes[0])

        @app.get('/health/ready')
        def ready():
            value = parent_ready()
            if (not isinstance(value, dict) or value.get('runtime_descriptor_checksum') != PARENT or
                    value.get('policy') != NONWINE_POLICY):
                raise RuntimeError('Actual db16 category readiness contract changed')
            return dict(value, snapshot=descriptor['checksum'],
                runtime_descriptor_checksum=descriptor['checksum'], parent_runtime=PARENT,
                p4_parent_ready_runtime=value.get('parent_runtime'))

        return app

    return pipeline, app_factory, dict(descriptor=descriptor, source=source, parent=parent_receipt,
        graph_checks=checks, parent_factory_calls=1, additional_image_models=0)
