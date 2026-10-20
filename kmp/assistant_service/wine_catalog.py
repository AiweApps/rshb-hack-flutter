"""Read-only published wine cards, with exact source-bound gastronomy metadata."""
from copy import deepcopy
from functools import lru_cache
import hashlib
import json
from pathlib import Path
import re
import unicodedata


def _normalized(value: str) -> str:
    return unicodedata.normalize("NFKC", value).casefold().replace("ё", "е")


class WineCatalog:
    def __init__(self):
        path = Path(__file__).with_name("catalogs") / "wines.json"
        body = path.read_bytes()
        document = json.loads(body)
        coverage = json.loads(path.with_name("wines-coverage.json").read_bytes())
        if hashlib.sha256(body).hexdigest() != coverage.get("catalog_sha256"):
            raise ValueError("Wine catalog differs from its source coverage manifest")
        if document.get("schema_version") != 1 or not isinstance(document.get("cards"), dict):
            raise ValueError("Unsupported wine catalog schema")
        self.snapshot = document["snapshot"]
        self.sha256 = hashlib.sha256(body).hexdigest()
        self.cards = document["cards"]
        if len(self.cards) != coverage.get("published_cards") or len(self.cards) != coverage.get("exported_cards"):
            raise ValueError("Incomplete published wine catalog")
        self._search = {}
        for slug, card in self.cards.items():
            if card.get("slug") != slug or not card.get("in_catalog"):
                raise ValueError("Unpublished or mismatched wine card")
            self._search[slug] = _normalized(" ".join(str(card.get(key) or "") for key in
                ("title", "producer", "slug", "grapes", "region", "category")))

    def get(self, slug: str) -> dict | None:
        row = self.cards.get(slug)
        return deepcopy(row) if row else None

    def search(self, query: str, limit: int = 10) -> tuple[list[dict], int]:
        tokens = re.findall(r"[\w]+", _normalized(query))
        if not tokens:
            return [], 0
        matches = [slug for slug, text in self._search.items() if all(token in text for token in tokens)]
        matches.sort(key=lambda slug: (not _normalized(self.cards[slug]["title"]).startswith(_normalized(query)),
                                       _normalized(self.cards[slug]["title"]), slug))
        return [self.get(slug) for slug in matches[:limit]], len(matches)

    def enrich(self, summary: dict) -> dict:
        """Preserve recognition/source-photo context; metadata is not identity proof."""
        result = deepcopy(summary)
        card = self.cards.get(summary.get("slug"))
        if card:
            for key in ("description", "food_pairings", "serving_temperature", "color", "sugar",
                        "metadata_source", "page_url", "reference", "reference_url", "dishes", "alcohol"):
                result[key] = deepcopy(card.get(key))
            if card["metadata_source"]["status"] == "site_asserted":
                for key in ("category", "grapes"):
                    result[key] = deepcopy(card.get(key))
        return result


@lru_cache(maxsize=1)
def wine_catalog() -> WineCatalog:
    return WineCatalog()
