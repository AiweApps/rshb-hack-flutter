"""Unified per-card attribute table over the pinned identity registry and profiles.

Strict values come only from trusted upstream claims or from literal catalogue raw fields
normalized by the profile-v1 rules; published slug terms enter only a separate
training-candidate projection that is never fit-admitted.
"""
import hashlib
import importlib.util
import json
import re
import unicodedata
from collections import Counter, defaultdict
from copy import deepcopy
from pathlib import Path

from rshb_vine.catalog.product_claims import normalized_values
from rshb_vine.catalog.profiles import CatalogProfiles
from rshb_vine.catalog_training_data_v2 import site_metadata
from rshb_vine.io import digest, local_path, read_json, read_jsonl, sha256, verify

VERSION = 'catalog-training-item-v2'
REVISION = 3
BUNDLE = 'data/product-identity-v1/snapshot-03-candidate/manifest.json'
PROFILE_POINTER = 'data/catalog-profiles-v1/current.json'
CATALOG_FILES = ['data/normalized/catalog.jsonl', 'data/catalog-additions-20260921/catalog.jsonl']
PROFILE_RULES = 'scripts/build_catalog_profiles.py'
SENTINELS = ['config/curation.json']
SCHEMA = 'schemas/catalog-training-item-v2.schema.json'
ITEMS = 'data/catalog-training-data-v2/stage1/items.jsonl'
MANIFEST = 'data/catalog-training-data-v2/stage1/manifest.json'
VALIDATION = 'runs/catalog-training-data-v2/stage1/validation.json'
PREVIOUS_ITEMS = 'data/catalog-training-data-v2/stage1/revision2/items.jsonl'
CODE = ['rshb_vine/catalog_training_data_v2/__init__.py', 'rshb_vine/catalog_training_data_v2/table.py',
        'rshb_vine/catalog_training_data_v2/site_metadata.py',
        'scripts/catalog_training_data_v2.py']

ROLE_ATTRS = {'producer': 'manufacturer', 'product_name': 'commercial_name', 'series': 'series',
              'grapes': 'grape_blend', 'wine_color': 'color', 'sweetness': 'sugar',
              'sparkling_style': 'style', 'visible_brand': 'visible_brand'}
PROFILE_ATTRS = ['wine_hue', 'wine_type', 'region', 'reference_year', 'catalog_vintage', 'label_color']
ATTRS = list(ROLE_ATTRS) + PROFILE_ATTRS
GROUPS = {'required_b3': ['producer', 'product_name', 'grapes', 'wine_color', 'sweetness', 'sparkling_style', 'wine_type'],
          'context': ['region', 'wine_hue', 'visible_brand'],
          'optional': ['series', 'reference_year', 'catalog_vintage', 'label_color']}
TRUSTED = {'catalog_asserted', 'source_verified', 'source_verified_alias'}
VERIFIED = {'source_verified', 'source_verified_alias'}
CANDIDATE_KINDS = {'external_catalog_candidate', 'reference_ocr', 'reference_fullframe_ocr'}
TIER = {'source_verified': 4, 'source_verified_alias': 4, 'catalog_asserted': 3, 'catalog_raw_field_literal': 2.5,
        'candidate': 2, 'catalog_slug_literal': 1}
SPARKLING = [(('ekstra', 'bryut'), 'extra_brut'), (('extra', 'brut'), 'extra_brut'),
             (('bryut', 'nature'), 'brut_nature'), (('brut', 'nature'), 'brut_nature'),
             (('bryut', 'natur'), 'brut_nature'), (('zero', 'dozazh'), 'brut_nature'),
             (('zero', 'dosage'), 'brut_nature'), (('demi', 'sec'), 'demi_sec'),
             (('bryut',), 'brut'), (('brut',), 'brut')]
# demi-sec has no single still-wine sugar equivalent; it is kept as an ambiguous marker.
SLUG_TERMS = {
    'sweetness': [(t, None if v == 'demi_sec' else v) for t, v in SPARKLING] + [
        (('polusuhoe',), 'semidry'), (('polusladkoe',), 'semisweet'),
        (('suhoe',), 'dry'), (('sladkoe',), 'sweet')],
    'sparkling_style': SPARKLING,
    'wine_color': [(('beloe',), 'white'), (('krasnoe',), 'red'), (('rozovoe',), 'rose'),
                   (('roze',), 'rose'), (('rose',), 'rose'), (('oranzhevoe',), 'orange'),
                   (('oranzh',), 'orange'), (('orange',), 'orange')],
    'wine_type': [(('igristoe',), 'sparkling'), (('shampanskoe',), 'sparkling'),
                  (('pet', 'nat'), 'sparkling'), (('petnat',), 'sparkling')],
}
BROADER = {'brut': {'extra_brut', 'brut_nature'}}
NEXT = {'conflict': 'source_review_of_conflicting_trusted_claims',
        'review_required_competing_claims': 'resolve_competing_claim_against_producer_or_label_source',
        'review_required_identity_hold': 'resolve_catalog_resolution_hold_before_use',
        'candidate_only': 'verify_candidate_against_producer_source_before_admission',
        'unsupported_value': 'extend_vocabulary_keeping_raw_modifiers',
        'extraction_failure': 'repair_catalog_field_parser',
        'card_absent_from_profile_snapshot': 'build_profile_successor_with_reference_ocr_for_card',
        'source_absence': 'producer_or_retailer_source_page_lookup',
        'not_applicable': 'none_not_applicable'}
