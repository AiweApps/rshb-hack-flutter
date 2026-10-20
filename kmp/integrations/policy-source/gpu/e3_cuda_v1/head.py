"""Feature tensors only. No source, filename, PID, query or role enters this function."""
import numpy as np


def kernel(features,centers,radii):
    x=np.asarray(features,dtype=np.float64)
    distance=np.linalg.norm(x[:,None,:]-centers[None,:,:],axis=2)
    return np.maximum(0.,1.-(distance/radii[None,:])**2)**2


class CompactResidualHead:
    def __init__(self,centers,radii,coefficients):
        self.centers=np.asarray(centers,dtype=np.float64)
        self.radii=np.asarray(radii,dtype=np.float64)
        self.coefficients=np.asarray(coefficients,dtype=np.float64)
        if self.centers.shape!=(6,768) or self.radii.shape!=(6,) or self.coefficients.shape!=(6,768):
            raise ValueError('Exact six768 compact residual parameters required')
        if not all(np.isfinite(x).all() for x in (self.centers,self.radii,self.coefficients)) or not (self.radii>0).all():
            raise ValueError('Finite head and positive fixed radii required')

    @classmethod
    def load(cls,path):
        with np.load(path,allow_pickle=False) as params:
            if set(params.files)!={'centers','radii','coefficients'}:raise ValueError('Only feature-space head arrays allowed')
            return cls(params['centers'],params['radii'],params['coefficients'])

    def apply(self,features):
        x=np.asarray(features)
        if x.dtype!=np.float32 or x.ndim!=2 or x.shape[1]!=768 or not np.isfinite(x).all():
            raise ValueError('Finite frozen C float32 Nx768 required')
        if (np.abs(np.linalg.norm(x.astype(np.float64),axis=1)-1)>2e-5).any():
            raise ValueError('Frozen backbone input must already be normalized')
        k=kernel(x,self.centers,self.radii)
        active=np.any(k!=0,axis=1)
        # Returning original normalized C bytes on zero support is part of the global
        # feature function, not a branch by filename or input role.
        output=x.copy()
        if active.any():
            residual=x[active].astype(np.float64)+k[active]@self.coefficients
            norms=np.linalg.norm(residual,axis=1,keepdims=True)
            if not np.isfinite(residual).all() or (norms<=1e-8).any():raise ValueError('Nonfinite/zero adapted output')
            output[active]=(residual/norms).astype(np.float32)
        return output
