"""The same single-image float32 frozen feature function for any live input."""
import hashlib
import numpy as np
from PIL import ImageOps

from rshb_vine.b3_local_residual_v1.head import CompactResidualHead, kernel


class CapturedEncoder:
    def __init__(self, artifact, head_path, observer, guard, arm):
        self.artifact=artifact; self.head=CompactResidualHead.load(head_path) if head_path else None
        self.observer=observer;self.guard=guard;self.arm=arm

    def encode(self, images):
        import torch
        from rshb_vine.models import synchronize
        rows=[]
        for image in images:
            self.guard(forwards=1)
            square=ImageOps.pad(image,(384,384),color='white')
            inputs=self.artifact.processor(images=[square],return_tensors='pt')
            pixels=inputs['pixel_values']
            if image.mode != 'RGB' or tuple(pixels.shape)!=(1,3,384,384) or pixels.dtype != torch.float32:
                raise ValueError('Same RGB/float32/384 processor required')
            tensor_sha=hashlib.sha256(pixels[0].contiguous().numpy().tobytes()).hexdigest()
            with torch.inference_mode():
                vectors=self.artifact.model.get_image_features(**inputs.to(self.artifact.device))
                vectors=torch.nn.functional.normalize(vectors.float(),dim=-1)
            synchronize(self.artifact.device)
            base=vectors.cpu().numpy().astype(np.float32)
            result=self.head.apply(base) if self.head else base.copy()
            activation=int(np.count_nonzero(kernel(base,self.head.centers,self.head.radii))) if self.head else 0
            self.observer(image,square,tensor_sha,base[0],result[0],activation)
            rows.append(result[0]);square.close();self.guard()
        return np.asarray(rows,dtype=np.float32).reshape(-1,768)

    def features(self,*_,**__):
        raise RuntimeError('B3 retrieval adapter is inference-only; never use it for frozen object gate')
