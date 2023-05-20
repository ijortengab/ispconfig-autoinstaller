#!/bin/bash
commands_required=$(cat <<EOF
gpl-ispconfig-setup-variation1.sh
gpl-certbot-setup-nginx.sh
gpl-nginx-setup-php-fpm.sh
gpl-debian11-setup-basic.sh
gpl-mariadb-autoinstaller.sh
gpl-mariadb-setup-ispconfig.sh
gpl-nginx-autoinstaller.sh
gpl-nginx-setup-ispconfig.sh
gpl-php-autoinstaller.sh
gpl-php-setup-ispconfig.sh
gpl-postfix-autoinstaller.sh
gpl-postfix-setup-ispconfig.sh
gpl-phpmyadmin-autoinstaller-nginx-php-fpm.sh
gpl-roundcube-autoinstaller-nginx-php-fpm.sh
gpl-ispconfig-autoinstaller-nginx-php-fpm.sh
gpl-ispconfig-setup-internal-command.sh
gpl-roundcube-setup-ispconfig-integration.sh
gpl-amavis-setup-ispconfig.sh
gpl-ispconfig-setup-wrapper-nginx-setup-php-fpm.sh
gpl-ispconfig-control-manage-domain.sh
gpl-ispconfig-control-manage-email-mailbox.sh
gpl-ispconfig-control-manage-email-alias.sh
gpl-digitalocean-api-manage-domain.sh
gpl-digitalocean-api-manage-domain-record.sh
gpl-ispconfig-setup-wrapper-digitalocean.sh
gpl-certbot-autoinstaller.sh
gpl-certbot-digitalocean-autoinstaller.sh
gpl-ispconfig-setup-wrapper-certbot-setup-nginx.sh
gpl-ispconfig-setup-dump-variables.sh
EOF
)
mkdir -p "$HOME/bin"
while IFS= read -r line; do
    if [ ! -f "$HOME/bin/$line" ];then
        wget https://github.com/ijortengab/gpl/raw/master/$(cut -d- -f2 <<< "$line")/"$line" -O "$HOME/bin/$line"
        chmod a+x "$HOME/bin/$line"
    elif [[ ! -x "$HOME/bin/$line" ]];then
        chmod a+x "$HOME/bin/$line"
    fi
done <<< "$commands_required"
