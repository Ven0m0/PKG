#!/bin/bash

#configuration
mail_address=root
source_dir_path=/usr/share/nginx/nextcloud/
source_data_path=/var/nextcloud/
target_path=user@domain.de:/path/to/backup
#putting SSH options into array for nested quotes
ssh_options=(-e "ssh -p 22 -i /home/user/.ssh/id_ed25519")
sql_options="--user nextclouduser -password my_password123"
nextcloud_user=http

#maintenance mode on
log=$(sudo -u $nextcloud_user php "${source_dir_path}"occ maintenance:mode --on)"\n"

#copy nextcloud execution directory, data directory and sql DB dump
log+=$(rsync -Aavx --delete "${ssh_options[@]}" "$source_dir_path" "$target_path"/nextcloud-dirbkp/)"\n"
log+=$(rsync -Aavx --delete "${ssh_options[@]}" --exclude 'appdata_*/preview' "$source_data_path" "$target_path"/nextcloud-databkp/)"\n"
log+=$(mysqldump --single-transaction -h localhost $sql_options nextcloud > nextcloud-sqlbkp.bak)"\n"
log+=$(rsync -Aavx --delete "${ssh_options[@]}" nextcloud-sqlbkp.bak "$target_path"/nextcloud-sqlbkp.bak)"\n"
log+=$(rm nextcloud-sqlbkp.bak)"\n"

#maintenance mode off
log+=$(sudo -u $nextcloud_user php "${source_dir_path}"occ maintenance:mode --off)"\n"

#logging for journal
printf "$log"

#sending email
hostname=$(cat /etc/hostname)
mail_header="Subject: Nextcloud Backup on: $hostname\n\r\n\r"
mail_body="The nextcloud backup was run:\n\r\n\r"$log
printf "$mail_header$mail_body" | sendmail "$mail_address"


