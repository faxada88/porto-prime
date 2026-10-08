#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
routing_data="$project_root/.routing"
routing_image="${OSRM_IMAGE:-ghcr.io/project-osrm/osrm-backend:26.10.0-debian}"
mkdir -p "$routing_data"
if ! command -v docker >/dev/null || ! docker info >/dev/null 2>&1; then
  printf '%s\n' 'Docker precisa estar disponível neste Codespace para iniciar o roteador local.' >&2
  exit 1
fi
if [[ ! -f "$routing_data/ready-v1" ]]; then
  if ! command -v osmium >/dev/null; then
    sudo apt-get update
    sudo apt-get install -y osmium-tool
  fi
  if [[ ! -s "$routing_data/nordeste.osm.pbf" ]]; then
    curl --fail --location --retry 3 --output "$routing_data/nordeste.osm.pbf.part" https://download.geofabrik.de/south-america/brazil/nordeste-latest.osm.pbf
    mv "$routing_data/nordeste.osm.pbf.part" "$routing_data/nordeste.osm.pbf"
  fi
  # Recorte regional: Porto Seguro e entorno; preserva todos os nós das vias.
  osmium extract -b "${ROUTING_BBOX:--39.6,-16.9,-38.8,-15.9}" -s complete_ways --overwrite "$routing_data/nordeste.osm.pbf" -o "$routing_data/porto.osm.pbf"
  osmium export "$routing_data/porto.osm.pbf" -f geojsonseq | python3 "$project_root/scripts/build-street-index.py" "$routing_data/streets.json"
  docker run --rm -v "$routing_data:/data" "$routing_image" osrm-extract -t 2 -p /opt/car.lua /data/porto.osm.pbf
  docker run --rm -v "$routing_data:/data" "$routing_image" osrm-partition -t 2 /data/porto.osrm
  docker run --rm -v "$routing_data:/data" "$routing_image" osrm-customize -t 2 /data/porto.osrm
  touch "$routing_data/ready-v1"
fi
if docker container inspect porto-prime-routing >/dev/null 2>&1; then
  docker start porto-prime-routing >/dev/null
else
  docker run -d --name porto-prime-routing --restart unless-stopped -p 127.0.0.1:5000:5000 -v "$routing_data:/data:ro" "$routing_image" osrm-routed --algorithm mld /data/porto.osrm >/dev/null
fi
for ((attempt=0; attempt<60; attempt++)); do
  if curl --silent --fail 'http://127.0.0.1:5000/nearest/v1/driving/-39.064,-16.449?number=1' >/dev/null; then
    printf '%s\n' 'Rotas locais prontas. Dados © OpenStreetMap contributors · ODbL.'
    exit 0
  fi
  sleep 1
done
printf '%s\n' 'O roteador não respondeu. Consulte docker logs porto-prime-routing.' >&2
exit 1
