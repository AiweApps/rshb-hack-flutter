"""Frozen MPS text constants and one FP32 vision tower, no wine graph.

No forward is allowed until protocol resource bounds have been supplied. This
placement change still requires a separately admitted native numerical check.
The inherited image classification method and its per-target batch stay intact.
"""
import gc
import hashlib
import json
import math
from pathlib import Path

FROZEN_SOURCES = {
    'rshb_vine/nonwine_local_v1/classifier.py': '51b72ef582d7658330d23de5c66ddca1b2d5c44809dbdc94ce716b9b8722d710',
    'rshb_vine/nonwine_context_v2/classifier.py': 'aa928b7d43a8de2736c6077fac3b3761b76d2ada5e81b2ab3486b2d387aa3bfa',
    'rshb_vine/nonwine_local_v1/runtime.py': '890891c457fa5e7d3b9daa3866a5e9da66542d35d5fdd20ed48ac8dd2f165944',
}
FROZEN_FILES = {
    'config.json': 'b1b2481aa448d0cd29001bcf5244e72fa8f916dd8348bd18abf9e5533105b96c',
    'model.safetensors': 'ed72c0ace85020ae610fc817c2538b9cae5a477b012a50859c60af5b3ad30857',
    'preprocessor_config.json': 'fb2817d3523ca3b666c859f15320c7138416bc38ffc515e2963f78c868c51c90',
    'special_tokens_map.json': 'baec30ea10906f16adb8c18af7a34023002c1746542612b8b41c9f09e1351351',
    'tokenizer.json': 'cb9140fae3ac5122c972d37adf83e1248471a38147ad76f8215c8872c6fd8322',
    'tokenizer_config.json': '14afe629fe4959b9e0d51e1852b8d9f7ad074f90a1a7125a4fcdd17f06e78fc8',
}
TEXT_BYTES = 1129214976
VISION_BYTES = 372704256
PLACEMENT = 'frozen_source_bound_text_cache_then_vision_accelerator'
TEXT_CACHE_KIND = 'frozen-nonwine-mps-text-cache-v1'
LOGIT_SCALE = 112.84601593017578
LOGIT_BIAS = -16.77224349975586
RUNTIME_MODULES = ('transformers.models.siglip.modeling_siglip',
                   'transformers.models.siglip.configuration_siglip', 'transformers.modeling_utils')


