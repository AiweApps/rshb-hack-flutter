"""Source adapter over saved vino-svoe.ru API bodies: fills only attributes lacking a trusted strict value.

Category/manufacturer/region/grapes/title/color are catalogue assertions of the public site, never
source_verified and never proof of a photo binding. Descriptions contribute only explicit
classification phrases adjacent to the word «вино»; tasting vocabulary is never a sugar claim.
"""
import hashlib
import json
import re
from copy import deepcopy

from rshb_vine.catalog.product_claims import normalized_values
from rshb_vine.io import local_path, read_json, sha256

PARSER_VERSION = 'site-metadata-v1'
COVERAGE = 'runs/site-catalog-audit-20260921/coverage.json'
ACCESS_SUMMARY = 'data/catalog-training-data-v2/site-missing-20260925/summary.json'
API_PREFIX = 'https://vino-svoe.ru/api/wines/'
PAGE_PREFIX = 'https://vino-svoe.ru/wines/'
TRUSTED = {'catalog_asserted', 'source_verified', 'source_verified_alias'}
FILLABLE_REASONS = {'source_absence', 'candidate_only', 'unsupported_value', 'extraction_failure',
                    'card_absent_from_profile_snapshot'}
HELD_REASONS = {'conflict', 'review_required_competing_claims', 'review_required_identity_hold'}
UNSUPPORTED = {'series': 'site_api_has_no_series_field',
               'visible_brand': 'site_api_has_no_visible_brand_field',
               'reference_year': 'site_title_year_is_not_reference_or_photo_year',
               'catalog_vintage': 'site_title_year_not_parsed_without_explicit_vintage_contract',
               'label_color': 'site_api_has_no_label_color_field'}
DESC_ADJ = (r'(?:сухое|полусухое|полусладкое|сладкое|белое|красное|розовое|оранжевое|игристое|'
            r'крепленое|креплёное|ликерное|ликёрное)')
# Same line only: a newline separates award lists and headings from the classification phrase.
DESC_PHRASE = re.compile(r'(?<![\w-])(?:' + DESC_ADJ + r'[ \t,]+){1,3}вино(?![\w-])|(?<![\w-])вино(?:[ \t,]+'
                         + DESC_ADJ + r'){1,3}(?![\w-])', re.I)
SPECIFIC = {'brut': {'extra_brut', 'brut_nature'}}
NEGATION = re.compile(r'(?:^|[^\w])(?:не|ни)[ \t]+$', re.I)


def load_site(root):
    """Verify every cached body against its receipt and the coverage copy; fail closed on any mismatch."""
    coverage = read_json(local_path(root, COVERAGE))
    records, errors = {}, []
    for row in coverage:
        slug, rec = row['slug'], row.get('api_receipt') or {}
        body_path = rec.get('body_path')
        if not body_path:
            errors.append('no api receipt: ' + slug)
            continue
        body = local_path(root, body_path).read_bytes()
        parsed = json.loads(body)
        if (hashlib.sha256(body).hexdigest() != rec['sha256'] or rec['status'] != 200 or len(body) != rec['bytes']
                or parsed != row['site_raw'] or parsed.get('slug') != slug or rec['url'] != API_PREFIX + slug
                or rec['final_url'] != rec['url'] or slug in records):
            errors.append('receipt/body/slug mismatch: ' + slug)
            continue
        records[slug] = {'raw': parsed, 'receipt': deepcopy(rec), 'page_url': row.get('url'),
                         'site_identity_status': row.get('site_identity_status')}
    if errors:
        raise ValueError('site cache verification failed: ' + '; '.join(errors[:5]))
    summary = read_json(local_path(root, ACCESS_SUMMARY))
    access = {}
    for r in summary['results']:
        body = local_path(root, r['body_path']).read_bytes()
        if hashlib.sha256(body).hexdigest() != r['sha256'] or r['url'] != API_PREFIX + r['slug']:
            raise ValueError('access-error receipt mismatch: ' + r['slug'])
        access[r['slug']] = deepcopy(r)
    pins = {p: sha256(local_path(root, p)) for p in (COVERAGE, ACCESS_SUMMARY)}
    return {'records': records, 'access_errors': access, 'pins': pins,
            'verified_bodies': len(records), 'access_error_receipts': len(access)}


def _source(site, kind, field, raw, rule, span=None):
    rec = site['receipt']
    return {'kind': kind, 'path': rec['body_path'], 'sha256': rec['sha256'], 'url': rec['url'],
            'page_url': site['page_url'], 'retrieved_at': rec['retrieved_at'], 'http_status': rec['status'],
            'field': field, 'rule': rule, 'span': span, 'parser_version': PARSER_VERSION,
            'coverage_path': COVERAGE, 'derived': True}


def _claim(value, raw, source):
    return {'normalized': value, 'raw': raw, 'status': 'catalog_asserted', 'tier': 3,
            'source_kind': source['kind'], 'source': source}


