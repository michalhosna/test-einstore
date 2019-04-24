#!/bin/sh
set -eu
IFS=$'\n\t'
SCRIPT=$(readlink -f "$0")
DIR=$(dirname "$SCRIPT")

cd "$DIR"

DOMAIN_REGEX="^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"

# Params: <Question> <Regex> [DefaultValue]
ask(){
    while true; do
        if [ $# -eq 2 ]; then
            read -p "$1: " RESULT
        elif [ $# -eq 3 ]; then
            read -p "$1 [$3]: " RESULT
            : "${RESULT:=$3}"
        else
            echo "Internal error"
            exit 1;
        fi;

        ( echo "$RESULT" | grep -Eq "$2" ) && return 0
        echo "Invalid input, must match $2"
    done
}

if [ -f docker-compose.override.yaml ]; then
    echo "docker-compose.override.yaml already exists, aborting"
    exit 1
fi

if [ -f config/traefik.toml ]; then
    echo "config/traefik.toml already exists, aborting"
    exit 1
fi

ask "Base domain (e.g. \"example.com\")" $DOMAIN_REGEX
export BASE_URL="${RESULT}"

ask "ACME email (Let's Encrypt)" "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
export ACME_EMAIL="${RESULT}"

ask "Enable Adminer (will enable adminer on /adminer path)" "^true|false$" "false"
export ENABLE_ADMINER="${RESULT}"


ask "DB Password (default is randomly generated)" "\S+" $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
export DB_PASSWORD="${RESULT}"

ask "Enable object storage backend (S3 or compatible)" "^true|false$" "false"
export APICORE_STORAGE_S3_ENABLED="${RESULT}"

if [ "$APICORE_STORAGE_S3_ENABLED" = "true" ]; then
    ask "S3 bucket" "^\S+$"
    export APICORE_STORAGE_S3_BUCKET="${RESULT}"

    ask "S3 Access key" "^\S+$"
    export APICORE_STORAGE_S3_ACCESS_KEY="${RESULT}"

    ask "S3 Secret key" "^\S+$"
    export APICORE_STORAGE_S3_SECRET_KEY="${RESULT}"

    ask "S3 region" "^\S*$"
    export APICORE_STORAGE_S3_REGION="${RESULT}"
else
    export APICORE_STORAGE_S3_BUCKET="~"
    export APICORE_STORAGE_S3_ACCESS_KEY="~"
    export APICORE_STORAGE_S3_REGION="~"
    export APICORE_STORAGE_S3_SECRET_KEY="~"
fi

ask "Server name (see https://github.com/Einstore/Einstore/wiki/Environmental-variables#APICORE_SERVER_NAME)" "^\S+$"
export APICORE_SERVER_NAME="${RESULT}"

ask "Maximum file uplod size in MB" "^\d+$" "800"
export APICORE_SERVER_MAX_UPLOAD_FILESIZE="50"

ask "Mailing email" "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
export APICORE_MAIL_EMAIL="${RESULT}"


ask "Email protocol <mailgun|smtp>" "^mailgun|smtp$" "smtp"
if [ "$RESULT" = "smtp" ]; then
    ask "SMTP configuration <smtp_server;username;password;port>" "^\S+;\S*;\S*;\d+$"
    export APICORE_MAIL_SMTP="${RESULT}"
    export APICORE_MAIL_MAILGUN_DOMAIN="~"
    export APICORE_MAIL_MAILGUN_KEY="~"
elif [ "$RESULT" = "mailgun" ]; then
    export APICORE_MAIL_SMTP="~"

    ask "Mailgun domain" $DOMAIN_REGEX
    export APICORE_MAIL_MAILGUN_DOMAIN="${RESULT}"
    ask "Mailgun key" "^[a-zA-Z0-9-]+$"
    export APICORE_MAIL_MAILGUN_KEY="${RESULT}"
fi


ask "Enable GitHub login" "^true|false$" "false"
export APICORE_AUTH_GITHUB_ENABLED="${RESULT}"

if [ "$APICORE_AUTH_GITHUB_ENABLED" = "true" ]; then

    echo "See https://github.com/Einstore/Einstore/wiki/Environmental-variables"

    ask "APICORE_AUTH_GITHUB_CLIENT" "^\S*$"
    export APICORE_AUTH_GITHUB_CLIENT="${RESULT}"

    ask "APICORE_AUTH_GITHUB_SECRET" "^\S*$"
    export APICORE_AUTH_GITHUB_SECRET="${RESULT}"

    ask "APICORE_AUTH_GITHUB_HOST" "^\S*$" "https://github.com"
    export APICORE_AUTH_GITHUB_HOST="${RESULT}"

    ask "APICORE_AUTH_GITHUB_API" "^\S*$" "https://api.github.com"
    export APICORE_AUTH_GITHUB_API="${RESULT}"

    ask "APICORE_AUTH_GITHUB_TEAMS" "^\S*$"
    export APICORE_AUTH_GITHUB_TEAMS="${RESULT}"
else
    export APICORE_AUTH_GITHUB_CLIENT="~"
    export APICORE_AUTH_GITHUB_SECRET="~"
    export APICORE_AUTH_GITHUB_HOST="~"
    export APICORE_AUTH_GITHUB_API="~"
    export APICORE_AUTH_GITHUB_TEAMS="~"
fi

ask "Enable GitLab login" "^true|false$" "false"
export APICORE_AUTH_GITLAB_ENABLED="${RESULT}"
if [ "$APICORE_AUTH_GITLAB_ENABLED" = "true" ]; then
    echo "See https://github.com/Einstore/Einstore/wiki/Environmental-variables"

    ask "APICORE_AUTH_GITLAB_APPLICATION" "^\S*"
    export APICORE_AUTH_GITLAB_APPLICATION="${RESULT}"

    ask "APICORE_AUTH_GITLAB_SECRET" "^\S*"
    export APICORE_AUTH_GITLAB_SECRET="${RESULT}"

    ask "APICORE_AUTH_GITLAB_HOST" "^\S*" "https://gitlab.com"
    export APICORE_AUTH_GITLAB_HOST="${RESULT}"

    ask "APICORE_AUTH_GITLAB_API" "^\S*" "https://gitlab.com/api/v4"
    export APICORE_AUTH_GITLAB_API="${RESULT}"

#    ask "APICORE_AUTH_GITLAB_GROUPS" "^\S*"
#    export APICORE_AUTH_GITLAB_GROUPS="${RESULT}"
else
    export APICORE_AUTH_GITLAB_APPLICATION="~"
    export APICORE_AUTH_GITLAB_SECRET="~"
    export APICORE_AUTH_GITLAB_HOST="~"
    export APICORE_AUTH_GITLAB_API="~"
    export APICORE_AUTH_GITLAB_GROUPS="~"
fi

export APICORE_JWT_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

envsubst '${ACME_EMAIL}' < config/traefik.template.toml > config/traefik.toml
envsubst < docker-compose.override.template.yaml > docker-compose.override.yaml

docker-compose up -d
