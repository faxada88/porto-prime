#!/usr/bin/env python3
"""Local OSM address index and Porto Seguro airport terminal reference."""
import hashlib
import json
import sys
from pathlib import Path
rows, terminals = [], []
places = []
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
    name = tags.get('name') or tags.get('brand') or ''
    kind = 'HOTEL' if tags.get('tourism') in ('hotel', 'guest_house', 'hostel', 'motel', 'apartment', 'resort') else 'PLACE'
    street = tags.get('addr:street') or (tags.get('name') if tags.get('highway') else None)
    is_place = bool(name and (tags.get('tourism') or tags.get('shop') or tags.get('amenity') or tags.get('office') or tags.get('leisure')))
    if street or is_place:
        ref = hashlib.sha256(json.dumps([feature.get('properties', {}).get('@id'), street, name, positions], ensure_ascii=False).encode()).hexdigest()[:32]
        if is_place:
            lng = sum(p[0] for p in positions)/len(positions)
            lat = sum(p[1] for p in positions)/len(positions)
        places.append({'id': ref, 'name': name if is_place else street, 'kind': kind if is_place else 'STREET',
                       'street': tags.get('addr:street', '') if is_place else street, 'number': tags.get('addr:housenumber', ''),
                       'city': tags.get('addr:city', ''), 'neighborhood': tags.get('addr:suburb', '') or tags.get('addr:neighbourhood', ''),
                       'postalCode': tags.get('addr:postcode', ''), 'latitude': lat, 'longitude': lng})
    if street:
        rows.append({'street': street, 'number': tags.get('addr:housenumber', ''),
                     'city': tags.get('addr:city', ''), 'neighborhood': tags.get('addr:suburb', ''),
                     'postalCode': tags.get('addr:postcode', ''), 'latitude': lat, 'longitude': lng})
output = Path(sys.argv[1])
output.write_text(json.dumps(rows, ensure_ascii=False), encoding='utf-8')
output.with_name('places.json').write_text(json.dumps(places, ensure_ascii=False), encoding='utf-8')
origin = output.with_name('airport-origin.json')
if terminals:
    origin.write_text(json.dumps(max(terminals, key=lambda r: r['vertices'])), encoding='utf-8')
else:
    origin.unlink(missing_ok=True)
print(f'{len(rows)} ruas e {len(places)} locais indexados localmente.', file=sys.stderr)
