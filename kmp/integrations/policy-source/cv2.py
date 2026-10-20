"""The verifier's OpenCV API, backed by real same-version native OpenCV calls.

Only the APIs actually used by the source-bound layout verifier are exposed.
Unsupported operations fail; no fabricated descriptor, match or layout result.
"""
import ctypes as C
import os
from types import SimpleNamespace
import numpy as np

class error(Exception): pass
_library = os.environ.get('WINE_GEOMETRY_LIBRARY')
if not _library: raise ImportError('Signed native WineGeometry library is required')
_cv = C.CDLL(_library)
_float = C.POINTER(C.c_float); _double = C.POINTER(C.c_double); _byte = C.POINTER(C.c_uint8)
class _Features(C.Structure):
    _fields_ = [('count',C.c_int),('xy',_float),('descriptors',_float),('metadata',_float)]
class _Matches(C.Structure):
    _fields_ = [('count',C.c_int),('queries',C.c_int),('offsets',C.POINTER(C.c_int)),
                ('query',C.POINTER(C.c_int)),('train',C.POINTER(C.c_int)),('distance',_float)]
def _function(name, result, *args):
    function=getattr(_cv,name);function.restype=result;function.argtypes=list(args);return function
_function('wg_version',C.c_char_p);_function('wg_error',C.c_char_p)
if _function('wg_abi',C.c_int)()!=2: raise ImportError('WineGeometry C ABI2 required')
_function('wg_initialize',None)()
_function('wg_seed',None,C.c_int)
_function('wg_gray',C.c_int,_byte,C.c_int,C.c_int,_byte)
_function('wg_sift',C.POINTER(_Features),_byte,C.c_int,C.c_int,C.c_int)
_function('wg_free_features',None,C.POINTER(_Features))
_function('wg_match',C.POINTER(_Matches),_float,C.c_int,_float,C.c_int,C.c_int)
_function('wg_free_matches',None,C.POINTER(_Matches))
_function('wg_homography',C.c_int,_float,_float,C.c_int,C.c_int,C.c_double,_double,_byte)
_function('wg_hull',C.c_int,_float,C.c_int,_float,C.POINTER(C.c_int))
_function('wg_area',C.c_double,_float,C.c_int)
_function('wg_convex',C.c_int,_float,C.c_int)
_function('wg_perspective',C.c_int,_float,C.c_int,_double,_float)
__version__=_cv.wg_version().decode()
if __version__!='4.14.0': raise ImportError('The layout bridge requires frozen OpenCV4.14.0')
COLOR_RGB2GRAY=7
RANSAC=8
NORM_L2=4
def _check(value):
    if value<0: raise error(_cv.wg_error().decode())
    return value
def _points(value):
    array=np.ascontiguousarray(value,dtype=np.float32)
    if array.size%2 or array.size>100000: raise error('Invalid point array')
    return array.reshape(-1,2)
def cvtColor(image,code):
    array=np.ascontiguousarray(image,dtype=np.uint8)
    if code!=COLOR_RGB2GRAY or array.ndim!=3 or array.shape[2]!=3: raise error('Unsupported color conversion')
    out=np.empty(array.shape[:2],dtype=np.uint8)
    _check(_cv.wg_gray(array.ctypes.data_as(_byte),array.shape[1],array.shape[0],out.ctypes.data_as(_byte)));return out
class _Sift:
    def __init__(self,nfeatures): self.limit=nfeatures
    def detectAndCompute(self,image,mask):
        if mask is not None: raise error('Verifier SIFT expects no mask')
        array=np.ascontiguousarray(image,dtype=np.uint8)
        if array.ndim!=2: raise error('Verifier SIFT expects grayscale')
        result=_cv.wg_sift(array.ctypes.data_as(_byte),array.shape[1],array.shape[0],self.limit)
        if not result: raise error(_cv.wg_error().decode())
        try:
            n=result.contents.count
            if not n: return (),None
            xy=np.ctypeslib.as_array(result.contents.xy,shape=(n*2,)).reshape(n,2).copy()
            descriptors=np.ctypeslib.as_array(result.contents.descriptors,shape=(n*128,)).reshape(n,128).copy()
            metadata=np.ctypeslib.as_array(result.contents.metadata,shape=(n*4,)).reshape(n,4).copy()
            return tuple(SimpleNamespace(pt=tuple(map(float,row)),size=float(m[0]),angle=float(m[1]),
                response=float(m[2]),octave=int(m[3])) for row,m in zip(xy,metadata)),descriptors
        finally: _cv.wg_free_features(result)
def SIFT_create(nfeatures=0): return _Sift(nfeatures)
class _Matcher:
    def knnMatch(self,query,reference,k):
        q=np.ascontiguousarray(query,dtype=np.float32);r=np.ascontiguousarray(reference,dtype=np.float32)
        if q.ndim!=2 or r.ndim!=2 or q.shape[1]!=128 or r.shape[1]!=128: raise error('Invalid SIFT descriptor shape')
        result=_cv.wg_match(q.ctypes.data_as(_float),len(q),r.ctypes.data_as(_float),len(r),k)
        if not result: raise error(_cv.wg_error().decode())
        try:
            v=result.contents
            return tuple(tuple(SimpleNamespace(queryIdx=v.query[i],trainIdx=v.train[i],distance=float(v.distance[i]))
                for i in range(v.offsets[row],v.offsets[row+1])) for row in range(v.queries))
        finally: _cv.wg_free_matches(result)
def BFMatcher(normType=NORM_L2,crossCheck=False):
    if normType!=NORM_L2 or crossCheck: raise error('Unsupported verifier matcher')
    return _Matcher()
def setRNGSeed(seed): _cv.wg_seed(seed)
def findHomography(source,destination,method,reprojection):
    a,b=_points(source),_points(destination)
    if a.shape!=b.shape: raise error('Homography point arrays differ')
    h=np.empty((3,3),dtype=np.float64);mask=np.empty((len(a),1),dtype=np.uint8)
    found=_check(_cv.wg_homography(a.ctypes.data_as(_float),b.ctypes.data_as(_float),len(a),method,
        reprojection,h.ctypes.data_as(_double),mask.ctypes.data_as(_byte)))
    return (h,mask) if found else (None,None)
def convexHull(points):
    a=_points(points);out=np.empty_like(a);n=C.c_int()
    _check(_cv.wg_hull(a.ctypes.data_as(_float),len(a),out.ctypes.data_as(_float),C.byref(n)))
    return out[:n.value].reshape(-1,1,2)
def contourArea(points):
    a=_points(points);value=_cv.wg_area(a.ctypes.data_as(_float),len(a))
    if not np.isfinite(value): raise error(_cv.wg_error().decode())
    return value
def isContourConvex(points):
    a=_points(points);return bool(_check(_cv.wg_convex(a.ctypes.data_as(_float),len(a))))
def perspectiveTransform(points,h):
    shape=np.shape(points);a=_points(points);matrix=np.ascontiguousarray(h,dtype=np.float64)
    if matrix.shape!=(3,3): raise error('Perspective matrix must be3x3')
    out=np.empty_like(a)
    _check(_cv.wg_perspective(a.ctypes.data_as(_float),len(a),matrix.ctypes.data_as(_double),out.ctypes.data_as(_float)))
    return out.reshape(shape)