def description_phrases(text):
    out = []
    for m in DESC_PHRASE.finditer(text or ''):
        if NEGATION.search(text[max(0, m.start() - 6):m.start()]):
            continue
        out.append({'phrase': m.group(0), 'span': [m.start(), m.end()]})
    return out


def site_claims(attr, site, rules, grape_components):
    """(structured claims, description claims) for one attribute; each carries exact field/span."""
    raw = site['raw']
    structured, described = [], []
    category = (raw.get('category') or {}).get('name') or ''
    if attr in ('sweetness', 'wine_color', 'sparkling_style') and category:
        found = (rules.style_values(category) if attr == 'sparkling_style' else
                 rules.values(category, rules.SWEET if attr == 'sweetness' else rules.COLORS))
        if len(found) == 1:
            structured.append(_claim(sorted(found), category, _source(site, 'site_api_structured', 'category.name', category,
                                                                      'single_explicit_term_in_site_category')))
    elif attr == 'producer' and (raw.get('manufacturer') or {}).get('name'):
        name = raw['manufacturer']['name']
        structured.append(_claim(normalized_values('manufacturer', name), name,
                                 _source(site, 'site_api_structured', 'manufacturer.name', name, 'claims_v1_manufacturer_normalize')))
    elif attr == 'product_name' and raw.get('title'):
        structured.append(_claim(normalized_values('commercial_name', raw['title']), raw['title'],
                                 _source(site, 'site_api_structured', 'title', raw['title'], 'claims_v1_commercial_name_normalize')))
    elif attr == 'region' and (raw.get('region') or {}).get('name'):
        name = raw['region']['name']
        structured.append(_claim([name], name, _source(site, 'site_api_structured', 'region.name', name, 'profile_v1_raw_field_copy')))
    elif attr == 'wine_hue' and raw.get('color'):
        structured.append(_claim([raw['color']], raw['color'],
                                 _source(site, 'site_api_structured', 'color', raw['color'], 'profile_v1_raw_field_copy')))
    elif attr == 'grapes' and raw.get('grapes'):
        names = [g.get('name') for g in raw['grapes'] if g.get('name')]
        if names:
            structured.append(_claim(grape_components(', '.join(names)), names,
                                     _source(site, 'site_api_structured', 'grapes[].name', names, 'profile_v1_grape_components')))
    vocab = {'sweetness': rules.SWEET, 'wine_color': rules.COLORS, 'wine_type': rules.TYPES}.get(attr)
    if vocab:
        text = raw.get('description') or ''
        for p in description_phrases(text):
            found = rules.values(p['phrase'], vocab)
            if len(found) == 1:
                described.append(_claim(sorted(found), p['phrase'],
                                        _source(site, 'site_api_description_explicit', 'description', p['phrase'],
                                                'explicit_wine_classification_phrase_adjacent_to_vino', p['span'])))
    return structured, described


def _distinct(claims):
    return {json.dumps(c['normalized'], ensure_ascii=False, sort_keys=True): c['normalized'] for c in claims}


def _audit_relation(attr, site_value, strict):
    if site_value == strict:
        return 'agrees'
    if [' '.join(str(v).split()) for v in site_value] == [' '.join(str(v).split()) for v in strict]:
        return 'agrees_after_whitespace_normalization'
    if attr == 'grapes' and set(site_value) <= set(strict):
        return 'subset_of_strict'
    if len(site_value) == len(strict) == 1:
        a, b = site_value[0], strict[0]
        if a in SPECIFIC.get(b, ()) or b in SPECIFIC.get(a, ()):
            return 'compatible_specificity_differs'
    return 'differs_audit_only'


