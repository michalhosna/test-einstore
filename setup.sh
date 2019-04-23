#!/bin/sh
set -eu
IFS=$'\n\t'
SCRIPT=$(readlink -f "$0")
DIR=$(dirname "$SCRIPT")
set -x

cd "$DIR"

ACME_EMAIL="hosna+test@mangoweb.cz"
ACME_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"

BASE_URL="gdqngtrjwxef4flh7u9rutmw.t.michalhosna.com"
ENABLE_ADMINER=false
DB_PASSWORD="einstore"

envsubst ACME_EMAIL ACME_SERVER < config/traefik.template.toml > config/traefik.toml
envsubst BASE_URL DB_PASSWORD ADMINER_URL < docker-compose.override.template.yaml > docker-compose.override.yaml


