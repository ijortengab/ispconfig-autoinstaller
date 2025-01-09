#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then domain="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --php-version=*) php_version="${1#*=}"; shift ;;
        --php-version) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then php_version="$2"; shift; fi; shift ;;
        --project=*) project="${1#*=}"; shift ;;
        --project) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then project="$2"; shift; fi; shift ;;
        --subdomain=*) subdomain="${1#*=}"; shift ;;
        --subdomain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then subdomain="$2"; shift; fi; shift ;;
        --url-host=*) url_host="${1#*=}"; shift ;;
        --url-host) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_host="$2"; shift; fi; shift ;;
        --url-path=*) url_path="${1#*=}"; shift ;;
        --url-path) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_path="$2"; shift; fi; shift ;;
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
__() { echo -n "$INDENT" >&2; echo -n "#" '    ' >&2; [ -n "$1" ] && echo "$@" >&2; }
____() { echo >&2; [ -n "$RCM_DELAY" ] && sleep "$RCM_DELAY"; }

# Define variables and constants.
RCM_DELAY=${RCM_DELAY:=.5}; [ -n "$fast" ] && unset RCM_DELAY
ROUNDCUBE_FQDN_LOCALHOST=${ROUNDCUBE_FQDN_LOCALHOST:=roundcube.localhost}
PHPMYADMIN_FQDN_LOCALHOST=${PHPMYADMIN_FQDN_LOCALHOST:=phpmyadmin.localhost}

