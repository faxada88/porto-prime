#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/apps/mobile"
export CI=true BOT=true
flutter pub get
flutter build web --release
printf '%s\n' 'Frontend atualizado. Reinicie o Flutter e atualize o navegador.'
