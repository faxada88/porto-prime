#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
command -v flutter >/dev/null || { printf '%s\n' 'Flutter não está disponível no PATH. Nenhum serviço foi parado.'; exit 1; }
command -v python3 >/dev/null
cd "$project_root/apps/api"
npm install
npx --no-install prisma db execute --file prisma/migrations/20261011230000_delivery_chat/migration.sql
npx --no-install prisma generate
npm run build
cd "$project_root/apps/mobile"
export CI=true BOT=true
flutter pub get
flutter build web --release
# Restart only after both builds succeed. Admin, PostgreSQL and routing stay up.
while read -r pid process_command; do
 process_dir="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
 if [[ "$process_dir" == "$project_root/apps/api" ]]; then
  case "$process_command" in *"nest start"*|*"nest.js start"*|*"npm run start:dev"*) kill -TERM "$pid" 2>/dev/null || true;; esac
 elif [[ "$process_dir" == "$project_root/apps/mobile" ]]; then
  case "$process_command" in *"flutter run"*|*"flutter_tools.snapshot run"*) kill -TERM "$pid" 2>/dev/null || true;; esac
 fi
done < <(ps -eo pid=,args=)
for port in 3000 8090; do fuser -k -TERM "$port/tcp" 2>/dev/null || true; done
for attempt in {1..20}; do if ! ss -ltnH | awk '{print $4}' | grep -Eq ':(3000|8090)$'; then break; fi; sleep .25; done
public_app_url="${FRONTEND_PUBLIC_URL:-}"
if [[ -z "$public_app_url" && -n "${CODESPACE_NAME:-}" ]]; then public_app_url="https://${CODESPACE_NAME}-8090.app.github.dev"; fi
(cd "$project_root/apps/api" && nohup env FRONTEND_PUBLIC_URL="$public_app_url" PORT=3000 ROUTING_BASE_URL=http://127.0.0.1:5000 npm run start:dev > /tmp/porto-nest.log 2>&1 < /dev/null &)
# Serve the optimized Flutter release, avoiding another debug compilation.
(cd "$project_root/apps/mobile" && nohup python3 -m http.server 8090 --bind 0.0.0.0 --directory build/web > /tmp/porto-flutter-8090.log 2>&1 < /dev/null &)
if [[ -n "${CODESPACE_NAME:-}" ]] && command -v gh >/dev/null; then
 gh codespace ports visibility 3000:public 8090:public -c "$CODESPACE_NAME" || true
 printf 'App: https://%s-8090.app.github.dev/\n' "$CODESPACE_NAME"
fi
printf '%s\n' 'Envio de mensagens corrigido e abertura automática do chat do destinatário instalada. App: 8090. Nest: 3000. Admin e rotas preservados.'
