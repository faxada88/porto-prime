#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/apps/api"
npm install
npx --no-install prisma db execute --file prisma/migrations/20261010140000_courier_demand_signal/migration.sql
npx --no-install prisma db execute --file prisma/migrations/20261010160000_demand_bonus/migration.sql
npx --no-install prisma db execute --file prisma/migrations/20261010200000_customer_demand_surcharge/migration.sql
npx --no-install prisma db execute --file prisma/migrations/20261010210000_order_item_availability/migration.sql
npx --no-install prisma generate
npm run build
cd "$project_root/apps/admin"
npm install
npm run build
printf '%s\n' 'Atendimento de itens indisponíveis instalado. Reinicie Nest e Admin para ativar o novo endpoint. O banco deve estar iniciado antes de executar este script.'
