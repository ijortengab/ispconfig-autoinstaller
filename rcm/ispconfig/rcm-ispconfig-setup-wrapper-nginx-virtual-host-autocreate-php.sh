#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --fast) fast=1; shift ;;
        --php-version=*) php_version="${1#*=}"; shift ;;
        --php-version) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then php_version="$2"; shift; fi; shift ;;
        --project=*) project="${1#*=}"; shift ;;
        --project) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then project="$2"; shift; fi; shift ;;
        --url-host=*) url_host="${1#*=}"; shift ;;
        --url-host) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_host="$2"; shift; fi; shift ;;
        --url-port=*) url_port="${1#*=}"; shift ;;
        --url-port) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_port="$2"; shift; fi; shift ;;
        --url-scheme=*) url_scheme="${1#*=}"; shift ;;
        --url-scheme) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_scheme="$2"; shift; fi; shift ;;
        --[^-]*) shift ;;
        *) _new_arguments+=("$1"); shift ;;
    esac
done
set -- "${_new_arguments[@]}"
unset _new_arguments

# Common Functions.
red() { echo -ne "\e[91m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
green() { echo -ne "\e[92m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
yellow() { echo -ne "\e[93m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
blue() { echo -ne "\e[94m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
magenta() { echo -ne "\e[95m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
error() { echo -n "$INDENT" >&2; red '#' "$@" >&2; echo >&2; }
success() { echo -n "$INDENT" >&2; green '#' "$@" >&2; echo >&2; }
chapter() { echo -n "$INDENT" >&2; yellow '#' "$@" >&2; echo >&2; }
title() { echo -n "$INDENT" >&2; blue '#' "$@" >&2; echo >&2; }
code() { echo -n "$INDENT" >&2; magenta "$@" >&2; echo >&2; }
x() { echo >&2; exit 1; }
e() { echo -n "$INDENT" >&2; echo -n "$@" >&2; }
_() { echo -n "$INDENT" >&2; echo -n "#"' ' >&2; [ -n "$1" ] && echo -n "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "# ${RCM_INDENT}" >&2; [ -n "$1" ] && echo "$@" >&2; }
____() { echo >&2; [ -n "$RCM_DELAY" ] && sleep "$RCM_DELAY"; }

# Define variables and constants.
RCM_DELAY=${RCM_DELAY:=.5}; [ -n "$fast" ] && unset RCM_DELAY
RCM_INDENT='    '; [ "$(tput cols)" -le 80 ] && RCM_INDENT='  '
ROUNDCUBE_FQDN_LOCALHOST=${ROUNDCUBE_FQDN_LOCALHOST:=roundcube.localhost}
PHPMYADMIN_FQDN_LOCALHOST=${PHPMYADMIN_FQDN_LOCALHOST:=phpmyadmin.localhost}

# Functions.
printVersion() {
    echo '0.9.17'
}
printHelp() {
    title RCM ISPConfig Setup Wrapper
    _ 'Variation '; yellow Nginx Virtual Host Autocreate PHP-FPM; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php [options]

Options:
   --subdomain
        Set the subdomain if any.
   --domain
        Set the domain.
   --project
        Available value: ispconfig, phpmyadmin, roundcube.
   --php-version
        Set the version of PHP FPM.

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.

Environment Variables:
   ROUNDCUBE_FQDN_LOCALHOST
        Default to $ROUNDCUBE_FQDN_LOCALHOST
   PHPMYADMIN_FQDN_LOCALHOST
        Default to $PHPMYADMIN_FQDN_LOCALHOST

Dependency:
   rcm-nginx-virtual-host-autocreate-php
   rcm-php-fpm-setup-project-config
   curl
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php
____

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'`cut -d: -f1 <<< "${line}"`'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Functions.
backupFile() {
    local mode="$1"
    local oldpath="$2" i newpath
    local target_dir="$3"
    i=1
    dirname=$(dirname "$oldpath")
    basename=$(basename "$oldpath")
    if [ -n "$target_dir" ];then
        case "$target_dir" in
            parent) dirname=$(dirname "$dirname") ;;
            *) dirname="$target_dir"
        esac
    fi
    [ -d "$dirname" ] || { echo 'Directory is not exists.' >&2; return 1; }
    newpath="${dirname}/${basename}.${i}"
    if [ -f "$newpath" ]; then
        let i++
        newpath="${dirname}/${basename}.${i}"
        while [ -f "$newpath" ] ; do
            let i++
            newpath="${dirname}/${basename}.${i}"
        done
    fi
    case $mode in
        move)
            mv "$oldpath" "$newpath" ;;
        copy)
            local user=$(stat -c "%U" "$oldpath")
            local group=$(stat -c "%G" "$oldpath")
            cp "$oldpath" "$newpath"
            chown ${user}:${group} "$newpath"
    esac
}

# Require, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
code 'ROUNDCUBE_FQDN_LOCALHOST="'$ROUNDCUBE_FQDN_LOCALHOST'"'
code 'PHPMYADMIN_FQDN_LOCALHOST="'$PHPMYADMIN_FQDN_LOCALHOST'"'
if [ -n "$project" ];then
    case "$project" in
        ispconfig|phpmyadmin|roundcube) ;;
        *) error "Argument --project not valid."; x ;;
    esac
fi
if [ -z "$project" ];then
    error "Argument --project required."; x
fi
if [ -z "$url_scheme" ];then
    error "Argument --url-scheme required."; x
fi
if [ -z "$url_host" ];then
    error "Argument --url-host required."; x
fi
if [ -z "$url_port" ];then
    error "Argument --url-port required."; x
fi
code 'project="'$project'"'
code 'url_scheme="'$url_scheme'"'
code 'url_host="'$url_host'"'
code 'url_port="'$url_port'"'
code 'php_version="'$php_version'"'
____

chapter Prepare arguments.

case "$project" in
    ispconfig)
        php_fpm_user=ispconfig
        code 'php_fpm_user="'$php_fpm_user'"'
        prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
        ;;
    roundcube|phpmyadmin)
        nginx_user=
        conf_nginx=`command -v nginx > /dev/null && command -v nginx > /dev/null && nginx -V 2>&1 | grep -o -P -- '--conf-path=\K(\S+)'`
        if [ -f "$conf_nginx" ];then
            nginx_user=`grep -o -P '^user\s+\K([^;]+)' "$conf_nginx"`
        fi
        code 'nginx_user="'$nginx_user'"'
        if [ -z "$nginx_user" ];then
            error "Variable \$nginx_user failed to populate."; x
        fi
        php_fpm_user="$nginx_user"
        code 'php_fpm_user="'$php_fpm_user'"'
        prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
