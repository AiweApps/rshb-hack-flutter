"""Bind one printed sugar fact to every live db16 consumer, without changing raw claims.

``validate_sources`` is a source-only preflight. ``install_graph`` must run
after the exact parent factory and before the first image request. Neither
function performs inference, OCR, catalogue search, or fit.
"""

from collections import Counter, defaultdict
from collections.abc import Mapping
from copy import copy, deepcopy
import gzip
import hashlib
import importlib.util
import json
import os
from pathlib import Path


PACKAGE_CONTRACT = Path(__file__).with_name('contract.json')
KIND = 'p4-source-verified-sugar-current4474-v1'
UNKNOWN = {'status': 'unknown', 'unknown': True, 'values': [], 'claims': []}
RESET_GUARD_SHA256 = '4f5a440adb7b89bbec50c8b5b4a5b0a70913054eaf7d9e5195279813931d4b69'
_RESET_GUARD = None


def _check_read(path):
    """Load the exact existing RESET guard without importing rshb_vine first."""
    global _RESET_GUARD
    if _RESET_GUARD is None:
        core = os.environ.get('WINE_SCANNER_CORE_ROOT')
        if core:
            root = Path(core).resolve(strict=True)
        else:
            # The only local fallback is this repository's package location.
            root = Path(__file__).resolve().parents[2]
            if not (root / 'AGENTS.md').is_file():
                raise ValueError('Exact core root is required before parent import')
        guard_path = root / 'rshb_vine/evaluation/reset_access.py'
        if not guard_path.is_file() or hashlib.sha256(guard_path.read_bytes()).hexdigest() != RESET_GUARD_SHA256:
            raise ValueError('Exact RESET source-read guard changed')
        spec = importlib.util.spec_from_file_location('p4_exact_reset_access', guard_path)
        if spec is None or spec.loader is None:
            raise ValueError('Exact RESET guard cannot be loaded')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        _RESET_GUARD = module.check_read
    _RESET_GUARD(path)


def _unique(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError('Duplicate source JSON key: ' + key)
        result[key] = value
    return result


def _digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True,
                                     separators=(',', ':'), allow_nan=False).encode()).hexdigest()


def _source(root, relative):
    if not isinstance(relative, str) or not relative or Path(relative).is_absolute():
        raise ValueError('Expected source path relative to pinned root')
    original = root / relative
    path = original.resolve(strict=True)
    if original.is_symlink() or not path.is_relative_to(root) or not path.is_file():
        raise ValueError('Source escapes pinned root: ' + relative)
    _check_read(path)
    return path


def _bytes(path, expected):
    _check_read(path)
    data = path.read_bytes()
    if hashlib.sha256(data).hexdigest() != expected:
        raise ValueError('Source SHA changed: ' + str(path))
    return data


def _json_bytes(data, name):
    try:
        if name.endswith('.gz'):
            data = gzip.decompress(data)
        return json.loads(data, object_pairs_hook=_unique)
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ValueError('Invalid pinned source JSON: ' + name) from exc


def _sealed(value, name):
    if not isinstance(value, dict) or value.get('checksum') != _digest(
            {key: item for key, item in value.items() if key != 'checksum'}):
        raise ValueError('Pinned document checksum differs: ' + name)
    return value


def _rows(data, name):
    rows = [_json_bytes(line, name) for line in data.splitlines() if line.strip()]
    by_slug = {row['slug']: row for row in rows}
    if len(rows) != len(by_slug):
        raise ValueError('Duplicate source catalogue slug: ' + name)
    return by_slug


class FrozenSugarView(Mapping):
    """One immutable map; returned fact objects are detached from the map."""

    def __init__(self, entries, *, source_sha256, added_slug, registry_checksums):
        self._items = {slug: json.dumps(fact, ensure_ascii=False, sort_keys=True,
                                       separators=(',', ':'), allow_nan=False)
                       for slug, fact in entries.items()}
        self.source_sha256 = source_sha256
        self.added_slug = added_slug
        self.registry_checksums = tuple(registry_checksums)

    def __getitem__(self, slug):
        return json.loads(self._items[slug])

    def __iter__(self):
        return iter(self._items)

    def __len__(self):
        return len(self._items)

    def describe(self):
        return {'kind': 'immutable-source-verified-sugar-view-p4-v1',
                'source_contract_sha256': self.source_sha256,
                'old_entries': len(self) - 1, 'entries': len(self),
                'added_source_fact_count': 1,
                'registry_checksums': list(self.registry_checksums)}


