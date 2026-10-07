#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspaces/porto-prime"
BRANCH="feat/mobile-production-flow"

cd "$ROOT"
git pull --ff-only origin "$BRANCH"

cd "$ROOT/apps/admin"
npm install
npm run build

cd "$ROOT/apps/mobile"
flutter pub get
flutter build web --release --no-wasm-dry-run

echo
echo "Frontend Porto Prime atualizado e compilado com sucesso."
echo "Admin: apps/admin"
echo "App Web: apps/mobile/build/web"
