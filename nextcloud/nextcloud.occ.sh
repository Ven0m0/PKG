#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail
shopt -s nullglob globstar
export LC_ALL=C
IFS=$'\n\t'
s=${BASH_SOURCE[0]}; [[ $s != /* ]] && s=$PWD/$s; cd -P -- "${s%/*}"
has(){ command -v -- "$1" &>/dev/null; }

readonly default_config="/etc/php-legacy/php.ini" default_php_command="/usr/bin/php-legacy" default_user="nextcloud" preserved_environment_vars="NEXTCLOUD_CONFIG_DIR"

config="" php_command="" user=""

check_sudo(){ has sudo || { printf 'The sudo command is not available.\n'; exit 1; }; }

if [[ -n ${NEXTCLOUD_PHP_CONFIG:-} && -f ${NEXTCLOUD_PHP_CONFIG} ]]; then
  config=$NEXTCLOUD_PHP_CONFIG
else
  config=$default_config
fi

if [[ -n ${NEXTCLOUD_PHP:-} ]] && has "$NEXTCLOUD_PHP"; then
  php_command=$NEXTCLOUD_PHP
else
  php_command=$default_php_command
fi

if [[ -n ${NEXTCLOUD_USER:-} ]] && id "$NEXTCLOUD_USER" >/dev/null 2>&1; then
  user=$NEXTCLOUD_USER
else
  user=$default_user
fi

if [[ $UID -eq 0 ]]; then
  runuser --whitelist-environment="$preserved_environment_vars" -u "$user" -- "$php_command" -c "$config" /usr/share/webapps/nextcloud/occ "$@"
else
  check_sudo
  sudo --preserve-env="$preserved_environment_vars" -u "$user" "$php_command" -c "$config" /usr/share/webapps/nextcloud/occ "$@"
fi
