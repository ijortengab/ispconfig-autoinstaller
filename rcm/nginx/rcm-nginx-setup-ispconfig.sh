#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --fast) fast=1; shift ;;
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

# Functions.
printVersion() {
    echo '0.9.19'
}
printHelp() {
    title RCM Nginx Setup
    _ 'Variation '; yellow ISPConfig Default; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << 'EOF'
Usage: rcm-nginx-setup-ispconfig [options]

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.

Dependency:
   systemctl
   rcm-nginx-reload
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-nginx-setup-ispconfig
____

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'`cut -d: -f1 <<< "${line}"`'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Functions.
link_symbolic() {
    local source="$1"
    local target="$2"
    local sudo="$3"
    local source_mode="$4"
    local create
    [ "$sudo" == - ] && sudo=
    [ "$source_mode" == absolute ] || source_mode=
    [ -e "$source" ] || { error Source not exist: $source.; x; }
    [ -f "$source" ] || { error Source exists but not file: $source.; x; }
    [ -n "$target" ] || { error Target not defined.; x; }
    [[ $(type -t backupFile) == function ]] || { error Function backupFile not found.; x; }
    [[ $(type -t backupDir) == function ]] || { error Function backupDir not found.; x; }
    chapter Membuat symbolic link.
    __ source: '`'$source'`'
    __ target: '`'$target'`'
    if [ -f "$target" ];then
        if [ -h "$target" ];then
            __ Path target saat ini sudah merupakan file symbolic link: '`'$target'`'
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
            __ Melakukan backup regular file: '`'"$target"'`'.
            backupFile move "$target"
            create=1
        fi
    elif [ -d "$target" ];then
        __ Melakukan backup direktori: '`'"$target"'`'.
        backupDir "$target"
        create=1
    else
        create=1
    fi
    if [ -n "$create" ];then
        __ Membuat symbolic link: '`'$target'`'.
        local target_parent=$(dirname "$target")
        code mkdir -p "$target_parent"
        mkdir -p "$target_parent"
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

# Require, validate, and populate value.
chapter Dump variable.
rcm_nginx_reload=
____

chapter Mengecek UnitFileState service Apache2. # Menginstall PHP di Debian, biasanya auto install juga Apache2.
msg=$(systemctl show apache2.service --no-page | grep UnitFileState | grep -o -P "UnitFileState=\K(\S+)")
disable=
if [[ -z "$msg" ]];then
    __ UnitFileState service Apache2 not found.
elif [[ "$msg"  == 'enabled' ]];then
    __ UnitFileState service Apache2 enabled.
    disable=1
else
    __ UnitFileState service Apache2: $msg.
fi
____

if [ -n "$disable" ];then
    chapter Mematikan service Apache2.
    code systemctl disable --now apache2
    systemctl disable --now apache2
    msg=$(systemctl show apache2.service --no-page | grep UnitFileState | grep -o -P "UnitFileState=\K(\S+)")
    if [[ $msg == 'disabled' ]];then
        __; green Berhasil disabled.; _.
    else
        __; red Gagal disabled.; _.
        __ UnitFileState state: $msg.
        exit
    fi
    ____
fi

chapter Mengecek ActiveState service Nginx. # Kadang bentrok dengan Apache2.
msg=$(systemctl show nginx.service --no-page | grep ActiveState | grep -o -P "^ActiveState=\K(\S+)")
restart=
if [[ -z "$msg" ]];then
    __; red Service nginx tidak ditemukan.; x
elif [[ "$msg"  == 'active' ]];then
    __ Service nginx active.
else
    __ Service ActiveState nginx: $msg.
    restart=1
fi
____

if [ -n "$restart" ];then
    chapter Menjalankan service nginx.
    code systemctl enable --now nginx
    systemctl enable --now nginx
    msg=$(systemctl show nginx.service --no-page | grep ActiveState | grep -o -P "ActiveState=\K(\S+)")
    if [[ $msg == 'active' ]];then
        __; green Berhasil activated.; _.
    else
        __; red Gagal activated.; _.
        __ ActiveState state: $msg.
        exit
    fi
    ____
fi

chapter Membatasi akses ke localhost.

if [ -f /etc/nginx/sites-available/default ];then
    __ Backup file /etc/nginx/sites-available/default
    backupFile move /etc/nginx/sites-available/default
    cat <<'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html;
    server_name _;
    location / {
        deny all;
    }
}
EOF
    rcm_nginx_reload=1
fi
____

source=/etc/nginx/sites-available/default
target=/etc/nginx/sites-enabled/default
link_symbolic "$source" "$target"

if [ -n "$rcm_nginx_reload" ];then
    INDENT+="    " \
    rcm-nginx-reload \
        ; [ ! $? -eq 0 ] && x
fi

chapter Mengecek HTTP Response Code.
i=0
code=
if [ -z "$tempfile" ];then
    tempfile=$(mktemp -p /dev/shm -t rcm-nginx-setup-ispconfig.XXXXXX)
fi
until [ $i -eq 10 ];do
    __; magenta curl -o /dev/null -s -w '"'%{http_code}\\n'"' '"'http://127.0.0.1'"'; _.
    curl -o /dev/null -s -w "%{http_code}\n" "http://127.0.0.1" > $tempfile
    while read line; do e "$line"; _.; done < $tempfile
    code=$(head -1 $tempfile)
    if [ "$code" -eq 403 ];then
        break
    else
        __ Retry.
        __; magenta sleep .5; _.
        sleep .5
    fi
    let i++
done
if [ "$code" -eq 403 ];then
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
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# CSV=(
# )
# EOF
# clear
