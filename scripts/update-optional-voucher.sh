#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/apps/api"
npm install
npx --no-install prisma db execute --file prisma/migrations/20261010210000_order_item_availability/migration.sql
npx --no-install prisma db execute --file prisma/migrations/20261010220000_admin_order_removal/migration.sql
npx --no-install prisma generate
npm run build
cd "$project_root/apps/admin"
npm install
npm run build
cd "$project_root/apps/mobile"
export CI=true BOT=true
flutter pub get
flutter build web --release
printf '%s\n' 'Voucher opcional e resumo dos pedidos sincronizados. Reinicie Nest, Admin e Flutter. O banco precisa estar iniciado.'
