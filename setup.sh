#!/bin/sh
set -eu
IFS=$'\n\t'
SCRIPT=$(readlink -f "$0")
DIR=$(dirname "$SCRIPT")
set -x

cd "$DIR"

export ACME_EMAIL="hosna+test@mangoweb.cz"
export ACME_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"

export BASE_URL="gdqngtrjwxef4flh7u9rutmw.t.michalhosna.com"
export ENABLE_ADMINER=false
export DB_PASSWORD="einstore"

envsubst '${ACME_EMAIL} ${ACME_SERVER}' < config/traefik.template.toml > config/traefik.toml
envsubst '${BASE_URL} ${DB_PASSWORD} ${ENABLE_ADMINER}' < docker-compose.override.template.yaml > docker-compose.override.yaml



