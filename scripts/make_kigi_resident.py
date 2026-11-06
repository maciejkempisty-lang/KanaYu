"""Original KanaYu vector resident, authored directly in the pinned Rive schema.

No sample geometry is reused. Rebuild after flutter pub get with Python 3.
The file contains an idle timeline and default state machine (float + blink).
"""
from pathlib import Path
import math
import re
import struct

ROOT = Path(__file__).resolve().parent.parent
SCHEMA = ROOT / '.tooling/pub-cache/hosted/pub.dev/rive_native-0.1.11/runtime/include/rive/generated'
props, fields = {}, {}
for path in SCHEMA.rglob('*_base.hpp'):
    source = path.read_text()
    cls = re.search(r'class (\w+) :', source)
    if cls:
        for key, value in re.findall(r'static const uint16_t (\w+) = (\d+);', source):
            props[f'{cls[1]}::{key}'] = int(value)
registry = (SCHEMA / 'core_registry.hpp').read_text().split('static int propertyFieldId(int propertyKey)')[1]
parts = re.split(r'return Core(\w+)Type::id;', registry)
for group, kind in zip(parts[0::2], parts[1::2]):
    for name in re.findall(r'case\s+(\w+Base::\s*\w+)\s*:', group):
        key = re.sub(r'\s', '', name)
        if key in props:
            fields[props[key]] = kind

def var(n):
    result = bytearray()
    while n > 127:
        result.append((n & 127) | 128)
        n >>= 7
    result.append(n)
    return result

data = bytearray(b'RIVE') + var(7) + var(0) + var(0) + var(0)
count = -1
objects = []
def obj(kind, values=None, component=True):
    global count
    if component: count += 1
    objects.append((kind, values or {}, count if component else None))
    return count

def encode(kind, values):
    data.extend(var(kind))
    for key, value in (values or {}).items():
        data.extend(var(key))
        typ = fields[key]
        if typ == 'String':
            value = value.encode('utf8')
            data.extend(var(len(value)) + value)
        elif typ == 'Double': data.extend(struct.pack('<f', value))
        elif typ == 'Color': data.extend(struct.pack('<I', value))
        elif typ == 'Bool': data.append(int(value))
        else: data.extend(var(value))
    data.append(0)

obj(23, component=False)
obj(1, {4: 'Yuu — Kigi', 7: 240.0, 8: 260.0, 236: 0})
body = obj(2, {4: 'float', 5: 0, 13: 120., 14: 142.})
INK, LEAF, LIGHT, PEACH = 0xFF3F5F34, 0xFFAACC78, 0xFFDEEBBD, 0xFFF4A574

def paint(shape, color, stroke=False):
    p = obj(24 if stroke else 20, {5: shape, **({47: 2.6, 48: 1, 49: 1} if stroke else {})})
    obj(18, {5: p, 37: color})

def ellipse(x, y, w, h, color, parent=body, rotation=0., outline=False, name=''):
    s = obj(3, {4: name, 5: parent, 13: float(x), 14: float(y), 15: rotation})
    obj(4, {5: s, 20: float(w), 21: float(h)})
    paint(s, color)
    if outline: paint(s, INK, True)
    return s

def curve(points, color, parent=body, closed=False, outline=False):
    s = obj(3, {5: parent})
    p = obj(16, {5: s, 32: closed})
    for x, y in points:
        obj(5, {5: p, 24: float(x), 25: float(y)})
    if closed: paint(s, color)
    if not closed or outline: paint(s, INK if outline else color, True)
    return s

def bez(a, b, c, d):
    return [tuple((1-t)**3*a[i]+3*(1-t)**2*t*b[i]+3*(1-t)*t*t*c[i]+t**3*d[i] for i in (0,1))
            for t in [j/16 for j in range(17)]]

