"""Two general, instance-local stages over the released 2df selector.

The typed-name bridge consumes only an existing, source-bound OCR line. The
style guard changes ordering only when the challenger has category/style text
but no identifying text and a distinct label/context pair agrees otherwise.
No OCR, catalogue admission, pool, model weights or trained feature is changed.
"""
from collections import Counter
from copy import deepcopy

from rshb_vine.generic_core_name_v1.policy import _member_coverage
from rshb_vine.learned_selection_features import _candidate_key
from rshb_vine.ocr_candidate_repair_v1.selection import _relabel
from rshb_vine.ocr_candidate_repair_v1 import discriminator as D
from rshb_vine.system_selection_v4 import features as V4, text
from rshb_vine.systemic_ranking_v2 import evidence as E
from rshb_vine.systemic_ranking_v2.selection import feature_digest

NAME_FEATURES = ('name.read_w','name.read_g.v','name.read_g.p','name.exclusive_w','name.fuzzy_w')
VISUAL_RR = tuple(f'vis.{channel}.rr' for channel in V4.CHANNELS)
IDENTITY = ('prod.read_w','name.read_w','name.exclusive_w','series.read_w',
            'prod.phrase','name.phrase','typ.grape_blend.support_g.v','typ.grape_blend.support_g.p')
STYLE = tuple(f'typ.{role}.support_g.{reader}' for role in ('color','sugar','style') for reader in E.READERS)
RULE = {'version':'source-bound-typed-name-and-style-only-visual-v1',
        'parent':'generic-core-name-query-match-v1 / E3 d006 / 5c0be',
        'typed_alias':'commercial-name grape atom, same canonical existing lexicon key, single-token OCR line, '
                      'same reader and label crop as another read core-name token; direct name read absent',
        'glyph_core':'existing all-Latin visual glyph conversion then existing one-fuzzy-edit matcher, core name token length>=5; only same label crop/reader as source-bound core+single-grape read; never exclusive',
        'post_veto':'only frozen control fallback caused exactly by explicit grape conflict; rank existing same-producer pool by unchanged score among source-bound typed+glyph alternatives and accept only through frozen resolver/I',
        'visual_guard':'distinct B3 label/context rank1 agrees; challenger not stronger in any visual rank, '
                       'has only color/sugar/style support and no producer/name/series/grape support; '
                       'agreed candidate has no extra contradiction',
        'preserved':'original OCR and provenance, visual/pool/catalogue/weights, typed support, all non-name features, '
                    'existing product resolver/I/T/guard and post layout'}


def _source(record):
    bbox=record.get('crop_bbox')
    if record.get('crop_source')!='label_view_crop' or not isinstance(bbox,list) or len(bbox)!=4:
        return None
    return (record.get('reader'),record['crop_source'],tuple(bbox),record.get('rotation'))


def _entity_key(lexicon, tokens):
    found=lexicon.entities(tuple(tokens))['grape_blend']
    if len(found)!=1:return None
    item=found[0]
    if (item['start'],item['end'])!=(0,len(tokens)) or item['mapping']!='alias' or item['match_kind'] not in ('exact','homoglyph'):
        return None
    return item['key']


def _line_sources(line, provenance):
    output={}
    for i in line['observation_ids']:
        row=provenance[i]
        source=_source(row)
        score=row.get('native_score')
        if source is not None and isinstance(score,(int,float)) and not isinstance(score,bool) and score>0:
            reader=E.READER_SHORT.get(E.E1.READER_TAGS.get(row['reader']))
            if reader:
                output[(source,reader)]=max(output.get((source,reader),0.),float(score))
    return output


def _rerun_identity(selection,out,call,request):
    """The frozen resolver and I stage materialize a changed raw winner."""
    resolver=selection.legacy.resolver
    if not hasattr(resolver,'frozen'):
        raise RuntimeError('Current 2df I resolver is absent')
    out['proposal']=resolver.frozen.resolve(out['base'],out['raw_proposal'])
    stage=next((s for s in selection.stages if s.trace_key=='cross_script_identity'),None)
    if stage is None:raise RuntimeError('Current 2df I stage is absent')
    out=stage.apply(selection,out,call,request)
    return out