# Raw-field rules reused from the profile-v1 builder for cards the pinned profile snapshot lacks.
RAW_COPY = {'region': 'Регион', 'wine_hue': 'Цвет'}
TITLE_RULES = ['sweetness', 'sparkling_style', 'wine_type', 'catalog_vintage']
NO_RAW_SOURCE = {'reference_year', 'label_color', 'series', 'visible_brand'}


def _pins(root, paths):
    return {p: sha256(local_path(root, p)) for p in sorted(paths)}


def _rules(root):
    spec = importlib.util.spec_from_file_location('build_catalog_profiles_rules', Path(root) / PROFILE_RULES)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load_inputs(root):
    root = Path(root).resolve()
    bundle = verify(read_json(root / BUNDLE))
    registry = verify(read_json(root / bundle['registry']['path']))
    claims = verify(read_json(root / bundle['claims']['path']))
    if (registry['checksum'] != bundle['registry']['checksum'] or claims['checksum'] != bundle['claims']['checksum']
            or claims['identity_registry_checksum'] != registry['checksum']):
        raise ValueError('Identity bundle is not self-consistent')
    profiles = CatalogProfiles(root)
    pointer = read_json(root / PROFILE_POINTER)
    snap = pointer['snapshot']
    rows = read_jsonl(root / snap / 'profiles.jsonl')
    pins = _pins(root, [BUNDLE, bundle['registry']['path'], bundle['claims']['path'], PROFILE_POINTER,
                        snap + '/manifest.json', snap + '/verification.json', snap + '/profiles.jsonl',
                        *CATALOG_FILES, *SENTINELS, PREVIOUS_ITEMS])
    site = site_metadata.load_site(root)
    pins.update(site['pins'])
    catalogs = {pins[p]: p for p in CATALOG_FILES}
    catalog_rows = {p: {r['slug']: r for r in read_jsonl(root / p)} for p in CATALOG_FILES}
    return {'root': root, 'bundle': bundle, 'registry': registry, 'claims': claims,
            'profiles': {r['slug']: r for r in rows}, 'profile_checksum': profiles.snapshot_checksum,
            'profile_snapshot': snap, 'pins': pins, 'catalogs': catalogs, 'catalog_rows': catalog_rows,
            'rules': _rules(root), 'rules_pin': _pins(root, [PROFILE_RULES]), 'site': site}


def parse_slug(slug, attr):
    tokens = slug.split('-')
    starts, pos = [], 0
    for t in tokens:
        starts.append(pos)
        pos += len(t) + 1
    terms = sorted(SLUG_TERMS[attr], key=lambda x: -len(x[0]))
    markers, i = [], 0
    while i < len(tokens):
        for words, value in terms:
            if tuple(tokens[i:i + len(words)]) == words:
                j = i + len(words)
                markers.append({'term': '-'.join(words), 'normalized_proposal': value,
                                'ambiguous': value is None, 'token_span': [i, j],
                                'char_span': [starts[i], starts[j - 1] + len(tokens[j - 1])]})
                i = j
                break
        else:
            i += 1
    return markers


def _compatible(a, b):
    return a == b or a in BROADER.get(b, ()) or b in BROADER.get(a, ())


def _most_specific(found):
    """Single most specific value if every marker is compatible with it, else None."""
    for v in found:
        if all(o == v or v in BROADER.get(o, ()) for o in found):
            return v
    return None


def _relation(slug_value, strict):
    if strict is None:
        return 'strict_missing'
    if slug_value in strict:
        return 'agrees'
    if any(slug_value in BROADER.get(s, ()) for s in strict):
        return 'slug_more_specific'
    if any(s in BROADER.get(slug_value, ()) for s in strict):
        return 'strict_more_specific'
    return 'unresolved_contradiction'


def _claim(value, raw, status, source):
    return {'normalized': value, 'raw': raw, 'status': status, 'tier': TIER.get(status, 0),
            'source_kind': (source or {}).get('kind'), 'source': deepcopy(source or {})}


def _grape_components(rules, raw):
    components = []
    for chunk in re.split(r'[,;]', raw or ''):
        if not chunk.strip():
            continue
        matched = {k for k, aliases in rules.GRAPES.items() if rules.norm(chunk) in {rules.norm(a) for a in aliases}}
        components.extend(sorted(matched) if matched else ['unmapped:' + unicodedata.normalize('NFC', chunk).strip().casefold()])
    return sorted(set(components))


