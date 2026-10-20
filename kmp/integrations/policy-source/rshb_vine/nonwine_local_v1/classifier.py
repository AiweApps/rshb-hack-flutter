"""Frozen pretrained SigLIP2 zero-shot beverage type for one physical target; no fit, no brand prompts."""
from pathlib import Path
import numpy as np
from PIL import ImageOps
from rshb_vine.io import sha256

CATEGORIES={
    'wine':['a photo of a bottle of red wine','a photo of a bottle of white wine',
            'a photo of a bottle of rosé wine','a photo of a bottle of sparkling wine'],
    'beer':['a photo of a bottle of beer','a photo of a can of beer'],
    'soft_drink':['a photo of a bottle of soda','a photo of a bottle of lemonade','a photo of a bottle of juice'],
    'water':['a photo of a bottle of mineral water'],
    'spirits':['a photo of a bottle of whisky','a photo of a bottle of cognac','a photo of a bottle of vodka'],
    'oil_vinegar':['a photo of a bottle of olive oil','a photo of a bottle of vinegar'],
}
CROPS=('bottle','label')
WINE_PROBABILITY_MAX=0.25
CRITERION=('reject target only when on every available crop (bottle_bbox and label_bbox) the top category is not wine '
           'and softmax wine probability <%.2f; category logit=max prompt logit; softmax over categories' % WINE_PROBABILITY_MAX)
FILES=('config.json','model.safetensors','preprocessor_config.json','special_tokens_map.json','tokenizer.json','tokenizer_config.json')


class BeverageClassifier:
    def __init__(self,root,device):
        import torch
        from transformers import AutoImageProcessor,AutoModel,AutoTokenizer
        path=Path(root)/'models/encoder'
        self.device=device
        self.files_sha256={name:sha256(path/name) for name in FILES}
        self.processor=AutoImageProcessor.from_pretrained(path,local_files_only=True,use_fast=False)
        self.tokenizer=AutoTokenizer.from_pretrained(path,local_files_only=True)
        self.model=AutoModel.from_pretrained(path,local_files_only=True).eval().to(device)
        self.model.requires_grad_(False)
        self.prompts=[(category,prompt) for category,items in CATEGORIES.items() for prompt in items]
        with torch.inference_mode():
            tokens=self.tokenizer([p for _,p in self.prompts],padding='max_length',max_length=64,return_tensors='pt').to(device)
            text=torch.nn.functional.normalize(self.model.get_text_features(**tokens),dim=-1)
        self.text=text.cpu().numpy().astype('float64')
        self.scale=float(self.model.logit_scale.exp().item())
        self.bias=float(self.model.logit_bias.item())

    def classify(self,crops):
        import torch
        squares=[ImageOps.pad(im.convert('RGB'),(384,384),color='white') for im in crops]
        with torch.inference_mode():
            inputs=self.processor(images=squares,return_tensors='pt').to(self.device)
            vectors=torch.nn.functional.normalize(self.model.get_image_features(**inputs),dim=-1)
        vectors=vectors.cpu().numpy().astype('float64')
        rows=[]
        for vector in vectors:
            cosine=self.text@vector
            logits=self.scale*cosine+self.bias
            category={c:max(float(l) for (k,_),l in zip(self.prompts,logits) if k==c) for c in CATEGORIES}
            values=np.array(list(category.values()));probability=np.exp(values-values.max());probability/=probability.sum()
            probabilities=dict(zip(category,map(float,probability)))
            rows.append({'top':max(probabilities,key=probabilities.get),'probabilities':probabilities,'category_logits':category,
                         'prompt_cosine':{p:float(v) for (_,p),v in zip(self.prompts,cosine)}})
        return rows


def decide(rows):
    """rows: crop name -> classify row; missing crops are skipped, no crop means keep."""
    present=[r for r in rows.values() if r is not None]
    reject=bool(present) and all(r['top']!='wine' and r['probabilities']['wine']<WINE_PROBABILITY_MAX for r in present)
    return reject
