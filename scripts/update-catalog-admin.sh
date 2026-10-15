#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/apps/api"
# Additive, idempotent migration. Existing products and order data are untouched.
npx prisma db execute --file prisma/migrations/20261015_category_icon/migration.sql
npm test -- src/admin/catalog-category-delete.spec.ts
api_backup="$(mktemp -d /tmp/porto-catalog-api-XXXXXX)"
if [[ -d dist ]]; then cp -a dist "$api_backup/dist"; fi
api_ready=0
api_stopped=0
restore_previous_api() {
 if [[ "$api_stopped" == 1 && "$api_ready" != 1 && -d "$api_backup/dist" ]]; then
  fuser -k -TERM 3000/tcp 2>/dev/null || true
  for attempt in {1..20}; do if ! ss -ltnH | awk '{print $4}' | grep -Eq ':3000$'; then break; fi; sleep .25; done
  rm -rf -- dist
  cp -a "$api_backup/dist" dist
  old_entry=""
  for candidate in dist/main.js dist/src/main.js; do if [[ -f "$candidate" ]]; then old_entry="$candidate"; break; fi; done
  if [[ -n "$old_entry" ]]; then
   nohup node "$old_entry" > /tmp/porto-api.log 2>&1 < /dev/null &
   printf '%s\n' 'A atualização da API falhou; a versão compilada anterior foi restaurada.' >&2
  fi
 fi
}
trap restore_previous_api ERR
while read -r pid process_command; do
 [[ "$pid" == "$$" || "$pid" == "$PPID" ]] && continue
 process_dir="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
 if [[ "$process_dir" == "$project_root/apps/api" ]]; then
  case "$process_command" in *"nest start"*|*"nest.js start"*|*"npm run start:dev"*|*"node dist/main"*|*"node --enable-source-maps"*) kill -TERM "$pid" 2>/dev/null || true;; esac
 fi
done < <(ps -eo pid=,args=)
fuser -k -TERM 3000/tcp 2>/dev/null || true
for attempt in {1..40}; do if ! ss -ltnH | awk '{print $4}' | grep -Eq ':3000$'; then break; fi; sleep .25; done
api_stopped=1
npx prisma generate
npm run build
nohup npm run start:dev > /tmp/porto-api.log 2>&1 < /dev/null &
for attempt in {1..60}; do
 if curl --max-time 2 --fail --silent http://127.0.0.1:3000/api/health >/dev/null; then api_ready=1; break; fi
 sleep 1
done
if [[ "$api_ready" != 1 ]]; then printf '%s\n' 'A API não iniciou. Consulte /tmp/porto-api.log'; false; fi
bash "$project_root/scripts/update-admin-customers.sh"
printf '%s\n' 'Catálogo atualizado: ícones configuráveis e exclusão com transferência de produtos. API: 3000. Admin: 3002.'
