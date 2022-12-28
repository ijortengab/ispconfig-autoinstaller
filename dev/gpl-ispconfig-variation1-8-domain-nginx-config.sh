#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

# Dependencies of this script only.
[ -n "$domain" ] || { red "Value of variable \$domain required."; x; }

# populate variable
fqdn_phpmyadmin="${subdomain_phpmyadmin}.${domain}"
fqdn_roundcube="${subdomain_roundcube}.${domain}"
fqdn_ispconfig="${subdomain_ispconfig}.${domain}"
reload=

file_config_source="/etc/nginx/sites-available/$PHPMYADMIN_NGINX_CONFIG_FILE"
file_config="/etc/nginx/sites-available/$fqdn_phpmyadmin"
yellow Membuat file nginx config $file_config.
notfound=1
string="$fqdn_phpmyadmin"
string_quoted=$(pregQuote "$string")
if [ -f "$file_config" ];then
    if grep -q -E "^\s*server_name\s+$string_quoted\s*;\s*$" "$file_config";then
        __ Domain "$string" sudah terdapat pada file config.
        notfound=
    else
        __ Domain "$string" belum terdapat pada file config.
    fi
fi
if [ -n "$notfound" ];then
    if [ -f "$file_config" ];then
        __ Backup file "$file_config"
        backupFile move "$file_config"
    fi
    cp $file_config_source $file_config
    sed -i -E "s/server_name([^;]+);/server_name "${fqdn_phpmyadmin}";/" "$file_config"
    if grep -q -E "^\s*server_name\s+$string_quoted\s*;\s*$" "$file_config";then
        __; green Domain "$string" sudah terdapat pada file config.
        reload=1
    else
        __; red Domain "$string" belum terdapat pada file config.; exit
    fi
    cd /etc/nginx/sites-enabled/
    ln -sf ../sites-available/$fqdn_phpmyadmin
fi
____

file_config_source="/etc/nginx/sites-available/$ROUNDCUBE_NGINX_CONFIG_FILE"
file_config="/etc/nginx/sites-available/$fqdn_roundcube"
yellow Membuat file nginx config $file_config.
notfound=1
string="$fqdn_roundcube"
string_quoted=$(pregQuote "$string")
if [ -f "$file_config" ];then
    if grep -q -E "^\s*server_name\s+$string_quoted\s*;\s*$" "$file_config";then
        __ Domain "$string" sudah terdapat pada file config.
        notfound=
    else
        __ Domain "$string" belum terdapat pada file config.
    fi
fi
if [ -n "$notfound" ];then
    if [ -f "$file_config" ];then
        __ Backup file "$file_config"
        backupFile move "$file_config"
    fi
    cp $file_config_source $file_config
    sed -i -E "s/server_name([^;]+);/server_name "${fqdn_roundcube}";/" "$file_config"
    if grep -q -E "^\s*server_name\s+$string_quoted\s*;\s*$" "$file_config";then
        __; green Domain "$string" sudah terdapat pada file config.
        reload=1
    else
        __; red Domain "$string" belum terdapat pada file config.; exit
    fi
    cd /etc/nginx/sites-enabled/
    ln -sf ../sites-available/$fqdn_roundcube
fi
____

file_config_source="/etc/nginx/sites-available/$ISPCONFIG_NGINX_CONFIG_FILE"
file_config="/etc/nginx/sites-available/$fqdn_ispconfig"
yellow Membuat file nginx config $file_config.
notfound=1
string="$fqdn_ispconfig"
string_quoted=$(pregQuote "$string")
if [ -f "$file_config" ];then
    if grep -q -E "^\s*server_name\s+$string_quoted\s*;\s*$" "$file_config";then
        __ Domain "$string" sudah terdapat pada file config.
        notfound=
    else
        __ Domain "$string" belum terdapat pada file config.
    fi
fi
if [ -n "$notfound" ];then
    if [ -f "$file_config" ];then
        __ Backup file "$file_config"
        backupFile move "$file_config"
    fi
    cp $file_config_source $file_config
    sed -i -E "s/server_name([^;]+);/server_name "${fqdn_ispconfig}";/" "$file_config"
    if grep -q -E "^\s*server_name\s+$string_quoted\s*;\s*$" "$file_config";then
        __; green Domain "$string" sudah terdapat pada file config.
        reload=1
    else
        __; red Domain "$string" belum terdapat pada file config.; exit
    fi
    cd /etc/nginx/sites-enabled/
    ln -sf ../sites-available/$fqdn_ispconfig
fi
____

if [ -n "$reload" ];then
    if nginx -t 2> /dev/null;then
        magenta nginx -s reload
        nginx -s reload
    else
        red Terjadi kesalahan konfigurasi nginx. Gagal reload nginx.; exit
    fi
fi
