#!/bin/bash

# Dependency.
[ -n "$RCM_PHP_VERSION" ] || { red "Unable to proceed, variable \$RCM_PHP_VERSION is empty."; x; }
[ -n "$RCM_WEB_SERVER" ] || { red "Unable to proceed, variable \$RCM_WEB_SERVER is empty."; x; }
require rcm nginx reload

# Define variables and constants.
php_version="$RCM_PHP_VERSION"
web_server="$RCM_WEB_SERVER"
php_fpm_user=ispconfig
pool_name=ispconfig
ISPCONFIG_FQDN_LOCALHOST=${ISPCONFIG_FQDN_LOCALHOST:=ispconfig.localhost}
rcm_nginx_reload=

chapter Prepare arguments.
if [ -z "$prefix" ];then
    prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
fi
code 'pool_name="'$pool_name'"'
socket_filename=$(rcm php get-info pool --php-version="$php_version" --pool-name="$pool_name" --key=listen)
if [ -z "$socket_filename" ];then
    __; red Socket Filename of PHP-FPM not found.; x
fi
code 'socket_filename="'$socket_filename'"'
root="$prefix/interface/web"
code 'root="'$root'"'
url="http://${ISPCONFIG_FQDN_LOCALHOST}"
code 'url="'$url'"'
____

RCM_WEB_SERVER_URL="$url"
RCM_WEB_SERVER_ROOT="$root"
RCM_WEB_SERVER_PHP_FPM_SOCKET="$socket_filename"
include `rcm plugin run-method ispconfig/web-server $web_server add-vhost`

chapter Mengecek address host local '`'$ISPCONFIG_FQDN_LOCALHOST'`'.
notfound=
string="$ISPCONFIG_FQDN_LOCALHOST"
string_quoted=$(sed "s/\./\\\./g" <<< "$string")
if grep -q -E "^\s*127\.0\.0\.1\s+${string_quoted}" /etc/hosts;then
    __ Address Host local terdapat pada local DNS resolver '`'/etc/hosts'`'.
else
    __ Address Host local tidak terdapat pada local DNS resolver '`'/etc/hosts'`'.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    chapter Menambahkan host '`'$ISPCONFIG_FQDN_LOCALHOST'`'.
    echo "127.0.0.1"$'\t'"${ISPCONFIG_FQDN_LOCALHOST}" >> /etc/hosts
    if grep -q -E "^\s*127\.0\.0\.1\s+${string_quoted}" /etc/hosts;then
        __; green Address Host local terdapat pada local DNS resolver '`'/etc/hosts'`'.; _.
    else
        __; red Address Host local tidak terdapat pada local DNS resolver '`'/etc/hosts'`'.; x
    fi
    ____
fi

chapter Mengecek HTTP Response Code.
i=0
code=
if [ -z "$tempfile" ];then
    tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-autoinstaller-nginx.XXXXXX)
fi
until [ $i -eq 10 ];do
    __; magenta curl -o /dev/null -s -w '"'%{http_code}\\n'"' '"'http://127.0.0.1'"' -H '"'Host: $ISPCONFIG_FQDN_LOCALHOST'"'; _.
    curl -o /dev/null -s -w "%{http_code}\n" "http://127.0.0.1" -H "Host: ${ISPCONFIG_FQDN_LOCALHOST}" > $tempfile
    while read line; do e "$line"; _.; done < $tempfile
    code=$(head -1 $tempfile)
    if [[ "$code" =~ ^[2,3] ]];then
        break
    else
        __ Retry.
        __; magenta sleep .5; _.
        sleep .5
    fi
    let i++
done
if [[ "$code" =~ ^[2,3] ]];then
    __ HTTP Response code '`'$code'`' '('Required')'.
else
    __; red Terjadi kesalahan. HTTP Response code '`'$code'`'.; x
fi
____

chapter Menghapus port 8080 buatan ISPConfig
path=/etc/nginx/sites-enabled/000-ispconfig.vhost
rcm-file "$path" isExists
if [ -L "$path" ];then
    __ Menghapus symlink "$path"
    code rm "$path"
    rm "$path"
    rcm_nginx_reload=1
fi
____

chapter Menghapus virtual host acme challange buatan ISPConfig
path=/etc/nginx/sites-enabled/999-acme.vhost
rcm-file "$path" isExists
if [ -L "$path" ];then
    __ Menghapus symlink "$path"
    code rm "$path"
    rm "$path"
    rcm_nginx_reload=1
fi
____

if [ -n "$rcm_nginx_reload" ];then
    INDENT+="    " \
    rcm nginx reload \
        ; [ ! $? -eq 0 ] && x
fi

chapter Copy ISPConfig PHP scripts.
rcm-dir "${prefix}/remoting_client" isExists
if [ -n "$notfound" ];then
    code cp -r /tmp/ispconfig3_install/remoting_client -T "${prefix}/remoting_client"
    cp -r /tmp/ispconfig3_install/remoting_client -T "${prefix}/remoting_client"
    rcm-dir "${prefix}/remoting_client" mustExists
fi
rcm-dir "${prefix}/remoting_client" terminateIfNotExists
____
