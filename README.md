# odoo-docker-dev

Entorno de **desarrollo** Odoo con Docker Compose y VS Code DevContainers.
Un solo repo, una sola rama `main` — el **nombre de la carpeta** determina la versión.

> Este repo es **solo para desarrollo local**. No buildea ni publica imágenes de
> producción, no sincroniza repos automáticamente. Los addons salen de los repos
> que vos clonás a mano en `./repositories/`.

## Quick Start

```bash
git clone <repo> 18            # o 19, etc. El basename = versión de Odoo
cd 18
bash setup.sh                  # genera .env y odoo.conf a partir del nombre de la carpeta
# cloná los repos que quieras desarrollar:
cd repositories
git clone git@github.com:mi-org/mi-modulo.git
cd ..
docker compose up -d --build   # buildea la imagen de dev (oficial + debugpy) y levanta el stack
```

Luego en VS Code: **Reopen in Container** → **F5** para arrancar Odoo con el debugger.

> Para desarrollar en otra versión: cloná el repo de nuevo en otra carpeta y renombrala.
> Ejemplo: `git clone … 19 && cd 19 && bash setup.sh`

## Requisitos

- Docker + Docker Compose
- VS Code + extensión [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-remote.remote-containers)

## Cómo funciona el modelo "carpeta = versión"

`setup.sh` lee el `basename` del directorio actual y genera dos archivos **ignorados por git**:
- `.env` — variables de entorno (`ODOO_VERSION`, `COMPOSE_PROJECT_NAME`, puertos)
- `odoo.conf` — configuración de Odoo (el `addons_path` se completa en runtime)

El `Dockerfile` hace `FROM odoo:${ODOO_VERSION}.0` (imagen oficial) y solo agrega
`debugpy`, `git` y las dependencias de `requirements.txt`. **No hornea repos.**

## Módulos locales (desarrollo activo)

Cloná cualquier repo dentro de `./repositories/` en tu Mac. Cada subcarpeta directa
aparece automáticamente en el `addons_path` dentro del DevContainer (lo arma
`scripts/generate-addons-path.sh` al arrancar).

```bash
cd repositories
git clone git@github.com:mi-org/mi-modulo.git
```

El contenido de `repositories/` está gitignored — cada quien clona lo que necesita.

## Dependencias Python

El `requirements.txt` **no se versiona acá**: lo baja `setup.sh` desde un repo externo
definido en `requirements.source` (repo + rama), usando tu auth SSH del host. El
`Dockerfile` lo instala al buildear.

`requirements.source` está **gitignored** (tiene tu URL/credenciales). Se versiona solo
`requirements.source.example`. La primera vez, `setup.sh` te crea `requirements.source`
desde el ejemplo para que lo completes:

```ini
# requirements.source  (gitignored — completá con tu repo)
REQUIREMENTS_REPO=git@<host-ssh>:<owner>/<repo>.git
REQUIREMENTS_REF=18.0
REQUIREMENTS_PATH=requirements.txt
```

Para sumar/cambiar una dependencia: pusheala al repo de requirements (rama de la versión,
ej. `18.0`), corré `bash setup.sh` para rebajarla y `docker compose build`.

## Servicios disponibles

| Servicio | URL / Puerto               | Descripción             |
|----------|---------------------------|-------------------------|
| Odoo     | http://18.odoo.localhost  | App principal           |
| pgweb    | http://localhost:8088     | UI web para PostgreSQL  |
| Mailpit  | http://localhost:8028     | Captura de emails SMTP  |

> El número en la URL/puertos cambia según la versión (18, 19…).

## Debugger (F5)

La configuración en `.vscode/launch.json` levanta `odoo-bin` con `debugpy`.
Descomentá `-d mi_base` para apuntar a una DB específica, o dejalo sin `-d` para
que Odoo muestre el selector.

## Estructura del repo

```
.
├── setup.sh                      # genera .env y odoo.conf según nombre de carpeta
├── odoo.conf.tpl                 # template de configuración Odoo
├── docker-compose.yml            # stack: odoo, db, pgweb, smtp (+ traefik/dns opcionales)
├── Dockerfile                    # imagen de dev: oficial odoo + debugpy + requirements
├── requirements.source.example   # plantilla del origen del requirements (se versiona)
├── requirements.source           # (gitignored) tu repo+rama real
├── requirements.txt              # (gitignored) bajado por setup.sh — NO se versiona
├── repositories/                 # repos clonados a mano (gitignored) → addons_path
│   └── .gitkeep
├── scripts/
│   ├── entrypoint.sh             # regenera addons_path y arranca Odoo
│   ├── generate-addons-path.sh   # arma addons_path desde ./repositories + core
│   └── devcontainer-start.sh     # postStart del devcontainer
└── .devcontainer/
    ├── devcontainer.json
    └── odoo.code-workspace.tpl
```
