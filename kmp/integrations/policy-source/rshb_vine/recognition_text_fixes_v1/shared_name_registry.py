"""Source-confirmed printed text, separate from catalogue product identity.

The configuration contains complete literal front-label transcriptions. It does
not contain selected shared words or query outcomes. Shared words are derived
from distinct, source-bound card-local labels of the same catalogue producer.
Unknown product IDs stay unknown; a card-local witness is never a new SKU ID.
"""
from collections import defaultdict
from copy import deepcopy
import hashlib
import json
from pathlib import Path

from rshb_vine.system_selection_v4 import text


DEFAULT_PATH = 'config/recognition-shared-name-evidence-v1.json'
VERSION = 'source-confirmed-shared-printed-name-v1'


def _sha(value):
    if (not isinstance(value, str) or len(value) != 64 or
            any(char not in '0123456789abcdef' for char in value)):
        raise ValueError('Exact SHA-256 required for shared-name evidence')
    return value


class SharedNameRegistry:
    """Validated immutable evidence snapshot; no OCR, network or image decoding.

    ``expected_sha256`` must come from the candidate profile/source manifest.
    Pixel QA is an explicit source attestation in that pinned configuration.
    Gallery and catalogue metadata bind it to the actual runtime consumer.
    """

    def __init__(self, root, references, catalog, *, expected_sha256,
                 path=DEFAULT_PATH):
        root = Path(root).resolve()
        source = (root / path).resolve()
        if not source.is_relative_to(root):
            raise ValueError('Shared-name evidence must stay inside the bundle')
        data = source.read_bytes()
        self.sha256 = hashlib.sha256(data).hexdigest()
        if self.sha256 != _sha(expected_sha256):
            raise ValueError('Shared-name source configuration changed')
        document = json.loads(data)
        if (document.get('kind') != VERSION or document.get('schema_version') != 1 or
                document.get('policy') != {
                    'tokens': 'existing_tokenizer_primary_normalized_alphabetic_forms',
                    'shared': 'same_producer_distinct_card_local_source_labels',
                    'minimum_distinct_labels': 2,
                    'effect': 'only_remove_source_shared_contributions_from_name_exclusivity',
                    'identity': 'no_product_or_exact_SKU_promotion',
                }):
            raise ValueError('Unsupported shared-name evidence contract')
        by_slug = {row['slug']: row for row in catalog}
        if len(by_slug) != len(catalog):
            raise ValueError('Duplicate catalogue cards in shared-name consumer')
        entries, words = {}, defaultdict(list)
        records = document.get('labels')
        if not isinstance(records, list) or not records:
            raise ValueError('Shared-name source-label evidence is empty')
        for record in records:
            slug = record['catalog_slug']
            if slug in entries or slug not in by_slug:
                raise ValueError('Shared-name source card missing or repeated')
            row = by_slug[slug]
            producer = record['producer']
            if (producer != row['fields'].get('Винодельня') or
                    record['catalog_title'] != row['fields'].get('Название вина')):
                raise ValueError('Shared-name catalogue binding changed: ' + slug)
            producer_key = text.base_norm(producer)
            if not producer_key or producer_key != record['producer_key']:
                raise ValueError('Shared-name producer is not an exact catalogue key')
            scope = record['identity_scope']
            if (scope.get('kind') != 'card_local_label_only' or
                    scope.get('product_id') is not None or scope.get('exact_SKU_confirmed') is not False):
                raise ValueError('Source-label text must not promote an unknown product ID')
            image_sha = _sha(record['image_sha256'])
            if row.get('selected_sha256') != image_sha:
                raise ValueError('Shared-name source is not the selected catalogue asset')
            binding = record['gallery_front_label']
            index = binding['reference_index']
            if type(index) is not int or not 0 <= index < len(references):
                raise ValueError('Shared-name gallery row missing')
            reference = references[index]
            expected = dict(slug=slug, kind='front_label', image_sha256=image_sha,
                            bbox=binding['bbox'], original_size=record['oriented_size'],
                            coordinate_space='EXIF-oriented original pixels')
            if any(reference.get(key) != value for key, value in expected.items()):
                raise ValueError('Shared-name source/geometry differs from runtime gallery')
            qa = record['pixel_QA']
            if (qa.get('status') != 'direct_pixels_reviewed' or
                    qa.get('image_sha256') != image_sha or qa.get('method') != 'view_image' or
                    qa.get('transcription_scope') != 'complete_visible_front_label_text' or
                    not isinstance(qa.get('evidence_path'), str)):
                raise ValueError('A gallery-OCR candidate is not source-confirmed text')
            _sha(qa['evidence_sha256'])
            lines = record['literal_lines']
            if not isinstance(lines, list) or not lines or any(not isinstance(line, str) or not line.strip() for line in lines):
                raise ValueError('Complete literal source-label transcription required')
            tokens = {token.forms[0] for line in lines for token in text.tokenize(line)
                      if token.forms[0].isalpha()}
            item = dict(catalog_slug=slug, producer_key=producer_key,
                        image_sha256=image_sha, reference_index=index,
                        identity_scope=deepcopy(scope), tokens=frozenset(tokens))
            entries[slug] = item
            for token in tokens:
                words[(producer_key, token)].append(item)
        # Store private copies. Public methods return new JSON-compatible values.
        self._entries = entries
        self._shared = {
            key: tuple(rows) for key, rows in words.items()
            if len({row['catalog_slug'] for row in rows}) >= 2 and
            len({row['image_sha256'] for row in rows}) >= 2
        }
        self.identity = dict(version=VERSION, config_path=str(Path(path)),
                             config_sha256=self.sha256, source_labels=len(entries),
                             shared_producer_tokens=len(self._shared),
                             identity_scope='card-local text witnesses; no product IDs added')

    def witnesses(self, slug, claim_token):
        """Other exact source labels sharing this literal normalized name word.

        Skeleton/fuzzy similarity is not source proof. The normalizer is the
        released tokenizer; the query matcher and its grades stay unchanged.
        """
        own = self._entries.get(slug)
        if own is None or claim_token not in own['tokens']:
            return []
        return [dict(catalog_slug=row['catalog_slug'], image_sha256=row['image_sha256'],
                     reference_index=row['reference_index'],
                     identity_scope=deepcopy(row['identity_scope']))
                for row in self._shared.get((own['producer_key'], claim_token), ())
                if row['catalog_slug'] != slug and row['image_sha256'] != own['image_sha256']]

    def describe(self):
        return dict(self.identity, derived_shared_tokens=[
            dict(producer_key=producer, token=token,
                 labels=sorted(row['catalog_slug'] for row in rows))
            for (producer, token), rows in sorted(self._shared.items())])