class TypedNameAliasStage:
    trace_key='typed_name_alias_v1'
    position='pre_guard'
    identity={'stage':'source-bound-typed-name-alias-v1','rule':RULE}

    def apply(self,selection,out,call,request):
        base=out['base'];ids=list(out['candidate_ids'])
        if ids!=[c['candidate_id'] for c in base['candidates']]:raise RuntimeError('Typed alias received another candidate pool')
        inner=selection.inner;context,stats=inner.context,inner.stats
        lines=V4._lines(base['query_evidence']['observations']);index=E._Index(lines)
        provenance=call['provenance']
        if len(provenance)!=len(base['query_evidence']['observations']) or any(p is None for p in provenance):
            raise RuntimeError('Typed alias needs complete target-bound OCR provenance')
        grades=E._line_grades(lines,provenance)
        alias_lines={}
        for line in lines:
            if len(line['tokens'])!=1:continue
            key=_entity_key(context.lexicon,line['tokens'])
            if key is not None:
                alias_lines.setdefault(key,[]).append(line)
        per,products={},{}
        for c in base['candidates']:
            cid=c['candidate_id'];per[cid],_=E._members(c,context)
            products[cid]={inner.identity.product_id(slug) for slug in c['card_slugs']}
        claimed={cid:{t.skeletons[0] for m in members.values() for t in m['name']}
                 for cid,members in per.items()}
        canonical_atoms={cid:{key for m in members.values() for token in m['atoms']
                              if (key:=_entity_key(context.lexicon,(token,))) is not None}
                         for cid,members in per.items()}
        new_rows=[];new_evidence=[];links=[];changes=[]
        for i,candidate in enumerate(base['candidates']):
            cid=candidate['candidate_id']
            rivals=[o for o in per if o!=cid and not products[o]&products[cid]]
            rival_tokens=set().union(*(claimed[o] for o in rivals)) if rivals else set()
            rival_atoms=set().union(*(canonical_atoms[o] for o in rivals)) if rivals else set()
            original_names=[];names=[]
            for slug,member in per[cid].items():
                read=_member_coverage(index,grades,member['name'],member['core'],stats.name_weight,
                                      context.generic,Counter(),Counter())
                bridged={}
                glyph_ids=set()
                def with_exclusive(value,bridged_keys,glyph_tokens):
                    exclusive=sum(token_row['weight'] for token_row,token in zip(value['tokens'],member['name'])
                                  if any(token_row['grades'].values()) and token.skeletons[0] not in rival_tokens
                                  and id(token) not in glyph_tokens
                                  and (id(token) not in bridged_keys or bridged_keys[id(token)] not in rival_atoms))
                    return dict(value,slug=slug,exclusive=exclusive,atoms=[t.forms[0] for t in member['atoms']])
                original_names.append(with_exclusive(read,{},set()))
                adjusted=deepcopy(read)
                core_sources=set()
                for token,token_row in zip(member['name'],adjusted['tokens']):
                    if not any(token is part for part in member['core']) or not any(token_row['grades'].values()):continue
                    for lid in token_row['lines']:
                        for source_reader in _line_sources(lines[lid],provenance):core_sources.add(source_reader[0])
                if core_sources:
                    claims=member['typed']['grape_blend']['keys']
                    claim_keys={k['key'] for k in claims if k.get('mapping')=='alias'}
                    # A blend list is not a commercial-name reading of one grape.
                    if len(claim_keys)==1:
                        used_lines=set()
                        typed_sources=set()
                        for token,token_row in zip(member['name'],adjusted['tokens']):
                            if not any(token is part for part in member['atoms']) or any(token_row['grades'].values()):continue
                            key=_entity_key(context.lexicon,(token,))
                            if key is None or key not in claim_keys:continue
                            matches={}
                            matched_lines=set()
                            for line in alias_lines.get(key,[]):
                                if line['line_id'] in used_lines:continue
                                for (source,reader),score in _line_sources(line,provenance).items():
                                    if source in core_sources:
                                        matches[reader]=max(matches.get(reader,0.),score)
                                        matched_lines.add(line['line_id'])
                                        typed_sources.add(source)
                            if not matches:continue
                            used_lines.update(matched_lines)
                            bridged[id(token)]=key
                            weight=stats.name_weight(token)
                            total=sum(stats.name_weight(t) for t in member['name'])
                            adjusted['cover']+=weight/total
                            adjusted['read_w']+=weight
                            if token_row['fuzzy_only']:
                                adjusted['fuzzy_w']-=weight
                                token_row['fuzzy_only']=False
                            for reader,score in matches.items():
                                adjusted[f'read_g.{reader}']+=weight*score
                                token_row['grades'][reader]=score
                            token_row['lines']=sorted(matched_lines)
                            links.append(dict(candidate_id=cid,slug=slug,claim_token=token.forms[0],
                                              canonical_grape_key=key,reader_grades=matches,lines=sorted(matched_lines),
                                              source='same_reader_same_label_crop_as_read_core_name',
                                              kind='typed_grape_atom'))
                        if typed_sources:
                            for token,token_row in zip(member['name'],adjusted['tokens']):
                                if (not any(token is part for part in member['core']) or
                                        any(token_row['grades'].values()) or len(token.forms[0])<5):
                                    continue
                                matched_lines=set();matches={}
                                for line in lines:
                                    if len(line['tokens'])!=1 or line['line_id'] in used_lines:continue
                                    raw=line['tokens'][0].raw
                                    if (not raw.isascii() or not raw.isalpha() or
                                            any(ch not in text._TO_CYR for ch in raw) or
                                            text.token_match(line['tokens'][0],token.forms[0]) is not None):
                                        continue
                                    converted=text.tokenize(''.join(text._TO_CYR[ch] for ch in raw))
                                    if len(converted)!=1 or text.token_match(converted[0],token.forms[0])!='fuzzy':
                                        continue
                                    for (source,reader),score in _line_sources(line,provenance).items():
                                        if source in typed_sources:
                                            matches[reader]=max(matches.get(reader,0.),score)
                                            matched_lines.add(line['line_id'])
                                if not matches:continue
                                used_lines.update(matched_lines)
                                glyph_ids.add(id(token))
                                weight=stats.name_weight(token)
                                total=sum(stats.name_weight(t) for t in member['name'])
                                adjusted['cover']+=weight/total
                                adjusted['read_w']+=weight
                                if token_row['fuzzy_only']:
                                    adjusted['fuzzy_w']-=weight
                                    token_row['fuzzy_only']=False
                                for reader,score in matches.items():
                                    adjusted[f'read_g.{reader}']+=weight*score
                                    token_row['grades'][reader]=score
                                token_row['lines']=sorted(matched_lines)
                                links.append(dict(candidate_id=cid,slug=slug,claim_token=token.forms[0],
                                                  reader_grades=matches,lines=sorted(matched_lines),
                                                  source='same_reader_same_label_crop_as_typed_grape_and_core_name',
                                                  kind='core_name_glyph_fuzzy'))
                names.append(with_exclusive(adjusted,bridged,glyph_ids))
            keys=('slug','cover','read_w','exclusive','tokens','atoms','read_g.v','read_g.p')
            projected=lambda values:[{key:value[key] for key in keys} for value in values]
            if projected(original_names)!=out['evidence'][i]['name']:
                raise RuntimeError('Typed alias lost exact current2df name evidence: '+cid)
            def fields(values):
                best=max(values,key=E._rank,default=None) or E._coverage(index,grades,[],stats.name_weight)
                return {'name.read_w':E._cap(best['read_w']),
                        'name.read_g.v':E._cap(best['read_g.v']),'name.read_g.p':E._cap(best['read_g.p']),
                        'name.exclusive_w':E._cap(max((n['exclusive'] for n in values),default=0.)),
                        'name.fuzzy_w':E._cap(max((n['fuzzy_w'] for n in values),default=0.))}
            before=out['rows'][i]
            if any(before[k]!=v for k,v in fields(original_names).items()):
                raise RuntimeError('Typed alias lost exact current2df name features: '+cid)
            update=fields(names);after=dict(before,**update)
            diff={k:[before[k],after[k]] for k in NAME_FEATURES if before[k]!=after[k]}
            if diff:changes.append(dict(candidate_id=cid,features=diff))
            new_rows.append(after);new_evidence.append(dict(out['evidence'][i],name=projected(names)))
        trace=dict(rule=RULE,applied=bool(changes),links=links,changes=changes,
                   before=dict(raw=out['raw_proposal']['representative_slug'],
                               selected=out['proposal']['representative_slug'],feature_digest=out['feature_digest']))
        if new_evidence!=out['evidence']:
            out['evidence_before_typed_name_alias']=out['evidence'];out['evidence']=new_evidence
        if changes:
            out['rows_before_typed_name_alias']=out['rows'];out['raw_proposal_before_typed_name_alias']=out['raw_proposal']
            out['proposal_before_typed_name_alias']=out['proposal'];out['rows']=new_rows
            out['feature_digest']=feature_digest(new_rows,ids)
            injected={_candidate_key(slug,selection.registry.cards) for slug in out['ocr_candidate_injection']['injected']}
            raw=inner._propose(base,out['v4'],new_rows,call['control_slug']);_relabel(raw,injected)
            out['raw_proposal']=raw
            out=_rerun_identity(selection,out,call,request)
        resolution=out['proposal'].get('existing_evidence_resolution') or {}
        fallback=dict(applied=False,reason='not_exact_grape_conflict_control_fallback',
                      blocked_top=out['raw_proposal']['representative_slug'],
                      blocked_reasons=list(resolution.get('reasons') or []),candidates=[])
        if (resolution.get('blocked') is True and
                set(resolution.get('reasons') or [])=={'grape:explicit_conflict'} and
                resolution.get('selected')==resolution.get('control')==call['control_slug']):
            control=next((i for i,c in enumerate(base['candidates'])
                          if call['control_slug'] in c['card_slugs']),None)
            if control is None:
                raise RuntimeError('Existing resolver control absent from unchanged pool')
            control_keys=set(out['evidence'][control]['producer_keys'])
            evidence_by_candidate={}
            for link in links:
                evidence_by_candidate.setdefault(link['candidate_id'],set()).add(link['kind'])
            ranked={row['candidate_id']:row for row in out['raw_proposal']['ranked_candidates']}
            eligible=[]
            for i,candidate in enumerate(base['candidates']):
                cid=candidate['candidate_id']
                if cid==out['candidate_ids'][control] or not {
                        'typed_grape_atom','core_name_glyph_fuzzy'}<=evidence_by_candidate.get(cid,set()):
                    continue
                if not control_keys or not control_keys & set(out['evidence'][i]['producer_keys']):
                    continue
                if any(out['rows'][i][f'typ.contra_verified_g.{r}']>0 for r in E.READERS):
                    continue
                row=ranked.get(cid)
                if row is not None:
                    eligible.append(row)
            eligible.sort(key=lambda row:(-row['score'],row['candidate_id']))
            fallback['candidates']=[dict(candidate_id=row['candidate_id'],score=row['score'],
                                         original_rank=row['rank']) for row in eligible]
            if not eligible:
                fallback['reason']='no_source_bound_compatible_alternate'
            elif len(eligible)>1 and eligible[0]['score']==eligible[1]['score']:
                fallback['reason']='ambiguous_equal_score_alternates'
            else:
                chosen=eligible[0]
                promoted=deepcopy(out['raw_proposal'])
                for row in promoted['ranked_candidates']:row['learned_rank']=row['rank']
                promoted['ranked_candidates'].sort(key=lambda row:row['candidate_id']!=chosen['candidate_id'])
                for rank,row in enumerate(promoted['ranked_candidates'],1):row['rank']=rank
                top=promoted['ranked_candidates'][0]
                promoted.update(candidate_id=top['candidate_id'],product_id=top['product_id'],
                                representative_slug=top['representative_slug'],best_candidate=top['representative_slug'],
                                representative_source=top['representative_source'],score=top['score'],
                                score_margin=None,reason='source_bound_compatible_alternate_v1',
                                exact_slug=None,probability=None,release_admitted=False)
                old_raw,old_proposal=out['raw_proposal'],out['proposal']
                out['raw_proposal']=promoted
                out=_rerun_identity(selection,out,call,request)
                accepted=(out['proposal']['representative_slug']==top['representative_slug'] and
                          not (out['proposal'].get('existing_evidence_resolution') or {}).get('blocked'))
                fallback.update(attempted=top['representative_slug'],accepted=accepted,
                                resolver_reason=(out['proposal'].get('existing_evidence_resolution') or {}).get('reason'))
                if accepted:
                    out['raw_proposal_before_compatible_alternate']=old_raw
                    out['proposal_before_compatible_alternate']=old_proposal
                    fallback.update(applied=True,reason='existing_resolver_accepted_source_bound_alternate')
                else:
                    out['raw_proposal'],out['proposal']=old_raw,old_proposal
                    # Restore I's trace for the actual published proposal, too.
                    stage=next(s for s in selection.stages if s.trace_key=='cross_script_identity')
                    out=stage.apply(selection,out,call,request)
                    fallback['reason']='existing_resolver_rejected_alternate'
        trace['post_veto_compatible_alternate']=fallback
        trace['after']=dict(raw=out['raw_proposal']['representative_slug'],
                            selected=out['proposal']['representative_slug'],feature_digest=out['feature_digest'])
        out[self.trace_key]=trace
        return out


