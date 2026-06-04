#!/usr/bin/env bash
set -euo pipefail

# Genera el addons_path en odoo.conf a partir de:
#   1) cada subcarpeta de ./repositories (repos clonados a mano para desarrollo)
#   2) los addons del core de Odoo (paquete del sistema de la imagen oficial)
#
# Imprime el addons_path resultante en la última línea (lo consume el entrypoint).

# Raíz de repos: dentro del container es /opt/odoo/repositories; en el host, ./repositories
if [[ -d "/opt/odoo/repositories" ]]; then
  REPO_ROOT="/opt/odoo/repositories"
else
  PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
  REPO_ROOT="${PROJECT_ROOT}/repositories"
fi

ADDONS_PATH=""

# 1) Repos locales — cada subcarpeta directa de repositories/
if [[ -d "${REPO_ROOT}" ]]; then
  local_paths="$(find "${REPO_ROOT}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
    | sort -u | paste -sd, -)"
  [[ -n "${local_paths}" ]] && ADDONS_PATH="${local_paths}"
fi

# 2) Core de Odoo (paquete del sistema de la imagen oficial)
CORE_ADDONS="/usr/lib/python3/dist-packages/odoo/addons"
[[ -d "${CORE_ADDONS}" ]] && ADDONS_PATH="${ADDONS_PATH:+${ADDONS_PATH},}${CORE_ADDONS}"

# Limpiar comas sobrantes
ADDONS_PATH="$(echo "${ADDONS_PATH}" | sed 's/,,*/,/g; s/^,//; s/,$//')"

ODOO_CONF="${ODOO_RC:-/etc/odoo/odoo.conf}"
if [[ ! -f "${ODOO_CONF}" ]]; then
  echo "ERROR: Odoo config no encontrado en ${ODOO_CONF}" >&2
  exit 1
fi
if [[ ! -w "${ODOO_CONF}" ]]; then
  echo "ERROR: Odoo config no escribible en ${ODOO_CONF}" >&2
  exit 1
fi

tmp_conf="$(mktemp /tmp/odoo-conf.XXXXXX)"
trap 'rm -f "${tmp_conf}"' EXIT

awk -v addons_path="${ADDONS_PATH}" '
  /^[[:space:]]*addons_path[[:space:]]*=/ { next }
  /^\[options\][[:space:]]*$/ {
    print
    if (!inserted) { print "addons_path = " addons_path; inserted = 1 }
    saw_options = 1; next
  }
  /^\[[^]]+\][[:space:]]*$/ { print; next }
  { print }
  END {
    if (!inserted) {
      if (!saw_options) { print ""; print "[options]" }
      print "addons_path = " addons_path
    }
  }
' "${ODOO_CONF}" > "${tmp_conf}"
cat "${tmp_conf}" > "${ODOO_CONF}"
echo "${ADDONS_PATH}"
