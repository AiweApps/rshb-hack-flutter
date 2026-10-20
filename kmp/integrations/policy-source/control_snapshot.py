"""Restore trusted source-bound control metadata with explicit native roles.

No model constructor is called. Metadata-only descriptors have no prediction
methods; a production caller must supply real bindings for every frozen slot.
The historical4314 snapshot is not automatically a current4474 runtime.
"""
import gzip
import hashlib
import io
import json
from pathlib import Path
import pickle
import contextvars
import os
import threading


class OpaqueNativeRole:
    """Metadata descriptor only; deliberately cannot predict, encode or read."""
    def __init__(self, specification): self.specification = specification


def load(directory, *, bind_slot=None, metadata_only=False):
    directory = Path(directory)
    receipt = json.loads((directory / 'inspection.json').read_text())
    parent = receipt['kind'] in ('ondevice-frozen-parent4314-control-snapshot-v1','ondevice-frozen-parent4314-outer-snapshot-v1') and receipt['registry_rows'] == 4314 and receipt['current4474'] is False
    current = receipt['kind'] in ('ondevice-current4474-control-snapshot-v1','ondevice-current4474-outer-snapshot-v1') and receipt['registry_rows'] == 4474 and receipt['current4474'] is True
    if receipt['serialized'] is not True or not (parent or current):
        raise ValueError('Source-bound parent or admitted current control snapshot required')
    if current:
        admission = json.loads((directory / 'admission.json').read_text())
        if hashlib.sha256(json.dumps(admission,sort_keys=True,ensure_ascii=False,separators=(',',':'),allow_nan=False).encode()).hexdigest() != receipt['admission_sha256']:
            raise ValueError('Current control admission changed')
    data = (directory / 'control.pkl.gz').read_bytes()
    if len(data) > 32 * 1024**2 or hashlib.sha256(data).hexdigest() != receipt['payload_sha256']:
        raise ValueError('Trusted control snapshot bytes changed')
    with gzip.GzipFile(fileobj=io.BytesIO(data)) as stream:
        decoded = stream.read(128 * 1024**2 + 1)
    if len(decoded) != receipt['raw_bytes'] or len(decoded) > 128 * 1024**2:
        raise ValueError('Control metadata exceeds the original declared size')
    if metadata_only:
        if bind_slot is not None: raise ValueError('Metadata restore cannot bind model owners')
        bind_slot = OpaqueNativeRole
    elif bind_slot is None:
        raise ValueError('Every control model role requires a real native binding')
    def key(value): return json.dumps(value, sort_keys=True, ensure_ascii=False, allow_nan=False)
    admitted = {key(slot): slot for slot in receipt['model_slots']}
    bound = {}
    class Restore(pickle.Unpickler):
        def persistent_load(self, token):
            kind, specification = token
            identity = key(specification)
            if kind != 'wine-native-control-slot-v1' or identity not in admitted:
                raise ValueError('Unknown control model role')
            if identity not in bound:
                value = bind_slot(specification)
                if value is None or (not metadata_only and isinstance(value, OpaqueNativeRole)):
                    raise ValueError('Unbound native model role: ' + specification['role'])
                bound[identity] = value
            return bound[identity]
    result = Restore(io.BytesIO(decoded)).load()
    outer = receipt.get('outer_graph') is True
    if set(result) != ({'control','cache','graph'} if outer else {'control','cache'}):
        raise ValueError('Unexpected control snapshot owners')
    if outer and (result['graph'].base.runtime.control is not result['control'] or
                  result['graph'].base.runtime.visual_cache is not result['cache']):
        raise ValueError('Outer graph lost shared control/cache identity')
    report = dict(kind=receipt['kind'], parent_profile=receipt['parent_profile'],
        bound_roles=len(bound), expected_roles=len(admitted), metadata_only=metadata_only,
        full_scanner_complete=False, current4474=current, outer_graph=outer)
    if len(bound) != len(admitted):
        # Slots absent from the serialized control+cache cannot be claimed as
        # exercised. The caller sees the exact roster actually restored.
        report['unreferenced_slots'] = [slot for identity, slot in admitted.items() if identity not in bound]
    return result, report