def _contract_path(root, contract, config_path):
    chosen = config_path if config_path is not None else contract.get('config_path')
    if chosen is None:
        path = PACKAGE_CONTRACT.resolve(strict=True)
        _check_read(path)
        return path
    return _source(root, chosen)


def validate_sources(source_root, contract, *, expected_config_sha256=None,
                     config_path=None):
    """Check the exact old fact against db16 sources with only source bytes.

    ``contract`` is the wrapper's already checked parent binding. It must
    contain the active profile and its source-manifest checksum, not a guessed
    card slug or a selector result. The function does not construct a model.
    """
    root = Path(source_root).resolve(strict=True)
    if not root.is_dir() or not isinstance(contract, Mapping):
        raise ValueError('A pinned source root and parent contract are required')
    profile = contract.get('profile_checksum') or contract.get('parent_profile_checksum')
    source_manifest_sha = (contract.get('source_manifest_sha256') or
                           contract.get('parent_source_manifest_sha256'))
    path = _contract_path(root, contract, config_path)
    data = path.read_bytes()
    contract_sha = hashlib.sha256(data).hexdigest()
    demanded = expected_config_sha256 or contract.get('config_sha256')
    if demanded is None or demanded != contract_sha:
        raise ValueError('P4 source contract SHA is not pinned by wrapper')
    config = _json_bytes(data, path.name)
    if (config.get('kind') != KIND or
            config.get('admission') != 'candidate_source_only_no_fit_no_released_runtime_mutation' or
            profile != config.get('parent_profile_checksum') or
            source_manifest_sha != config.get('parent_source_manifest_sha256') or
            len(config.get('fact', {})) < 5):
        raise ValueError('P4 source contract or actual parent differs')
    refs = config['source_refs']
    required = {'site_source_manifest', 'site_descriptor', 'site_E_descriptor',
                'site_catalog', 'site_gallery', 'prior_gallery', 'prior_catalog',
                'old_candidate_config', 'old_bundle', 'old_claims', 'old_ledger',
                'source_decision', 'source_photo'}
    if set(refs) != required or any(set(item) != {'path', 'sha256'} for item in refs.values()):
        raise ValueError('P4 source closure differs')
    sources = {name: _bytes(_source(root, item['path']), item['sha256'])
               for name, item in refs.items()}
    documents = {name: _json_bytes(sources[name], refs[name]['path']) for name in
                 required - {'site_catalog', 'prior_catalog', 'source_photo'}}
    manifest = documents['site_source_manifest']
    if (manifest['expected_profile_checksum'] != profile or
            manifest['E_install_view']['gallery_sha256'] != refs['site_gallery']['sha256'] or
            manifest['candidate_descriptor'] != refs['site_descriptor'] or
            manifest['E_descriptor'] != refs['site_E_descriptor']):
        raise ValueError('Actual db16 factory source manifest differs')
    descriptor = _sealed(documents['site_descriptor'], 'site descriptor')
    if (descriptor['catalog'] != refs['site_catalog']['path'] or
            descriptor['pins_sha256'].get(descriptor['catalog']) != refs['site_catalog']['sha256'] or
            len(descriptor['added_slugs']) != config['gallery']['new_slugs']):
        raise ValueError('Source-admitted 80-card catalogue descriptor differs')
    old = documents['old_candidate_config']
    fact = config['fact']
    if (old['kind'] != 'source-verified-attributes-v1' or
            old['records'] != [fact] or fact['role'] != 'sugar' or
            fact['value'] != 'dry' or fact['status'] != 'source_verified' or
            fact['original_claim'] != UNKNOWN or
            fact['source_decision'] != refs['source_decision'] | {'decision': fact['source_decision']['decision']} or
            fact['reference']['sha256'] != refs['source_photo']['sha256'] or
            fact['reference']['path'] != refs['source_photo']['path']):
        raise ValueError('Old exact source decision or unknown claim differs')
    decision = documents['source_decision']
    reference = fact['reference']
    if (decision.get('decision') != fact['source_decision']['decision'] or
            decision['reference']['source_sha256'] != reference['sha256'] or
            decision['reference']['current_gallery_indices'] != reference['gallery_indices'] or
            decision['reference']['printed_attribute_text'] != reference['printed_text'] or
            decision['reference']['observed_year_literal'] != reference['printed_year'] or
            decision['reference']['front_name_lines'] != reference['printed_grapes'] or
            decision['typed_attribute']['role'] != 'sugar' or
            decision['typed_attribute']['value'] != 'dry'):
        raise ValueError('Pinned printed-source decision differs')
    ledger = _sealed(documents['old_ledger'], 'old ledger')['records']
    if (len(ledger) != config['old_ledger_count'] or
            config['old_ledger_count'] != 349 or fact['card_slug'] in ledger or
            any(row.get('verified') is not True for row in ledger.values())):
        raise ValueError('Old 349 verified facts differ')
    bundle = _sealed(documents['old_bundle'], 'old bundle')
    claim_doc = _sealed(documents['old_claims'], 'old claims')
    if bundle['claims']['sha256'] != refs['old_claims']['sha256']:
        raise ValueError('Original claim source differs from pinned product bundle')
    profiles = {row['slug']: row for row in claim_doc['records']}
    slug = fact['card_slug']
    original = profiles[slug]
    if (original['product_id'] != fact['product_id'] or
            original['roles']['sugar'] != {**UNKNOWN, 'comparison_allowed': True}):
        raise ValueError('ProductID/unknown original claim differs')
    prior = _rows(sources['prior_catalog'], refs['prior_catalog']['path'])
    current = _rows(sources['site_catalog'], refs['site_catalog']['path'])
    if (len(prior) != 2186 or len(current) != config['identity']['catalog_rows'] or
            len(current) != 2266 or current[slug] != prior[slug] or
            set(current) != set(prior) | set(descriptor['added_slugs']) or
            current[slug].get('selected_sha256') != reference['sha256']):
        raise ValueError('Current catalogue lost old Mezyb binding or 80-card roster')
    prior_gallery = _sealed(documents['prior_gallery'], '4314 gallery')
    gallery = _sealed(documents['site_gallery'], '4474 gallery')
    rows, previous = gallery['references'], prior_gallery['references']
    scope = config['gallery']
    if (len(previous) != scope['parent_rows'] or len(rows) != scope['total_rows'] or
            scope != {'parent_rows': 4314, 'new_rows': 160, 'new_slugs': 80,
                      'total_rows': 4474, 'mezyb_indices': [3004, 3005],
                      'mezyb_kinds': ['context', 'front_label']} or
            rows[:4314] != previous or
            set(row['slug'] for row in rows[4314:]) != set(descriptor['added_slugs']) or
            Counter((row['slug'], row['kind']) for row in rows[4314:]) !=
            Counter((slug, kind) for slug in descriptor['added_slugs']
                    for kind in ('context', 'front_label'))):
        raise ValueError('Current E gallery lost old 4314 or new 80x2 views')
    for index, kind in zip(reference['gallery_indices'], reference['gallery_kinds']):
        if (rows[index]['slug'], rows[index]['image_sha256'], rows[index]['kind']) != (
                slug, reference['sha256'], kind):
            raise ValueError('Exact printed Mezyb source is not G3004/G3005')
    if (reference['gallery_indices'], reference['gallery_kinds']) != ([3004, 3005],
                                                                         ['context', 'front_label']):
        raise ValueError('Mezyb gallery target indices differ')
    return {'kind': KIND, 'status': 'SOURCE_ONLY_PASS',
            'parent_profile_checksum': profile,
            'source_manifest_sha256': source_manifest_sha,
            'config_sha256': contract_sha,
            'selector_registry_checksum': config['identity']['selector_registry_checksum'],
            'selector_claims_checksum': config['identity']['selector_claims_checksum'],
            'public_registry_checksum': config['identity']['public_registry_checksum'],
            'public_claims_checksum': config['identity']['public_claims_checksum'],
            'catalog_cards': len(current), 'gallery_rows': len(rows),
            'gallery_prefix_rows': len(previous), 'added_card_count': len(descriptor['added_slugs']),
            'added_view_count': len(rows)-len(previous),
            'source_pins_sha256': {item['path']: item['sha256'] for item in refs.values()},
            'fact_id': fact['id'], 'fact_product_id': fact['product_id'],
            'old_ledger_count': len(ledger), 'merged_view_count': len(ledger)+1,
            'models_loaded': False, 'NN': 0, 'OCR': 0, 'HTTP': 0, 'fit': 0}


