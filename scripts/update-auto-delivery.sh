#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$project_root/scripts/start-routing.sh"
if ! command -v osmium >/dev/null; then
  sudo apt-get update
  sudo apt-get install -y osmium-tool
fi
# Atualiza o índice mesmo quando as rotas já foram preparadas anteriormente.
osmium export "$project_root/.routing/porto.osm.pbf" -f geojsonseq | python3 "$project_root/scripts/build-street-index.py" "$project_root/.routing/streets.json"
cd "$project_root/apps/api"
npm install
npx --no-install prisma db execute --file prisma/migrations/20261008190000_catalog_control/migration.sql
npx --no-install prisma db execute --file prisma/migrations/20261008193000_admin_finance/migration.sql
npx --no-install prisma db execute --file prisma/migrations/20261008200000_delivery_pricing/migration.sql
npx --no-install prisma db execute --file prisma/migrations/20261009190000_address_place_search/migration.sql
npx --no-install prisma generate
node "$project_root/scripts/configure-airport-base.cjs"
cd "$project_root/apps/admin"
npm install
cd "$project_root/apps/mobile"
export CI=true BOT=true
flutter clean
flutter pub get
printf '%s\n' 'Atualização concluída. Reinicie Nest, Admin e Flutter nos terminais em que estão rodando. A base de teste é o Aeroporto de Porto Seguro.'
