#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/apps/api"
npx --no-install prisma db execute --file prisma/migrations/20261008190000_catalog_control/migration.sql
npx --no-install prisma db execute --file prisma/migrations/20261008193000_admin_finance/migration.sql
npx --no-install prisma generate
cd "$project_root/apps/mobile"
export CI=true BOT=true
flutter clean
flutter pub get
printf '%s\n' 'Central financeira atualizada. Reinicie Nest, Admin e Flutter.'