def _view(root, config, registry, config_sha256):
    """Construct one detached view only after live source/registry proof."""
    ledger_ref = config['source_refs']['old_ledger']
    ledger = _sealed(_json_bytes(_bytes(_source(root, ledger_ref['path']),
                                        ledger_ref['sha256']), ledger_ref['path']), 'old ledger')['records']
    fact = config['fact']
    slug = fact['card_slug']
    if (registry.checksum != config['identity']['selector_registry_checksum'] or
            registry.claims_checksum != config['identity']['selector_claims_checksum'] or
            registry.product_id(slug) != fact['product_id'] or
            registry.cards[slug]['binding_status'] != 'bootstrap_not_verified_product' or
            registry.claims[slug]['roles']['sugar'] != {**UNKNOWN, 'comparison_allowed': True}):
        raise ValueError('Live selector registry lost exact unknown source/card binding')
    merged = deepcopy(ledger)
    merged[slug] = {'verified': True, 'value': fact['value'],
                    'source_status': 'source_verified', 'source_verified': True,
                    'source': {'kind': 'exact_reference_print',
                               'reference_image_sha256': fact['reference']['sha256'],
                               'gallery_indices': list(fact['reference']['gallery_indices']),
                               'decision_path': fact['source_decision']['path'],
                               'decision_sha256': fact['source_decision']['sha256'],
                               'overlay_record_id': fact['id']},
                    'claims': [{'value': fact['value'], 'status': 'source_verified',
                                'source': {'kind': 'exact_reference_print',
                                           'image_sha256': fact['reference']['sha256']}}]}
    if len(merged) != config['view_count'] or any(merged[old] != entry for old, entry in ledger.items()):
        raise ValueError('Merged sugar view changed a frozen ledger entry')
    return FrozenSugarView(merged, source_sha256=config_sha256, added_slug=slug,
                           registry_checksums=(registry.checksum, registry.claims_checksum))