def _raw_claims(card, inputs, in_profile):
    """Catalogue raw-field claims reproducible from the card's own source catalogue row."""
    rules, raw = inputs['rules'], card['raw_metadata']
    path = inputs['catalogs'].get(card['source_catalog_sha'])
    out = defaultdict(list)
    if path is None:
        return out

    def add(attr, value, field, rule, status='catalog_asserted'):
        if value in (None, '', []):
            return
        src = {'kind': 'catalog_raw_field', 'path': path, 'sha256': card['source_catalog_sha'],
               'slug': card['slug'], 'field': field, 'rule': rule, 'derived': True}
        c = _claim(value if isinstance(value, list) else [value], raw.get(field), status, src)
        if c not in out[attr]:
            out[attr].append(c)
    sugar = rules.values(raw.get('Категория') or '', rules.SWEET)
    if len(sugar) == 1:
        add('sweetness', sorted(sugar), 'Категория', 'single_explicit_sugar_word_in_category')
    if in_profile:
        return out
    for attr, field in RAW_COPY.items():
        add(attr, raw.get(field), field, 'profile_v1_raw_field_copy')
    add('grapes', _grape_components(rules, raw.get('Сорт винограда')), 'Сорт винограда', 'profile_v1_grape_components')
    for v in sorted(rules.values(raw.get('Категория') or '', rules.COLORS)):
        add('wine_color', [v], 'Категория', 'profile_v1_category_color')
    name = raw.get('Название вина') or ''
    for v in sorted(rules.values(name, rules.SWEET)):
        add('sweetness', [v], 'Название вина', 'profile_v1_title_term')
    for v in sorted(rules.style_values(name)):
        add('sparkling_style', [v], 'Название вина', 'profile_v1_title_term')
    for v in sorted(rules.values(name, rules.TYPES)):
        add('wine_type', [v], 'Название вина', 'profile_v1_title_term')
    for year in re.findall(r'\b(?:19|20)\d{2}\b', name):
        add('catalog_vintage', [int(year)], 'Название вина', 'profile_v1_title_year',
            'catalog_asserted' if re.search(r'урож[а-я]*|vintage|harvest', name, re.I) else 'candidate')
    return out


def _key(c):
    s = c['source']
    return (c['status'], c['source_kind'], s.get('field'), s.get('image_sha256'), s.get('observation_index'),
            s.get('line_index'), json.dumps(c['normalized'], ensure_ascii=False, sort_keys=True))


def _merge(claims, extra):
    added = 0
    for c in extra:
        if any(_key(o) == _key(c) or (o['source'].get('field') == c['source'].get('field') and o['status'] == c['status']
                                       and o['normalized'] == c['normalized']) for o in claims):
            continue
        claims.append(c)
        added += 1
    return added


def _upstream_role(attr, role, profile):
    claims = [_claim(c['normalized'] if isinstance(c['normalized'], list) else [c['normalized']],
                     c['raw'].get('value') if isinstance(c['raw'], dict) else c['raw'],
                     c['status'], c['source']) for c in role['claims']]
    union = 0
    prop = (profile or {}).get('properties', {}).get(attr)
    if prop:
        union = _merge(claims, [_claim(normalized_values(role_name, c['value']), c['source'].get('raw'), c['status'], c['source'])
                                for role_name in [ROLE_ATTRS[attr]] for c in prop['claims']])
    return claims, role['status'], role['comparison_allowed'], union


def _upstream_profile(attr, profile):
    if profile is None:
        return [], 'unknown', False, 0
    prop = profile['properties'][attr]
    claims = [_claim(c['value'] if isinstance(c['value'], list) else [c['value']], c['source'].get('raw'),
                     c['status'], c['source']) for c in prop['claims']]
    return claims, prop['status'], prop['status'] in TRUSTED and not prop['review_required'], 0


def _choose(attr, trusted):
    distinct = {json.dumps(c['normalized'], ensure_ascii=False, sort_keys=True): c['normalized'] for c in trusted}
    if attr == 'visible_brand':
        return sorted({v for c in trusted for v in c['normalized']}) or None
    if attr == 'grapes':
        verified = {k: v for k, v in distinct.items()
                    if any(c['status'] == 'source_verified' and c['normalized'] == v for c in trusted)}
        if len(verified) == 1:
            (v,) = verified.values()
            if all(set(c['normalized']) <= set(v) for c in trusted):
                return v
    return next(iter(distinct.values())) if len(distinct) == 1 else None


