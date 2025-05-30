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
MYSQL_ROOT_PASSWD=${MYSQL_ROOT_PASSWD:=[HOME]/.mysql-root-passwd.txt}
MYSQL_ROOT_PASSWD_INI=${MYSQL_ROOT_PASSWD_INI:=[HOME]/.mysql-root-passwd.ini}

# Functions.
printVersion() {
    echo '0.9.22'
}
printHelp() {
    title RCM MariaDB Setup
    _ 'Variation '; yellow ISPConfig; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-mariadb-setup-ispconfig [options]

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.

Environment Variables:
   MYSQL_ROOT_PASSWD
        Default to $MYSQL_ROOT_PASSWD
   MYSQL_ROOT_PASSWD_INI
        Default to $MYSQL_ROOT_PASSWD_INI

Dependency:
   systemctl
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-mariadb-setup-ispconfig
____

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'`cut -d: -f1 <<< "${line}"`'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Functions.

# Requirement, validate, and populate value.
chapter Dump variable.
code 'MYSQL_ROOT_PASSWD="'$MYSQL_ROOT_PASSWD'"'
find='[HOME]'
replace="$HOME"
MYSQL_ROOT_PASSWD="${MYSQL_ROOT_PASSWD/"$find"/"$replace"}"
code 'MYSQL_ROOT_PASSWD="'$MYSQL_ROOT_PASSWD'"'
code 'MYSQL_ROOT_PASSWD_INI="'$MYSQL_ROOT_PASSWD_INI'"'
find='[HOME]'
replace="$HOME"
MYSQL_ROOT_PASSWD_INI="${MYSQL_ROOT_PASSWD_INI/"$find"/"$replace"}"
code 'MYSQL_ROOT_PASSWD_INI="'$MYSQL_ROOT_PASSWD_INI'"'
____

chapter Mengecek konfigurasi MariaDB '`'/etc/mysql/mariadb.conf.d/50-server.cnf'`'.
if [ -f /etc/mysql/mariadb.conf.d/50-server.cnf ];then
    if grep -q '^\s*bind-address\s*=\s*127.0.0.1\s*$' /etc/mysql/mariadb.conf.d/50-server.cnf;then
        __ Disable bind-address localhost '[disabling]'.
        sed -i 's/^bind-address/# bind-address/g' /etc/mysql/mariadb.conf.d/50-server.cnf
    elif grep -q '^\s*#\s*bind-address\s*=\s*127.0.0.1\s*$' /etc/mysql/mariadb.conf.d/50-server.cnf;then
        __ Disable bind-address localhost '[existing]'.
    else
        __ Not found: bind-address localhost
    fi
else
    __; red File '`'/etc/mysql/mariadb.conf.d/50-server.cnf'`' tidak ditemukan.; x
fi
____

chapter Mengecek konfigurasi MariaDB '`'/etc/security/limits.conf'`'.
if [ -f /etc/security/limits.conf ];then
    append=
    if grep -q -E '^\s*#\s*mysql\s+soft\s+nofile\s+65535\s*$' /etc/security/limits.conf;then
        __ Enable line '`'mysql soft nofile 65535'`' '[enabling]'.
        sed -i -E 's/^\s*#\s*mysql\s+soft\s+nofile\s+65535\s*$/mysql soft nofile 65535/' /etc/security/limits.conf
    elif grep -q -E '^\s*mysql\s+soft\s+nofile\s+65535\s*$' /etc/security/limits.conf;then
        __ Enable line '`'mysql soft nofile 65535'`' '[existing]'.
    else
        __ Append line '`'mysql soft nofile 65535'`'.
        append=1
    fi
    if grep -q -E '^\s*#\s*mysql\s+hard\s+nofile\s+65535\s*$' /etc/security/limits.conf;then
        __ Enable line '`'mysql hard nofile 65535'`' '[enabling]'.
        sed -i -E 's/^\s*#\s*mysql\s+hard\s+nofile\s+65535\s*$/mysql hard nofile 65535/' /etc/security/limits.conf
    elif grep -q -E '^\s*mysql\s+hard\s+nofile\s+65535\s*$' /etc/security/limits.conf;then
        __ Enable line '`'mysql hard nofile 65535'`' '[existing]'.
    else
        __ Append line '`'mysql hard nofile 65535'`'.
        append=1
    fi
    if [ -n "$append" ];then
        echo    "" >> /etc/security/limits.conf
        echo    "# Added at ${NOW}" >> /etc/security/limits.conf
        grep -q -E '^\s*mysql\s+soft\s+nofile\s+65535\s*$' /etc/security/limits.conf || \
            echo    "mysql soft nofile 65535" >> /etc/security/limits.conf
        grep -q -E '^\s*mysql\s+hard\s+nofile\s+65535\s*$' /etc/security/limits.conf || \
            echo    "mysql hard nofile 65535" >> /etc/security/limits.conf
    fi
else
    __; red File '`'/etc/security/limits.conf'`' tidak ditemukan.; x
fi
____

chapter Mengecek konfigurasi MariaDB '`'/etc/systemd/system/mysql.service.d/limits.conf'`'.
notfound=
if [ -f /etc/systemd/system/mysql.service.d/limits.conf ];then
    __ File ditemukan.
else
    __ File tidak ditemukan.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    chapter Membuat unit file service '`'/etc/systemd/system/mysql.service.d/limits.conf'`'.
    mkdir -p /etc/systemd/system/mysql.service.d/
    cat << EOF > /etc/systemd/system/mysql.service.d/limits.conf
[Service]
LimitNOFILE=infinity
EOF
    code systemctl daemon-reload
    code systemctl restart mariadb
    systemctl daemon-reload
    systemctl restart mariadb
    if [ -f /etc/systemd/system/mysql.service.d/limits.conf ];then
        __; green File ditemukan.; _.
    else
        __; red File tidak ditemukan.; x
    fi
    ____
fi

chapter Mengecek password MySQL untuk root.
found=
if [ -f "$MYSQL_ROOT_PASSWD" ];then
    mysql_root_passwd=$(<"$MYSQL_ROOT_PASSWD")
    [ -n "$mysql_root_passwd" ] && found=1
    __ Password ditemukan: "$mysql_root_passwd"
fi
if [ -z "$found" ];then
    mysql_root_passwd=$(pwgen -s 32 -1)
    echo "$mysql_root_passwd" > "$MYSQL_ROOT_PASSWD"
    printf "[client]\nuser = %s\npassword = %s\n" "root" "$mysql_root_passwd" > "$MYSQL_ROOT_PASSWD_INI"
    chmod 0400 "$MYSQL_ROOT_PASSWD"
    chmod 0400 "$MYSQL_ROOT_PASSWD_INI"
    __; green Password berhasil dibuat: "$mysql_root_passwd"; _.
fi
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
