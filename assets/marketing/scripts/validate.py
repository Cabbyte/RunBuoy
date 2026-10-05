"""Validate export dimensions, color mode, canonical web copies and asset hashes."""
from pathlib import Path
import hashlib
import json
import struct

base = Path(__file__).resolve().parents[1]
root = base.parents[1]
manifest = json.loads((base / 'promoted/exports.json').read_text())
checks = []
for item in manifest['exports']:
    path = base / item['path']
    data = path.read_bytes()
    if path.suffix == '.png':
        assert data[:8] == b'\x89PNG\r\n\x1a\n', path
        w, h, bit_depth, color_type = struct.unpack('>IIBB', data[16:26])
        assert (w, h) == (item['width'], item['height']), path
        assert (bit_depth, color_type) == (8, 2), f'Expected opaque 8-bit RGB in {path}'
        if 'app-store' in item['path']:
            assert (w, h) == (1320, 2868), path
    item['sha256'] = hashlib.sha256(data).hexdigest()
    item['bytes'] = len(data)
    if item['path'].startswith('promoted/web/'):
        rel = item['path'].removeprefix('promoted/web/')
        dest = root / 'website/docs/public' / ('og.png' if rel == 'og.png' else f'marketing/{rel}')
        assert data == dest.read_bytes(), f'Web copy differs: {dest}'
    checks.append(item)
assert len(list((base / 'promoted/app-store').glob('*/*.png'))) == 12
for source in (base / 'sources/screenshots').glob('*/*.png'):
    data = source.read_bytes()
    assert struct.unpack('>II', data[16:24]) == (1320, 2868), source
captures = json.loads((base / 'sources/captures.json').read_text())
for capture in captures['captures']:
    path = base / capture['path']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == capture['sha256'], f'Update capture provenance after replacing {path}'
result = {'status': 'passed', 'app_store_exports': 12, 'dimensions': '1320x2868', 'alpha': False, 'assets': checks}
(base / 'verification/export-validation.json').write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
print('PASS: 12 opaque 1320x2868 App Store PNGs; source sizes and website copies verified.')