def _resolve(attr, card, profile, record, derived, rules):
    raw = card['raw_metadata']
    if attr in ROLE_ATTRS:
        claims, up_status, up_allowed, union = _upstream_role(attr, record['roles'][ROLE_ATTRS[attr]], profile)
    else:
        claims, up_status, up_allowed, union = _upstream_profile(attr, profile)
    n_derived = _merge(claims, derived.get(attr, []))
    raw_key = lambda c: (c['source'].get('field'), json.dumps(c['raw'], ensure_ascii=False, sort_keys=True))
    parsed = {raw_key(c) for c in claims if c['source'].get('kind') == 'catalog_raw_field'}
    for c in claims:
        # The same literal field re-parsed by the profile-v1 rule keeps modifiers the lossy upstream mapping dropped.
        if c['status'] in TRUSTED and c['source'].get('kind') != 'catalog_raw_field' and raw_key(c) in parsed:
            c['superseded_by'] = 'catalog_raw_field_profile_v1_parse'
    trusted = [c for c in claims if c['status'] in TRUSTED and c['normalized'] and not c.get('superseded_by')]
    value = _choose(attr, trusted) if trusted else None
    chosen = value
    held = bool(profile and profile.get('excluded_from_retrieval'))
    review_flag, resolution, reason = None, None, None
    if value is not None and up_status == 'conflict':
        value, reason, resolution = None, 'conflict', 'upstream_conflict_kept'
    elif value is not None and not up_allowed and up_status in TRUSTED and held:
        value, reason, resolution = None, 'review_required_identity_hold', 'upstream_withheld_identity_hold'
    elif value is not None:
        dissent = [c for c in claims if c['status'] not in TRUSTED and c['normalized'] and c['normalized'] != value
                   and not (attr == 'grapes' and set(c['normalized']) <= set(value))]
        if up_status in TRUSTED and not up_allowed:
            resolution = 'admitted_upstream_fact_unmasked'
            review_flag = {'reason': 'untrusted_candidate_disagreement' if dissent else 'upstream_review_required',
                           'upstream_comparison_allowed': False,
                           'dissenting_values': sorted({json.dumps(c['normalized'], ensure_ascii=False) for c in dissent}),
                           'dissenting_source_kinds': sorted({c['source_kind'] or '' for c in dissent})}
        elif up_status in TRUSTED:
            resolution = 'upstream_trusted'
        else:
            resolution = 'catalog_raw_field_derived'
        if attr == 'grapes':
            prop = (profile or {}).get('properties', {}).get('grapes')
            if prop and prop['value'] not in (None, []) and set(prop['value']) >= set(value):
                value = list(prop['value'])
    else:
        trusted_any = [c for c in claims if c['status'] in TRUSTED and not c.get('superseded_by')]
        if len({json.dumps(c['normalized'], sort_keys=True) for c in trusted}) > 1 or up_status == 'conflict':
            reason = 'conflict'
        elif trusted_any and not trusted:
            reason = 'unsupported_value'
        elif up_status in TRUSTED and not up_allowed:
            reason = 'review_required_competing_claims'
        elif any(c['status'] == 'candidate' for c in claims):
            reason = 'candidate_only'
        elif attr == 'sweetness' and any(rules.values(raw.get(f) or '', rules.SWEET) for f in ('Название вина', 'Категория')):
            reason = 'extraction_failure'
        elif profile is None and attr in NO_RAW_SOURCE - {'series', 'visible_brand'}:
            reason = 'card_absent_from_profile_snapshot'
        else:
            reason = 'source_absence'
        resolution = 'withheld_' + reason
    basis = [i for i, c in enumerate(claims) if value is not None and c['status'] in TRUSTED and c['normalized']
             and not c.get('superseded_by') and (set(map(str, c['normalized'])) & set(map(str, chosen))
                                                 if attr in ('grapes', 'visible_brand') else c['normalized'] == chosen)]
    if basis and all(claims[i]['source'].get('kind') == 'catalog_raw_field' for i in basis) and resolution == 'upstream_trusted':
        resolution = 'catalog_raw_field_reparse_of_lossy_upstream'
    status = (max((claims[i]['status'] for i in basis), key=lambda s: TIER[s]) if basis else
              'conflict' if reason == 'conflict' else up_status)
    if status not in TRUSTED | {'candidate', 'conflict', 'unknown'}:
        status = 'unknown'
    entry = {'status': status, 'upstream_status': up_status, 'upstream_comparison_allowed': up_allowed,
             'value': value, 'basis_claims': basis, 'claims': claims, 'comparison_allowed': value is not None,
             'resolution': resolution, 'review_flag': review_flag, 'missing_reason': reason,
             'source_unknown_reason': ((profile or {}).get('properties', {}).get(attr) or {}).get('unknown_reason')
             if profile else 'registry_card_not_in_catalog_profiles_v1',
             'claims_added_from_profile_union': union, 'claims_added_from_raw_fields': n_derived}
    if attr == 'grapes':
        components = entry['value'] or _grape_components(rules, raw.get('Сорт винограда'))
        entry.update(components=components, raw_components=raw.get('Сорт винограда'),
                     unmapped_components=[c for c in components if c.startswith('unmapped:')],
                     completeness='reported_components_not_proven_exhaustive',
                     supports_negative_inference_from_absence=False)
    return entry


def _projection(attr, entry, slug, raw, rules):
    if attr not in SLUG_TERMS:
        entry.update(slug_literal=None, slug_relation=None)
    else:
        markers = parse_slug(slug, attr)
        found = sorted({m['normalized_proposal'] for m in markers if not m['ambiguous']})
        specific = _most_specific(found) if found else None
        marker_set = ('none' if not found else 'single' if len(found) == 1 else
                      'multiple_compatible' if specific else 'multiple_contradictory')
        if not found:
            relation = 'ambiguous_marker_only' if markers else 'no_marker'
        elif specific is None:
            relation = 'multiple_contradictory_markers'
        else:
            relation = _relation(specific, entry['value'])
        entry.update(slug_literal={'source_kind': 'catalog_slug_literal', 'slug': slug, 'markers': markers,
                                   'distinct_values': found, 'marker_set': marker_set, 'most_specific': specific},
                     slug_relation=relation)
    if entry['value'] is not None:
        statuses = [entry['claims'][i]['status'] for i in entry['basis_claims']] or [entry['status']]
        entry['training_candidate'] = {'value': entry['value'], 'origin': 'strict_resolved',
                                       'evidence_tier': max(statuses, key=lambda s: TIER.get(s, 0)),
                                       'reason': entry['resolution'], 'review_flag': entry['review_flag'] is not None,
                                       'fit_admitted': False, 'hard_veto_allowed': False}
        return
    entry['training_candidate'] = None
    if entry['missing_reason'] == 'extraction_failure':
        found = {f: sorted(rules.values(raw.get(f) or '', rules.SWEET)) for f in ('Название вина', 'Категория')}
        distinct = sorted({v for vs in found.values() for v in vs})
        if len(distinct) == 1:
            field = next(f for f, vs in found.items() if vs)
            entry['training_candidate'] = {
                'value': distinct, 'origin': 'catalog_raw_field_literal', 'evidence_tier': 'catalog_raw_field_literal',
                'reason': 'preserved_raw_catalog_field_term_not_extracted_upstream', 'field': field,
                'raw': raw[field], 'source_verified': False, 'fit_admitted': False, 'hard_veto_allowed': False}
        return
    if attr not in SLUG_TERMS or entry['slug_relation'] != 'strict_missing':
        return
    if entry['missing_reason'] in ('conflict', 'review_required_competing_claims', 'review_required_identity_hold'):
        entry['slug_relation'] = 'strict_disputed_slug_not_projected'
        return
    v = entry['slug_literal']['most_specific']
    others = sorted({n for c in entry['claims'] if c['status'] == 'candidate' for n in c['normalized']})
    if any(not _compatible(o, v) for o in others):
        entry['slug_relation'] = 'slug_vs_candidate_disagreement'
        return
    marker = next(m for m in entry['slug_literal']['markers'] if m['normalized_proposal'] == v)
    entry['training_candidate'] = {
        'value': [v], 'origin': 'catalog_slug_literal', 'evidence_tier': 'catalog_slug_literal',
        'reason': ('published_slug_whole_term_single_marker' if entry['slug_literal']['marker_set'] == 'single'
                   else 'published_slug_compatible_markers_most_specific'),
        'slug_term': marker['term'], 'token_span': marker['token_span'], 'char_span': marker['char_span'],
        'corroborating_candidate_values': [o for o in others if o == v],
        'specificity_variants': [o for o in others if o != v],
        'source_verified': False, 'fit_admitted': False, 'hard_veto_allowed': False}


