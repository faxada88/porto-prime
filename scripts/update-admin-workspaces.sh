#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Stop repository-local watchers as well as their listeners.
while read -r pid process_command; do
  process_dir="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
  if [[ "$process_dir" == "$project_root/apps/api" || "$process_dir" == "$project_root/apps/admin" ]]; then
    case "$process_command" in
      *"nest start"*|*"nest.js start"*|*"next dev"*|*"npm run start:dev"*|*"npm run dev"*) kill -TERM "$pid" 2>/dev/null || true ;;
    esac
  fi
done < <(ps -eo pid=,args=)
# Restart the app to receive customer profile and credit events.
for port in 3000 3001 3002 8086; do
  fuser -k -TERM "$port/tcp" 2>/dev/null || true
done
for attempt in {1..20}; do
  if ! ss -ltnH | awk '{print $4}' | grep -Eq ':(3000|3001|3002|8086)$'; then break; fi
  sleep 0.25
done
cd "$project_root/apps/api"
npm install
npx --no-install prisma generate
npm run build
cd "$project_root/apps/admin"
if [[ -d .next ]]; then
  admin_cache_backup="$(mktemp -d /tmp/porto-admin-cache-XXXXXX)"
  mv .next "$admin_cache_backup/next"
fi
npm install
npm run build
cd "$project_root/apps/mobile"
export CI=true BOT=true
flutter pub get
flutter build web --release
(cd "$project_root/apps/api" && nohup env PORT=3000 ROUTING_BASE_URL=http://127.0.0.1:5000 npm run start:dev > /tmp/porto-nest.log 2>&1 < /dev/null &)
(cd "$project_root/apps/admin" && nohup env API_INTERNAL_URL=http://127.0.0.1:3000/api npm run dev -- --hostname 0.0.0.0 --port 3002 > /tmp/porto-admin.log 2>&1 < /dev/null &)
(cd "$project_root/apps/mobile" && nohup env CI=true BOT=true flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8086 > /tmp/porto-flutter.log 2>&1 < /dev/null &)
printf '%s\n'  'Cadastro do cliente, motivos rápidos e central financeira atualizados. Nest, Admin e Flutter iniciando. Banco deve continuar ligado.'
