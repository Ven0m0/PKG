#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR external-sources=true
set -euo pipefail
shopt -s nullglob
export LC_ALL=C
IFS=$'\n\t'

# ─── Configuration ─────────────────────────────────────────────────────────
readonly mail_address=${MAIL_ADDRESS:-root}
readonly source_dir_path=${SOURCE_DIR_PATH:-/usr/share/nginx/nextcloud/}
readonly source_data_path=${SOURCE_DATA_PATH:-/var/nextcloud/}
readonly target_path=${TARGET_PATH:-user@domain.de:/path/to/backup}
readonly nextcloud_user=${NEXTCLOUD_USER:-http}

# SSH options - putting into array for nested quotes
readonly ssh_options=(-e "ssh -p ${SSH_PORT:-22} -i ${SSH_KEY:-/home/user/.ssh/id_ed25519}")

# SQL options - SECURITY: Use environment variables or config file instead of hardcoding
readonly sql_options="--user ${SQL_USER:-nextclouduser} --password=${SQL_PASSWORD:-my_password123}"

# ─── Main Backup Logic ────────────────────────────────────────────────────
log=''

# Maintenance mode on
log+=$(sudo -u "$nextcloud_user" php "${source_dir_path}occ" maintenance:mode --on)$'\n'

# Copy nextcloud execution directory, data directory and SQL DB dump
log+=$(rsync -Aavx --delete "${ssh_options[@]}" "$source_dir_path" "$target_path/nextcloud-dirbkp/")$'\n'
log+=$(rsync -Aavx --delete "${ssh_options[@]}" --exclude 'appdata_*/preview' "$source_data_path" "$target_path/nextcloud-databkp/")$'\n'

# shellcheck disable=SC2086
log+=$(mysqldump --single-transaction -h localhost $sql_options nextcloud >nextcloud-sqlbkp.bak)$'\n'
log+=$(rsync -Aavx --delete "${ssh_options[@]}" nextcloud-sqlbkp.bak "$target_path/nextcloud-sqlbkp.bak")$'\n'
log+=$(rm nextcloud-sqlbkp.bak)$'\n'

# Maintenance mode off
log+=$(sudo -u "$nextcloud_user" php "${source_dir_path}occ" maintenance:mode --off)$'\n'

# Logging for journal
printf '%s' "$log"

# Sending email
readonly hostname=$(</etc/hostname)
readonly mail_header="Subject: Nextcloud Backup on: $hostname"$'\n\r\n\r'
readonly mail_body="The nextcloud backup was run:"$'\n\r\n\r'"$log"
printf '%s%s' "$mail_header" "$mail_body" | sendmail "$mail_address"