def _owners(graph):
    """Walk actual owned graph and explicit top-level selector children."""
    from rshb_vine.reference_additions_v1.component import holders

    selector = graph.selection
    roots = [('graph', graph), ('selector.inner', selector.inner),
             ('selector.index', selector.index),
             ('selector.legacy.resolver', selector.legacy.resolver)]
    kinds = ('SystemicSelection', 'SelectionContext', 'ExistingEvidenceResolution',
             'ProductEvidenceResolution', 'SugarEvidence', 'CatalogSugarEvidence',
             'CatalogueIndex', 'ProductRegistry', 'LabelFirstIndex')
    grouped = {kind: {} for kind in kinds}
    for root_name, root in roots:
        for kind, entries in holders(root, kinds).items():
            for obj, path in entries:
                row = grouped[kind].setdefault(id(obj), {'object': obj, 'paths': []})
                row['paths'].append(root_name + ':' + path)
    return grouped


def _guard_roster(resolvers):
    from rshb_vine.label_specialist_consensus import VariantGuard

    found = {}
    for resolver in resolvers:
        guard = getattr(resolver, 'guard', None)
        if guard is None:
            raise ValueError('Actual resolver lacks the old raw-fields guard')
        wrappers = []
        while type(guard).__name__ == 'EffectiveColorGuard':
            wrappers.append(f'{type(guard).__module__}.{type(guard).__name__}')
            guard = guard.original
        if not isinstance(guard, VariantGuard) or not isinstance(guard.fields, dict):
            raise ValueError('Actual source guard is not the pinned raw VariantGuard')
        found[id(guard)] = {'class': f'{type(guard).__module__}.{type(guard).__name__}',
                            'fields_sha256': _digest(guard.fields),
                            'field_count': len(guard.fields), 'wrappers': wrappers}
    if not found or any(value['field_count'] < 2266 for value in found.values()):
        raise ValueError('Full runtime source guard or card roster is missing')
    return sorted(found.values(), key=lambda row: (row['class'], row['fields_sha256']))


