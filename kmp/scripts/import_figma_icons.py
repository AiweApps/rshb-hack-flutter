"""Import the named 24x24 components from the pinned Figma v3 SVG export.

Figma has outlined 37 icons; the Photo component retains its actual 1.75 strokes.
Only coordinates are translated to their component origin. No image tracing.
"""
from decimal import Decimal
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from icon_overrides import apply_overrides

ROOT = Path(__file__).resolve().parents[1]
DESIGN = ROOT / 'design/icons'
SOURCE = DESIGN / 'figma-v3/source.svg'
NAMES = 'home history heart profile scan search pin flash filter back close arrow-out plus minus star glass grape bottle assistant compare menu compose mic send check chevron-right chevron-down chevron-up photo flash-off fork-knife bag gear chevron-left arrow-up expand more plus-circle'.split()
CONCEPTS = 'Home History Favorite Account Camera Search Location Flash Filter Back Close External Add Remove Star Wine Grape Bottle Chat Compare Menu NewChat Mic Send Check ChevronRight ChevronDown ChevronUp Photos FlashOff Dinner Store Settings ChevronLeft ArrowUp Expand More PlusCircle'.split()
ARITY = {'M': 2, 'L': 2, 'C': 6, 'H': 1, 'V': 1, 'Z': 0}

def number(value):
    return format(value.normalize(), 'f') if value else '0'

def translate(data, ox, oy, mirror=False):
    tokens = re.findall(r'[A-Za-z]|[-+]?(?:\d*\.\d+|\d+\.?\d*)(?:[eE][-+]?\d+)?', data)
    output, i = [], 0
    while i < len(tokens):
        command = tokens[i]; i += 1
        if command not in ARITY:
            raise ValueError(f'Unexpected export command: {command}')
        output.append(command)
        arity = ARITY[command]
        while arity and i < len(tokens) and not tokens[i].isalpha():
            values = [Decimal(n) for n in tokens[i:i+arity]]; i += arity
            for j, value in enumerate(values):
                if command == 'V':
                    values[j] = value - oy
                elif command == 'H' or j % 2 == 0:
                    values[j] = value - ox
                    if mirror: values[j] = Decimal(24) - values[j]
                else:
                    values[j] = value - oy
            output.append(' '.join(number(v) for v in values))
    return ' '.join(output)

def extract(group, ox, oy):
    paths, styles = [], []
    for e in group.iter():
        kind = e.tag.rsplit('}', 1)[-1]
        if kind == 'g': continue
        if kind == 'path':
            d = translate(e.attrib['d'], ox, oy)
        elif kind == 'rect':
            x = Decimal(e.attrib['x']) - ox; y = Decimal(e.attrib['y']) - oy
            w = Decimal(e.attrib['width']); h = Decimal(e.attrib['height']); r = Decimal(e.attrib.get('rx','0'))
            n = number
            d = f'M {n(x+r)} {n(y)} H {n(x+w-r)} A {n(r)} {n(r)} 0 0 1 {n(x+w)} {n(y+r)} V {n(y+h-r)} A {n(r)} {n(r)} 0 0 1 {n(x+w-r)} {n(y+h)} H {n(x+r)} A {n(r)} {n(r)} 0 0 1 {n(x)} {n(y+h-r)} V {n(y+r)} A {n(r)} {n(r)} 0 0 1 {n(x+r)} {n(y)} Z'
        elif kind == 'circle':
            x = Decimal(e.attrib['cx']) - ox; y = Decimal(e.attrib['cy']) - oy; r = Decimal(e.attrib['r']); n=number
            d = f'M {n(x-r)} {n(y)} A {n(r)} {n(r)} 0 1 0 {n(x+r)} {n(y)} A {n(r)} {n(r)} 0 1 0 {n(x-r)} {n(y)} Z'
        else: raise ValueError(f'Unexpected SVG shape {kind}')
        assert set(e.attrib) <= {'id','d','x','y','width','height','rx','cx','cy','r','fill','stroke','stroke-width','stroke-linecap','stroke-linejoin'}
        paths.append(d)
        styles.append({'fill':e.attrib.get('fill','none') != 'none','strokeWidth':float(e.attrib.get('stroke-width','0')) if e.attrib.get('stroke') else 0})
    return paths, styles

def main():
    source = SOURCE.read_bytes(); root = ET.fromstring(source)
    groups = [e for e in root[0] if e.tag.endswith('g')]
    assert [g.attrib['id'] for g in groups] == ['icon-v3/'+n for n in NAMES]
    registry = json.loads((DESIGN/'icons.json').read_text())
    registry.update(schema_version=2, stroke=1.5, state='tone', provenance='Exact named Figma v3 components; 24x24 origin translation only, outlined geometry retained. Photo retains the nested v2 component actually present in the v3 export.')
    for index, (name, concept, group) in enumerate(zip(NAMES,CONCEPTS,groups)):
        ox = Decimal(32+48*(index%19)); oy=Decimal(32+48*(index//19))
        paths, styles = extract(group, ox, oy)
        registry['icons'][concept] = dict(paths=paths, pathStyles=styles, filled=True, autoMirror=concept in {'Back','External','ChevronLeft','ChevronRight','NewChat'}, figma_name=name)
    # Existing semantic names remain stable for consumers. Selected state is the same outline.
    registry['icons']['FavoriteFilled'] = {**registry['icons']['Favorite'], 'aliasOf':'Favorite'}
    registry['icons']['Forward'] = {**registry['icons']['Back'], 'paths':[translate(d,Decimal(0),Decimal(0),mirror=True) for d in registry['icons']['Back']['paths']], 'derived':'horizontal mirror of back'}
    apply_overrides(registry)
    (DESIGN/'icons.json').write_text(json.dumps(registry,ensure_ascii=False,indent=2)+'\n')
    (DESIGN/'figma-v3/source.json').write_text(json.dumps(dict(figma_url='https://www.figma.com/design/o89XJ8gwRpBwb3rmg3OTyZ?node-id=431-7699',selected_section='Иконки v3',source_sha256=hashlib.sha256(source).hexdigest(),component_count=38,grid=24,layout=dict(columns=19,origin=[32,32],step=[48,48]),mapping=dict(zip(NAMES,CONCEPTS)),not_redrawn=True),ensure_ascii=False,indent=2)+'\n')
    print('Imported38 pinned Figma components;',len(registry['icons']),'stable app concepts')

if __name__ == '__main__': main()
