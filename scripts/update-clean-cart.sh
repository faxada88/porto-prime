#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/apps/mobile"
export CI=true BOT=true
flutter pub get
flutter build web --release
# Swap only the app after a successful compilation.
while read -r pid process_command; do
 process_dir="$(readlink "/proc/$pid/cwd" 2>/dev/null || true)"
 if [[ "$process_dir" == "$project_root/apps/mobile" ]]; then case "$process_command" in *"flutter run"*|*"flutter_tools.snapshot run"*) kill -TERM "$pid" 2>/dev/null || true;; esac; fi
done < <(ps -eo pid=,args=)
fuser -k -TERM 8090/tcp 2>/dev/null || true
for attempt in {1..20}; do if ! ss -ltnH | awk '{print $4}' | grep -Eq ':8090$'; then break; fi; sleep .25; done
nohup python3 -m http.server 8090 --bind 0.0.0.0 --directory build/web > /tmp/porto-flutter-8090.log 2>&1 < /dev/null &
if [[ -n "${CODESPACE_NAME:-}" ]] && command -v gh >/dev/null; then
 gh codespace ports visibility 8090:public -c "$CODESPACE_NAME" || true
 printf 'App: https://%s-8090.app.github.dev/\n' "$CODESPACE_NAME"
fi
printf '%s\n' 'Carrinho simplificado e botão de continuar visível. Backend, Admin e pagamentos preservados.'
