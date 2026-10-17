#!/usr/bin/env bash
# Runs inside a disposable Debian container, not in Windows or Git Bash.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl osmium-tool python3
cd /project/.routing
if [[ ! -s nordeste.osm.pbf ]]; then
 curl --fail --location --retry 3 --output nordeste.osm.pbf.part https://download.geofabrik.de/south-america/brazil/nordeste-latest.osm.pbf
 mv nordeste.osm.pbf.part nordeste.osm.pbf
fi
osmium extract -b '-39.6,-16.9,-38.8,-15.9' -s complete_ways --overwrite nordeste.osm.pbf -o porto.osm.pbf
osmium export porto.osm.pbf -f geojsonseq | python3 /project/scripts/build-street-index.py /project/.routing/streets.json
