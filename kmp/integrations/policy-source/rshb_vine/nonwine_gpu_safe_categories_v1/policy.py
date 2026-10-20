"""Narrow frozen nonwine-context-v2 refusals without changing its scores.

Spirits are outside this refusal scope: wine may look like spirits, so a
spirits-top crop preserves the existing answer. This intentionally leaves
vodka/whisky coverage unresolved. There are no SKU, OCR or geometry inputs.
"""
from copy import deepcopy
import hashlib
import json
import math

POLICY = 'nonwine-gpu-safe-categories-v1'
BLOCK = 'nonwine_gpu_safe_categories_v1'
REFUSAL_SCOPE = ('beer', 'soft_drink', 'water', 'oil_vinegar')
CATEGORIES = frozenset(('wine', 'beer', 'soft_drink', 'water', 'spirits', 'oil_vinegar'))
INSUFFICIENT = 'insufficient_bottle_context'
WINE_PROBABILITY_MAX = 0.25  # Frozen original criterion, not a newly selected cutoff.


def _canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':'), allow_nan=False).encode()


def _sha(value):
    return hashlib.sha256(_canonical(value)).hexdigest()


def _base_rule(verdict):
    if not isinstance(verdict, dict) or BLOCK in verdict or verdict.get('calibrated') is not False:
        raise ValueError('Require an unprojected uncalibrated frozen CUDA verdict')
    crops = verdict.get('crops')
    if not isinstance(crops, dict) or not set(crops) <= {'bottle', 'label'}:
        raise ValueError('Unexpected frozen crop roster')
    for row in crops.values():
        if not isinstance(row, dict):
            raise ValueError('Missing crop must be absent, not an invented score')
        probabilities, logits = row.get('probabilities'), row.get('category_logits')
        if not isinstance(probabilities, dict) or set(probabilities) != CATEGORIES:
            raise ValueError('Frozen category probability roster differs')
        if not isinstance(logits, dict) or set(logits) != CATEGORIES:
            raise ValueError('Frozen category logit roster differs')
        for name, values in (('probabilities', probabilities), ('category_logits', logits)):
            if any(isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v) for v in values.values()):
                raise ValueError('Unreadable/nonfinite raw ' + name)
        if any(not 0 <= value <= 1 for value in probabilities.values()):
            raise ValueError('Invalid frozen category relative score')
        top = row.get('top')
        if top not in CATEGORIES or probabilities[top] != max(probabilities.values()):
            raise ValueError('Frozen top category disagrees with the raw relative scores')
    # Same operations as the pinned nonwine_local_v1.decide followed by
    # nonwine_context_v2.decide. Do not recompute or replace model scores.
    v1_rule = bool(crops) and all(row['top'] != 'wine' and
                                row['probabilities']['wine'] < WINE_PROBABILITY_MAX for row in crops.values())
    context = 'bottle' in crops
    reject = v1_rule and context
    reason = INSUFFICIENT if v1_rule and not context else None
    for key, expected in (('v1_rule', v1_rule), ('bottle_context', context), ('reject', reject)):
        if type(verdict.get(key)) is not bool or verdict[key] != expected:
            raise ValueError('Raw frozen verdict does not recompute: ' + key)
    if verdict.get('reason') != reason:
        raise ValueError('Raw frozen context reason does not recompute')
    return reject


def project_verdicts(verdicts):
    """Copy a (contract_instance_id, role)->base-verdict mapping and narrow it.

    Each copy binds its complete original verdict with a canonical SHA. Missing
    bottle context still keeps the answer. Every raw probability/logit/cosine
    remains untouched. Calling this on already projected data is an error.
    """
    if not isinstance(verdicts, dict):
        raise ValueError('Require an exact per-contract verdict mapping')
    projected = {}
    for key, base in verdicts.items():
        if (not isinstance(key, tuple) or len(key) != 2 or not isinstance(key[0], str) or
                key[1] not in ('bottle', 'roi_observation')):
            raise ValueError('Verdict key must preserve exact instance and role')
        before = _sha(base)
        base_reject = _base_rule(base)
        tops = [row['top'] for row in base['crops'].values()]
        in_scope = bool(tops) and all(top in REFUSAL_SCOPE for top in tops)
        output = deepcopy(base)
        output['reject'] = base_reject and in_scope
        reason = ('base_keeps_answer' if not base_reject else
                  'all_available_top_categories_in_refusal_scope' if in_scope else
                  'spirits_category_outside_refusal_scope_keep_answer')
        output[BLOCK] = dict(policy=POLICY, base_verdict_canonical_sha256=before,
                             base_reject=base_reject, projected_reject=output['reject'], reason=reason,
                             refusal_scope=list(REFUSAL_SCOPE), spirits_not_covered=True,
                             raw_model_scores_unchanged=True, OCR_used=False,
                             calibrated=False, fit=False)
        if _sha(base) != before:
            raise RuntimeError('Original verdict mutated')
        projected[key] = output
    return projected
