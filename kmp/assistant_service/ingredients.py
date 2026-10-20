"""Conservative exclusions for a human dinner, before model and basket admission.

This is not a nutrition/allergen classifier. Unknown food stays unknown; explicit
pet supplies and a beverage returned for a whole lemon are not dinner ingredients.
"""
import re


_PET = re.compile(
    r"\b(?:корм(?:а|ов|у|ом|е|ы)?|whiskas|вискас|kitekat|китикет|sheba|шеба|purina)\b"
    r"|\bдля\s+(?:кош\w*|котят\w*|собак\w*|щен\w*|животн\w*|грызун\w*)\b",
    re.IGNORECASE,
)


def ingredient_candidate(product: dict, query: str | None = None) -> bool:
    title = str(product.get("title") or "").casefold().replace("ё", "е")
    if _PET.search(title):
        return False
    # "лимон" also matches "лимонад" in the retailer's search. A whole-fruit
    # ingredient request must not silently become a drink, sweet or detergent.
    if (query or "").strip().casefold() in ("лимон", "лимоны"):
        if re.search(r"\b(?:лимонад\w*|напит\w*|сок\w*|вода|воды|сироп\w*|средств\w*|мыл\w*|шампун\w*|ароматизатор\w*)\b", title):
            return False
        return bool(re.search(r"\bлимон(?:ы|ов|а)?\b", title))
    return True