def install_graph(graph, source_root, *, expected_config_sha256, config_path=None):
    """Install after the db16 parent factory, before request admission.

    Every live consumer gets the same immutable view. A missing required owner
    aborts startup. This is the full runtime path, never selector-only replay.
    """
    from rshb_vine.learned_selection_resolution import ExistingEvidenceResolution
    from rshb_vine.sugar_evidence_challenger import SugarEvidence
    from rshb_vine.system_selection_v4.context import SelectionContext

    root = Path(source_root).resolve(strict=True)
    path = _contract_path(root, {}, config_path)
    config = _json_bytes(_bytes(path, expected_config_sha256), path.name)
    parent = {'profile_checksum': config['parent_profile_checksum'],
              'source_manifest_sha256': config['parent_source_manifest_sha256'],
              'config_sha256': expected_config_sha256}
    source_receipt = validate_sources(root, parent,
                                      expected_config_sha256=expected_config_sha256,
                                      config_path=config_path)
    owners = _owners(graph)
    systemic = list(owners['SystemicSelection'].values())
    if len(systemic) != 1 or systemic[0]['object'] is not graph.selection.inner:
        raise ValueError('Current full graph has no unique live SystemicSelection')
    selector_registry = graph.selection.inner.registry
    public_registry = graph.selection.inner.identity
    identity = config['identity']
    if ((selector_registry.checksum, selector_registry.claims_checksum,
         public_registry.checksum, public_registry.claims_checksum) !=
        (identity['selector_registry_checksum'], identity['selector_claims_checksum'],
         identity['public_registry_checksum'], identity['public_claims_checksum'])):
        raise ValueError('Current E4474 selector/public ProductRegistry changed')
    registries = [row['object'] for row in owners['ProductRegistry'].values()]
    expected_kinds = {identity['selector_registry_checksum'], identity['public_registry_checksum']}
    if (len(registries) < 3 or {registry.checksum for registry in registries} != expected_kinds or
            selector_registry not in registries or public_registry not in registries):
        raise ValueError('Full current identity registry roster incomplete')
    fact = config['fact']
    slug = fact['card_slug']
    for registry in registries:
        if (len(registry.cards) != identity['registry_cards'] or
                registry.product_id(slug) != fact['product_id'] or
                registry.cards[slug]['binding_status'] != 'bootstrap_not_verified_product' or
                registry.claims[slug]['roles']['sugar'] != {**UNKNOWN, 'comparison_allowed': True} or
                not set(config['fact']['reference']['gallery_indices']) <= {3004, 3005}):
            raise ValueError('Live registry lost Mezyb/80-card source binding')
    raws = list(owners['LabelFirstIndex'].values())
    if len(raws) != 1 or len(raws[0]['object'].references) != 4474:
        raise ValueError('Actual E4474 visual source is absent or duplicated')
    for index, kind in zip(fact['reference']['gallery_indices'], fact['reference']['gallery_kinds']):
        row = raws[0]['object'].references[index]
        if (row['slug'], row['kind'], row['image_sha256']) != (slug, kind, fact['reference']['sha256']):
            raise ValueError('Actual E reference at G3004/G3005 differs')
    contexts = [row['object'] for row in owners['SelectionContext'].values()]
    resolvers = ([row['object'] for row in owners['ExistingEvidenceResolution'].values()] +
                 [row['object'] for row in owners['ProductEvidenceResolution'].values()])
    early = ([row['object'] for row in owners['SugarEvidence'].values()] +
             [row['object'] for row in owners['CatalogSugarEvidence'].values()])
    indices = [row['object'] for row in owners['CatalogueIndex'].values()]
    # The released GPU core does not construct or ship CatalogueIndex. If a
    # future graph actually owns one, require its exact native implementation;
    # never fabricate a verifier or silently skip a live consumer.
    if indices:
        from rshb_vine.typed_verification_probe_v1.verifier import CatalogueIndex
        if any(not isinstance(value, CatalogueIndex) for value in indices):
            raise ValueError('Active CatalogueIndex has an unknown implementation')
    if (not contexts or len(resolvers) < 2 or len(owners['CatalogSugarEvidence']) != 1 or
            any(not isinstance(value, SelectionContext) for value in contexts) or
            any(not isinstance(value, ExistingEvidenceResolution) for value in resolvers) or
            any(not isinstance(value, SugarEvidence) for value in early) or
            graph.selection.inner.context not in contexts or
            graph.selection.legacy.resolver.frozen not in resolvers or
            graph.selection.legacy.resolver.copy not in resolvers):
        raise ValueError('Full graph sugar context, resolver or early owner is missing')
    view = _view(root, config, selector_registry, expected_config_sha256)
    old = {key: view[key] for key in view if key != view.added_slug}
    for context in contexts:
        if dict(context.sugar_facts) != old:
            raise ValueError('Live context sugar facts differ from exact old ledger')
    for resolver in resolvers:
        if resolver.sugar != old or slug not in resolver.guard.fields:
            raise ValueError('Live resolver sugar ledger or raw source card differs')
    for owner in early:
        if owner.ledger != old or slug not in owner.catalog or len(owner.catalog) != 2266:
            raise ValueError('Early SugarEvidence lost old ledger or 80 new cards')
    guards_before = _guard_roster(resolvers)
    registry_before = [(registry, _digest(registry.document), _digest(registry.claims))
                       for registry in registries]
    raw_refs_before = _digest(raws[0]['object'].references)
    staged = []
    for index in indices:
        matching = [context for context in contexts if index.context is context]
        if (len(matching) != 1 or index.registry not in registries or
                index.registry.product_id(slug) != fact['product_id']):
            raise ValueError('Live CatalogueIndex is not bound to pinned ProductRegistry/context')
        proxy = copy(matching[0]); proxy.sugar_facts = view
        rebuilt = CatalogueIndex(index.registry, proxy, index.reference)
        if set(index.products) != set(rebuilt.products):
            raise ValueError('CatalogueIndex product roster changed')
        for pid in index.products:
            before, after = deepcopy(index.products[pid]), deepcopy(rebuilt.products[pid])
            if before != after:
                if pid != fact['product_id']:
                    raise ValueError('CatalogueIndex changed another product')
                before['verified_typed']['sugar'] = after['verified_typed']['sugar']
                if before != after:
                    raise ValueError('CatalogueIndex changed a non-sugar field')
        staged.append((index, rebuilt, matching[0]))
    original = ([(context, context.sugar_facts) for context in contexts] +
                [(resolver, resolver.sugar) for resolver in resolvers] +
                [(owner, owner.ledger) for owner in early])
    previous_indices = [(index, dict(index.__dict__)) for index in indices]
    try:
        for context in contexts: context.sugar_facts = view
        for resolver in resolvers: resolver.sugar = view
        for owner in early: owner.ledger = view
        for index, rebuilt, context in staged:
            index.__dict__.update(rebuilt.__dict__)
            index.context = context
        if (any(context.sugar_facts is not view for context in contexts) or
                any(resolver.sugar is not view for resolver in resolvers) or
                any(owner.ledger is not view for owner in early) or
                any(index.context not in contexts or
                    index.products[index.registry.product_id(slug)]['verified_typed']['sugar'] != 'dry'
                    for index in indices) or
                guards_before != _guard_roster(resolvers) or
                any((_digest(registry.document), _digest(registry.claims)) !=
                    (document_sha, claims_sha)
                    for registry, document_sha, claims_sha in registry_before) or
                _digest(raws[0]['object'].references) != raw_refs_before):
            raise ValueError('P4 binding did not preserve raw fields, identity or owner aliases')
    except Exception:
        for owner, previous in original:
            if hasattr(owner, 'sugar_facts'): owner.sugar_facts = previous
            elif hasattr(owner, 'sugar'): owner.sugar = previous
            else: owner.ledger = previous
        for index, previous in previous_indices: index.__dict__.clear(); index.__dict__.update(previous)
        raise
    return {'kind': 'p4-source-verified-sugar-full-graph-binding-v1',
            'status': 'BOUND_BEFORE_IMAGE_ADMISSION',
            'source': source_receipt, 'view': view.describe(),
            'owner_paths': {kind: [path for row in owners[kind].values() for path in row['paths']]
                            for kind in owners},
            'owner_counts': {kind: len(owners[kind]) for kind in owners},
            'raw_guard_owners': guards_before, 'raw_guard_fields_unchanged': True,
            'catalogue_index_status': ('active_source_rebuilt' if indices else
                                       'not_constructed_in_current_runtime'),
            'old_ledger_preserved': 349, 'new_fact_count': 1,
            'registry_checksums': sorted(expected_kinds),
            'gallery_rows': len(raws[0]['object'].references),
            'models_loaded_by_overlay': False, 'NN': 0, 'OCR': 0, 'HTTP': 0, 'fit': 0}
