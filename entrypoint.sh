#!/usr/bin/env sh

#       ___                        __      __                           
#      / __|_ __ ____ _ _ _ _ __   \ \    / / _ __ _ _ __ _ __  ___ _ _ 
#      \__ \ V  V / _` | '_| '  \   \ \/\/ / '_/ _` | '_ \ '_ \/ -_) '_|
#      |___/\_/\_/\__,_|_| |_|_|_|   \_/\_/|_| \__,_| .__/ .__/\___|_|  
#                                                   |_|  |_|            
#      W r a p   c o n t a i n e r s   i n   D o c k e r - C o m p o s e 

# Prepare shell for script execution
set -Eeo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT
[[ "$0" != "$BASH_SOURCE" ]] && EXIT=return || EXIT=exit
cleanup() {
  msg "👋 Shutting down ..."
  trap - SIGINT SIGTERM ERR EXIT
  docker compose down
  if [ -f /var/run/socat.pid ]; then
    kill -9 $(cat /var/run/socat.pid)
  fi
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m\033[1m' GREEN='\033[0;32m\033[1m' ORANGE='\033[0;33m\033[1m' BLUE='\033[0;34m\033[1m' PURPLE='\033[0;35m\033[1m' CYAN='\033[0;36m\033[1m' YELLOW='\033[1;33m\033[1m'
    # Highlight            Warning                  Green / everything is ok     No Color (same as no format)
    HL='\033[0;34m\033[1m' WARN='\033[0;31m\033[1m' OK='\033[0;32m\033[1m'       NC='\033[0m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
    HL='' WARN='' OK='' NC=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

AUTO_NAME="$(hostname)-wrapper"
export COMPOSE_FILE=/compose.yml
export COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-$AUTO_NAME}

## AWS
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$ECR_REGISTRY" ]; then
  echo "⏭  Skipping AWS ECR login (not configured)";
else
  echo -e "🔑  Logging in to ${YELLOW}AWS ECR$NC";
  apk add -q aws-cli;
  aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $ECR_REGISTRY;
fi

## Generic Docker registry
if [ -z "$DOCKER_LOGIN_USERNAME" ] || [ -z "$DOCKER_LOGIN_PASSWORD" ] || [ -z "$DOCKER_LOGIN_REGISTRY" ]; then
  msg "⏭  Skipping additional Docker login (not configured)";
else
  msg "🔑  Logging in to ${YELLOW}Docker registry$NC ($DOCKER_LOGIN_REGISTRY)";
  echo "$DOCKER_LOGIN_PASSWORD" | docker login -u "${DOCKER_LOGIN_USERNAME}" --password-stdin ${DOCKER_LOGIN_REGISTRY};
fi

msg "🚀 Starting containers in $GREEN$COMPOSE_FILE$NC as $YELLOW$COMPOSE_PROJECT_NAME$NC"

if [ -e "$COMPOSE_FILE" ]; then
  docker compose up --remove-orphans --abort-on-container-exit &
  child=$!

  if [ ! -z "$PROXY_TARGET" ]; then
    msg "🌍 Start proxy for $YELLOW$PROXY_TARGET$NC on port $GREEN${PROXY_PORT:-8080}$NC"
    socat TCP4-LISTEN:${PROXY_PORT:-8080},fork,reuseaddr,ignoreeof TCP4:$PROXY_TARGET &
    echo $! > /var/run/socat.pid
  fi
  # https://chandrat.hashnode.dev/simulate-tcp-and-tls-proxy-using-socket-cat

  msg "👻 Waiting for compose to finish in backgorund ..."
  wait $child

  e=$?
  msg "🏁 docker compose finished with exit code: $GREEN$e$NC"

  msg "🧼 Cleaning up ..."
  if [ -f /var/run/socat.pid ]; then
    kill -9 $(</var/run/socat.pid)
  fi
  docker compose rm -f
  exit $e
else
  msg "💥 $RED$COMPOSE_FILE not found!$NC"
  exit 127
fi
