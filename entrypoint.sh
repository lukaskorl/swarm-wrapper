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

msg "🚀 Starting containers in $GREEN$COMPOSE_FILE$NC as $YELLOW$COMPOSE_PROJECT_NAME$NC"

if [ -e "$COMPOSE_FILE" ]; then
  docker compose up --remove-orphans --abort-on-container-exit &
  child=$!

  msg "👻 Waiting for compose to finish in backgorund ..."
  wait $child

  e=$?
  msg "🏁 docker compose finished with exit code: $GREEN$e$NC"

  msg "🧼 Cleaning up ..."
  docker compose rm -f
  exit $e
else
  msg "💥 $RED$COMPOSE_FILE not found!$NC"
  exit 127
fi
