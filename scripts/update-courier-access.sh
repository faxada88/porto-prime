#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/apps/api"
npm install
npx --no-install prisma db execute --file prisma/migrations/20261010120000_requirement_cancellation/migration.sql
npx --no-install prisma generate
cd "$project_root/apps/admin"
npm install
npx --no-install tsc --noEmit
cd "$project_root/apps/mobile"
export CI=true BOT=true
flutter pub get
printf '%s\n' 'Correções instaladas. Reinicie os processos Nest e Admin e reinicie o Flutter para carregar esta versão. Candidaturas com pendências antigas canceladas ainda exigem aprovação explícita no Admin.'
