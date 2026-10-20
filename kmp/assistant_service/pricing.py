"""Retailer price units and purchase lots. Recipe text is never a price input."""
from copy import deepcopy
from decimal import Decimal, ROUND_HALF_UP, ROUND_CEILING
import math
import re


def _number(value):
    return value if type(value) in (int, float) and math.isfinite(value) and 0 <= value <= 1_000_000_000 else None


def _money(value):
    return value if type(value) is int and 0 <= value <= 1_000_000_000 else None


def priced_product(product: dict) -> dict:
    """Rebuild canonical fields from explicit retailer fields, including old snapshots."""
    result = dict(product)
    unit = product.get("unit")
    unit = unit if type(unit) is int and 0 <= unit <= 100 else None
    name = product.get("unit_name")
    name = name.strip()[:20] if isinstance(name, str) and name.strip() else None
    if unit is None:
        # Old server snapshots manufactured a default 'шт' while the source unit
        # had already been lost. Keep that historical string only as diagnostic.
        result["source_unit_name"] = product.get("source_unit_name", name)
        name = None
    normalized = (name or "").lower().rstrip(".")
    result.update(unit=unit, unit_name=name, price_kopeks=_money(product.get("price_kopeks")))
    for key in ("quantum", "quantum_step", "weight", "volume"):
        result[key] = _number(product.get(key))
    result["price_per_quantum_kopeks"] = _money(product.get("price_per_quantum_kopeks"))
    basis = "piece" if unit == 1 and normalized == "шт" else "weight" if unit == 2 and normalized == "кг" else "unknown"
    result["price_basis"] = basis
    lot = None
    if basis == "piece" and result["quantum"] in (None, 1000) and result["quantum_step"] in (None, 1000):
        # Source piece receipts use1000 for a single sellable item. Do not
        # silently ignore a vendor's different minimum/step while labelling1шт.
        lot = {"quantity": 1, "unit": "шт", "price_kopeks": result["price_kopeks"], "source": "retailer_unit"}
    elif basis == "weight":
        quantum, step, source_lot_price, rate = result["quantum"], result["quantum_step"], result["price_per_quantum_kopeks"], result["price_kopeks"]
        # Source admission: official lemon page 33773, q=step=380, rate22999/kg:
        # 0.38kg ->8740kop; two lots0.76kg ->17479kop (not8740*2).
        # The retail quantity UI proves thousandths-of-kg for this source contract.
        # A changed/minimum-vs-step format is held unknown until separately proven.
        if quantum and quantum == step and rate is not None:
            quantity = Decimal(str(quantum)) / 1000
            calculated = int((Decimal(rate) * quantity).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
            if source_lot_price is None or calculated == source_lot_price:
                lot = {"quantity": float(quantity), "unit": "кг", "price_kopeks": calculated,
                       "source": "retailer_quantum_ui_verified"}
    result["purchase_lot"] = lot
    return result


_MASS = re.compile(r"(?P<number>[0-9]+(?:[.,][0-9]+)?)\s*(?P<unit>кг|kg|г|гр|g)", re.IGNORECASE)


def required_mass_grams(text: str) -> Decimal | None:
    """Accept one explicit mass, not ranges, portions or prose with guessed amounts."""
    match = _MASS.fullmatch(text.strip())
    if match is None:
        return None
    value = Decimal(match["number"].replace(",", "."))
    if match["unit"].lower() in ("кг", "kg"):
        value *= 1000
    return value if 0 < value <= 1_000_000 else None


def _lot_mass_grams(product: dict) -> Decimal | None:
    if product.get("purchase_lot") is None:
        return None
    if product["price_basis"] == "weight":
        return Decimal(str(product["quantum"]))
    # Bare masterData.weight also occurs on drinks measured in ml. Admit piece
    # mass only when the source title independently states exactly that mass.
    weight = product.get("weight")
    if not weight or product.get("volume") not in (None, 0):
        return None
    title = product.get("title") or ""
    matches = list(_MASS.finditer(title))
    if len(matches) != 1:
        return None
    match = matches[0]
    if (match.start() and (title[match.start()-1].isalnum() or title[match.start()-1] in "×x*")) or (match.end() < len(title) and title[match.end()].isalpha()):
        return None
    mass = required_mass_grams(match[0])
    return mass if mass == Decimal(str(weight)) else None


def planner_product(product: dict) -> dict:
    """Expose the same admitted lot mass used by priced_row, never guessed mass."""
    product = priced_product(product)
    mass = _lot_mass_grams(product)
    if mass is not None:
        reason = None
    elif product["purchase_lot"] is None:
        reason = "purchase_lot_unknown"
    elif product.get("volume") not in (None, 0):
        reason = "source_volume_present"
    else:
        reason = "source_mass_not_verified"
    # Omit images and long provenance from model context, not from stored events.
    result = {key: product.get(key) for key in (
        "product_id", "title", "price_kopeks", "balance_state", "price_basis",
        "purchase_lot", "unit", "unit_name", "weight", "volume", "quantum", "quantum_step",
        "price_per_quantum_kopeks",
        "checked_at", "source", "store_id", "url")}
    result["quantity_planning"] = {
        "lot_price_known": product["purchase_lot"] is not None and
                           product["purchase_lot"]["price_kopeks"] is not None,
        "lot_mass_grams": float(mass) if mass is not None else None,
        "mass_recipe_supported": mass is not None,
        "mass_unknown_reason": reason,
        "max_purchase_lots": 20,
        "max_recipe_mass_grams": float(mass * 20) if mass is not None else None,
    }
    return result


def priced_row(product: dict, packages: int, recipe_quantity: str = "") -> dict:
    product = priced_product(product)
    lot = product.get("purchase_lot")
    price = lot.get("price_kopeks") if lot else None
    required = required_mass_grams(recipe_quantity)
    lot_mass = _lot_mass_grams(product)
    coverage = "explicit_lot_count"
    requested_packages = packages
    if required is not None:
        if lot_mass:
            minimum = int((required / lot_mass).to_integral_value(rounding=ROUND_CEILING))
            if minimum <= 20:
                packages = max(packages, minimum)
                coverage = "verified_mass"
            else:
                coverage = "unverified_recipe_quantity"
        else:
            coverage = "unverified_recipe_quantity"
    elif product["price_basis"] == "weight" or _MASS.search(recipe_quantity):
        # A lot count alone does not establish that a weight-priced ingredient
        # is enough for the recipe. Require an unambiguous g/kg amount.
        coverage = "unverified_recipe_quantity"
    if price is not None and product["price_basis"] == "weight":
        quantity = Decimal(str(product["quantum"])) * packages / 1000
        line_total = int((Decimal(product["price_kopeks"]) * quantity).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
        purchase_quantity = float(quantity)
    else:
        line_total = price * packages if price is not None else None
        purchase_quantity = lot["quantity"] * packages if lot else None
    if coverage == "unverified_recipe_quantity":
        line_total = None
    return {"product": product, "packages": packages, "recipe_quantity": recipe_quantity,
            "line_total_kopeks": line_total,
            "purchase_quantity": purchase_quantity,
            "purchase_unit": lot["unit"] if lot else None,
            "quantity_status": coverage,
            "required_mass_grams": float(required) if required is not None else None,
            "purchased_mass_grams": float(lot_mass * packages) if lot_mass else None,
            "quantity_adjusted": packages != requested_packages}


def reprice_list(data: dict) -> dict:
    result = deepcopy(data)
    rows = result.get("items")
    if not isinstance(rows, list):
        return result
    rebuilt = []
    for row in rows:
        if not isinstance(row, dict) or not isinstance(row.get("product"), dict):
            continue
        count = row.get("packages")
        if type(count) is not int or not 1 <= count <= 20:
            continue
        priced = priced_row(row["product"], count, str(row.get("recipe_quantity") or "")[:60])
        priced["quantity_adjusted"] = priced["quantity_adjusted"] or row.get("quantity_adjusted") is True
        rebuilt.append({**row, **priced})
    result["items"] = rebuilt
    known = bool(rebuilt) and len(rebuilt) == len(rows) and all(row["line_total_kopeks"] is not None for row in rebuilt)
    result["total_kopeks"] = sum(row["line_total_kopeks"] for row in rebuilt) if known else None
    result["pricing_status"] = "verified_lots" if known else "incomplete_price_basis"
    return result