def build_items(inputs):
    registry, claims, profiles, rules = inputs['registry'], inputs['claims'], inputs['profiles'], inputs['rules']
    records = {r['slug']: r for r in claims['records']}
    products = {p['product_id']: p for p in registry['products']}
    refs = defaultdict(list)
    for ref in registry['reference_images']:
        for slug in ref['card_slugs']:
            refs[slug].append({'reference_id': ref['reference_id'], 'image_sha256': ref['image_sha256'],
                               'product_ids': ref['product_ids'], 'binding_status': ref['binding_status'],
                               'provenance_status': ref['provenance_status'],
                               'shared_with_cards': sorted(set(ref['card_slugs']) - {slug}),
                               'view_kinds': sorted(Counter(v['kind'] for v in ref['views']).items()),
                               'n_views': len(ref['views'])})
    alias_of = {a['alias']: a for a in registry['catalog_alias_links']}
    canonical_of = defaultdict(list)
    for a in registry['catalog_alias_links']:
        canonical_of[a['canonical']].append(a['alias'])
    items = []
    for card in sorted(registry['cards'], key=lambda c: c['slug']):
        slug, raw = card['slug'], card['raw_metadata']
        profile = profiles.get(slug)
        derived = _raw_claims(card, inputs, profile is not None)
        attrs = {attr: _resolve(attr, card, profile, records[slug], derived, rules) for attr in ATTRS}
        held = bool(profile and profile.get('excluded_from_retrieval'))
        for attr, entry in attrs.items():
            entry['site_enrichment'] = site_metadata.enrich(attr, entry, slug, inputs['site'], rules,
                                                            lambda text: _grape_components(rules, text), held)
        if attrs['grapes']['site_enrichment']['outcome'].startswith('filled_'):
            g = attrs['grapes']
            g.update(components=g['value'], unmapped_components=[c for c in g['value'] if c.startswith('unmapped:')])
        if attrs['sparkling_style']['value'] is None and attrs['wine_type']['value'] == ['fortified']:
            attrs['sparkling_style'].update(missing_reason='not_applicable', resolution='withheld_not_applicable',
                                            not_applicable_basis='trusted_wine_type_fortified')
        for attr, entry in attrs.items():
            _projection(attr, entry, slug, raw, rules)
            entry['next_repair'] = NEXT.get(entry['missing_reason']) if entry['value'] is None else None
        pid = card['product_id']
        items.append({
            'schema_version': VERSION, 'revision': REVISION, 'slug': slug, 'product_id': pid,
            'binding_status': card['binding_status'],
            'product_identity_status': products[pid]['identity_status'],
            'active_in_gallery': card['active_in_gallery'],
            'excluded_from_retrieval': profile['excluded_from_retrieval'] if profile else None,
            'catalog_resolution': deepcopy(profile['catalog_resolution']) if profile else None,
            'in_profile_snapshot': profile is not None,
            'source_catalog_path': inputs['catalogs'].get(card['source_catalog_sha']),
            'alias': {'catalog_alias_target': card['catalog_alias_target'], 'is_alias_of': (alias_of.get(slug) or {}).get('canonical'),
                      'aliases': sorted(canonical_of.get(slug, [])),
                      'recovered_alias_card': slug in registry.get('recovered_alias_cards', []),
                      'product_merge_admitted': False},
            'references': sorted(refs.get(slug, []), key=lambda r: r['image_sha256']),
            'profile_selected_sha256': profile.get('selected_sha256') if profile else None,
            'vintage': deepcopy(card['vintage']),
            'raw_metadata': deepcopy(raw), 'source_catalog_sha': card['source_catalog_sha'],
            'external_product_candidates': deepcopy(profile['external_product_candidates']) if profile else [],
            'attributes': attrs, 'fit_admitted': False, 'runtime_admitted': False, 'exact_card_verified': False})
    return items


def _jsonl(items):
    return ''.join(json.dumps(i, ensure_ascii=False, sort_keys=True, separators=(',', ':')) + '\n' for i in items)


