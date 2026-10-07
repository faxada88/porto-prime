#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
command -v flutter >/dev/null || { echo 'Flutter precisa estar instalado para compilar o frontend.' >&2; exit 1; }
command -v npm >/dev/null || { echo 'Node/npm precisam estar instalados para compilar o Admin.' >&2; exit 1; }
# CI desativa a detecção de infraestrutura por metadados do SDK.
export CI=true BOT=true
cd "$project_root/apps/mobile"
flutter --suppress-analytics pub get --enforce-lockfile
flutter --suppress-analytics analyze --no-fatal-infos --no-fatal-warnings
flutter --suppress-analytics test
flutter_args=(build web --release)
if [[ -n "${API_URL:-}" ]]; then flutter_args+=("--dart-define=API_URL=$API_URL"); fi
flutter --suppress-analytics "${flutter_args[@]}"
cd "$project_root/apps/admin"
npm ci --no-audit --no-fund
npm run build
printf '%s\n' 'Frontend compilado: apps/mobile/build/web e apps/admin/.next'
