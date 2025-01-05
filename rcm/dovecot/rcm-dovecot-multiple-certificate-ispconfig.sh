#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --certbot-authenticator=*) certbot_authenticator="${1#*=}"; shift ;;
        --certbot-authenticator) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then certbot_authenticator="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --fqdn=*) fqdn="${1#*=}"; shift ;;
        --fqdn) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then fqdn="$2"; shift; fi; shift ;;
        --root-sure) root_sure=1; shift ;;
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
____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

# Define variables and constants.
delay=.5; [ -n "$fast" ] && unset delay
DOVECOT_CONFIG_DIR=${DOVECOT_CONFIG_DIR:=/etc/dovecot}
DOVECOT_CONFIG_FILE_ISPCONFIG=${DOVECOT_CONFIG_FILE_ISPCONFIG:=${DOVECOT_CONFIG_DIR}/conf.d/99-ispconfig-custom-config.conf}
MAILBOX_HOST=${MAILBOX_HOST:=hostmaster}

# Functions.
printVersion() {
    echo '0.9.12'
}
printHelp() {
    title RCM Postfix Multiple Certificate
    _ 'Variation '; yellow ISPConfig; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-dovecot-multiple-certificate-ispconfig [options]

Options:
   --fqdn *
        Fully Qualified Domain Name of the certificate, for example: \`server1.example.org\`.
   --certbot-authenticator *
        Available value: digitalocean, nginx.

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.
   --root-sure
        Bypass root checking.

Environment Variables:
   MAILBOX_HOST
        Default to $MAILBOX_HOST
   DOVECOT_CONFIG_DIR
        Default to $DOVECOT_CONFIG_DIR
   DOVECOT_CONFIG_FILE_ISPCONFIG
        Default to $DOVECOT_CONFIG_FILE_ISPCONFIG

Dependency:
   rcm-certbot-obtain-authenticator-nginx
   rcm-certbot-obtain-authenticator-digitalocean
   rcm-dovecot-multiple-certificate
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-dovecot-multiple-certificate-ispconfig
____

if [ -z "$root_sure" ];then
    chapter Mengecek akses root.
    if [[ "$EUID" -ne 0 ]]; then
        error This script needs to be run with superuser privileges.; x
    else
        __ Privileges.
    fi
    ____
fi

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'$line'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Functions.
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

# Require, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
code 'MAILBOX_HOST="'$MAILBOX_HOST'"'
code 'DOVECOT_CONFIG_DIR="'$DOVECOT_CONFIG_DIR'"'
code 'DOVECOT_CONFIG_FILE_ISPCONFIG="'$DOVECOT_CONFIG_FILE_ISPCONFIG'"'
if [ -z "$fqdn" ];then
    error "Argument --fqdn required."; x
fi
code 'fqdn="'$fqdn'"'
if [ -n "$certbot_authenticator" ];then
    case "$certbot_authenticator" in
        digitalocean|nginx) ;;
        *) error "Argument --certbot-authenticator not valid."; x ;;
    esac
fi
if [ -z "$certbot_authenticator" ];then
    error "Argument --certbot-authenticator required."; x
fi
code 'certbot_authenticator="'$certbot_authenticator'"'
certbot_certificate_name="$fqdn"
code 'certbot_certificate_name="'$certbot_certificate_name'"'
____

path="/etc/letsencrypt/live/${certbot_certificate_name}"
chapter Mengecek direktori certbot '`'$path'`'.
isDirExists "$path"
____

if [ -n "$notfound" ];then
    chapter Mengecek '$PATH'.
    code PATH="$PATH"
    if grep -q '/snap/bin' <<< "$PATH";then
        __ '$PATH' sudah lengkap.
    else
        __ '$PATH' belum lengkap.
        __ Memperbaiki '$PATH'
        PATH=/snap/bin:$PATH
        if grep -q '/snap/bin' <<< "$PATH";then
            __; green '$PATH' sudah lengkap.; _.
            __; magenta PATH="$PATH"; _.
        else
            __; red '$PATH' belum lengkap.; x
        fi
    fi
    ____

    if [[ "$certbot_authenticator" == 'digitalocean' ]]; then
        INDENT+="    " \
        PATH=$PATH \
        rcm-certbot-obtain-authenticator-digitalocean $isfast --root-sure \
            --certbot-dns-digitalocean-sure \
            --domain="$fqdn" \
            ; [ ! $? -eq 0 ] && x
        # @todo, cek harusnya parent sudah validate certbot-dns-digitalocean
        # sehingga bisa kita kasih option --certbot-dns-digitalocean-sure
    elif [[ "$certbot_authenticator" == 'nginx' ]]; then
        INDENT+="    " \
        PATH=$PATH \
        rcm-certbot-obtain-authenticator-nginx $isfast --root-sure \
            --domain="$fqdn" \
            ; [ ! $? -eq 0 ] && x
    fi
fi

chapter Memeriksa certificate SSL.
ssl_cert="/etc/letsencrypt/live/${certbot_certificate_name}/fullchain.pem"
code 'ssl_cert="'$ssl_cert'"'
[ -f "$ssl_cert" ] || fileMustExists "$ssl_cert"
ssl_key="/etc/letsencrypt/live/${certbot_certificate_name}/privkey.pem"
code 'ssl_key="'$ssl_key'"'
[ -f "$ssl_key" ] || fileMustExists "$ssl_key"
____

INDENT+="    " \
rcm-dovecot-multiple-certificate $isfast --root-sure \
    --ssl-cert="$ssl_cert" \
    --ssl-key="$ssl_key" \
    --fqdn="$fqdn" \
    --additional-config-file="$DOVECOT_CONFIG_FILE_ISPCONFIG" \
    ; [ ! $? -eq 0 ] && x

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
# --root-sure
# )
# VALUE=(
# --fqdn
# --certbot-authenticator
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# CSV=(
# )
# EOF
# clear
