#!/usr/bin/env python3
"""Local OSM address index and Porto Seguro airport terminal reference."""
import json
import sys
from pathlib import Path
rows, terminals = [], []
def points(value):
    if not value:
        return []
    if len(value) >= 2 and isinstance(value[0], (int, float)):
        return [value[:2]]
    return [p for item in value for p in points(item)]
for raw in sys.stdin:
    raw = raw.strip().lstrip('\x1e')
    if not raw:
        continue
    feature = json.loads(raw)
    tags = feature.get('properties', {})
    positions = points(feature.get('geometry', {}).get('coordinates', []))
    if not positions:
        continue
    lng, lat = positions[len(positions)//2]
    if tags.get('aeroway') == 'terminal':
        x = sum(p[0] for p in positions) / len(positions)
        y = sum(p[1] for p in positions) / len(positions)
        # SBPS terminal, excluding terminals in other regional airports.
        if -39.09 < x < -39.06 and -16.46 < y < -16.42:
            terminals.append({'longitude': x, 'latitude': y, 'vertices': len(positions)})
    street = tags.get('addr:street') or (tags.get('name') if tags.get('highway') else None)
    if street:
        rows.append({'street': street, 'number': tags.get('addr:housenumber', ''),
                     'city': tags.get('addr:city', ''), 'neighborhood': tags.get('addr:suburb', ''),
                     'postalCode': tags.get('addr:postcode', ''), 'latitude': lat, 'longitude': lng})
output = Path(sys.argv[1])
output.write_text(json.dumps(rows, ensure_ascii=False), encoding='utf-8')
origin = output.with_name('airport-origin.json')
if terminals:
    origin.write_text(json.dumps(max(terminals, key=lambda r: r['vertices'])), encoding='utf-8')
else:
    origin.unlink(missing_ok=True)
print(f'{len(rows)} ruas/pontos indexados localmente.', file=sys.stderr)