class StyleOnlyVisualGuardStage:
    trace_key='style_only_visual_guard_v1'
    position='pre_guard'
    identity={'stage':'style-only-visual-agreement-v1','rule':RULE}

    def __init__(self,references):
        if len(references)!=4314:raise ValueError('Current pinned gallery is not 4314 views')
        self.references=references

    def apply(self,selection,out,call,request):
        raw=out.get('raw_proposal');trace=dict(rule=RULE,applied=False,reason='no_qualified_style_only_override')
        if not raw or not raw.get('ranked_candidates'):
            trace['reason']='empty_pool';out[self.trace_key]=trace;return out
        agreed=D.agreed_visual(out['evidence'])
        if agreed is None:
            trace['reason']='no_agreed_visual';out[self.trace_key]=trace;return out
        incumbent,channels=agreed
        winner=raw['ranked_candidates'][0]['input_pool_index']
        if winner==incumbent:
            trace['reason']='winner_is_agreed_visual';out[self.trace_key]=trace;return out
        if not {'B3_label','B3_context'}<=set(channels):
            trace['reason']='no_B3_label_context_pair';out[self.trace_key]=trace;return out
        visual=out['base']['candidates'][incumbent]['provenance']['visual']
        pair=[v for v in visual if v['channel'] in ('B3_label','B3_context') and v['rank']==1]
        if (len(pair)!=2 or any(type(v.get('raw',{}).get('reference_index')) is not int or
                               type(v.get('raw',{}).get('query_view_index')) is not int for v in pair) or
                len({v['raw']['reference_index'] for v in pair})!=2 or
                len({v['raw']['query_view_index'] for v in pair})!=2):
            trace['reason']='B3_views_or_references_not_distinct';out[self.trace_key]=trace;return out
        target=request.target(str(call['raw_visual']['instance_id'])) if request is not None else None
        cross=((target or {}).get('retrieval') or {}).get('crossview_evidence') or {}
        label=cross.get('label_query_global_top1') or {}
        context=cross.get('context_query_global_top1') or {}
        views=call['raw_visual'].get('views') or []
        by_channel={v['channel']:v['raw'] for v in pair}
        bound=True
        for channel,entry,kind in (('B3_label',label,'front_label'),('B3_context',context,'context')):
            raw_hit=by_channel[channel]
            index=entry.get('query_view_index')
            ref=entry.get('reference_index')
            source_sha=entry.get('reference_source_sha256')
            valid_ref=type(ref) is int and 0<=ref<len(self.references)
            actual_ref=self.references[ref] if valid_ref else {}
            if (entry.get('slug') not in out['base']['candidates'][incumbent]['card_slugs'] or
                    entry.get('reference_kind')!=kind or not valid_ref or
                    actual_ref.get('slug')!=entry.get('slug') or actual_ref.get('kind')!=kind or
                    actual_ref.get('image_sha256')!=source_sha or
                    ref!=raw_hit.get('reference_index') or
                    index!=raw_hit.get('query_view_index') or type(index) is not int or
                    not 0<=index<len(views) or entry.get('query_view')!=views[index] or
                    not isinstance(source_sha,str) or len(source_sha)!=64 or
                    any(c not in '0123456789abcdef' for c in source_sha)):
                bound=False
        if (not bound or cross.get('policy')!='same_physical_instance_reciprocal_gallery_kinds_v3' or
                cross.get('gallery_rows')!=4314 or cross.get('same_exact_card') is not True or
                cross.get('query_geometry')!='same_frame_label_within_context' or
                label.get('query_view_index')==context.get('query_view_index') or
                label.get('reference_index')==context.get('reference_index')):
            trace['reason']='B3_pair_not_source_bound';out[self.trace_key]=trace;return out
        x,y=out['rows'][incumbent],out['rows'][winner]
        non_style_advantages=[]
        for key in E.FEATURE_NAMES:
            if key in STYLE:continue
            sign=E.SIGNS[key]
            if ((sign>0 and y[key]>x[key]) or (sign<0 and y[key]<x[key]) or
                    (sign==0 and y[key]!=x[key])):
                non_style_advantages.append(key)
        if (any(y[k]>0 for k in IDENTITY) or non_style_advantages or
                not any(y[k]>x[k] for k in STYLE)):
            trace['reason']='challenger_has_identity_or_other_advantage_or_no_style_edge'
            trace['non_style_advantages']=non_style_advantages
            out[self.trace_key]=trace;return out
        cid=out['candidate_ids'][incumbent]
        top=next((r for r in raw['ranked_candidates'] if r['candidate_id']==cid),None)
        if top is None:raise RuntimeError('Visual incumbent absent from unchanged candidate pool')
        new=deepcopy(raw)
        for row in new['ranked_candidates']:row['learned_rank']=row['rank']
        new['ranked_candidates'].sort(key=lambda r:r['candidate_id']!=cid)
        for rank,row in enumerate(new['ranked_candidates'],1):row['rank']=rank
        top=new['ranked_candidates'][0]
        new.update(candidate_id=top['candidate_id'],product_id=top['product_id'],
                   representative_slug=top['representative_slug'],best_candidate=top['representative_slug'],
                   representative_source=top['representative_source'],score=top['score'],score_margin=None,
                   reason='style_only_visual_agreement_v1',exact_slug=None,probability=None,release_admitted=False)
        trace.update(applied=True,reason='style_only_text_cannot_override_distinct_B3_label_context',
                     incumbent=cid,challenger=out['candidate_ids'][winner],channels=channels,
                     reference_indices=[v['raw']['reference_index'] for v in pair],
                     query_view_indices=[v['raw']['query_view_index'] for v in pair],
                     style_advantages={k:[x[k],y[k]] for k in STYLE if y[k]>x[k]},
                     source_bound_crossview_policy=cross['policy'],
                     before=raw['representative_slug'],after=top['representative_slug'])
        out['raw_proposal_before_style_only_guard']=raw;out['proposal_before_style_only_guard']=out['proposal']
        out['raw_proposal']=new
        out=_rerun_identity(selection,out,call,request)
        out[self.trace_key]=trace
        return out
