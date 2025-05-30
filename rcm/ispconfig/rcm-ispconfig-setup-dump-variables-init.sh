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
MARIADB_PREFIX_MASTER=${MARIADB_PREFIX_MASTER:=/usr/local/share/mariadb}
MARIADB_USERS_CONTAINER_MASTER=${MARIADB_USERS_CONTAINER_MASTER:=users}

# Functions.
printVersion() {
    echo '0.9.22'
}
printHelp() {
    title RCM ISPConfig Setup
    _ 'Variation '; yellow Dump Variables; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-setup-dump-variables-init [options]

Options:

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.

Environment Variables:
   MARIADB_PREFIX_MASTER
        Default to $MARIADB_PREFIX_MASTER
   MARIADB_USERS_CONTAINER_MASTER
        Default to $MARIADB_USERS_CONTAINER_MASTER
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-setup-dump-variables-init
____

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'`cut -d: -f1 <<< "${line}"`'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Functions.
fileMustExists() {
    # global used:
    # global modified:
    # function used: __, success, error, x
    if [ -f "$1" ];then
        __; green File '`'$(basename "$1")'`' ditemukan.; _.
    else
        __; red File '`'$(basename "$1")'`' tidak ditemukan.; x
    fi
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
populateDatabaseUserPassword() {
    local path="${MARIADB_PREFIX_MASTER}/${MARIADB_USERS_CONTAINER_MASTER}/$1"
    local DB_USER DB_USER_PASSWORD
    if [ -f "$path" ];then
        . "$path"
        db_user_password=$DB_USER_PASSWORD
    fi
}
databaseCredentialIspconfig() {
    local php_fpm_user prefix path
    php_fpm_user=ispconfig
    prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
    path="${prefix}/interface/lib/config.inc.php"
    db_user=$(php -r "include '$path';echo DB_USER;")
    db_user_password=$(php -r "include '$path';echo DB_PASSWORD;")
}
websiteCredentialIspconfig() {
    local ISPCONFIG_WEB_USER_PASSWORD
    path=/usr/local/share/ispconfig/credential/website
    [ -f "$path" ] || fileMustExists "$path"
    . "$path"
    ispconfig_web_user_password=$ISPCONFIG_WEB_USER_PASSWORD
}

# Require, validate, and populate value.
chapter Dump variable.
code 'MARIADB_PREFIX_MASTER="'$MARIADB_PREFIX_MASTER'"'
code 'MARIADB_USERS_CONTAINER_MASTER="'$MARIADB_USERS_CONTAINER_MASTER'"'
____

if [ -f /usr/local/share/ispconfig/website ];then
    . /usr/local/share/ispconfig/website
fi
[ -n "$URL_ISPCONFIG" ] || URL_ISPCONFIG=http://ispconfig.localhost/
if [ -f /usr/local/share/phpmyadmin/website ];then
    . /usr/local/share/phpmyadmin/website
fi
[ -n "$URL_PHPMYADMIN" ] || URL_PHPMYADMIN=http://phpmyadmin.localhost/
if [ -f /usr/local/share/roundcube/website ];then
    . /usr/local/share/roundcube/website
fi
[ -n "$URL_ROUNDCUBE" ] || URL_ROUNDCUBE=http://roundcube.localhost/

chapter Website available.
_ ' - ISPConfig  :' "$URL_ISPCONFIG"; _.
[ "$URL_ISPCONFIG" == 'http://ispconfig.localhost/' ] || _ '              :' http://ispconfig.localhost/; _.
_ ' - PHPMyAdmin :' "$URL_PHPMYADMIN"; _.
[ "$URL_PHPMYADMIN" == 'http://phpmyadmin.localhost/' ] || _ '              :' http://phpmyadmin.localhost/; _.
_ ' - Roundcube  :' "$URL_ROUNDCUBE"; _.
[ "$URL_ROUNDCUBE" == 'http://roundcube.localhost/' ] || _ '              :' http://roundcube.localhost/; _.
____

chapter PHPMyAdmin Credentials.
db_user=phpmyadmin
populateDatabaseUserPassword "$db_user"
_ ' - 'username: $db_user; _.
_ '   'password: $db_user_password; _.
db_user=roundcube
populateDatabaseUserPassword "$db_user"
_ ' - 'username: $db_user; _.
_ '   'password: $db_user_password; _.
databaseCredentialIspconfig
_ ' - 'username: $db_user; _.
_ '   'password: $db_user_password; _.
____

chapter ISPConfig Credentials.
websiteCredentialIspconfig
_ ' - 'username: admin; _.
_ '   'password: $ispconfig_web_user_password; _.
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
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# CSV=(
# )
# EOF
# clear
