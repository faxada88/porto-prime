#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/apps/admin"
npm install
npm run build
printf '%s\n' 'Central de Pagamentos e Arquivo instalada. Reinicie o Admin. Backend, banco e Flutter permanecem inalterados.'
