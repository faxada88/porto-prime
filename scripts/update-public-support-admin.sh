#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/apps/api"
npx prisma db execute --file prisma/migrations/20261015_public_support/migration.sql
npm test -- src/support/public-support.service.spec.ts
bash "$project_root/scripts/update-catalog-admin.sh"
if [[ -n "${CODESPACE_NAME:-}" ]] && command -v gh >/dev/null; then
 gh codespace ports visibility 3000:public 3002:public -c "$CODESPACE_NAME" || true
 printf 'Admin: https://%s-3002.app.github.dev/\n' "$CODESPACE_NAME"
fi
printf '%s\n' 'Suporte sem login e comercial instalado: fila separada, protocolos, respostas e notas internas. API: 3000. Admin: 3002.'
