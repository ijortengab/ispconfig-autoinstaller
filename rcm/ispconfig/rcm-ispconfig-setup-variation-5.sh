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
        --hostname=*) hostname="${1#*=}"; shift ;;
        --hostname) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then hostname="$2"; shift; fi; shift ;;
        --ip-address=*) ip_address="${1#*=}"; shift ;;
        --ip-address) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then ip_address="$2"; shift; fi; shift ;;
        --non-interactive) non_interactive=1; shift ;;
        --root-sure) root_sure=1; shift ;;
        --timezone=*) timezone="${1#*=}"; shift ;;
        --timezone) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then timezone="$2"; shift; fi; shift ;;
        --with-update-system) update_system=1; shift ;;
        --without-update-system) update_system=0; shift ;;
        --with-upgrade-system) upgrade_system=1; shift ;;
        --without-upgrade-system) upgrade_system=0; shift ;;
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
    echo '0.9.4'
}
printHelp() {
    title RCM ISPConfig Setup
    _ 'Variation '; yellow 5; _, . Debian 12, ISPConfig 3.2.11p2, PHPMyAdmin 5.2.1, Roundcube 1.6.6, PHP 8.3, Manual DNS.; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-setup-variation-5 [options]

Options:
   --domain *
        Domain name of the server.
   --hostname *
        Hostname of the server.
   --ip-address *
        Set the IP Address. Used to verify A record in DNS. Available value: auto, or other.
   --non-interactive ^
        Skip confirmation of --ip-address=auto.
   --timezone
        Set the timezone of this machine. Available values: Asia/Jakarta, or other.
   --without-update-system ^
        Skip execute update system. Default to --with-update-system.
   --without-upgrade-system ^
        Skip execute upgrade system. Default to --with-upgrade-system.

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

Dependency:
   wget
   rcm-debian-12-setup-basic
   rcm-mariadb-autoinstaller
   rcm-nginx-autoinstaller
   rcm-php-autoinstaller
   rcm-php-setup-adjust-cli-version
   rcm-postfix-autoinstaller
   rcm-certbot-autoinstaller
   rcm-ispconfig-autoinstaller-nginx:`printVersion`
   rcm-ispconfig-setup-remote-user-root:`printVersion`
   rcm-ispconfig-setup-internal-command:`printVersion`
   rcm-roundcube-setup-ispconfig-integration:`printVersion`
   rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php:`printVersion`
   rcm-ispconfig-control-manage-domain:`printVersion`
   rcm-ispconfig-control-manage-email-mailbox:`printVersion`
   rcm-ispconfig-control-manage-email-alias:`printVersion`
   rcm-ispconfig-setup-dump-variables:`printVersion`

Download:
   [rcm-ispconfig-autoinstaller-nginx](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-autoinstaller-nginx.sh)
   [rcm-ispconfig-setup-remote-user-root](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-remote-user-root.sh)
   [rcm-ispconfig-setup-internal-command](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-internal-command.sh)
   [rcm-roundcube-setup-ispconfig-integration](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/roundcube/rcm-roundcube-setup-ispconfig-integration.sh)
   [rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php.sh)
   [rcm-ispconfig-control-manage-domain](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-domain.sh)
   [rcm-ispconfig-control-manage-email-mailbox](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-email-mailbox.sh)
   [rcm-ispconfig-control-manage-email-alias](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-email-alias.sh)
   [rcm-ispconfig-setup-dump-variables](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-dump-variables.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-setup-variation-5
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

chapter Mengecek ISPConfig User.
php_fpm_user=ispconfig
code id -u '"'$php_fpm_user'"'
if id "$php_fpm_user" >/dev/null 2>&1; then
    __ User '`'$php_fpm_user'`' found.
    error Setup terminated. ISPConfig already installed.; x
else
    __ User '`'$php_fpm_user'`' not found.;
fi
____

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'$line'`'.; x; }
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

# Require, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
[[ "$update_system" == "0" ]] && is_without_update_system=' --without-update-system' || is_without_update_system=''
[[ "$upgrade_system" == "0" ]] && is_without_upgrade_system=' --without-upgrade-system' || is_without_upgrade_system=''
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
code 'timezone="'$timezone'"'
if [ -z "$domain" ];then
    error "Argument --domain required."; x
fi
code 'domain="'$domain'"'
if [ -z "$hostname" ];then
    error "Argument --hostname required."; x
fi
code 'hostname="'$hostname'"'
fqdn="${hostname}.${domain}"
code fqdn="$fqdn"
code non_interactive="$non_interactive"
php_version=8.3
code php_version="$php_version"
phpmyadmin_version=5.2.1
code phpmyadmin_version="$phpmyadmin_version"
roundcube_version=1.6.6
code roundcube_version="$roundcube_version"
ispconfig_version=3.2.11p2
code ispconfig_version="$ispconfig_version"
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
if ! grep -q -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<<  "$ip_address" ;then
    error IP Address version 4 format is not valid; x
fi
____

INDENT+="    " \
rcm-debian-12-setup-basic $isfast --root-sure \
    --timezone="$timezone" \
    $is_without_update_system \
    $is_without_upgrade_system \
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
    --type=cname \
    --hostname="$hostname" \
    && INDENT+="    " \
rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
    --domain="$domain" \
    --type=a \
    --ip-address="$ip_address" \
    --hostname="$hostname" \
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
    --mail-provider="$fqdn" \
    ; [ ! $? -eq 0 ] && x

chapter Mengecek FQDN '(Fully-Qualified Domain Name)'
code fqdn="$fqdn"
current_fqdn=$(hostname -f 2>/dev/null)
adjust=
if [[ "$current_fqdn" == "$fqdn" ]];then
    __ Variable '$fqdn' sama dengan value system hostname saat ini '$(hostname -f)'.
else
    __ Variable '$fqdn' tidak sama dengan value system hostname saat ini '$(hostname -f)'.
    adjust=1
fi
____

if [[ -n "$adjust" ]];then
    chapter Adjust FQDN.
    code hostnamectl set-hostname "${hostname}"
    hostnamectl set-hostname "${hostname}"
    echo "127.0.1.1"$'\t'"${fqdn}"$'\t'"${hostname}" >> /etc/hosts
    sleep .5
    current_fqdn=$(hostname -f 2>/dev/null)
    if [[ "$current_fqdn" == "$fqdn" ]];then
        __; green Variable '$fqdn' sama dengan value system FQDN saat ini '$(hostname -f)'.; _.
    else
        __; red Variable '$fqdn' tidak sama dengan value system hostname saat ini '$(hostname -f)'.; x
    fi
    ____
fi

INDENT+="    " \
rcm-mariadb-autoinstaller $isfast --root-sure \
    && INDENT+="    " \
rcm-nginx-autoinstaller $isfast --root-sure \
    && INDENT+="    " \
rcm-php-autoinstaller $isfast --root-sure \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-php-setup-adjust-cli-version $isfast --root-sure \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-postfix-autoinstaller $isfast --root-sure \
    --hostname="$hostname" \
    --domain="$domain" \
    && INDENT+="    " \
rcm-certbot-autoinstaller $isfast --root-sure \
    ; [ ! $? -eq 0 ] && x

chapter Take a break.
e Begin to Install ISPConfig and Friends.
sleepExtended 3
____

INDENT+="    " \
rcm-ispconfig-autoinstaller-nginx $isfast --root-sure \
    --certbot-authenticator=nginx \
    --hostname="$hostname" \
    --domain="$domain" \
    --ispconfig-version="$ispconfig_version" \
    --roundcube-version="$roundcube_version" \
    --phpmyadmin-version="$phpmyadmin_version" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-ispconfig-setup-remote-user-root $isfast --root-sure \
    && INDENT+="    " \
rcm-ispconfig-setup-internal-command $isfast --root-sure \
    && INDENT+="    " \
rcm-roundcube-setup-ispconfig-integration $isfast --root-sure \
    ; [ ! $? -eq 0 ] && x

chapter Take a break.
e Lets play with Certbot LetsEncrypt with Nginx Plugin.
sleepExtended 3
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
    ; [ ! $? -eq 0 ] && x

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

INDENT+="    " \
PATH=$PATH \
rcm-certbot-deploy-nginx $isfast --root-sure \
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

chapter Send Welcome email.
code postqueue -f
postqueue -f
____

chapter Take a break.
e Everything is OK, "let's" dump variables.
sleepExtended 3
____

INDENT+="    " \
rcm-ispconfig-setup-dump-variables $isfast --root-sure \
    --domain="$domain" \
    --ip-address="$ip_address" \
    ; [ ! $? -eq 0 ] && x

chapter Finish
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
# --timezone
# --hostname
# --domain
# --ip-address
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# CSV=(
    # 'long:--with-update-system,parameter:update_system'
    # 'long:--without-update-system,parameter:update_system,flag_option:reverse'
    # 'long:--with-upgrade-system,parameter:upgrade_system'
    # 'long:--without-upgrade-system,parameter:upgrade_system,flag_option:reverse'
# )
# EOF
# clear
