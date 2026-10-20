"""Exact decimal-literal matching for candidate diagnostics.

This module only distinguishes complete decimal literals. It does not remove
integer, year, strength, or other numeric evidence from text.
"""
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
import re


_DECIMAL = re.compile(r'(?<![\w.,])(?P<value>\d+(?:[.,]\d+))(?![\w.,])', re.UNICODE)


@dataclass(frozen=True)
class DecimalLiteral:
    raw: str
    start: int
    end: int
    value: Decimal


def find_decimal_literals(text):
    """Return complete decimal literals; adjacent digits/letters/punctuation block a partial read."""
    found = []
    for match in _DECIMAL.finditer(str(text)):
        raw = match.group('value')
        try:
            value = Decimal(raw.replace(',', '.'))
        except InvalidOperation:
            continue
        if value.is_finite():
            found.append(DecimalLiteral(raw, match.start(), match.end(), value))
    return tuple(found)


def same_decimal_literal(observed, claimed):
    """True only when both strings contain one unambiguous, equal decimal value."""
    left, right = find_decimal_literals(observed), find_decimal_literals(claimed)
    if len(left) != 1 or len(right) != 1:
        return None
    return left[0].value == right[0].value