# Functions.
printVersion() {
    echo '0.9.15'
}
printHelp() {
    title RCM ISPConfig Setup Wrapper
    _ 'Variation '; yellow Nginx Virtual Host Autocreate PHP-FPM; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root [options]

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
   rcm-nginx-virtual-host-autocreate-php-multiple-root
   rcm-php-fpm-setup-project-config
   curl
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root
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
dirMustExists() {
    # global used:
    # global modified:
    # function used: __, success, error, x
    if [ -d "$1" ];then
        __; green Direktori '`'$(basename "$1")'`' ditemukan.; _.
    else
        __; red Direktori '`'$(basename "$1")'`' tidak ditemukan.; x
    fi
}
isDirExists() {
    # global used:
    # global modified: found, notfound
    # function used: __
    found=
    notfound=
    if [ -d "$1" ];then
        __ Direktori '`'$(basename "$1")'`' ditemukan.
        found=1
    else
        __ Direktori '`'$(basename "$1")'`' tidak ditemukan.
        notfound=1
    fi
}
link_symbolic_dir() {
    local source="$1"
    local target="$2"
    local sudo="$3"
    local source_mode="$4"
    local create
    # Trim trailing slash.
    source=$(echo "$source" | sed -E 's|/+$||g')
    target=$(echo "$target" | sed -E 's|/+$||g')
    [ "$sudo" == - ] && sudo=
    [ "$source_mode" == absolute ] || source_mode=
    [ -e "$source" ] || { error Source not exist: $source.; x; }
    [ -d "$source" ] || { error Source exists but not directory: $source.; x; }
    [ -n "$target" ] || { error Target not defined.; x; }
    [[ $(type -t backupFile) == function ]] || { error Function backupFile not found.; x; }
    [[ $(type -t backupDir) == function ]] || { error Function backupDir not found.; x; }
    chapter Membuat symbolic link directory.
    __ source: '`'$source'`'
    __ target: '`'$target'`'
    if [ -d "$target" ];then
        if [ -h "$target" ];then
            __ Path target saat ini sudah merupakan directory symbolic link: '`'$target'`'
            local _readlink=$(readlink "$target")
            __; magenta readlink "$target"; _.
            _ $_readlink; _.
            if [[ "$_readlink" =~ ^[^/\.] ]];then
                local target_parent=$(dirname "$target")
                local _dereference="${target_parent}/${_readlink}"
            elif [[ "$_readlink" =~ ^[\.] ]];then
                local target_parent=$(dirname "$target")
                local _dereference="${target_parent}/${_readlink}"
                _dereference=$(realpath -s "$_dereference")
            else
                _dereference="$_readlink"
            fi
            __; _, Mengecek apakah link merujuk ke '`'$source'`':' '
            if [[ "$source" == "$_dereference" ]];then
                _, merujuk.; _.
            else
                _, tidak merujuk.; _.
                __ Melakukan backup.
                backupFile move "$target"
                create=1
            fi
        else
            __ Melakukan backup regular direktori: '`'"$target"'`'.
            backupDir "$target"
            create=1
        fi
    elif [ -f "$target" ];then
        __ Melakukan backup file: '`'"$target"'`'.
        backupFile move "$target"
        create=1
    else
        create=1
    fi
    if [ -n "$create" ];then
        __ Membuat symbolic link: '`'$target'`'.
        local target_parent=$(dirname "$target")
        if [ -n "$sudo" ];then
            code sudo -u '"'$sudo'"' mkdir -p '"'$target_parent'"'
            sudo -u "$sudo" mkdir -p "$target_parent"
        else
            code mkdir -p "$target_parent"
            mkdir -p "$target_parent"
        fi
        if [ -z "$source_mode" ];then
            source=$(realpath -s --relative-to="$target_parent" "$source")
        fi
        if [ -n "$sudo" ];then
            code sudo -u '"'$sudo'"' ln -s '"'$source'"' '"'$target'"'
            sudo -u "$sudo" ln -s "$source" "$target"
        else
            code ln -s '"'$source'"' '"'$target'"'
            ln -s "$source" "$target"
        fi
        if [ $? -eq 0 ];then
            __; green Symbolic link berhasil dibuat.; _.
        else
            __; red Symbolic link gagal dibuat.; x
        fi
    fi
    ____
}
backupDir() {
    local oldpath="$1" i newpath
    # Trim trailing slash.
    oldpath=$(echo "$oldpath" | sed -E 's|/+$||g')
    i=1
    newpath="${oldpath}.${i}"
    if [ -e "$newpath" ]; then
        let i++
        newpath="${oldpath}.${i}"
        while [ -e "$newpath" ] ; do
            let i++
            newpath="${oldpath}.${i}"
        done
    fi
    mv "$oldpath" "$newpath"
}
ArrayPop() {
    local index
    local source=("${!1}")
    # declare -i last_index
    local last_index=${#source[@]}
    last_index=$((last_index - 1))
    _return=()
    for (( index=0; index < "$last_index" ; index++ )); do
        _return+=("${source[$index]}")
    done
    return="${source[-1]}"
}
adjustNginxWebRoot() {
    # global modified $nginx_web_root
    local url_path=$1; shift;
    if [ -z "$url_path" ];then
        # not modified.
        return
    fi
    local url_path_clean=$(echo "$url_path" | sed -E 's|(^/+\|/+$)||g')
    if [[ ! "$url_path_clean" =~ / ]];then
        # not modified.
        return
    fi
    # Explode by space.
    # read -ra array -d '' <<< "$string"
    # Explode by slash.
    IFS='/' read -ra array <<< "$url_path_clean"
    # for each in "${array[@]}"; do echo "_${each}_"; done;
    ArrayPop array[@]
    array=("${_return[@]}"); unset _return
    for each in "${array[@]}"; do nginx_web_root+="/${each}.d"; done;
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
code 'project="'$project'"'
if [ -z "$url_scheme" ];then
    error "Argument --url-scheme required."; x
fi
if [ -z "$url_host" ];then
    error "Argument --url-host required."; x
fi
if [ -z "$url_port" ];then
    error "Argument --url-port required."; x
fi
if [[ "$url_path" == '/' ]];then
    url_path=
fi
if [ -n "$url_path" ];then
    # Trim leading and trailing slash.
    url_path_clean=$(echo "$url_path" | sed -E 's|(^/+\|/+$)||g')
    url_path_clean_trailing=$(echo "$url_path" | sed -E 's|/+$||g')
    # Must leading with slash.
    # Karena akan digunakan pada nginx configuration.
    _url_path_correct="/${url_path_clean}"
    if [ ! "$url_path_clean_trailing" == "$_url_path_correct" ];then
        error "Argument --url-path not valid."; x
    fi
fi
code 'url_scheme="'$url_scheme'"'
code 'url_host="'$url_host'"'
code 'url_port="'$url_port'"'
code 'url_path="'$url_path'"'
code 'url_path_clean="'$url_path_clean'"'
code 'php_version="'$php_version'"'
____

chapter Prepare arguments.
nginx_user=
conf_nginx=`command -v nginx > /dev/null && command -v nginx > /dev/null && nginx -V 2>&1 | grep -o -P -- '--conf-path=\K(\S+)'`
if [ -f "$conf_nginx" ];then
    nginx_user=`grep -o -P '^user\s+\K([^;]+)' "$conf_nginx"`
fi
code 'nginx_user="'$nginx_user'"'
if [ -z "$nginx_user" ];then
    error "Variable \$nginx_user failed to populate."; x
fi
nginx_user_home=$(getent passwd "$nginx_user" | cut -d: -f6 )
case "$project" in
    ispconfig)
        php_fpm_user=ispconfig
        code 'php_fpm_user="'$php_fpm_user'"'
        prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
        ;;
    roundcube|phpmyadmin)
        php_fpm_user="$nginx_user"
        code 'php_fpm_user="'$php_fpm_user'"'
        prefix="$nginx_user_home"
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
fastcgi_pass="unix:${socket_filename}"
code 'fastcgi_pass="'$fastcgi_pass'"'
code root="$root"
if [[ "$url_port" == 80 || "$url_port" == 443 ]];then
    filename="$url_host"
    additional_path_custom_port=
else
    filename="${url_host}.${url_port}"
    additional_path_custom_port="/${url_port}"
fi
code filename="$filename"
server_name="$url_host"
code server_name="$server_name"
____

# User yang digunakan sudah pasti adalah user nginx, karena akan dibuat di
# `/var/www`.
chapter Populate variable.
nginx_web_root="${nginx_user_home}/${url_host}${additional_path_custom_port}/web"
code 'nginx_web_root="'$nginx_web_root'"'
nginx_config_dir="${nginx_user_home}/${url_host}${additional_path_custom_port}/nginx.conf.d"
nginx_config_file="${nginx_user_home}/${url_host}${additional_path_custom_port}/nginx.conf"
code 'nginx_config_dir="'$nginx_config_dir'"'
code 'nginx_config_file="'$nginx_config_file'"'
adjustNginxWebRoot "$url_path"
code 'nginx_web_root="'$nginx_web_root'"'
____

chapter Mengecek direktori web root '`'$nginx_web_root'`'.
isDirExists "$nginx_web_root"
____

if [ -n "$notfound" ];then
    chapter Membuat direktori web root '`'$nginx_web_root'`'.
    code mkdir -p '"'$nginx_web_root'"'
    mkdir -p "$nginx_web_root"
    code chown -R $nginx_user:$nginx_user '"'$nginx_web_root'"'
    chown -R $nginx_user:$nginx_user "$nginx_web_root"
    dirMustExists "$nginx_web_root"
    ____
fi

target="$nginx_web_root"
if [ -n "$url_path_clean" ];then
    target+="/${url_path_clean}"
fi
code 'target="'$target'"'
chapter Memeriksa direktori target '`'$target'`'
create=
if [[ "$target" == "$nginx_web_root" ]];then
    __ Target sama dengan web root. Symbolic link tidak diperlukan.
else
    __ Target tidak sama dengan web root. Symbolic link diperlukan.
    create=1
fi
____

if [ -n "$create" ];then
    source="$root"
    link_symbolic_dir "$source" "$target" - absolute
fi

if [ -n "$url_path" ];then
    chapter Mengecek direktori nginx additional config '`'$nginx_config_dir'`'.
    isDirExists "$nginx_config_dir"
    ____

    if [ -n "$notfound" ];then
        chapter Membuat direktori web root '`'$nginx_config_dir'`'.
        code mkdir -p '"'$nginx_config_dir'"'
        mkdir -p "$nginx_config_dir"
        code chown -R $nginx_user:$nginx_user '"'$nginx_config_dir'"'
        chown -R $nginx_user:$nginx_user "$nginx_config_dir"
        dirMustExists "$nginx_config_dir"
        ____
    fi
fi

chapter Prepare Arguments.
master_root="$nginx_web_root"
master_include="${nginx_config_dir}/*"
master_include_2="$nginx_config_file"
master_filename="$filename"
master_url_host="$url_host"
master_url_scheme="$url_scheme"
master_url_port="$url_port"
slave_root=
slave_filename="${url_path_clean//\//.}"
slave_dirname="$nginx_config_dir"
slave_fastcgi_pass="$fastcgi_pass"
slave_url_path="$url_path_clean_trailing"
slave_url_path_clean="$url_path_clean"
if [ -z "$url_path" ];then
    slave_filename="$(basename "$nginx_config_file")"
    slave_dirname="$(dirname "$nginx_config_file")"
    slave_url_path=
    slave_root="$root"
fi
code 'master_root="'$master_root'"'
code 'master_include="'$master_include'"'
code 'master_include_2="'$master_include_2'"'
code 'master_filename="'$master_filename'"'
code 'master_url_host="'$master_url_host'"'
code 'master_url_scheme="'$master_url_scheme'"'
code 'master_url_port="'$master_url_port'"'
code 'slave_root="'$slave_root'"'
code 'slave_filename="'$slave_filename'"'
code 'slave_dirname="'$slave_dirname'"'
code 'slave_fastcgi_pass="'$slave_fastcgi_pass'"'
code 'slave_url_path="'$slave_url_path'"'
____

INDENT+="    " \
rcm-nginx-virtual-host-autocreate-php-multiple-root $isfast \
    --with-certbot-obtain \
    --master-root="$master_root" \
    --master-include="$master_include" \
    --master-include-2="$master_include_2" \
    --master-filename="$master_filename" \
    --master-url-host="$master_url_host" \
    --master-url-scheme="$master_url_scheme" \
    --master-url-port="$master_url_port" \
    --slave-root="$slave_root" \
    --slave-filename="$slave_filename" \
    --slave-dirname="$slave_dirname" \
    --slave-fastcgi-pass="$slave_fastcgi_pass" \
    --slave-url-path="$slave_url_path" \
    ; [ ! $? -eq 0 ] && x

chapter Mengecek HTTP Response Code.
if [ "$url_scheme" == https ];then
    _k=' -k'
else
    _k=''
fi
code curl${_k} ${url_scheme}://127.0.0.1:${url_port}${url_path} -H '"'Host: ${url_host}'"'
code=$(curl${_k} \
    -o /dev/null -s -w "%{http_code}\n" \
    ${url_scheme}://127.0.0.1:${url_port}${url_path} -H "Host: ${url_host}")
[[ $code =~ ^[2,3] ]] && {
    __ HTTP Response code '`'$code'`' '('Required')'.
} || {
    __; red Terjadi kesalahan. HTTP Response code '`'$code'`'.; x
}
____

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
# --domain
# --subdomain
# --project
# --php-version
# --url-scheme
# --url-host
# --url-port
# --url-path
# )
# FLAG_VALUE=(
# )
# EOF
# clear
