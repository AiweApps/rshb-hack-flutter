"""Context-gated reuse of the frozen v1 SigLIP2 beverage classifier; same model, prompts and cutoff."""
from pathlib import Path
from rshb_vine.io import sha256

# Frozen v1 sources of descriptor 14cd055a; checked before any v1 module is imported.
V1_PINS={
    'rshb_vine/nonwine_local_v1/__init__.py':'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    'rshb_vine/nonwine_local_v1/classifier.py':'51b72ef582d7658330d23de5c66ddca1b2d5c44809dbdc94ce716b9b8722d710',
    'rshb_vine/nonwine_local_v1/runtime.py':'890891c457fa5e7d3b9daa3866a5e9da66542d35d5fdd20ed48ac8dd2f165944',
}
V1_DESCRIPTOR='14cd055a1f6eeb4ba4837bf2ad6078fe07fcff0acaf0a8ead30747436156fe4e'
ROOT=Path(__file__).resolve().parents[2]


def verify_v1(root=ROOT):
    changed=[p for p,h in V1_PINS.items() if sha256(Path(root)/p)!=h]
    if changed:raise RuntimeError('Frozen v1 nonwine sources differ: '+', '.join(changed))


verify_v1()
from rshb_vine.nonwine_local_v1.classifier import BeverageClassifier,CATEGORIES,CROPS,FILES,WINE_PROBABILITY_MAX
from rshb_vine.nonwine_local_v1.classifier import CRITERION as V1_CRITERION,decide as v1_decide

INSUFFICIENT='insufficient_bottle_context'
CRITERION=('reject target only when a valid bottle_bbox crop (>=8x8 px after clipping) was classified AND the unchanged v1 rule '
           'holds: %s; label-only evidence never rejects and is reported as %s' % (V1_CRITERION,INSUFFICIENT))


def decide(rows):
    """rows: crop name -> classify row or None. Returns (reject, v1_rule, reason)."""
    v1_rule=v1_decide(rows)
    bottle=rows.get('bottle') is not None
    if v1_rule and not bottle:return False,True,INSUFFICIENT
    return v1_rule and bottle,v1_rule,None