def coverage(items):
    out = {}
    for scope, rows in (('all', items), ('active', [i for i in items if i['active_in_gallery']])):
        scope_out = {'n': len(rows)}
        for attr in ATTRS:
            e = [r['attributes'][attr] for r in rows]
            scope_out[attr] = {
                'strict_filled': sum(x['value'] is not None for x in e),
                'strict_by_status': dict(Counter(x['status'] for x in e if x['value'] is not None)),
                'strict_by_resolution': dict(Counter(x['resolution'] for x in e if x['value'] is not None)),
                'strict_with_review_flag': sum(x['review_flag'] is not None for x in e),
                'upstream_status': dict(Counter(x['upstream_status'] for x in e)),
                'training_projection_by_origin': dict(Counter(x['training_candidate']['origin'] for x in e if x['training_candidate'])),
                'no_projection': sum(x['training_candidate'] is None for x in e),
                'missing_by_reason': dict(Counter(x['missing_reason'] for x in e if x['value'] is None)),
                'slug_relation': dict(Counter(x['slug_relation'] for x in e if x['slug_relation'])),
            }
        out[scope] = scope_out
    return out


def _pointers(e):
    keys = ('kind', 'path', 'sha256', 'catalog_sha', 'field', 'image_sha256', 'line_index', 'observation_index', 'source_line_index')
    return [{**{k: c['source'].get(k) for k in keys if c['source'].get(k) is not None}, 'status': c['status'],
             'normalized': c['normalized']} for c in e['claims']]


def gap_queue(items):
    rows = []
    for item in items:
        for attr, e in item['attributes'].items():
            if e['value'] is None:
                queue, why, action = 'missing', e['missing_reason'], e['next_repair']
            elif e['review_flag']:
                queue, why, action = 'review_flag', e['review_flag']['reason'], 'source_review_of_dissenting_candidate'
            elif e['slug_relation'] in ('unresolved_contradiction', 'multiple_contradictory_markers'):
                queue, why, action = 'slug_contradiction', 'slug_' + e['slug_relation'], 'source_review_slug_vs_trusted_value'
            else:
                continue
            rows.append({'queue': queue, 'slug': item['slug'], 'product_id': item['product_id'],
                         'active_in_gallery': item['active_in_gallery'], 'attribute': attr,
                         'group': next(g for g, a in GROUPS.items() if attr in a),
                         'strict_value': e['value'], 'status': e['status'], 'upstream_status': e['upstream_status'],
                         'why': why, 'source_unknown_reason': e['source_unknown_reason'],
                         'candidate_values': sorted({str(n) for c in e['claims'] if c['status'] == 'candidate' for n in c['normalized']}),
                         'slug_values': (e['slug_literal'] or {}).get('distinct_values'),
                         'slug_relation': e['slug_relation'],
                         'training_candidate': (e['training_candidate'] or {}).get('value'),
                         'training_candidate_origin': (e['training_candidate'] or {}).get('origin'),
                         'source_pointers': _pointers(e), 'next_action': action})
    return rows


def build(root):
    inputs = load_inputs(root)
    items = build_items(inputs)
    body = _jsonl(items)
    shas = [r['image_sha256'] for i in items for r in i['references']]
    manifest = {'kind': 'catalog-training-data-v2-stage1', 'schema_version': VERSION, 'revision': REVISION,
                'inputs': inputs['pins'], 'identity_bundle_checksum': inputs['bundle']['checksum'],
                'registry_checksum': inputs['registry']['checksum'], 'claims_checksum': inputs['claims']['checksum'],
                'profile_snapshot': inputs['profile_snapshot'], 'profile_manifest_checksum': inputs['profile_checksum'],
                'code': {**_pins(inputs['root'], CODE), **inputs['rules_pin']}, 'schema': _pins(inputs['root'], [SCHEMA]),
                'items_sha256': hashlib.sha256(body.encode()).hexdigest(),
                'site_source': {'verified_cached_bodies': inputs['site']['verified_bodies'],
                                'access_error_receipts': inputs['site']['access_error_receipts'],
                                'parser_version': site_metadata.PARSER_VERSION,
                                'api_prefix': site_metadata.API_PREFIX, 'status_assigned': 'catalog_asserted'},
                'counts': {'cards': len(items), 'active': sum(i['active_in_gallery'] for i in items),
                           'reference_unique_originals': len(set(shas)), 'reference_card_joins': len(shas),
                           'reference_views_unique': sum(len(r['views']) for r in inputs['registry']['reference_images'])},
                'fit_admitted': False, 'runtime_admitted': False, 'source_verified_created': 0,
                'limits': 'Strict values come from trusted upstream claims or literal catalogue raw fields (profile-v1 rules, '
                          'single sugar word in Категория). Revision3 fills only attributes lacking a trusted value from saved '
                          'vino-svoe.ru API bodies (structured category/manufacturer/title/region/grapes/color, explicit '
                          'description classification phrases) as catalog_asserted, never source_verified or photo binding proof. Candidate-only disagreement is kept as review_flag, never erases a trusted value. '
                          'Slug literals are weak training candidates only; not source_verified, not hard veto, not fit admission. '
                          'No OCR/image inference, no query GT.'}
    manifest['checksum'] = digest(manifest)
    return inputs, items, body, manifest