def enrich(attr, entry, slug, site_data, rules, grape_components, held_card):
    """Mutates entry only when its strict value is empty and no trusted claim disagrees; returns ledger row."""
    site = site_data['records'].get(slug)
    ledger = {'parser_version': PARSER_VERSION, 'outcome': None, 'reason': None, 'value_before': deepcopy(entry['value']),
              'missing_reason_before': entry['missing_reason'], 'structured_values': [], 'description_values': [],
              'structured_vs_description': None, 'audit_relation': None, 'claims_added': 0, 'source_url': None}
    if attr in UNSUPPORTED:
        ledger.update(outcome='source_field_unsupported', reason=UNSUPPORTED[attr])
        return ledger
    if site is None and entry['value'] is not None:
        ledger.update(outcome='already_trusted_skipped', reason='existing_strict_value_kept_unchanged_no_site_body_for_audit')
        return ledger
    if site is None:
        err = site_data['access_errors'].get(slug)
        if err:
            ledger.update(outcome='source_access_error500' if err['status'] == 500 else 'source_access_error',
                          reason=f"http_{err['status']}_at_{err['retrieved_at']}_not_evidence_of_absence",
                          source_url=err['url'], access_receipt_body_sha256=err['sha256'])
        else:
            ledger.update(outcome='no_cached_source', reason='slug_absent_from_verified_site_cache')
        return ledger
    ledger['source_url'] = site['receipt']['url']
    structured, described = site_claims(attr, site, rules, grape_components)
    s_vals, d_vals = _distinct(structured), _distinct(described)
    ledger['structured_values'] = list(s_vals.values())
    ledger['description_values'] = list(d_vals.values())
    if s_vals and d_vals:
        ledger['structured_vs_description'] = 'agree' if s_vals.keys() == d_vals.keys() else 'disagree'
    if entry['value'] is not None:
        site_value = next(iter(s_vals.values()), None) or (next(iter(d_vals.values())) if len(d_vals) == 1 else None)
        rel = None if site_value is None else _audit_relation(attr, site_value, entry['value'])
        ledger.update(outcome='already_trusted_skipped', reason='existing_strict_value_kept_unchanged', audit_relation=rel,
                      audit_site_value=site_value)
        return ledger
    if not s_vals and not d_vals:
        ledger.update(outcome='source_field_absent', reason='no_explicit_value_in_site_fields')
        return ledger
    if entry['missing_reason'] in HELD_REASONS:
        ledger.update(outcome='unresolved_conflict', reason='existing_' + entry['missing_reason'] + '_kept')
        return ledger
    if site['site_identity_status'] not in (None, 'source_asserted_not_visually_verified'):
        ledger.update(outcome='unresolved_conflict', reason='site_identity_status_' + str(site['site_identity_status']))
        return ledger
    if entry['missing_reason'] not in FILLABLE_REASONS:
        ledger.update(outcome='source_field_unsupported', reason='missing_reason_' + str(entry['missing_reason']) + '_not_fillable')
        return ledger
    if len(s_vals) > 1 or (not s_vals and len(d_vals) > 1):
        ledger.update(outcome='unresolved_conflict', reason='site_values_ambiguous')
        return ledger
    if s_vals and d_vals and ledger['structured_vs_description'] == 'disagree':
        ledger.update(outcome='unresolved_conflict', reason='site_structured_vs_description_disagree')
        return ledger
    (value,) = (s_vals or d_vals).values()
    trusted = [c for c in entry['claims'] if c['status'] in TRUSTED and c['normalized'] and not c.get('superseded_by')]
    if any(c['normalized'] != value for c in trusted):
        ledger.update(outcome='unresolved_conflict', reason='site_value_disagrees_with_existing_trusted_claim')
        return ledger
    new = structured + described
    start = len(entry['claims'])
    entry['claims'].extend(new)
    basis = [start + i for i, c in enumerate(new) if c['normalized'] == value]
    dissent = [c for c in entry['claims'][:start] if c['status'] not in TRUSTED and c['normalized']
               and c['normalized'] != value and not (attr == 'grapes' and set(c['normalized']) <= set(value))]
    outcome = 'filled_from_structured_field' if s_vals else 'filled_from_explicit_description'
    entry.update(value=value, status='catalog_asserted', basis_claims=basis, comparison_allowed=True,
                 resolution='site_api_' + ('structured' if s_vals else 'description') + '_fill_of_untrusted_attribute',
                 missing_reason=None,
                 review_flag={'reason': 'untrusted_candidate_disagreement', 'upstream_comparison_allowed': entry['upstream_comparison_allowed'],
                              'dissenting_values': sorted({json.dumps(c['normalized'], ensure_ascii=False) for c in dissent}),
                              'dissenting_source_kinds': sorted({c['source_kind'] or '' for c in dissent})} if dissent else None)
    if held_card:
        entry['downstream_hold'] = 'catalog_resolution_excluded_from_retrieval'
    ledger.update(outcome=outcome, reason='filled_untrusted_' + ledger['missing_reason_before'], claims_added=len(new),
                  value_after=deepcopy(value))
    return ledger


def _field_value(raw, field):
    if field == 'grapes[].name':
        return [g.get('name') for g in raw.get('grapes') or [] if g.get('name')]
    value = raw
    for part in field.split('.'):
        value = (value or {}).get(part)
    return value


def claim_errors(claim, slug, site_data):
    """Re-derive one site claim from the verified body; returns a list of problems."""
    site, s = site_data['records'].get(slug), claim['source']
    if site is None:
        return ['site claim without verified cached body']
    errs = []
    if (s['path'], s['sha256'], s['url'], s['parser_version']) != (site['receipt']['body_path'], site['receipt']['sha256'],
                                                                    site['receipt']['url'], PARSER_VERSION):
        errs.append('site claim receipt pointer differs')
    if claim['status'] != 'catalog_asserted':
        errs.append('site claim not catalog_asserted')
    if s['kind'] == 'site_api_structured':
        if _field_value(site['raw'], s['field']) != claim['raw']:
            errs.append('structured site claim raw differs from body field')
    elif s['kind'] == 'site_api_description_explicit':
        a, b = s['span']
        text = site['raw'].get('description') or ''
        if text[a:b] != claim['raw'] or not DESC_PHRASE.fullmatch(claim['raw']):
            errs.append('description span does not reproduce explicit phrase')
    else:
        errs.append('unknown site claim kind')
    return errs
