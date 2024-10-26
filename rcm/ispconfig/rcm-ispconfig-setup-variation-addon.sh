#!/bin/bash

# Parse arguments. Generated by parse-options.sh
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then domain="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --ip-address=*) ip_address="${1#*=}"; shift ;;
        --ip-address) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then ip_address="$2"; shift; fi; shift ;;
        --non-interactive) non_interactive=1; shift ;;
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
e() { echo -n "$INDENT" >&2; echo "#" "$@" >&2; }
_() { echo -n "$INDENT" >&2; echo -n "#" "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "#" '    ' >&2; [ -n "$1" ] && echo "$@" >&2 || echo -n  >&2; }
____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

# Functions.
printVersion() {
    echo '0.9.3'
}
printHelp() {
    title RCM ISPConfig Setup
    _ 'Variation '; yellow Add On; _, . ; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-setup-variation-addon [options]

Options:
   --domain *
        Domain name of the server.
   --ip-address *
        Set the IP Address. Used to verify A record in DNS. Tips: Try --ip-address=auto.
   --non-interactive ^
        Skip confirmation of --ip-address=auto.

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
   SUBDOMAIN_ISPCONFIG
        Default to cp
   SUBDOMAIN_PHPMYADMIN
        Default to db
   SUBDOMAIN_ROUNDCUBE
        Default to mail
   MAILBOX_ADMIN
        Default to admin
   MAILBOX_SUPPORT
        Default to support
   MAILBOX_WEB
        Default to webmaster
   MAILBOX_HOST
        Default to hostmaster
   MAILBOX_POST
        Default to postmaster
   ISPCONFIG_FQDN_LOCALHOST
        Default to ispconfig.localhost

Dependency:
   rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php:`printVersion`
   rcm-ispconfig-wrapper-certbot-deploy-nginx:`printVersion`
   rcm-ispconfig-control-manage-domain:`printVersion`
   rcm-ispconfig-control-manage-email-mailbox:`printVersion`
   rcm-ispconfig-control-manage-email-alias:`printVersion`
   rcm-ispconfig-setup-dump-variables:`printVersion`
   rcm-dig-is-name-exists
   rcm-dig-is-record-exists

Download:
   [rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php.sh)
   [rcm-ispconfig-control-manage-domain](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-domain.sh)
   [rcm-ispconfig-control-manage-email-mailbox](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-email-mailbox.sh)
   [rcm-ispconfig-control-manage-email-alias](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-email-alias.sh)
   [rcm-ispconfig-setup-dump-variables](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-dump-variables.sh)
   [rcm-ispconfig-wrapper-certbot-deploy-nginx](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-wrapper-certbot-deploy-nginx.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { echo -e "\e[91m""Unable to proceed, "'`'"${line}"'`'" command not found." "\e[39m"; exit 1; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Functions.
backupFile() {
    local mode="$1"
    local oldpath="$2" i newpath
    i=1
    newpath="${oldpath}.${i}"
    if [ -f "$newpath" ]; then
        let i++
        newpath="${oldpath}.${i}"
        while [ -f "$newpath" ] ; do
            let i++
            newpath="${oldpath}.${i}"
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
userInputBooleanDefaultNo() {
    __;  _, '['; yellow Enter; _, ']'; _, ' '; yellow N; _, 'o and skip.'; _.
    __;  _, '['; yellow Y; _, ']'; _, ' '; yellow Y; _, 'es and continue.'; _.
    boolean=
    while true; do
        __; read -rsn 1 -p "Select: " char
        if [ -z "$char" ];then
            char=n
        fi
        case $char in
            y|Y) echo "$char"; boolean=1; break;;
            n|N) echo "$char"; break ;;
            *) echo
        esac
    done
}
sleepExtended() {
    local countdown=$1
    countdown=$((countdown - 1))
    while [ "$countdown" -ge 0 ]; do
        printf "\r\033[K" >&2
        printf %"$countdown"s | tr " " "." >&2
        printf "\r"
        countdown=$((countdown - 1))
        sleep .9
    done
}
isFileExists() {
    # global used:
    # global modified: found, notfound
    # function used: __
    found=
    notfound=
    if [ -f "$1" ];then
        __ File '`'$(basename "$1")'`' ditemukan.
        found=1
    else
        __ File '`'$(basename "$1")'`' tidak ditemukan.
        notfound=1
    fi
}

# Title.
title rcm-ispconfig-setup-variation-addon
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

# Require, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
ISPCONFIG_FQDN_LOCALHOST=${ISPCONFIG_FQDN_LOCALHOST:=ispconfig.localhost}
code 'ISPCONFIG_FQDN_LOCALHOST="'$ISPCONFIG_FQDN_LOCALHOST'"'
SUBDOMAIN_ISPCONFIG=${SUBDOMAIN_ISPCONFIG:=cp}
code 'SUBDOMAIN_ISPCONFIG="'$SUBDOMAIN_ISPCONFIG'"'
SUBDOMAIN_PHPMYADMIN=${SUBDOMAIN_PHPMYADMIN:=db}
code 'SUBDOMAIN_PHPMYADMIN="'$SUBDOMAIN_PHPMYADMIN'"'
SUBDOMAIN_ROUNDCUBE=${SUBDOMAIN_ROUNDCUBE:=mail}
code 'SUBDOMAIN_ROUNDCUBE="'$SUBDOMAIN_ROUNDCUBE'"'
MAILBOX_ADMIN=${MAILBOX_ADMIN:=admin}
code 'MAILBOX_ADMIN="'$MAILBOX_ADMIN'"'
MAILBOX_SUPPORT=${MAILBOX_SUPPORT:=support}
code 'MAILBOX_SUPPORT="'$MAILBOX_SUPPORT'"'
MAILBOX_WEB=${MAILBOX_WEB:=webmaster}
code 'MAILBOX_WEB="'$MAILBOX_WEB'"'
MAILBOX_HOST=${MAILBOX_HOST:=hostmaster}
code 'MAILBOX_HOST="'$MAILBOX_HOST'"'
MAILBOX_POST=${MAILBOX_POST:=postmaster}
code 'MAILBOX_POST="'$MAILBOX_POST'"'
if [ -z "$domain" ];then
    error "Argument --domain required."; x
fi
code 'domain="'$domain'"'
if [ -z "$ip_address" ];then
    e Tips: Try --ip-address=auto
fi
if [[ $ip_address == auto ]];then
    ip_address=
    _ip_address=$(wget -T 3 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/")
    if [ -n "$_ip_address" ];then
        if [ -n "$non_interactive" ];then
            boolean=1
        else
            __; _, Do you wish to use this IP Address: "$_ip_address"?; _.
            userInputBooleanDefaultNo
        fi
        if [ -n "$boolean" ]; then
            ip_address="$_ip_address"
        fi
    fi
fi
if [ -z "$ip_address" ];then
    error "Argument --ip-address required."; x
fi
code ip_address="$ip_address"
____

chapter Mengecek ISPConfig User.
php_fpm_user=ispconfig
code id -u '"'$php_fpm_user'"'
if id "$php_fpm_user" >/dev/null 2>&1; then
    __ User '`'$php_fpm_user'`' found.
else
    error ISPConfig belum terinstall.; x
fi
____

chapter Mengecek FQDN '(Fully-Qualified Domain Name)'
current_fqdn=$(hostname -f 2>/dev/null)
code current_fqdn='"'$current_fqdn'"'
____

INDENT+="    " \
rcm-dig-is-name-exists $isfast --root-sure \
    --domain="$domain" \
    && INDENT+="    " \
rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
    --domain="$domain" \
    --type=a \
    --ip-address="$ip_address" \
    --hostname=@ \
    && INDENT+="    " \
rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
    --reverse \
    --domain="$domain" \
    --type=a \
    --ip-address="$ip_address" \
    --hostname="$SUBDOMAIN_ISPCONFIG" \
    && INDENT+="    " \
rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
    --domain="$domain" \
    --type=cname \
    --hostname="$SUBDOMAIN_ISPCONFIG" \
    && INDENT+="    " \
rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
    --reverse \
    --domain="$domain" \
    --type=a \
    --ip-address="$ip_address" \
    --hostname="$SUBDOMAIN_PHPMYADMIN" \
    && INDENT+="    " \
rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
    --domain="$domain" \
    --type=cname \
    --hostname="$SUBDOMAIN_PHPMYADMIN" \
    && INDENT+="    " \
rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
    --reverse \
    --domain="$domain" \
    --type=a \
    --ip-address="$ip_address" \
    --hostname="$SUBDOMAIN_ROUNDCUBE" \
    && INDENT+="    " \
rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
    --domain="$domain" \
    --type=cname \
    --hostname="$SUBDOMAIN_ROUNDCUBE" \
    && INDENT+="    " \
rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
    --domain="$domain" \
    --type=mx \
    --hostname=@ \
    --mail-provider="$current_fqdn" \
    ; [ ! $? -eq 0 ] && x

chapter Prepare arguments.
prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
root="$prefix/interface/web"
code root="$root"
____

chapter Mencari informasi PHP-FPM Version yang digunakan oleh ISPConfig.
__ Membuat file "${root}/.well-known/__getversion.php"
mkdir -p "${root}/.well-known"
cat << 'EOF' > "${root}/.well-known/__getversion.php"
<?php
echo PHP_VERSION;
EOF
__ Eksekusi file script.
__; magenta curl http://127.0.0.1/.well-known/__getversion.php -H '"'"Host: ${ISPCONFIG_FQDN_LOCALHOST}"'"'; _.
php_version=$(curl -Ss http://127.0.0.1/.well-known/__getversion.php -H "Host: ${ISPCONFIG_FQDN_LOCALHOST}")
__; magenta php_version="$php_version"; _.
if [ -z "$php_version" ];then
    error PHP-FPM version tidak ditemukan; x
fi
__ Menghapus file "${root}/.well-known/__getversion.php"
rm "${root}/.well-known/__getversion.php"
rmdir "${root}/.well-known" --ignore-fail-on-non-empty
____

chapter Perbaikan variable '`'php_version'`'.
__; magenta php_version="$php_version"; _.
major=$(sed -E 's,^([0-9]+)\.([0-9]+)\.([0-9]+)$,\1,' <<< "$php_version")
minor=$(sed -E 's,^([0-9]+)\.([0-9]+)\.([0-9]+)$,\2,' <<< "$php_version")
php_version="${major}.${minor}"
__; magenta php_version="$php_version"; _.
____

INDENT+="    " \
rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast --root-sure \
    --project=ispconfig \
    --subdomain="$SUBDOMAIN_ISPCONFIG" \
    --domain="$domain" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast --root-sure \
    --project=roundcube \
    --subdomain="$SUBDOMAIN_ROUNDCUBE" \
    --domain="$domain" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast --root-sure \
    --project=phpmyadmin \
    --subdomain="$SUBDOMAIN_PHPMYADMIN" \
    --domain="$domain" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast --root-sure \
    --project=ispconfig \
    --subdomain="${SUBDOMAIN_ISPCONFIG}.${domain}" \
    --domain="localhost" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast --root-sure \
    --project=roundcube \
    --subdomain="${SUBDOMAIN_ROUNDCUBE}.${domain}" \
    --domain="localhost" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast --root-sure \
    --project=phpmyadmin \
    --subdomain="${SUBDOMAIN_PHPMYADMIN}.${domain}" \
    --domain="localhost" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-ispconfig-wrapper-certbot-deploy-nginx $isfast --root-sure \
    --domain="${SUBDOMAIN_ISPCONFIG}.${domain}" \
    --domain="${SUBDOMAIN_PHPMYADMIN}.${domain}" \
    --domain="${SUBDOMAIN_ROUNDCUBE}.${domain}" \
    ; [ ! $? -eq 0 ] && x

chapter Take a break.
e Lets play with Mailbox.
sleepExtended 3
____

INDENT+="    " \
rcm-ispconfig-control-manage-domain $isfast --root-sure \
    add \
    --domain="$domain" \
    && INDENT+="    " \
rcm-ispconfig-control-manage-email-mailbox $isfast --root-sure --ispconfig-domain-exists-sure \
    --ispconfig-soap-exists-sure \
    --name="$MAILBOX_ADMIN" \
    --domain="$domain" \
    && INDENT+="    " \
rcm-ispconfig-control-manage-email-mailbox $isfast --root-sure --ispconfig-domain-exists-sure \
    --ispconfig-soap-exists-sure \
    --name="$MAILBOX_SUPPORT" \
    --domain="$domain" \
    && INDENT+="    " \
rcm-ispconfig-control-manage-email-alias $isfast --root-sure --ispconfig-domain-exists-sure \
    --ispconfig-soap-exists-sure \
    --name="$MAILBOX_HOST" \
    --domain="$domain" \
    --destination-name="$MAILBOX_ADMIN" \
    --destination-domain="$domain" \
    && INDENT+="    " \
rcm-ispconfig-control-manage-email-alias $isfast --root-sure --ispconfig-domain-exists-sure \
    --ispconfig-soap-exists-sure \
    --name="$MAILBOX_POST" \
    --domain="$domain" \
    --destination-name="$MAILBOX_ADMIN" \
    --destination-domain="$domain" \
    && INDENT+="    " \
rcm-ispconfig-control-manage-email-alias $isfast --root-sure --ispconfig-domain-exists-sure \
    --ispconfig-soap-exists-sure \
    --name="$MAILBOX_WEB" \
    --domain="$domain" \
    --destination-name="$MAILBOX_ADMIN" \
    --destination-domain="$domain" \
    ; [ ! $? -eq 0 ] && x

chapter Take a break.
e Everything is OK, "let's" dump variables.
sleepExtended 3
____

INDENT+="    " \
rcm-ispconfig-setup-dump-variables $isfast --root-sure \
    --domain="$domain" \
    --ip-address="$ip_address" \
    ; [ ! $? -eq 0 ] && x

chapter Send Welcome email.
code postqueue -f
sleepExtended 3
postqueue -f
____

chapter Finish
e If you want to see the credentials again, please execute this command:
code rcm-ispconfig-setup-dump-variables${isfast} --domain="$domain" --ip-address="$ip_address"
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
# --root-sure
# --non-interactive
# )
# VALUE=(
# --domain
# --ip-address
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# CSV=(
# )
# EOF
# clear
