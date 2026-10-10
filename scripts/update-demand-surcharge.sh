#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$project_root/scripts/update-admin-demand.sh"
bash "$project_root/scripts/update-mobile-demand.sh"
printf '%s\n' 'Alta demanda na taxa de entrega e novo aviso do motoboy instalados. Reinicie Nest, Admin e Flutter; recarregue o navegador.'
