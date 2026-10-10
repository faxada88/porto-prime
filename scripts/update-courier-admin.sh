#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/apps/api"
npm install
cd "$project_root/apps/admin"
npm install
npx --no-install tsc --noEmit
printf '%s\n' 'Ficha completa e seletor de pendências atualizados. Reinicie Nest e Admin para carregar as alterações. Não é necessário atualizar o Flutter ou modificar o banco.'
