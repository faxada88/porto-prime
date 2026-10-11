#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
while read -r pid process_command; do
 process_dir="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
 if [[ "$process_dir" == "$project_root/apps/admin" ]]; then
  case "$process_command" in *"next dev"*|*"npm run dev"*) kill -TERM "$pid" 2>/dev/null || true;; esac
 fi
done < <(ps -eo pid=,args=)
fuser -k -TERM 3002/tcp 2>/dev/null || true
for attempt in {1..20}; do if ! ss -ltnH | awk '{print $4}' | grep -Eq ':3002$'; then break; fi; sleep .25; done
cd "$project_root/apps/admin"
if [[ -d .next ]]; then cache_backup="$(mktemp -d /tmp/porto-payment-archive-XXXXXX)"; mv .next "$cache_backup/next"; fi
npm install
npm run build
nohup env API_INTERNAL_URL=http://127.0.0.1:3000/api npm run dev -- --hostname 0.0.0.0 --port 3002 > /tmp/porto-admin.log 2>&1 < /dev/null &
printf '%s\n' 'Pagamentos e Arquivo redesenhados e alinhados. Admin iniciando na porta 3002; API e Flutter preservados.'
