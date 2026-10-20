"""Isolated local per-target nonwine refusal after TiltLocal; parent recognition and frozen sources untouched."""
import time
from pathlib import Path
from rshb_vine.io import digest,read_json,seal,sha256
from rshb_vine.preprocessing import decode,InvalidImage
from rshb_vine.nonwine_local_v1 import classifier as C

KIND='nonwine-local-v1-candidate'
DECISION='not_wine'
REASON='nonwine_beverage_type'
SOURCES=('rshb_vine/nonwine_local_v1/__init__.py','rshb_vine/nonwine_local_v1/classifier.py',
         'rshb_vine/nonwine_local_v1/runtime.py','scripts/run_nonwine_local.py')
PARENT_PINS={
    'config/recognition-current.json':'0dd04c9771f8ce227ba13b26c76273a303d3f4330159be4a2e38b6535b1207a9',
    'rshb_vine/recognition_factory.py':'6e42408013cd000363db89c8f4c93fffaa11c85a333fe982428fa5d5c82adeee',
    'rshb_vine/orientation_local_v1/runtime.py':'71a549e13a7e48b690603a4782ac4d7c265c2eff79355fd4cd31755a473449b6',
    'rshb_vine/tilt_local_v1/runtime.py':'4e72ff4bc8155783de3a6207e3908afd129fc81cfccd06f65fba8299f9cc1401',
}
ROOT=Path(__file__).resolve().parents[2]
IMPORTED={p:sha256(ROOT/p) for p in SOURCES}
WITHDRAWN_TOP_LEVEL=('slug','best_candidate','probability_correct','ranked_candidates')
CURRENT_PRODUCT_FIELDS=('product_resolution','selected_product_output','selection_score')
SPEC={
    'scope':'each physical target separately; a nonwine neighbour never rejects the frame or another target',
    'crops':'target bottle_bbox and label bbox in EXIF-oriented original pixels (after TiltLocal inverse mapping)',
    'criterion':C.CRITERION,
    'scores':'relative_category_scores are an uncalibrated softmax over category logits, not a probability of correctness',
    'targets':'rejected targets move from targets[] to nonwine_local_v1.rejected_targets (raw, diagnostic only)',
    'contract':'rejected bottles keep geometry/select_roi; card/product_id/full_pass_card cleared; target_decision=not_wine',
    'roi_link':'a contract bottle carrying a roi_pass card follows the verdict of that roi-pass target',
    'top_level':'all targets rejected -> decision not_wine and no published card; a published card that no kept target '
                'carries is withdrawn; otherwise the parent publication is unchanged',
    'product_outputs':'on withdrawal %s move to nonwine_local_v1.parent_product_outputs and become null; otherwise their '
                      'rows of rejected instance_ids move there' % ', '.join(CURRENT_PRODUCT_FIELDS),
    'parent_diagnostics':'explicit stage/history blocks keep the parent raw values and are not product outputs',
    'timing':'target_contract.timing_ms.total and timing_ms.total include the classifier; parent totals kept',
}


def verify_parent(root):
    current={p:sha256(root/p) for p in PARENT_PINS}
    if current!=PARENT_PINS:
        raise RuntimeError('Pinned parent sources differ: '+', '.join(p for p in PARENT_PINS if current[p]!=PARENT_PINS[p]))


def verify_model(root,files):
    manifest=read_json(root/'models/manifest.json')['files']
    expected={name:manifest.get('encoder/'+name) for name in files}
    if expected!=files:raise RuntimeError('Classifier weights differ from models/manifest.json')


def _crop(image,box):
    if not box:return None
    x0,y0,x1,y1=[int(round(v)) for v in box]
    x0,y0=max(0,x0),max(0,y0);x1,y1=min(image.width,x1),min(image.height,y1)
    return image.crop((x0,y0,x1,y1)) if x1-x0>=8 and y1-y0>=8 else None


