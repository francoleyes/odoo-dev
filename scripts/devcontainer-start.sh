#!/usr/bin/env bash
set -euo pipefail

# postStartCommand del devcontainer.
# Regenera el addons_path en odoo.conf según lo que haya en ./repositories.
bash /usr/local/bin/generate-addons-path "${ODOO_VERSION:-}" || true

# Evitar que la extensión de Python cree un .venv falso en el workspace
rm -rf \
  /opt/odoo/data/workspace/.venv \
  /root/.vscode-server/data/User/workspaceStorage \
  /root/.vscode-server/data/User/globalStorage/ms-python.python 2>/dev/null || true
