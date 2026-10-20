"""One saved native selector call, with explicit refusal of image/SIFT work."""
from copy import deepcopy

PARITY_FIELDS = ('legacy_feature_digest', 'systemic_feature_digest', 'ranker',
                 'systemic_selected', 'ocr_candidate_injection',
                 'discriminator_guard', 'recognition_repair_v2')


class UnsupportedGeometry(ValueError):
    """The native trigger requires pixels unavailable to this model-free replay."""


def select_saved(selector, body, instance_id):
    """Return one native result; preserve caller body and clear request scopes.

    Native non-triggered geometry executes normally. A triggered sparse-layout
    branch raises UnsupportedGeometry before decoding pixels. Saved top-five
    SIFT summaries cannot reconstruct a changed incumbent's missing matrix.
    This function does not publish cards or repeat early model pipeline calls.
    """
    from rshb_vine.recognition_repair_v2.composition import Request
    from rshb_vine.recognition_text_fixes_v1.builder import replaying_source_scope
    from rshb_vine.next_card_fixes_v1.policy import TRACE_KEY as STYLE_KEY

    class NoImageRequest(Request):
        def image(self):
            raise UnsupportedGeometry('Native sparse layout requires pixels; no SIFT matrix is saved')

    sid = str(instance_id)
    native = deepcopy(body)
    rows = [row for row in native['product_identity_evidence']['targets']
            if str(row['instance_id']) == sid]
    if len(rows) != 1:
        raise ValueError('Exactly one saved native input required: ' + sid)
    if selector.request is not None or selector._select_scope is not None:
        raise ValueError('Selector request scope is not idle')
    evidence = rows[0]
    raw = evidence['raw_visual']
    if raw['arms']['B3']['retrieval']['crossview_evidence']['gallery_rows'] != 4474:
        raise ValueError('Saved raw input does not use current4474')
    selector.records.clear()
    selector.request_observations.clear()
    selector.current_result = native
    selector.request = NoImageRequest(native, b'')
    try:
        with replaying_source_scope(native):
            return selector.select(control_slug=evidence['control_slug'], raw_visual=raw,
                observations=evidence['ocr_observations'],
                control_candidates=evidence['control_candidates'])
    finally:
        selector.current_result = selector.request = None
        selector.request_observations.clear()
        for stage in selector.stages:
            if hasattr(stage, 'audit'):
                stage.audit.clear()
        style = getattr(selector, STYLE_KEY, None)
        if style is not None:
            style.audit.clear(); style.guard_audit.clear(); style.call_evidence.clear()


def baseline_parity(selected, body, instance_id):
    """Compare native functional records before any candidate call is permitted."""
    sid = str(instance_id)
    records = [row for row in body['systemic_ranking_v2']['targets']
               if str(row['instance_id']) == sid]
    if len(records) != 1:
        raise ValueError('Exactly one original native record required: ' + sid)
    actual, expected = selected['systemic_ranking_v2'], records[0]
    return {key: actual.get(key) == expected.get(key) for key in PARITY_FIELDS}
