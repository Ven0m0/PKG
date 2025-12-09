#!/bin/bash
nextcloud_path=/usr/share/nginx/nextcloud/
nextcloud_user=http

#this is a semi-manual process
sudo -u $nextcloud_user php "$nextcloudpath"occ maintenance:mode --on
sudo -u $nextcloud_user php "$nextcloudpath"updater/updater.phar
sudo -u $nextcloud_user php "$nextcloudpath"occ maintenance:mode --off
