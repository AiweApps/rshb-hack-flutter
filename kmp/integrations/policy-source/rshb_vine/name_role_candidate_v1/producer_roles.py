"""Role gate for producer evidence, using the selector's existing typed spans."""
from dataclasses import dataclass


@dataclass(frozen=True)
class ProducerLineDecision:
    producer_eligible: bool
    reason: str
    covered_token_indexes: tuple


def classify_producer_line(tokens, grape_entities):
    """Classify a tokenized OCR line using native typed-lexicon entity spans.

    ``tokens`` is the existing selector-v4 token sequence. ``grape_entities``
    is the ``grape_blend`` span list returned by its TypedLexicon.entities().
    A line is excluded from producer support only when every token is covered
    by grape spans. Any uncovered token (for example CHATEAU in CHATEAU PINOT)
    keeps the full line eligible. The line remains available to name/grape
    evidence; this function changes no other role.
    """
    token_count = len(tokens)
    covered = set()
    for entity in grape_entities:
        start, end = entity.get('start'), entity.get('end')
        if (isinstance(start, int) and isinstance(end, int)
                and 0 <= start < end <= token_count):
            covered.update(range(start, end))
    covered_indexes = tuple(sorted(covered))
    if token_count and len(covered) == token_count:
        return ProducerLineDecision(False, 'grape_only_line', covered_indexes)
    if covered:
        return ProducerLineDecision(True, 'mixed_line_keeps_non_grape_anchor', covered_indexes)
    return ProducerLineDecision(True, 'no_grape_entity', ())
