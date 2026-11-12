"""Generate canonical Unicode NFC tables using Python's standard Unicode data.
Runtime normalization is pure GDScript and does not invoke Python.
"""
import json
import pathlib
import unicodedata as u
result = {'decomposition': {}, 'combining': {}, 'composition': {}}
for code in range(0x110000):
    char = chr(code)
    decomposition = u.decomposition(char)
    combining = u.combining(char)
    if combining:
        result['combining'][str(code)] = combining
    if decomposition and not decomposition.startswith('<'):
        parts = [int(x, 16) for x in decomposition.split()]
        result['decomposition'][str(code)] = parts
        if len(parts) == 2 and u.normalize('NFC', ''.join(map(chr, parts))) == char:
            result['composition'][','.join(map(str, parts))] = code
root = pathlib.Path(__file__).resolve().parents[1]
(root / 'godot/assets/content/unicode-nfc.json').write_text(json.dumps(result, separators=(',', ':')))