def _input_facts(inputs):
    """(slug, attr, status, normalized) of every upstream claim, independent of the resolver."""
    facts = set()
    for rec in inputs['claims']['records']:
        for attr, role in ROLE_ATTRS.items():
            for c in rec['roles'][role]['claims']:
                n = c['normalized'] if isinstance(c['normalized'], list) else [c['normalized']]
                facts.add((rec['slug'], attr, c['status'], json.dumps(n, ensure_ascii=False, sort_keys=True)))
    for slug, p in inputs['profiles'].items():
        for attr, prop in p['properties'].items():
            for c in prop['claims']:
                v = c['value'] if isinstance(c['value'], list) else [c['value']]
                n = normalized_values(ROLE_ATTRS[attr], c['value']) if attr in ROLE_ATTRS else v
                facts.add((slug, attr, c['status'], json.dumps(n, ensure_ascii=False, sort_keys=True)))
    return facts


def validate(root, items_path=None, manifest_path=None):
    import jsonschema
    root = Path(root).resolve()
    items_path = Path(items_path or root / ITEMS)
    manifest = verify(read_json(manifest_path or root / MANIFEST))
    errors = []
    pinned = {**manifest['inputs'], **manifest['code'], **manifest['schema']}
    for path, expected in pinned.items():
        if sha256(local_path(root, path)) != expected:
            errors.append('pinned file changed: ' + path)
    stored = items_path.read_bytes()
    fresh_sha = hashlib.sha256(stored).hexdigest()
    if fresh_sha != manifest['items_sha256']:
        errors.append('items file does not match manifest')
    inputs, _, body, rebuilt_manifest = build(root)
    if body.encode() != stored:
        errors.append('rebuild from pinned inputs is not byte-identical')
    if rebuilt_manifest['checksum'] != manifest['checksum']:
        errors.append('rebuilt manifest differs from stored manifest')
    items = [json.loads(line) for line in stored.decode().splitlines()]
    validator = jsonschema.Draft202012Validator(json.loads((root / SCHEMA).read_text()))
    for item in items:
        for err in validator.iter_errors(item):
            errors.append(f"schema {item.get('slug')}: {err.message[:160]}")
            break
    registry = inputs['registry']
    slugs = [i['slug'] for i in items]
    if len(set(slugs)) != len(slugs) or set(slugs) != {c['slug'] for c in registry['cards']}:
        errors.append('roster is not the complete unique registry card set')
    if (len(items), sum(i['active_in_gallery'] for i in items)) != (registry['counts']['cards'], registry['counts']['active_cards']):
        errors.append('card/active counts differ from registry')
    joins = sorted((r['image_sha256'], i['slug']) for i in items for r in i['references'])
    if joins != sorted((r['image_sha256'], s) for r in registry['reference_images'] for s in r['card_slugs']):
        errors.append('card-reference joins differ from registry')
    if len({s for s, _ in joins}) != len({r['image_sha256'] for r in registry['reference_images']}):
        errors.append('unique reference originals differ from registry')
    facts = _input_facts(inputs)
    cards = {c['slug']: c for c in registry['cards']}
    created = 0
    for item in items:
        card = cards[item['slug']]
        if item['raw_metadata'] != card['raw_metadata'] or item['source_catalog_sha'] != card['source_catalog_sha']:
            errors.append('raw metadata/source sha differ from registry: ' + item['slug'])
        if item['active_in_gallery'] and not item['references']:
            errors.append('active card without reference: ' + item['slug'])
        if item['fit_admitted'] or item['runtime_admitted']:
            errors.append('admission flag set: ' + item['slug'])
        for attr, e in item['attributes'].items():
            tag = f"{item['slug']}/{attr}"
            if (e['value'] is None) == (e['missing_reason'] is None):
                errors.append('value/missing_reason mismatch: ' + tag)
            for c in e['claims']:
                s = c['source']
                if s.get('kind') == 'catalog_raw_field':
                    row = inputs['catalog_rows'].get(s.get('path'), {}).get(item['slug'])
                    if (s.get('sha256') != manifest['inputs'].get(s.get('path')) or row is None
                            or row['fields'].get(s['field']) != c['raw'] or item['raw_metadata'].get(s['field']) != c['raw']):
                        errors.append('raw-field claim not reproducible from pinned source catalogue: ' + tag)
                    if c['status'] in VERIFIED:
                        errors.append('raw-field claim marked verified: ' + tag)
                elif (s.get('kind') or '').startswith('site_api_'):
                    errors.extend(f'{m}: {tag}' for m in site_metadata.claim_errors(c, item['slug'], inputs['site']))
                elif (item['slug'], attr, c['status'], json.dumps(c['normalized'], ensure_ascii=False, sort_keys=True)) not in facts:
                    errors.append('claim absent from upstream claims/profile inputs: ' + tag)
            if e['value'] is not None:
                if e['value'] in ([], '') or any(v in (None, '') for v in e['value']):
                    errors.append('empty strict value: ' + tag)
                if e['status'] not in TRUSTED:
                    errors.append('strict value from untrusted status: ' + tag)
                basis = [e['claims'][i] for i in e['basis_claims']]
                if not basis or any(not (c['source'].get('path') or c['source'].get('catalog_sha')) for c in basis):
                    errors.append('strict value without provenance: ' + tag)
                if any(c['source_kind'] in CANDIDATE_KINDS or c['status'] not in TRUSTED for c in basis):
                    errors.append('candidate source used as strict basis: ' + tag)
                if e['status'] in VERIFIED and not any(c['status'] == e['status'] and c['source'].get('kind') != 'catalog_raw_field' for c in basis):
                    created += 1
                    errors.append('source_verified status without upstream verified basis: ' + tag)
                if e['resolution'] == 'admitted_upstream_fact_unmasked' and not e['review_flag']:
                    errors.append('unmasked value without review flag: ' + tag)
                if len({json.dumps(c['normalized'], sort_keys=True) for c in e['claims'] if c['status'] in TRUSTED and c['normalized']}) > 1 \
                        and attr not in ('grapes', 'visible_brand'):
                    errors.append('strict value chosen among disagreeing trusted claims: ' + tag)
            if e['status'] in TRUSTED and e['value'] is None and e['missing_reason'] not in (
                    'unsupported_value', 'review_required_competing_claims', 'review_required_identity_hold', 'not_applicable', 'conflict'):
                errors.append('known status with empty value lacks reason: ' + tag)
            tc = e['training_candidate']
            if tc:
                if tc['fit_admitted'] or tc['hard_veto_allowed']:
                    errors.append('training candidate admitted: ' + tag)
                if tc['origin'] == 'catalog_slug_literal':
                    if attr in ('reference_year', 'catalog_vintage') or not tc.get('char_span'):
                        errors.append('slug projection without span or on vintage: ' + tag)
                    s, t = tc['char_span']
                    if item['slug'][s:t] != tc['slug_term'] or tc.get('source_verified'):
                        errors.append('slug span does not reproduce term: ' + tag)
                if tc['origin'] == 'catalog_raw_field_literal' and item['raw_metadata'].get(tc['field']) != tc['raw']:
                    errors.append('raw-field projection does not reproduce source field: ' + tag)
    errors.extend(_previous_revision_gate(root, items))
    return {'kind': 'catalog-training-data-v2-stage1-validation', 'revision': REVISION,
            'manifest_checksum': manifest['checksum'], 'items_sha256': manifest['items_sha256'],
            'fresh_items_sha256': fresh_sha, 'n_items': len(items), 'passed': not errors,
            'source_verified_created': created, 'errors': errors[:200], 'n_errors': len(errors),
            'checks': ['pinned inputs/code/rules/schema/sentinel sha', 'fresh items sha vs manifest',
                       'byte-identical rebuild and identical manifest', 'JSON Schema 2020-12 all items',
                       'complete unique registry roster and active count', 'card-reference joins and unique originals',
                       'raw metadata equals registry', 'every claim traceable to upstream claims/profile or pinned source catalogue row',
                       'value xor missing_reason', 'no empty strict values', 'strict only from trusted basis with provenance',
                       'no OCR/Kultovo candidate as strict basis', 'no source_verified without upstream verified basis',
                       'unmasked values carry review flag', 'no strict choice among disagreeing trusted claims',
                       'slug projections carry reproducible span, never vintage', 'no fit/runtime admission',
                       'site cache: every body sha/HTTP200/JSON equality/exact slug; every site claim re-derived from body field or span',
                       'revision2 gate: every preexisting strict attribute byte-equal, previous claims preserved as prefix, '
                       'fills only on previously empty attributes, ledger outcome consistent with value change']}


