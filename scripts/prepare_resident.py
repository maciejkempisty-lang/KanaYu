"""Adapt the pinned MIT Rive sample, preserving animation and geometry.

Usage after flutter pub get: python3 scripts/prepare_resident.py
Only the alpha channels of the artboard background's two gradient stops change.
The original hash is checked before using the offsets (Rive runtime 0.1.11 schema).
"""
from pathlib import Path
import hashlib
import struct

root = Path(__file__).resolve().parent.parent
source = root / '.tooling/pub-cache/hosted/pub.dev/rive-0.14.11/example/assets/little_machine.riv'
data = bytearray(source.read_bytes())
assert hashlib.sha256(data).hexdigest() == '0dc144cd7289835c7285931a7a3040a0c147cca03fe61a170cd64401de14c214'
for offset, expected in [(10544, 0xfffdf9c6), (10554, 0xffdfadfd)]:
    assert struct.unpack_from('<I', data, offset)[0] == expected
    struct.pack_into('<I', data, offset, expected & 0x00ffffff)
(root / 'assets/rive/yuu_machine.riv').write_bytes(data)
