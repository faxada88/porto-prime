#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/apps/admin"
npm install
npm run build
printf '%s\n' 'Identidade visual do Admin atualizada e compilada. Reinicie o processo Next.js na porta 3001 e recarregue a página. Não há alteração de backend, banco, Flutter ou regras operacionais.'
