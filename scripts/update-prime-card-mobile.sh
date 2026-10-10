#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/apps/mobile"
export CI=true BOT=true
flutter pub get
flutter build web --release
printf '%s\n' 'Cartão Porto Prime disponível no Perfil. Reinicie Flutter e recarregue a página.'
