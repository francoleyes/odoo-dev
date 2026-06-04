# syntax=docker/dockerfile:1.7
# Imagen de DESARROLLO únicamente — devcontainer.
# Parte de la imagen oficial de Odoo y solo agrega lo necesario para debuggear.
# NO clona repos ni los hornea: los addons salen de ./repositories (montado en runtime).

ARG ODOO_VERSION
FROM odoo:${ODOO_VERSION}.0

USER root
ARG ODOO_VERSION
ENV ODOO_VERSION=${ODOO_VERSION}

RUN apt-get update \
    && apt-get install -y --no-install-recommends git gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Dependencias Python para desarrollo + las que requieren los addons locales
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir --break-system-packages debugpy \
    && pip3 install --no-cache-dir --break-system-packages --ignore-installed -r /tmp/requirements.txt

COPY --chown=odoo:odoo scripts/generate-addons-path.sh /usr/local/bin/generate-addons-path
COPY --chown=odoo:odoo scripts/devcontainer-start.sh /usr/local/bin/devcontainer-start
RUN chmod +x /usr/local/bin/generate-addons-path /usr/local/bin/devcontainer-start

# Dev: corremos como root para simplificar permisos del workspace montado.
# ENTRYPOINT/CMD se heredan de la imagen oficial (/entrypoint.sh + odoo);
# docker-compose hace el override con `command: sleep infinity`.
