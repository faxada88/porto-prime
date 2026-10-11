#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
while read -r pid process_command; do
 process_dir="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
 if [[ "$process_dir" == "$project_root/apps/api" || "$process_dir" == "$project_root/apps/admin" ]]; then
  case "$process_command" in *"nest start"*|*"nest.js start"*|*"next dev"*|*"npm run start:dev"*|*"npm run dev"*) kill -TERM "$pid" 2>/dev/null || true;; esac
 fi
done < <(ps -eo pid=,args=)
for port in 3000 3002; do fuser -k -TERM "$port/tcp" 2>/dev/null || true; done
for attempt in {1..20}; do if ! ss -ltnH | awk '{print $4}' | grep -Eq ':(3000|3002)$'; then break; fi; sleep .25; done
cd "$project_root/apps/api"
npm install
npx --no-install prisma db execute --file prisma/migrations/20261011150000_partner_referrals/migration.sql
npx --no-install prisma generate
npm run build
cd "$project_root/apps/admin"
if [[ -d .next ]]; then cache_backup="$(mktemp -d /tmp/porto-partners-admin-XXXXXX)"; mv .next "$cache_backup/next"; fi
npm install
npm run build
public_app_url="${FRONTEND_PUBLIC_URL:-}"
if [[ -z "$public_app_url" && -n "${CODESPACE_NAME:-}" ]]; then public_app_url="https://${CODESPACE_NAME}-8086.app.github.dev"; fi
(cd "$project_root/apps/api" && nohup env FRONTEND_PUBLIC_URL="$public_app_url" PORT=3000 ROUTING_BASE_URL=http://127.0.0.1:5000 npm run start:dev > /tmp/porto-nest.log 2>&1 < /dev/null &)
(cd "$project_root/apps/admin" && nohup env API_INTERNAL_URL=http://127.0.0.1:3000/api npm run dev -- --hostname 0.0.0.0 --port 3002 > /tmp/porto-admin.log 2>&1 < /dev/null &)
printf '%s\n' 'Parceiros, comissão e QR instalados. Nest: 3000. Admin: 3002. O banco e as rotas devem continuar ligados.'