class NonwineLocal:
    def __init__(self,root=ROOT,device=None,parent=True):
        import torch
        root=Path(root).resolve()
        verify_parent(root)
        if parent:
            from rshb_vine.tilt_local_v1.runtime import TiltLocal
            self.inner=TiltLocal(root)
            verify_parent(root)
        else:self.inner=None
        device=device or ('mps' if torch.backends.mps.is_available() else 'cpu')
        self.classifier=C.BeverageClassifier(root,device)
        verify_model(root,self.classifier.files_sha256)
        current={p:sha256(root/p) for p in SOURCES}
        if current!=IMPORTED:raise RuntimeError('Nonwine sources changed during model load')
        self.descriptor=seal({'kind':KIND,'local_only':True,'sources_sha256':current,'parent_pins':PARENT_PINS,
            'parent_descriptor':self.inner.descriptor['checksum'] if parent else None,
            'parent_runtime':self.inner.manifest['checksum'] if parent else None,
            'classifier':{'model':'models/encoder (pretrained SigLIP2 base patch16-384, frozen, text+vision towers)',
                          'files_sha256':self.classifier.files_sha256,'models_manifest_checksum':read_json(root/'models/manifest.json')['checksum'],
                          'device':device,'logit_scale':self.classifier.scale,'logit_bias':self.classifier.bias,
                          'letterbox':'ImageOps.pad white 384x384','categories':C.CATEGORIES,'crops':list(C.CROPS),
                          'wine_relative_score_max':C.WINE_PROBABILITY_MAX},
            'spec':SPEC,'decision':DECISION,'reason':REASON,'calibrated':False,'fit':False})
        self.profile={'kind':KIND,'checksum':self.descriptor['checksum']}
        self.manifest=seal({'kind':'nonwine-local-v1-runtime','runtime_descriptor_checksum':self.profile['checksum'],
                            'parent_runtime':self.descriptor['parent_runtime'],'profile_checksum':self.profile['checksum']})

    def _judge(self,image,cache,bottle_box,label_box):
        key=(tuple(bottle_box or ()),tuple(label_box or ()))
        if key not in cache:
            crops={'bottle':_crop(image,bottle_box),'label':_crop(image,label_box)}
            present=[k for k,v in crops.items() if v is not None]
            rows=dict(zip(present,self.classifier.classify([crops[k] for k in present]))) if present else {}
            cache[key]={'reject':C.decide({k:rows.get(k) for k in C.CROPS}),'crops':{k:{
                'bbox':list(bottle_box if k=='bottle' else label_box),'top_category':r['top'],
                'relative_category_scores':{c:round(v,5) for c,v in r['probabilities'].items()},
                'category_logits':{c:round(v,4) for c,v in r['category_logits'].items()}} for k,r in rows.items()},
                'calibrated':False}
        return cache[key]

    def recognize(self,data,roi=None,bottles='addressed'):
        started=time.perf_counter()
        result=self.inner.recognize(data,roi,bottles)
        if result.get('decision')=='invalid_image':return result
        return self.refine(result,data,(time.perf_counter()-started)*1000)

    def refine(self,result,data,parent_ms=None):
        started=time.perf_counter()
        try:image,_=decode(data)
        except InvalidImage:return result
        block=result.get('target_contract')
        targets=list(result.get('targets') or [])
        cache={}
        verdicts={str(t['instance_id']):self._judge(image,cache,t.get('bottle_bbox'),t.get('bbox')) for t in targets}
        rejected_ids={i for i,v in verdicts.items() if v['reject']}
        entries=list((block or {}).get('bottles') or [])
        observation=(block or {}).get('roi_observation')
        entry_verdicts={}
        for e in entries+([observation] if observation else []):
            linked=e.get('roi_pass_instance_id')
            if e.get('card_source')=='roi_pass' and linked is not None and str(linked) in verdicts:
                entry_verdicts[e['instance_id']]=dict(verdicts[str(linked)],source='roi_pass_target',roi_pass_instance_id=str(linked))
            else:
                entry_verdicts[e['instance_id']]=dict(self._judge(image,cache,e.get('bottle_bbox'),e.get('label_bbox')),source='own_geometry')
        parent_published={k:result.get(k) for k in ('decision',*WITHDRAWN_TOP_LEVEL,'requires_target_selection')}
        withdrawn=[]
        for e in entries+([observation] if observation else []):
            if not entry_verdicts[e['instance_id']]['reject']:continue
            withdrawn.append({'instance_id':e['instance_id'],'card':e.get('card'),'product_id':e.get('product_id'),
                              'full_pass_card':e.get('full_pass_card'),'target_decision':e.get('target_decision')})
            e.update(card=None,product_id=None,target_decision=DECISION,reasons=list(e.get('reasons') or [])+[REASON],
                     nonwine={'category':self._category(entry_verdicts[e['instance_id']]),'calibrated':False})
            if 'full_pass_card' in e:e.update(full_pass_card=None,full_pass_product_id=None)
        kept=[t for t in targets if str(t['instance_id']) not in rejected_ids]
        removed=[t for t in targets if str(t['instance_id']) in rejected_ids]
        result['targets']=kept
        kept_cards={(t.get('retrieval') or {}).get('best_candidate') for t in kept}
        status='unchanged'
        if removed and not kept:
            status='all_targets_not_wine'
            result.update(decision=DECISION,slug=None,best_candidate=None,probability_correct=None,ranked_candidates=[],
                          requires_target_selection=False)
        elif removed and result.get('best_candidate') is not None and result['best_candidate'] not in kept_cards:
            status='published_card_from_nonwine_target_withdrawn'
            result.update(decision='insufficient_evidence',slug=None,best_candidate=None,probability_correct=None,
                          ranked_candidates=[],requires_target_selection=len(kept)>1)
        elif removed:status='nonwine_targets_removed_parent_publication_kept'
        if removed:result['reasons']=list(result.get('reasons') or [])+[REASON]
        parent_products={}
        for name in CURRENT_PRODUCT_FIELDS:
            if name not in result:continue
            value=result[name]
            if status in ('all_targets_not_wine','published_card_from_nonwine_target_withdrawn'):
                parent_products[name]=value;result[name]=None
            elif removed and isinstance(value,dict) and isinstance(value.get('targets'),list):
                moved=[r for r in value['targets'] if isinstance(r,dict) and str(r.get('instance_id')) in rejected_ids]
                if moved:
                    parent_products[name]={'targets':moved}
                    result[name]=dict(value,targets=[r for r in value['targets'] if r not in moved])
        if block is not None:
            listed=[e for e in entries if not entry_verdicts[e['instance_id']]['reject']]
            primary_entry=next((e for e in entries+([observation] if observation else [])
                                if e['instance_id']==block.get('primary_instance_id')),None)
            if primary_entry is not None and primary_entry.get('target_decision')==DECISION:block['suggested_card']=None
            if entries and not listed and block.get('primary_basis')!='explicit_roi':
                block.update(primary_instance_id=None,primary_basis='no_wine_target',suggested_card=None,
                             requires_target_selection=False)
                for e in entries:e['primary']=False
            block['nonwine_parent_published']=block.get('published')
            block['published']={'card':result.get('best_candidate'),'decision':result.get('decision'),'slug':result.get('slug'),
                                'source':'nonwine_local_v1' if removed or withdrawn else 'parent_response_unchanged'}
            block['nonwine_parent_targets_digest']=block.get('result_targets_digest')
            block['result_targets_digest']=digest(result.get('targets'))
            block['nonwine_parent_profile_checksum']=block.get('profile_checksum')
            block['profile_checksum']=self.profile['checksum']
        classify_ms=(time.perf_counter()-started)*1000
        for timing in (result.get('timing_ms'),(block or {}).get('timing_ms')):
            if isinstance(timing,dict):
                timing['nonwine_parent_total']=timing.get('total')
                timing['nonwine_classify']=classify_ms
                timing['total']=(parent_ms if parent_ms is not None else timing.get('total') or 0)+classify_ms
        result['nonwine_local_v1']={'policy':KIND,'profile_checksum':self.profile['checksum'],
            'runtime_checksum':self.manifest['checksum'],'local_only':True,'calibrated':False,'status':status,
            'rejected_instance_ids':sorted(rejected_ids),
            'rejected_contract_instance_ids':sorted(i for i,v in entry_verdicts.items() if v['reject']),
            'target_verdicts':verdicts,'contract_verdicts':entry_verdicts,'rejected_targets':removed,
            'withdrawn_contract_cards':withdrawn,'parent_published':parent_published,
            'parent_product_outputs':parent_products,
            'coordinates':'EXIF-oriented original pixels','spec':SPEC,
            'timing_ms':{'parent_wall':parent_ms,'classify':classify_ms}}
        return result

    @staticmethod
    def _category(verdict):
        tops=[c['top_category'] for c in verdict['crops'].values()]
        return tops[0] if tops and all(t==tops[0] for t in tops) else 'not_wine'
