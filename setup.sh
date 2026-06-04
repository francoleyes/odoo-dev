#!/usr/bin/env bash
# setup.sh — genera .env y odoo.conf a partir del nombre de la carpeta.
# El basename del directorio (18, 19, …) determina la versión de Odoo.
# Correr una vez después de clonar (o de renombrar la carpeta). Ver README.md.
set -euo pipefail
cd "$(dirname "$0")"

VERSION="$(basename "$PWD")"

if [[ ! "${VERSION}" =~ ^[0-9]+$ ]]; then
  echo "ERROR: el nombre de la carpeta ('${VERSION}') debe ser la versión de Odoo (ej. 18 o 19)."
  echo "       Renombrá esta carpeta a una versión válida y volvé a correr ./setup.sh"
  exit 1
fi

# Último dígito de la versión para puertos únicos por instancia
# Permite correr v18 y v19 simultáneamente sin conflictos de puertos
VER_LAST="${VERSION: -1}"

cat > .env <<EOF
# Autogenerado por ./setup.sh — no editar a mano.
# Para cambiar de versión, renombrá la carpeta y volvé a correr ./setup.sh
ODOO_VERSION=${VERSION}
COMPOSE_PROJECT_NAME=odoo${VERSION}

# Puertos del host — únicos por versión para correr v18 y v19 en paralelo
PGWEB_PORT=808${VER_LAST}
MAILPIT_HTTP_PORT=802${VER_LAST}
MAILPIT_SMTP_PORT=102${VER_LAST}
EOF

cp odoo.conf.tpl odoo.conf
mkdir -p repositories
[[ -f repositories/.gitkeep ]] || touch repositories/.gitkeep

# Bajar requirements.txt desde el repo/rama definidos en requirements.source.
# Se clona con tu auth SSH del host (no se hornea en la imagen ni se commitea acá).
if [[ ! -f requirements.source && -f requirements.source.example ]]; then
  cp requirements.source.example requirements.source
  echo "[setup] Creé requirements.source desde el ejemplo — editá REQUIREMENTS_REPO con tu repo."
fi
if [[ -f requirements.source ]]; then
  # shellcheck disable=SC1091
  source requirements.source
  if [[ "${REQUIREMENTS_REPO:-}" == *"<"* ]]; then
    echo "[setup] requirements.source sin configurar (placeholder) — salteo la descarga." >&2
    REQUIREMENTS_REPO=""
  fi
  if [[ -n "${REQUIREMENTS_REPO:-}" ]]; then
    echo "[setup] Bajando requirements desde ${REQUIREMENTS_REPO} (${REQUIREMENTS_REF:-${VERSION}.0})..."
    tmp_req="$(mktemp -d)"
    if GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new" \
         git clone -q --depth 1 --branch "${REQUIREMENTS_REF:-${VERSION}.0}" "${REQUIREMENTS_REPO}" "${tmp_req}"; then
      cp "${tmp_req}/${REQUIREMENTS_PATH:-requirements.txt}" requirements.txt
      echo "[setup] requirements.txt actualizado."
    else
      echo "[setup] WARNING: no se pudo clonar el repo de requirements." >&2
      [[ -f requirements.txt ]] && echo "[setup] Uso el requirements.txt existente." >&2
    fi
    rm -rf "${tmp_req}"
  fi
fi
if [[ ! -f requirements.txt ]]; then
  echo "[setup] Sin requirements.txt (repo sin configurar o rama ${REQUIREMENTS_REF:-${VERSION}.0} inexistente) — creo uno vacío y sigo." >&2
  : > requirements.txt
fi

echo "[setup] Listo para Odoo ${VERSION}."
echo "        pgweb   → http://localhost:808${VER_LAST}"
echo "        mailpit → http://localhost:802${VER_LAST}"
echo "        Cloná los repos que quieras desarrollar en ./repositories/"
echo "        Próximos pasos: docker compose up -d --build"
echo "        Luego: Reopen in Container en VS Code → F5 para debuggear"
