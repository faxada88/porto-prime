#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$project_root/scripts/start-routing.sh"
cd "$project_root/apps/api"
npm install
npx --no-install prisma db execute --file prisma/migrations/20261008190000_catalog_control/migration.sql
npx --no-install prisma db execute --file prisma/migrations/20261008193000_admin_finance/migration.sql
npx --no-install prisma db execute --file prisma/migrations/20261008200000_delivery_pricing/migration.sql
npx --no-install prisma generate
cd "$project_root/apps/admin"
npm install
cd "$project_root/apps/mobile"
export CI=true BOT=true
flutter clean
flutter pub get
printf '%s\n' 'Entrega atualizada. Configure o ponto real da distribuidora em Entrega e despacho e reinicie os três aplicativos.'
