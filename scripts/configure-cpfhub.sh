#!/usr/bin/env bash
# Configure only the API environment; never include the credential in Git or Flutter.
set +x
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
if [[ -z "${CPFHUB_API_KEY:-}" ]]; then
  read -r -s -p 'Cole a chave do CPFHub (entrada oculta): ' CPFHUB_API_KEY
  printf '\n'
fi
if [[ ! "$CPFHUB_API_KEY" =~ ^[A-Za-z0-9_-]{16,200}$ ]]; then
  printf 'Chave inválida. Nenhum arquivo foi alterado.\n' >&2
  exit 1
fi
export CPFHUB_API_KEY
python3 - <<'PY'
import os, re, tempfile
from pathlib import Path
path = Path('apps/api/.env')
text = path.read_text() if path.exists() else ''
text = re.sub(r'^\s*(?:export\s+)?CPFHUB_API_KEY\s*=.*(?:\n|$)', '', text, flags=re.MULTILINE)
if text and not text.endswith('\n'):
    text += '\n'
text += 'CPFHUB_API_KEY=' + os.environ['CPFHUB_API_KEY'] + '\n'
fd, temporary = tempfile.mkstemp(prefix='.cpfhub-env-', dir=path.parent)
try:
    with os.fdopen(fd, 'w') as output:
        output.write(text)
    os.chmod(temporary, 0o600)
    os.replace(temporary, path)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
PY
unset CPFHUB_API_KEY
printf 'CPFHub configurado na API. Reinicie Nest e Flutter para carregar as alterações.\n'
