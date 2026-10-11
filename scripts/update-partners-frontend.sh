#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
while read -r pid process_command; do
 process_dir="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
 if [[ "$process_dir" == "$project_root/apps/mobile" ]]; then case "$process_command" in *"flutter run"*|*"flutter_tools.snapshot run"*) kill -TERM "$pid" 2>/dev/null || true;; esac; fi
done < <(ps -eo pid=,args=)
fuser -k -TERM 8086/tcp 2>/dev/null || true
for attempt in {1..20}; do if ! ss -ltnH | awk '{print $4}' | grep -Eq ':8086$'; then break; fi; sleep .25; done
cd "$project_root/apps/mobile"
export CI=true BOT=true
flutter pub get
flutter build web --release
nohup env CI=true BOT=true flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8086 > /tmp/porto-flutter.log 2>&1 < /dev/null &
if [[ -n "${CODESPACE_NAME:-}" ]] && command -v gh >/dev/null; then
 gh codespace ports visibility 8086:public -c "$CODESPACE_NAME"
 printf 'Aplicativo e QR: https://%s-8086.app.github.dev/\n' "$CODESPACE_NAME"
fi
printf '%s\n' 'Frontend de parceiros atualizado. Aguarde a compilação em /tmp/porto-flutter.log. Execute a atualização Admin/backend primeiro.'
