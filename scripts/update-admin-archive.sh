#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/apps/admin"
npm install
npm run build
printf '%s\n' 'Aba Arquivo instalada. Reinicie o Admin e atualize o navegador. Nenhuma alteração no banco ou no Flutter é necessária.'
