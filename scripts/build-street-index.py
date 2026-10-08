#!/usr/bin/env python3
"""Build a small local street/address index from osmium GeoJSON sequence output."""
import json
import sys
from pathlib import Path
rows = []
for raw in sys.stdin:
    raw = raw.strip().lstrip('\x1e')
    if not raw:
        continue
    feature = json.loads(raw)
    tags = feature.get('properties', {})
    street = tags.get('addr:street') or (tags.get('name') if tags.get('highway') else None)
    if not street:
        continue
    coords = feature.get('geometry', {}).get('coordinates', [])
    def points(value):
        if len(value) >= 2 and isinstance(value[0], (int, float)):
            return [value[:2]]
        return [p for item in value for p in points(item)]
    positions = points(coords)
    if not positions:
        continue
    # A rua é apenas uma sugestão. O usuário confirma a entrada no mapa.
    lng, lat = positions[len(positions)//2]
    rows.append({'street': street, 'number': tags.get('addr:housenumber', ''),
                 'city': tags.get('addr:city', ''), 'latitude': lat, 'longitude': lng})
Path(sys.argv[1]).write_text(json.dumps(rows, ensure_ascii=False), encoding='utf-8')
print(f'{len(rows)} ruas/pontos indexados localmente.', file=sys.stderr)
