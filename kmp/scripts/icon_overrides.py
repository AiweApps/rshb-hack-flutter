"""Compose the owner's scanner mark from existing outlined Figma components."""
from decimal import Decimal
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ARITY = {'M': 2, 'L': 2, 'C': 6, 'H': 1, 'V': 1, 'Z': 0}


def scaled_path(data: str, scale: Decimal, center: Decimal) -> str:
    """Uniform affine transform of this pinned absolute-path vocabulary."""
    tokens = re.findall(r'[A-Za-z]|[-+]?(?:\d*\.\d+|\d+\.?\d*)(?:[eE][-+]?\d+)?', data)
    output, index = [], 0
    offset = center * (1 - scale)
    while index < len(tokens):
        command = tokens[index]
        index += 1
        if command not in ARITY:
            raise ValueError(f'Unsupported source icon command: {command}')
        output.append(command)
        arity = ARITY[command]
        while arity and index < len(tokens) and not tokens[index].isalpha():
            values = [Decimal(v) * scale + offset for v in tokens[index:index + arity]]
            if len(values) != arity:
                raise ValueError('Incomplete source path command')
            index += arity
            output.append(' '.join(format(v.normalize(), 'f') if v else '0' for v in values))
    return ' '.join(output)


def apply_overrides(registry: dict) -> None:
    config = json.loads((ROOT / 'design/icons/overrides.json').read_text())['Camera']
    if config['kind'] != 'scan-frame-with-bottle':
        raise ValueError('Unknown scanner composition')
    frame = registry['icons'][config['frame_concept']]
    bottle = registry['icons'][config['bottle_concept']]
    # The first four closed contours are the corners. The fifth is the scan bar.
    # Taking the same four from an already-composed registry is idempotent.
    contours = re.findall(r'M .*?(?= M |$)', frame['paths'][0])
    if len(contours) < config['frame_subpaths']:
        raise ValueError('Pinned scanner frame no longer has four corners')
    frame_path = ' '.join(contours[:config['frame_subpaths']])
    scale, center = Decimal(config['bottle_scale']), Decimal(config['center'])
    paths = [frame_path] + [scaled_path(p, scale, center) for p in bottle['paths']]
    registry['icons']['Camera'] = {
        **frame,
        'paths': paths,
        'pathStyles': [dict(fill=True, strokeWidth=0)] * len(paths),
        'derived': 'Figma v3 scan corners, centre bar removed; Figma v3 bottle uniformly scaled to70% about12,12.',
        'owner_override': 'design/icons/overrides.json',
    }
    registry['provenance'] = ('Named Figma v3 components retain outlined geometry; Camera uses the owner-approved '
                              'scan-frame/bottle composition. Photo retains the nested v2 component present in v3.')
