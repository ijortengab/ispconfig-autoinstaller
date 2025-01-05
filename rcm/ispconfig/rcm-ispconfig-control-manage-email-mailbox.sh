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
        --ispconfig-domain-exists-sure) ispconfig_domain_exists_sure=1; shift ;;
        --ispconfig-soap-exists-sure) ispconfig_soap_exists_sure=1; shift ;;
        --name=*) name="${1#*=}"; shift ;;
        --name) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then name="$2"; shift; fi; shift ;;
        --root-sure) root_sure=1; shift ;;
        --) shift
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    *) _new_arguments+=("$1"); shift ;;
                esac
            done
            ;;
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
_() { echo -n "$INDENT" >&2; echo -n "#" "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "#" '    ' >&2; [ -n "$1" ] && echo "$@" >&2 || echo -n  >&2; }
____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

# Functions.
printVersion() {
    echo '0.9.12'
}
printHelp() {
    title RCM ISPConfig Control
    _ 'Variation '; yellow Manage Email Mailbox; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-control-manage-email-mailbox [options]

Options:
   --name
        The name of mailbox.
   --domain
        The domain of mailbox.
   --
        Every arguments after double dash will pass to \`rcm-php-ispconfig soap mail_user_add\` command.

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.
   --root-sure
        Bypass root checking.
   --ispconfig-domain-exists-sure
        Bypass domain exists checking.

Environment Variables:
   ISPCONFIG_REMOTE_USER_ROOT
        Default to root
   ISPCONFIG_FQDN_LOCALHOST
        Default to ispconfig.localhost

Dependency:
   rcm-ispconfig-control-manage-domain:`printVersion`
   rcm-php-ispconfig:`printVersion`
   php
   mysql

Download:
   [rcm-ispconfig-control-manage-domain](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-domain.sh)
   [rcm-php-ispconfig](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/php/rcm-php-ispconfig.php)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-control-manage-email-mailbox
____

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'$line'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

if [ -z "$root_sure" ];then
    chapter Mengecek akses root.
    if [[ "$EUID" -ne 0 ]]; then
        error This script needs to be run with superuser privileges.; x
    else
        __ Privileges.
    fi
    ____
fi

# Functions.
mailboxCredential() {
    # global modified $password
    local host="$1"
    local user="$2"
    [ -n "$host" ] || { error Variable host is required; x; }
    [ -n "$user" ] || { error Variable user is required; x; }

    local path="/usr/local/share/credential/mailbox/${host}/${user}"
    local dirname="/usr/local/share/credential/mailbox/${host}"
    __; magenta 'path="'$path'"'; _.
    if [ -z "$password" ];then
        password=$(pwgen 9 -1vA0B)
    fi
    if [ -f "$path" ];then
        local _password=$(<"$path")
        if [[ ! "$_password" == "$password" ]];then
            echo "$password" > "$path"
        fi
    else
        mkdir -p "$dirname"
        echo "$password" > "$path"
        chmod 0500 "$dirname"
        chmod 0400 "$path"
    fi
}
isExists() {
    # global $user, $host, $tempfile
    # global modified $mailuser_id
    [ -n "$user" ] || { error Variable user is required; x; }
    [ -n "$host" ] || { error Variable host is required; x; }
    [ -n "$tempfile" ] || { error Variable tempfile is required; x; }
    local email="${user}@${host}"
    code rcm-php-ispconfig soap --empty-array-is-false mail_user_get --email='"'$email'"'
    rcm-php-ispconfig soap --empty-array-is-false mail_user_get --email="$email" 2>&1 &> "$tempfile"
    local exit_code=$?
    if [ $exit_code -eq 0 ];then
        mailuser_id=$(rcm-php-ispconfig echo [0][mailuser_id] < "$tempfile")
        __; magenta mailuser_id=$mailuser_id; _.
    else
        while IFS= read line; do e "$line"; _.; done < "$tempfile"
    fi
    return $exit_code
}
create() {
    # global $user, $host, $tempfile
    # global modified $mailuser_id
    [ -n "$user" ] || { error Variable user is required; x; }
    [ -n "$host" ] || { error Variable host is required; x; }
    [ -n "$tempfile" ] || { error Variable tempfile is required; x; }
    local email="${user}@${host}"

    ____; client_id=$(INDENT+="    " rcm-ispconfig-control-manage-client $isfast get-client-id --username "$domain")
    code 'client_id="'$client_id'"'
    [ -n "$client_id" ] || client_id=0
    code 'client_id="'$client_id'"'
    mailboxCredential $host $user
    __; magenta 'password="'$password'"'; _.
    code rcm-php-ispconfig soap mail_user_add '"'$client_id'"' --server-id='"'1'"' --email='"'$email'"' --password='"'$password'"' "$@"
    rcm-php-ispconfig soap mail_user_add "$client_id" --server-id="1" --email="$email" --password="$password" "$@" 2>&1 &> "$tempfile"
    local exit_code=$?
    if [ $exit_code -eq 0 ];then
        mailuser_id=$(cat "$tempfile" | rcm-php-ispconfig echo)
        __; magenta mailuser_id=$mailuser_id; _.
    else
        while IFS= read line; do e "$line"; _.; done < "$tempfile"
    fi
    return $exit_code
}

# Require, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
ISPCONFIG_REMOTE_USER_ROOT=${ISPCONFIG_REMOTE_USER_ROOT:=root}
code 'ISPCONFIG_REMOTE_USER_ROOT="'$ISPCONFIG_REMOTE_USER_ROOT'"'
ISPCONFIG_FQDN_LOCALHOST=${ISPCONFIG_FQDN_LOCALHOST:=ispconfig.localhost}
code 'ISPCONFIG_FQDN_LOCALHOST="'$ISPCONFIG_FQDN_LOCALHOST'"'
if [ -z "$domain" ];then
    error "Argument --domain required."; x
fi
code 'domain="'$domain'"'
if [ -z "$name" ];then
    error "Argument --name required."; x
fi
code 'name="'$name'"'
code 'ispconfig_domain_exists_sure="'$ispconfig_domain_exists_sure'"'
code 'ispconfig_soap_exists_sure="'$ispconfig_soap_exists_sure'"'
tempfile=
____

if [ -z "$ispconfig_domain_exists_sure" ];then
    INDENT+="    " \
    rcm-ispconfig-control-manage-domain $isfast --root-sure \
        --domain="$domain" \
        ; [ ! $? -eq 0 ] && x
fi

if [ -z "$ispconfig_soap_exists_sure" ];then
    chapter Test koneksi SOAP.
    code rcm-php-ispconfig soap login
    if [ -z "$tempfile" ];then
        tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-control-manage-email-mailbox.XXXXXX)
    fi
    if rcm-php-ispconfig soap login 2> "$tempfile";then
        while IFS= read line; do e "$line"; _.; done < "$tempfile"
        __ Login berhasil.
    else
        rm "$tempfile"
        error Login gagal; x
    fi
    ____
fi

user="$name"
host="$domain"
email="${user}@${host}"
chapter Autocreate mailbox '`'$email'`' di Module Mail ISPConfig.
if [ -z "$tempfile" ];then
    tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-control-manage-email-mailbox.XXXXXX)
fi
if isExists;then
    __ Mailbox '`'$email'`' telah terdaftar di ISPConfig.
elif create "$@";then
    success Mailbox '`'$email'`' berhasil terdaftar di ISPConfig.
else
    error Mailbox '`'$email'`' gagal terdaftar di ISPConfig.; x
fi
____

exit 0

# parse-options.sh \
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
# --root-sure
# --ispconfig-domain-exists-sure
# --ispconfig-soap-exists-sure
# )
# VALUE=(
# --name
# --domain
# )
# FLAG_VALUE=(
# )
# EOF
# clear
