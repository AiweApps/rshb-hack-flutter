"""Role-aware catalog claims for product-first; no selection or implicit merges."""
import re
from copy import deepcopy
from rshb_vine.typed_catalog_lexicon import normalize
from rshb_vine.resolution.identity import values, GRAPES, COLOR, SUGAR

ROLES = {'producer':'manufacturer','product_name':'commercial_name','series':'series',
         'grapes':'grape_blend','wine_color':'color','sweetness':'sugar',
         'sparkling_style':'style'}


def normalized_values(role, value):
    if value is None:
        return []
    raw = value if isinstance(value,list) else [value]
    if role in ('manufacturer','commercial_name','series','visible_brand'):
        # Keep numbers in the source name: e.g. a commemorative name is not
        # automatically a vintage. Selector must treat year-like tokens separately.
        return sorted({normalize(str(v)) for v in raw} - {''})
    return sorted({str(v) for v in raw if v is not None and str(v)})


def normalize_card_claims(record, brand_aliases, catalog_sha):
    result = {'slug':record['slug'],'product_id':record['product_id'],
              'binding_status':record['binding_status'],'roles':{},
              'vintage':deepcopy(record['profile'].get('vintage',{}))}
    profile = record['profile']['product']
    for field, role in ROLES.items():
        prop = profile.get(field,{})
        claims = []
        for claim in prop.get('claims',[]):
            raw=claim.get('value')
            # Raw additions lack resolved comparisons; preserve catalog assertions
            # as soft claims, never silently upgrade to source_verified.
            value=raw
            if record['profile_origin']=='raw_catalog_claims_only':
                mapping={'grape_blend':GRAPES,'color':COLOR,'sugar':SUGAR}.get(role)
                if mapping:
                    found=values(str(raw),mapping)
                    value=sorted(found) if found else None
            claims.append({'raw':deepcopy(claim),'normalized':normalized_values(role,value),
                           'status':claim.get('status',prop.get('status','unknown')),
                           'source':deepcopy(claim.get('source',{})),
                           'hard_veto_allowed':False})
        # Conflicted profiles preserve claims but cannot provide resolved evidence.
        disputed=prop.get('status') in ('conflict','unresolved','ambiguous')
        usable=not disputed and (not prop.get('review_required') or record['profile_origin']=='raw_catalog_claims_only')
        result['roles'][role]={'claims':claims,'comparison_allowed':usable,
                               'values':sorted({v for c in claims for v in c['normalized']}) if usable else [],
                               'status':prop.get('status','unknown'),
                               'unknown':not claims or not any(c['normalized'] for c in claims)}
    producer=result['roles']['manufacturer']['values']
    brands=[]
    for item in brand_aliases:
        if item.get('status')=='verified' and normalize(item['producer']) in producer:
            for alias in item['aliases']:
                brands.append({'raw':alias,'normalized':normalize(alias),'status':'source_verified_alias',
                               'source':{'path':'config/producer-brand-aliases.json','sha256':catalog_sha,
                                         'record':deepcopy(item)},'hard_veto_allowed':False})
    result['roles']['visible_brand']={'claims':brands,'values':sorted({x['normalized'] for x in brands}),
                                      'comparison_allowed':True,'unknown':not brands,
                                      'status':'source_verified_alias' if brands else 'unknown'}
    return result
