#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/apps/mobile"
export CI=true BOT=true
flutter pub get
flutter build web --release
printf '%s\n' 'Frontend Porto Prime atualizado e compilado. Reinicie o Flutter e recarregue a página para carregar a nova interface. Backend, Admin, banco e integrações não foram modificados por esta atualização.'