def file_sha(path):
    from rshb_vine.evaluation.reset_access import check_read
    path = Path(path).resolve()
    check_read(path)
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(8 * 1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def verify_files(root):
    root = Path(root).resolve()
    for relative, expected in FROZEN_SOURCES.items():
        if file_sha(root / relative) != expected:
            raise ValueError('Frozen classifier source changed: ' + relative)
    for name, expected in FROZEN_FILES.items():
        if file_sha(root / 'models/encoder' / name) != expected:
            raise ValueError('Frozen pretrained model changed: ' + name)


def load_text_cache(spec, prompts):
    """Read only the exact query-independent old-MPS constants admitted by root.

    Float64 bytes encode the old classifier's normalized FP32 text features
    after its unchanged CPU float64 conversion. Neither fitting nor a new text
    forward happens in this consumer.
    """
    from rshb_vine.nonwine_gpu_transfer_v1.contract import json_bound, sha
    cache = json_bound(spec['path'], spec['file_sha256'], decoded_sha=spec['decoded_sha256'], max_bytes=2 * 1024 * 1024)
    if cache.get('kind') != TEXT_CACHE_KIND or cache.get('query_independent') is not True or cache.get('fit') is not False:
        raise ValueError('Text cache is not an admitted frozen query-independent constant')
    if cache['model_files_sha256'] != FROZEN_FILES or cache['source_pins'] != FROZEN_SOURCES:
        raise ValueError('Frozen text cache model/source provenance differs')
    if cache['prompts'] != [list(pair) for pair in prompts] or cache['tokenization'] != dict(padding='max_length', max_length=64):
        raise ValueError('Frozen text cache prompt order/tokenization differs')
    if cache['environment'] != spec['environment'] or cache['environment'].get('device') != 'mps':
        raise ValueError('Text cache was not created in the admitted old-MPS environment')
    for package in ('torch', 'transformers', 'numpy', 'Pillow', 'safetensors'):
        if not isinstance(cache['environment'].get(package), str) or not cache['environment'][package]:
            raise ValueError('Text cache native environment is incomplete')
    for field in ('creation_protocol_sha256', 'creation_source_sha256'):
        value = cache[field]
        if not isinstance(value, str) or len(value) != 64 or any(c not in '0123456789abcdef' for c in value):
            raise ValueError('Text cache creation evidence is missing')
    if cache['wine_relative_score_max'] != 0.25 or cache['logit_scale'] != LOGIT_SCALE or cache['logit_bias'] != LOGIT_BIAS:
        raise ValueError('Frozen text cache decision/scale constants differ')
    rows = cache['text']
    if cache['text_dtype'] != 'float64' or cache['text_shape'] != [15, 768] or not isinstance(rows, list) or len(rows) != 15:
        raise ValueError('Frozen text cache shape/dtype differs')
    if any(not isinstance(row, list) or len(row) != 768 or any(isinstance(x, bool) or not isinstance(x, (float, int)) or not math.isfinite(x) for x in row) for row in rows):
        raise ValueError('Frozen text cache contains nonfinite/malformed values')
    import numpy as np
    text = np.array(rows, dtype='<f8')
    as_float32 = text.astype('<f4')
    if not np.array_equal(text, as_float32.astype('<f8')):
        raise ValueError('Text cache did not preserve normalized FP32-to-float64 conversion')
    if sha(text.tobytes(order='C')) != cache['normalized_text_float64_sha256'] or sha(as_float32.tobytes(order='C')) != cache['normalized_text_float32_sha256']:
        raise ValueError('Frozen normalized text feature bytes differ')
    return text, cache


def checkpoint_header(path):
    """Read safetensors metadata only; never materialize text parameters."""
    from rshb_vine.evaluation.reset_access import check_read
    check_read(path)
    with Path(path).open('rb') as stream:
        length = int.from_bytes(stream.read(8), 'little')
        if not 0 < length <= 16 * 1024 * 1024:
            raise ValueError('Frozen checkpoint header size differs')
        header = json.loads(stream.read(length))
    return {key: value for key, value in header.items() if key != '__metadata__'}


class _VisionFacade:
    """Use the installed full-model feature method with only its vision module.

    SiglipModel.get_image_features calls vision_model(...).pooler_output.
    Neither this facade nor SiglipVisionModel constructs a text tower.
    """
    def __init__(self, vision_model, original_method):
        self.vision_model = vision_model
        self._original_method = original_method

    def get_image_features(self, **inputs):
        return self._original_method(self, **inputs)


class CategoryClassifier:
    """Frozen get_*_features operations, FP32, ordered bottle/label batch<=2.

    CPU loading relies on the installed transformers safetensors mmap/low-memory
    path; acceptance includes measured RSS/cgroup peaks, not an assumed limit.
    """
    def __init__(self, root, resources, checkpoint, *, text_cache, runtime_source_pins,
                 device='cuda:0', resource_trace=None):
        verify_files(root)
        import torch
        import transformers
        from transformers import AutoImageProcessor, SiglipVisionModel, SiglipModel
        from rshb_vine.nonwine_local_v1.classifier import BeverageClassifier
        from rshb_vine.nonwine_context_v2 import classifier as frozen
        import importlib
        if set(runtime_source_pins) != set(RUNTIME_MODULES):
            raise ValueError('Native vision method/loader source pins are incomplete')
        for name in RUNTIME_MODULES:
            module = importlib.import_module(name)
            if file_sha(module.__file__) != runtime_source_pins[name]:
                raise ValueError('Native vision method/loader source changed: ' + name)
        if device not in ('cuda:0', 'mps'):
            raise ValueError('Only explicitly admitted CUDA or local native-parity MPS is supported')
        if device == 'cuda:0' and not torch.cuda.is_available():
            raise RuntimeError('The explicitly admitted CUDA device is unavailable')
        if device == 'mps' and not torch.backends.mps.is_available():
            raise RuntimeError('The explicitly admitted native-parity MPS device is unavailable')
        self.torch = torch
        self.resources = resources
        self.checkpoint = checkpoint
        self.device = device
        self._prefix = 'cuda' if device == 'cuda:0' else 'mps'
        self._sampled_peak = 0
        self._sampled_reserved_peak = 0
        self.frozen = frozen
        self._image_method = BeverageClassifier.classify
        self.prompts = [(category, prompt) for category, items in frozen.CATEGORIES.items() for prompt in items]
        self.text, cache = load_text_cache(text_cache, self.prompts)
        self.scale = cache['logit_scale']
        self.bias = cache['logit_bias']
        self.observations = resource_trace if resource_trace is not None else []
        self.model = None
        self._closed = False
        # These are process-local numerical settings; this worker never shares
        # an interpreter or model with the production recognition service.
        torch.backends.cuda.matmul.allow_tf32 = False
        torch.backends.cudnn.allow_tf32 = False
        torch.set_float32_matmul_precision('highest')
        self._guard('before_cpu_load', 0)
        path = Path(root).resolve() / 'models/encoder'
        self.processor = AutoImageProcessor.from_pretrained(path, local_files_only=True, use_fast=False)
        self.files_sha256 = dict(FROZEN_FILES)
        try:
            header = checkpoint_header(path / 'model.safetensors')
            expected_vision = {key for key in header if key.startswith('vision_model.')}
            expected_unused = set(header) - expected_vision
            if (not expected_vision or not expected_unused or
                    any(not key.startswith('text_model.') and key not in ('logit_scale', 'logit_bias') for key in expected_unused)):
                raise RuntimeError('Frozen checkpoint tower namespaces differ')
            vision, loading = SiglipVisionModel.from_pretrained(path, local_files_only=True, low_cpu_mem_usage=True,
                                                               torch_dtype=torch.float32, output_loading_info=True)
            self.model = _VisionFacade(vision.vision_model, SiglipModel.get_image_features)
            vision.eval().requires_grad_(False)
            if (loading.get('missing_keys') or loading.get('mismatched_keys') or loading.get('error_msgs') or
                    set(loading.get('unexpected_keys') or []) != expected_unused):
                raise RuntimeError('Vision-only checkpoint load is incomplete or contains unexpected namespaces')
            state = vision.state_dict()
            if (set(state) != expected_vision or hasattr(vision, 'text_model') or
                    any('text' in name for name, _ in vision.named_modules()) or
                    any(value.dtype != torch.float32 or list(value.shape) != header[name]['shape'] for name, value in state.items())):
                raise RuntimeError('Vision-only state differs or text parameters were instantiated')
            vision_bytes = sum(value.numel() * value.element_size() for value in state.values())
            if vision_bytes != VISION_BYTES:
                raise RuntimeError('Frozen vision-only byte size differs')
            attention_implementation = vision.config._attn_implementation
            # Drop temporary parameter-reference dictionaries before movement;
            # the facade owns exactly the loaded SiglipVisionTransformer.
            del state, vision
            self._guard('vision_only_cpu_loaded_no_text_parameters', 0)
            self._guard('before_vision_accelerator', VISION_BYTES)
            self.model.vision_model.to(self.device)
            self._guard('vision_ready', 0)
            self.identity = dict(model_files_sha256=dict(FROZEN_FILES), source_pins=dict(FROZEN_SOURCES),
                                 torch=torch.__version__, transformers=transformers.__version__,
                                 dtype='float32', device=self.device, image_batch_max=2,
                                 placement=PLACEMENT,
                                 text_batch=len(self.prompts), text_length=64, tf32=False,
                                 scale=self.scale, bias=self.bias, categories=frozen.CATEGORIES,
                                 attention_implementation=attention_implementation,
                                 loading_class='SiglipVisionModel', instantiated_text_parameters=0,
                                 vision_parameter_bytes=VISION_BYTES, unused_checkpoint_keys=sorted(expected_unused),
                                 runtime_source_pins=dict(runtime_source_pins),
                                 requires_bottle_crop=True, cutoff=frozen.WINE_PROBABILITY_MAX,
                                 text_cache_file_sha256=text_cache['file_sha256'],
                                 text_cache_decoded_sha256=text_cache['decoded_sha256'],
                                 normalized_text_float64_sha256=cache['normalized_text_float64_sha256'],
                                 text_origin='frozen_original_MPS_text_forward', text_forwards=0,
                                 text_cache_environment=cache['environment'],
                                 native_numerical_parity='requires_separate_admitted_evidence')
        except BaseException:
            self.close()
            raise

    def _guard(self, stage, additional_bytes):
        torch = self.torch
        if self.device == 'cuda:0':
            torch.cuda.synchronize()
            free, total = torch.cuda.mem_get_info()
            allocated = torch.cuda.memory_allocated()
            reserved = torch.cuda.memory_reserved()
            peak = torch.cuda.max_memory_allocated()
            reserved_peak = torch.cuda.max_memory_reserved()
            peak_kind = 'cuda_allocator_peak'
        else:
            torch.mps.synchronize()
            allocated = torch.mps.current_allocated_memory()
            reserved = torch.mps.driver_allocated_memory()
            total = torch.mps.recommended_max_memory()
            free = max(0, total - reserved)
            self._sampled_peak = max(self._sampled_peak, allocated)
            self._sampled_reserved_peak = max(self._sampled_reserved_peak, reserved)
            peak, reserved_peak = self._sampled_peak, self._sampled_reserved_peak
            peak_kind = 'mps_checkpoint_samples_not_transient_peak'
        state = dict(stage=stage, free_bytes=free, total_bytes=total, allocated_bytes=allocated,
                     reserved_bytes=reserved, peak_allocated_bytes=peak,
                     peak_reserved_bytes=reserved_peak, peak_kind=peak_kind, device=self.device)
        self.observations.append(state)
        checkpoint_state = self.checkpoint(stage)
        if isinstance(checkpoint_state, dict):
            state.update(checkpoint_state)
        required = additional_bytes + self.resources[self._prefix + '_activation_reserve_bytes'] + self.resources[self._prefix + '_min_free_bytes']
        if free < required:
            raise RuntimeError(self._prefix + ' resource guard: insufficient pre-forward headroom at ' + stage)
        if reserved + additional_bytes > self.resources[self._prefix + '_max_reserved_bytes'] or peak > self.resources[self._prefix + '_max_allocated_bytes']:
            raise RuntimeError(self._prefix + ' resource guard: frozen worker budget exceeded at ' + stage)

    def classify(self, crops):
        if self._closed or not 1 <= len(crops) <= 2:
            raise ValueError('Frozen per-target image batch must contain one or two crops')
        self._guard('before_image_forward', 0)
        rows = self._image_method(self, crops)
        self._guard('after_image_forward', 0)
        return rows

    def close(self):
        if not self._closed:
            self.model = None
            gc.collect()
            self._empty_cache()
            self._closed = True
            # Externally owned trace survives constructor failure. This
            # observation does not call a failing deadline/RSS checkpoint.
            if self.device == 'cuda:0':
                self.torch.cuda.synchronize()
                free, total = self.torch.cuda.mem_get_info()
                self.observations.append(dict(stage='model_close', device=self.device, free_bytes=free,
                                             total_bytes=total, allocated_bytes=self.torch.cuda.memory_allocated(),
                                             reserved_bytes=self.torch.cuda.memory_reserved(),
                                             peak_allocated_bytes=self.torch.cuda.max_memory_allocated(),
                                             peak_reserved_bytes=self.torch.cuda.max_memory_reserved(),
                                             peak_kind='cuda_allocator_peak'))
            else:
                self.torch.mps.synchronize()
                self.observations.append(dict(stage='model_close', device=self.device,
                                             allocated_bytes=self.torch.mps.current_allocated_memory(),
                                             reserved_bytes=self.torch.mps.driver_allocated_memory(),
                                             peak_kind='mps_checkpoint_samples_not_transient_peak'))

    def _empty_cache(self):
        if self.device == 'cuda:0':
            self.torch.cuda.empty_cache()
        else:
            self.torch.mps.empty_cache()