def _previous_revision_gate(root, items):
    errors = []
    previous = {r['slug']: r for r in read_jsonl(root / PREVIOUS_ITEMS)}
    if set(previous) != {i['slug'] for i in items}:
        return ['revision2 roster differs']
    for item in items:
        old = previous[item['slug']]
        if {k: v for k, v in item.items() if k not in ('attributes', 'revision')} != \
                {k: v for k, v in old.items() if k not in ('attributes', 'revision')}:
            errors.append('item-level fields changed vs revision2: ' + item['slug'])
        for attr, e in item['attributes'].items():
            o, tag, ledger = old['attributes'][attr], f"{item['slug']}/{attr}", e['site_enrichment']
            filled = ledger['outcome'] in ('filled_from_structured_field', 'filled_from_explicit_description')
            if o['value'] is not None:
                if {k: v for k, v in e.items() if k != 'site_enrichment'} != o or ledger['outcome'] != 'already_trusted_skipped' \
                        and ledger['outcome'] != 'source_field_unsupported':
                    errors.append('preexisting strict attribute changed: ' + tag)
                continue
            if e['claims'][:len(o['claims'])] != o['claims']:
                errors.append('previous claims not preserved: ' + tag)
            if filled != (e['value'] is not None):
                errors.append('value change without fill outcome: ' + tag)
            if not filled and {k: v for k, v in e.items() if k != 'site_enrichment'} != o:
                errors.append('unfilled attribute changed: ' + tag)
            if filled and any(not (c['source'].get('kind') or '').startswith('site_api_') for c in e['claims'][len(o['claims']):]):
                errors.append('fill added non-site claim: ' + tag)
    return errors


def load_validated_stage1(root):
    """Training-consumer entry point: fresh full validation plus sealed validation record; raises on any drift."""
    root = Path(root).resolve()
    result = validate(root)
    if not result['passed']:
        raise ValueError('stage1 validation failed: ' + '; '.join(result['errors'][:5]))
    stored = verify(read_json(root / VALIDATION))
    for key in ('manifest_checksum', 'items_sha256', 'passed', 'n_items', 'n_errors', 'revision'):
        if stored.get(key) != result[key]:
            raise ValueError('sealed validation record does not match fresh validation: ' + key)
    if stored['fresh_items_sha256'] != result['fresh_items_sha256']:
        raise ValueError('sealed validation was made for different items bytes')
    manifest = verify(read_json(root / MANIFEST))
    items = [json.loads(line) for line in (root / ITEMS).read_text().splitlines()]
    return manifest, stored, items