# Back-to-front shapes. A tiny seed spirit with a sprout, not an existing character.
ellipse(120, 234, 100, 13, 0x203F5F34, parent=0)
ellipse(-34, 72, 34, 19, INK, rotation=-.2)
ellipse(33, 72, 34, 19, INK, rotation=.2)
ellipse(-67, 10, 22, 53, LEAF, rotation=-.6, outline=True)
ellipse(66, 2, 22, 57, LEAF, rotation=.65, outline=True)
ellipse(0, 14, 132, 143, LEAF, outline=True)
ellipse(-5, 37, 94, 82, LIGHT)
curve(bez((0,-55),(-7,-81),(3,-90),(6,-104)), INK)
curve(bez((2,-88),(-17,-116),(-45,-116),(-47,-101)) + bez((-47,-101),(-34,-81),(-12,-81),(2,-88))[1:], LEAF, closed=True, outline=True)
curve(bez((5,-92),(21,-123),(46,-120),(53,-110)) + bez((53,-110),(39,-88),(20,-86),(5,-92))[1:], LEAF, closed=True, outline=True)
curve(bez((-38,-102),(-22,-102),(-10,-94),(0,-89)), INK)
curve(bez((12,-96),(28,-104),(34,-108),(45,-109)), INK)
ellipse(-41, 19, 19, 11, PEACH)
ellipse(41, 19, 19, 11, PEACH)
eyes = obj(2, {4: 'blink', 5: body, 14: 2.})
ellipse(-25, 0, 10, 14, INK, parent=eyes)
ellipse(25, 0, 10, 14, INK, parent=eyes)
ellipse(-26.5, -3, 3, 4, 0xFFFBF5E5, parent=eyes)
ellipse(23.5, -3, 3, 4, 0xFFFBF5E5, parent=eyes)
curve(bez((-9,19),(-4,28),(5,28),(10,19)), INK)
ellipse(-18, 49, 7, 10, LEAF, rotation=-.5)
ellipse(0, 55, 7, 10, LEAF)
ellipse(18, 49, 7, 10, LEAF, rotation=.5)

obj(31, {55:'Breeze', 56:60, 57:240, 59:1}, False)
def keys(target, prop, values):
    obj(25, {51:target}, False)
    obj(26, {53:prop}, False)
    for frame, value in values:
        obj(30, {67:frame, 68:1, 70:float(value)}, False)
keys(body, 14, [(f,142-5*math.sin(f*math.pi/120)) for f in range(0,241,10)])
keys(body, 15, [(f,.025*math.sin(f*math.pi/120)) for f in range(0,241,10)])
keys(eyes, 17, [(0,1),(150,1),(156,.12),(162,1),(240,1)])
obj(53, {55:'Yuu'}, False)
obj(57, {138:'Breeze'}, False)
obj(63, component=False)  # Entry is state 0.
obj(65, {151:1}, False)  # Transition to state 1.
obj(61, {149:0}, False)
obj(62, component=False)
obj(64, component=False)
target = ROOT / 'assets/rive/yuu_kigi.riv'
# Rive's drawable list renders last-to-first. Keep each path's ordered vertices,
# reverse only shape groups, and remap references (including animation targets).
nodes, groups, current = [], [], []
for record in objects:
    kind, values, index = record
    if index is None: continue
    if kind in (1, 2):
        if current: groups.append(current); current = []
        nodes.append(record)
    else:
        if kind == 3 and current: groups.append(current); current = []
        current.append(record)
if current: groups.append(current)
components = nodes + [record for group in reversed(groups) for record in group]
remap = {record[2]: index for index, record in enumerate(components)}
encode(23, {})
for kind, values, index in components:
    values = dict(values)
    if 5 in values: values[5] = remap[values[5]]
    encode(kind, values)
for kind, values, index in objects:
    if index is not None or kind == 23: continue
    values = dict(values)
    if kind == 25: values[51] = remap[values[51]]
    encode(kind, values)
target.write_bytes(data)
print(f'{target}: {len(data)} bytes, {count+1} components')