def _blank(cls): return object.__new__(cls)
def _state(value, state): object.__getattribute__(value, '__dict__').update(state)
def _context(name): return contextvars.ContextVar(name, default=None)
def _array(data, dtype, shape):
    # NumPy2 protocol5 uses the private numpy._core.numeric module, absent
    # from the pinned iOS NumPy1.26. Preserve exact values through public APIs.
    import numpy as np
    return np.frombuffer(data,dtype=np.dtype(dtype)).reshape(shape).copy()
def _path(value, original_root):
    path = Path(value);destination = os.environ.get('WINE_CONTROL_DATA_ROOT')
    return Path(destination)/path.relative_to(original_root) if destination and path.is_relative_to(original_root) else path


def save_admitted(state, parent_receipt, admission, directory, original_root):
    """Write metadata only; all actual model roles remain explicit persistent slots."""
    import cloudpickle
    import numpy as np
    from copy import deepcopy
    directory=Path(directory);directory.mkdir(parents=True,exist_ok=False)
    slots=deepcopy(parent_receipt['model_slots'])
    for slot in slots:
        if slot['role'] in ('E_raw_index','E_filtered_index'): slot['rows']=4474
    class Writer(cloudpickle.CloudPickler):
        def persistent_id(self,value):
            if isinstance(value,OpaqueNativeRole):
                specification=deepcopy(value.specification)
                if specification['role'] in ('E_raw_index','E_filtered_index'): specification['rows']=4474
                return ('wine-native-control-slot-v1',specification)
            if type(value).__module__.startswith(('torch','paddle','paddlex','transformers')):
                raise ValueError('ML object entered a metadata-only admission')
            return None
        def reducer_override(self,value):
            cls=type(value)
            if cls is np.ndarray:
                if value.dtype.hasobject: raise ValueError('Object array is not portable control metadata')
                return _array,(value.tobytes(order='C'),value.dtype.str,value.shape)
            if isinstance(value,Path): return _path,(str(value),str(original_root))
            if isinstance(value,contextvars.ContextVar):
                if value.get(None) is not None: raise ValueError('Active request cannot be admitted')
                return _context,(value.name,)
            if isinstance(value,type(threading.RLock())):
                if not value.acquire(blocking=False): raise ValueError('Active control lock')
                value.release()
                if value._is_owned(): raise ValueError('Held control lock')
                return threading.RLock,()
            if isinstance(value,type(threading.Lock())):
                if not value.acquire(blocking=False): raise ValueError('Active outer control lock')
                value.release()
                return threading.Lock,()
            if cls.__module__.startswith(('rshb_vine','scripts.')) and hasattr(cls,'__getattr__'):
                return _blank,(cls,),object.__getattribute__(value,'__dict__'),None,None,_state
            return super().reducer_override(value)
    buffer=io.BytesIO();Writer(buffer,protocol=5).dump(state)
    data=gzip.compress(buffer.getvalue(),mtime=0);(directory/'control.pkl.gz').write_bytes(data)
    encoded=json.dumps(admission,sort_keys=True,ensure_ascii=False,separators=(',',':'),allow_nan=False).encode()
    (directory/'admission.json').write_bytes(encoded)
    receipt=deepcopy(parent_receipt)
    receipt.update(kind='ondevice-current4474-outer-snapshot-v1' if parent_receipt.get('outer_graph') else 'ondevice-current4474-control-snapshot-v1',current4474=True,registry_rows=4474,
        parent_payload_sha256=parent_receipt['payload_sha256'],payload_sha256=hashlib.sha256(data).hexdigest(),
        compressed_bytes=len(data),raw_bytes=buffer.tell(),model_slots=slots,
        admission_sha256=hashlib.sha256(encoded).hexdigest(),mobile_consumer_verified=False)
    (directory/'inspection.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n')
    return receipt
