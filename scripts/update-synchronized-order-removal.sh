#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
for port in 3000 3001 3002 8084 8085 8086; do
  fuser -k -TERM "$port/tcp" 2>/dev/null || true
done
cd "$project_root/apps/api"
npm install
npx --no-install prisma db execute --file prisma/migrations/20261010210000_order_item_availability/migration.sql
npx --no-install prisma db execute --file prisma/migrations/20261010220000_admin_order_removal/migration.sql
npx --no-install prisma db execute --file prisma/migrations/20261011110000_synchronized_order_removal/migration.sql
npx --no-install prisma generate
npm run build
cd "$project_root/apps/admin"
npm install
npm run build
cd "$project_root/apps/mobile"
export CI=true BOT=true
flutter pub get
flutter build web --release
(cd "$project_root/apps/api" && nohup env PORT=3000 ROUTING_BASE_URL=http://127.0.0.1:5000 npm run start:dev > /tmp/porto-nest.log 2>&1 < /dev/null &)
(cd "$project_root/apps/admin" && nohup env API_INTERNAL_URL=http://127.0.0.1:3000/api npm run dev -- --hostname 0.0.0.0 --port 3002 > /tmp/porto-admin.log 2>&1 < /dev/null &)
(cd "$project_root/apps/mobile" && nohup env CI=true BOT=true flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8086 > /tmp/porto-flutter.log 2>&1 < /dev/null &)
printf '%s\n' 'Atualização aplicada. Nest, Admin e Flutter iniciando; acompanhe /tmp/porto-nest.log, /tmp/porto-admin.log e /tmp/porto-flutter.log.'
if [[ -n "${CODESPACE_NAME:-}" ]]; then
  printf 'ADMIN: https://%s-3002.app.github.dev/\nAPP: https://%s-8086.app.github.dev/\n' "$CODESPACE_NAME" "$CODESPACE_NAME"
fi