esac
code 'prefix="'$prefix'"'
case "$project" in
    ispconfig)
        root="$prefix/interface/web"
        php_project_name="ispconfig"
        code 'php_project_name="'$php_project_name'"'
        ;;
    phpmyadmin)
        project_container="$PHPMYADMIN_FQDN_LOCALHOST"
        code 'project_container="'$project_container'"'
        root="$prefix/${project_container}/web"
        php_project_name=www
        code 'php_project_name="'$php_project_name'"'
        ;;
    roundcube)
        project_container="$ROUNDCUBE_FQDN_LOCALHOST"
        code 'project_container="'$project_container'"'
        root="$prefix/${project_container}/web"
        php_project_name=www
        code 'php_project_name="'$php_project_name'"'
        ;;
esac
____; socket_filename=$(INDENT+="    " rcm-php-fpm-setup-project-config $isfast --php-version="$php_version" --php-fpm-user="$php_fpm_user" --project-name="$php_project_name" get listen)
if [ -z "$socket_filename" ];then
    __; red Socket Filename of PHP-FPM not found.; x
fi
code 'socket_filename="'$socket_filename'"'
code root="$root"
if [[ "$url_port" == 80 || "$url_port" == 443 ]];then
    filename="$url_host"
else
    filename="${url_host}.${url_port}"
fi
code filename="$filename"
____

INDENT+="    " \
rcm-nginx-virtual-host-autocreate-php $isfast \
    --with-certbot-obtain \
    --root="$root" \
    --fastcgi-pass="unix:${socket_filename}" \
    --filename="$filename" \
    --server-name="$server_name" \
    --url-host="$url_host" \
    --url-scheme="$url_scheme" \
    --url-port="$url_port" \
    ; [ ! $? -eq 0 ] && x

chapter Mengecek HTTP Response Code.
if [ "$url_scheme" == https ];then
    _k=' -k'
else
    _k=''
fi
i=0
code=
if [ -z "$tempfile" ];then
    tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php.XXXXXX)
fi
until [ $i -eq 10 ];do
    __; magenta curl"$_k" -o /dev/null -s -w '"'%{http_code}\\n'"' '"'"${url_scheme}://127.0.0.1:${url_port}${url_path}"'"' -H '"'Host: $url_host'"'; _.
    curl$_k -o /dev/null -s -w "%{http_code}\n" "${url_scheme}://127.0.0.1:${url_port}${url_path}" -H "Host: ${url_host}" > $tempfile
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

if [ -n "$tempfile" ];then
    rm "$tempfile"
fi

exit 0

# parse-options.sh \
# --without-end-options-double-dash \
# --compact \
# --clean \
# --no-hash-bang \
# --no-original-arguments \
# --no-error-invalid-options \
# --no-error-require-arguments << EOF | clip
# FLAG=(
# --fast
# --version
# --help
# )
# VALUE=(
# --project
# --php-version
# --url-scheme
# --url-host
# --url-port
# )
# FLAG_VALUE=(
# )
# EOF
# clear
