#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail
shopt -s nullglob
export LC_ALL=C
IFS=$'\n\t'

nextcloud_path=/usr/share/nginx/nextcloud/
nextcloud_user=http

# this is a semi-manual process
sudo -u "$nextcloud_user" php "${nextcloud_path}occ" maintenance:mode --on
sudo -u "$nextcloud_user" php "${nextcloud_path}updater/updater.phar"
sudo -u "$nextcloud_user" php "${nextcloud_path}occ" maintenance:mode --off
