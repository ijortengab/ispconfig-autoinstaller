#!/bin/bash

# Parse arguments. Generated by parse-options.sh
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --digitalocean-token=*) digitalocean_token="${1#*=}"; shift ;;
        --digitalocean-token) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then digitalocean_token="$2"; shift; fi; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then domain="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --hostname=*) hostname="${1#*=}"; shift ;;
        --hostname) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then hostname="$2"; shift; fi; shift ;;
        --ip-address=*) ip_address="${1#*=}"; shift ;;
        --ip-address) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then ip_address="$2"; shift; fi; shift ;;
        --non-interactive) non_interactive=1; shift ;;
        --timezone=*) timezone="${1#*=}"; shift ;;
        --timezone) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then timezone="$2"; shift; fi; shift ;;
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
e() { echo -n "$INDENT" >&2; echo -n "$@" >&2; }
_() { echo -n "$INDENT" >&2; echo -n "#"' ' >&2; [ -n "$1" ] && echo -n "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "#" '    ' >&2; [ -n "$1" ] && echo "$@" >&2; }
____() { echo >&2; [ -n "$RCM_DELAY" ] && sleep "$RCM_DELAY"; }

# Define variables and constants.
RCM_DELAY=${RCM_DELAY:=.5}; [ -n "$fast" ] && unset RCM_DELAY
SUBDOMAIN_ISPCONFIG=${SUBDOMAIN_ISPCONFIG:=cp}
SUBDOMAIN_PHPMYADMIN=${SUBDOMAIN_PHPMYADMIN:=db}
SUBDOMAIN_ROUNDCUBE=${SUBDOMAIN_ROUNDCUBE:=mail}
MAILBOX_ADMIN=${MAILBOX_ADMIN:=admin}
MAILBOX_SUPPORT=${MAILBOX_SUPPORT:=support}
MAILBOX_WEB=${MAILBOX_WEB:=webmaster}
MAILBOX_HOST=${MAILBOX_HOST:=hostmaster}
MAILBOX_POST=${MAILBOX_POST:=postmaster}

# Functions.
printVersion() {
    echo '0.9.12'
}
printHelp() {
    title RCM ISPConfig Setup
    _ 'Variation '; yellow 3; _, . Debian 12, ISPConfig 3.2.10, PHPMyAdmin 5.2.1, Roundcube 1.6.2, PHP 8.1, DigitalOcean DNS.; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-setup-variation-3 [options]

Options:
   --domain *
        Domain name of the server.
   --hostname *
        Hostname of the server.
   --ip-address *
        Set the IP Address. Use with A record while registered. Tips: Try --ip-address=auto.
   --digitalocean-token *
        Token access from digitalocean.com to consume DigitalOcean API.
   --non-interactive ^
        Skip confirmation of --ip-address=auto.
   --timezone
        Set the timezone of this machine.
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

Environment Variables:
   SUBDOMAIN_ISPCONFIG
        Default to $SUBDOMAIN_ISPCONFIG
   SUBDOMAIN_PHPMYADMIN
        Default to $SUBDOMAIN_PHPMYADMIN
   SUBDOMAIN_ROUNDCUBE
        Default to $SUBDOMAIN_ROUNDCUBE
   MAILBOX_ADMIN
        Default to $MAILBOX_ADMIN
   MAILBOX_SUPPORT
        Default to $MAILBOX_SUPPORT
   MAILBOX_WEB
        Default to $MAILBOX_WEB
   MAILBOX_HOST
        Default to $MAILBOX_HOST
   MAILBOX_POST
        Default to $MAILBOX_POST

Dependency:
   wget
   rcm-debian-12-setup-basic
   rcm-mariadb-autoinstaller
   rcm-nginx-autoinstaller
   rcm-php-autoinstaller
   rcm-php-setup-adjust-cli-version
   rcm-postfix-autoinstaller
   rcm-certbot-autoinstaller
   rcm-certbot-digitalocean-autoinstaller
   rcm-digitalocean-api-manage-domain
   rcm-digitalocean-api-manage-domain-record
   rcm-ispconfig-autoinstaller-nginx:`printVersion`
   rcm-ispconfig-setup-internal-command:`printVersion`
   rcm-roundcube-setup-ispconfig-integration:`printVersion`
   rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php:`printVersion`
   rcm-certbot-deploy-installer-nginx-authenticator-digitalocean
   rcm-ispconfig-control-manage-domain:`printVersion`
   rcm-ispconfig-control-manage-email-mailbox:`printVersion`
   rcm-ispconfig-control-manage-email-alias:`printVersion`
   rcm-ispconfig-setup-wrapper-digitalocean:`printVersion`
   rcm-ispconfig-setup-dump-variables:`printVersion`
   rcm-ispconfig-setup-remote-user-root:`printVersion`

Download:
   [rcm-ispconfig-autoinstaller-nginx](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-autoinstaller-nginx.sh)
   [rcm-ispconfig-setup-internal-command](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-internal-command.sh)
   [rcm-roundcube-setup-ispconfig-integration](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/roundcube/rcm-roundcube-setup-ispconfig-integration.sh)
   [rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php.sh)
   [rcm-ispconfig-control-manage-domain](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-domain.sh)
   [rcm-ispconfig-control-manage-email-mailbox](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-email-mailbox.sh)
   [rcm-ispconfig-control-manage-email-alias](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-email-alias.sh)
   [rcm-ispconfig-setup-wrapper-digitalocean](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-wrapper-digitalocean.sh)
   [rcm-ispconfig-setup-dump-variables](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-dump-variables.sh)
   [rcm-ispconfig-setup-remote-user-root](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-remote-user-root.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-setup-variation-3
____

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

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
    local width=$2
    if [ -z "$width" ];then
        width=80
    fi
    if [ "$countdown" -gt 0 ];then
        dikali10=$((countdown*10))
        _dikali10=$dikali10
        _dotLength=$(( ( width * _dikali10 ) / dikali10 ))
        printf "\r\033[K" >&2
        e; printf %"$_dotLength"s | tr " " "." >&2
        printf "\r"
        while [ "$_dikali10" -ge 0 ]; do
            dotLength=$(( ( width * _dikali10 ) / dikali10 ))
            if [[ ! "$dotLength" == "$_dotLength" ]];then
                _dotLength="$dotLength"
                printf "\r\033[K" >&2
                e; printf %"$dotLength"s | tr " " "." >&2
                printf "\r"
            fi
            _dikali10=$((_dikali10 - 1))
            sleep .1
        done
    fi
}

# Require, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
[ "$update_system" == 0 ] && update_system=
[ "$upgrade_system" == 0 ] && upgrade_system=
[ -z "$update_system" ] && is_without_update_system=' --without-update-system' || is_without_update_system=''
[ -z "$upgrade_system" ] && is_without_upgrade_system=' --without-upgrade-system' || is_without_upgrade_system=''
code 'SUBDOMAIN_ISPCONFIG="'$SUBDOMAIN_ISPCONFIG'"'
code 'SUBDOMAIN_PHPMYADMIN="'$SUBDOMAIN_PHPMYADMIN'"'
code 'SUBDOMAIN_ROUNDCUBE="'$SUBDOMAIN_ROUNDCUBE'"'
code 'MAILBOX_ADMIN="'$MAILBOX_ADMIN'"'
code 'MAILBOX_SUPPORT="'$MAILBOX_SUPPORT'"'
code 'MAILBOX_WEB="'$MAILBOX_WEB'"'
code 'MAILBOX_HOST="'$MAILBOX_HOST'"'
code 'MAILBOX_POST="'$MAILBOX_POST'"'
code 'timezone="'$timezone'"'
if [ -z "$digitalocean_token" ];then
    error "Argument --digitalocean-token required."; x
fi
code 'digitalocean_token="'$digitalocean_token'"'
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
php_version=8.1
code php_version="$php_version"
phpmyadmin_version=5.2.1
code phpmyadmin_version="$phpmyadmin_version"
roundcube_version=1.6.2
code roundcube_version="$roundcube_version"
ispconfig_version=3.2.10
code ispconfig_version="$ispconfig_version"
until [[ -n "$ip_address" ]];do
    _ Tips: Try --ip-address=auto; _.
    _; read -p "Argument --ip-address required: " ip_address
done
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

chapter Menyimpan DigitalOcean Token sebagai file text.
if [ -f $HOME/.digitalocean-token.txt ];then
    _token=$(<$HOME/.digitalocean-token.txt)
    if [[ ! "$_token" == "$digitalocean_token" ]];then
        __ Backup file $HOME/.digitalocean-token.txt
        backupFile move $HOME/.digitalocean-token.txt
        echo "$digitalocean_token" > $HOME/.digitalocean-token.txt
    fi
else
    echo "$digitalocean_token" > $HOME/.digitalocean-token.txt
fi
fileMustExists $HOME/.digitalocean-token.txt
____

INDENT+="    " \
rcm-debian-12-setup-basic $isfast \
    --timezone="$timezone" \
    $is_without_update_system \
    $is_without_upgrade_system \
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

chapter Mengecek Name Server domain '`'$domain'`'
code dig NS $domain +trace
stdout=$(dig NS $domain +trace)
found=
if grep -q --ignore-case 'ns.\.digitalocean\.com\.' <<< "$stdout";then
    found=1
fi
if [ -n "$found" ];then
    code dig NS $domain +short
    stdout=$(dig NS $domain +short)
    if [ -n "$stdout" ];then
        _ "$stdout"; _.
    fi
    if grep -q --ignore-case 'ns.\.digitalocean\.com\.' <<< "$stdout";then
        __ Name Server pada domain "$domain" sudah mengarah ke DigitalOcean.
    else
        __ Name Server pada domain "$domain" belum mengarah ke DigitalOcean.
    fi
else
    error Name Server pada domain "$domain" tidak mengarah ke DigitalOcean.
    _ Memerlukan manual edit pada registrar domain.; x; _.
fi
# Contoh:
# nsid2.rumahweb.net.
# nsid4.rumahweb.org.
# nsid3.rumahweb.biz.
# nsid1.rumahweb.com.
# ns3.digitalocean.com.
# ns1.digitalocean.com.
# ns2.digitalocean.com.
____

INDENT+="    " \
rcm-mariadb-autoinstaller $isfast \
    && INDENT+="    " \
rcm-nginx-autoinstaller $isfast \
    && INDENT+="    " \
rcm-php-autoinstaller $isfast \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-php-setup-adjust-cli-version $isfast \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-postfix-autoinstaller $isfast \
    --fqdn="$fqdn" \
    && INDENT+="    " \
rcm-certbot-autoinstaller $isfast \
    && INDENT+="    " \
rcm-certbot-digitalocean-autoinstaller $isfast \
    ; [ ! $? -eq 0 ] && x

chapter Take a break.
_ Lets play with DigitalOcean API.; _.
sleepExtended 3
____

INDENT+="    " \
rcm-digitalocean-api-manage-domain $isfast \
    add \
    --domain="$domain" \
    --ip-address="$ip_address" \
    && INDENT+="    " \
rcm-digitalocean-api-manage-domain-record $isfast --digitalocean-domain-exists-sure \
    add \
    --domain="$domain" \
    --type=a \
    --ip-address="$ip_address" \
    --hostname=@ \
    && INDENT+="    " \
rcm-digitalocean-api-manage-domain-record $isfast --digitalocean-domain-exists-sure \
    delete \
    --domain="$domain" \
    --type=cname \
    --hostname="$hostname" \
    && INDENT+="    " \
rcm-digitalocean-api-manage-domain-record $isfast --digitalocean-domain-exists-sure \
    add \
    --domain="$domain" \
    --type=a \
    --ip-address="$ip_address" \
    --hostname="$hostname" \
    && INDENT+="    " \
rcm-digitalocean-api-manage-domain-record $isfast --digitalocean-domain-exists-sure \
    delete \
    --domain="$domain" \
    --type=a \
    --ip-address="$ip_address" \
    --hostname="$SUBDOMAIN_ISPCONFIG" \
    && INDENT+="    " \
rcm-digitalocean-api-manage-domain-record $isfast --digitalocean-domain-exists-sure \
    add \
    --domain="$domain" \
    --type=cname \
    --hostname="$SUBDOMAIN_ISPCONFIG" \
    && INDENT+="    " \
rcm-digitalocean-api-manage-domain-record $isfast --digitalocean-domain-exists-sure \
    delete \
    --domain="$domain" \
    --type=a \
    --ip-address="$ip_address" \
    --hostname="$SUBDOMAIN_PHPMYADMIN" \
    && INDENT+="    " \
rcm-digitalocean-api-manage-domain-record $isfast --digitalocean-domain-exists-sure \
    add \
    --domain="$domain" \
    --type=cname \
    --hostname="$SUBDOMAIN_PHPMYADMIN" \
    && INDENT+="    " \
rcm-digitalocean-api-manage-domain-record $isfast --digitalocean-domain-exists-sure \
    delete \
    --domain="$domain" \
    --type=a \
    --ip-address="$ip_address" \
    --hostname="$SUBDOMAIN_ROUNDCUBE" \
    && INDENT+="    " \
rcm-digitalocean-api-manage-domain-record $isfast --digitalocean-domain-exists-sure \
    add \
    --domain="$domain" \
    --type=cname \
    --hostname="$SUBDOMAIN_ROUNDCUBE" \
    && INDENT+="    " \
rcm-digitalocean-api-manage-domain-record $isfast --digitalocean-domain-exists-sure \
    add \
    --domain="$domain" \
    --type=mx \
    --hostname=@ \
    --mail-provider="$fqdn" \
    ; [ ! $? -eq 0 ] && x

chapter Take a break.
_ Begin to Install ISPConfig and Friends.; _.
sleepExtended 3
____

INDENT+="    " \
rcm-ispconfig-autoinstaller-nginx $isfast \
    --certbot-authenticator=digitalocean \
    --hostname="$hostname" \
    --domain="$domain" \
    --ispconfig-version="$ispconfig_version" \
    --roundcube-version="$roundcube_version" \
    --phpmyadmin-version="$phpmyadmin_version" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-ispconfig-setup-remote-user-root $isfast \
    && INDENT+="    " \
rcm-ispconfig-setup-internal-command $isfast \
    && INDENT+="    " \
rcm-roundcube-setup-ispconfig-integration $isfast \
    ; [ ! $? -eq 0 ] && x

chapter Take a break.
_ Lets play with Certbot LetsEncrypt with Nginx Plugin.; _.
sleepExtended 3
____

INDENT+="    " \
rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast \
    --project=ispconfig \
    --subdomain="$SUBDOMAIN_ISPCONFIG" \
    --domain="$domain" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast \
    --project=roundcube \
    --subdomain="$SUBDOMAIN_ROUNDCUBE" \
    --domain="$domain" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast \
    --project=phpmyadmin \
    --subdomain="$SUBDOMAIN_PHPMYADMIN" \
    --domain="$domain" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast \
    --project=ispconfig \
    --subdomain="${SUBDOMAIN_ISPCONFIG}.${domain}" \
    --domain="localhost" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast \
    --project=roundcube \
    --subdomain="${SUBDOMAIN_ROUNDCUBE}.${domain}" \
    --domain="localhost" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast \
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
rcm-certbot-deploy-installer-nginx-authenticator-digitalocean $isfast \
    --certbot-dns-digitalocean-sure \
    --domain="${SUBDOMAIN_ISPCONFIG}.${domain}" \
    --domain="${SUBDOMAIN_PHPMYADMIN}.${domain}" \
    --domain="${SUBDOMAIN_ROUNDCUBE}.${domain}" \
    ; [ ! $? -eq 0 ] && x

chapter Take a break.
_ Lets play with Mailbox.; _.
sleepExtended 3
____

INDENT+="    " \
rcm-ispconfig-control-manage-domain $isfast \
    add \
    --domain="$domain" \
    && INDENT+="    " \
rcm-ispconfig-control-manage-email-mailbox $isfast --ispconfig-domain-exists-sure \
    --ispconfig-soap-exists-sure \
    --name="$MAILBOX_ADMIN" \
    --domain="$domain" \
    && INDENT+="    " \
rcm-ispconfig-control-manage-email-mailbox $isfast --ispconfig-domain-exists-sure \
    --ispconfig-soap-exists-sure \
    --name="$MAILBOX_SUPPORT" \
    --domain="$domain" \
    && INDENT+="    " \
rcm-ispconfig-control-manage-email-alias $isfast --ispconfig-domain-exists-sure \
    --ispconfig-soap-exists-sure \
    --name="$MAILBOX_HOST" \
    --domain="$domain" \
    --destination-name="$MAILBOX_ADMIN" \
    --destination-domain="$domain" \
    && INDENT+="    " \
rcm-ispconfig-control-manage-email-alias $isfast --ispconfig-domain-exists-sure \
    --ispconfig-soap-exists-sure \
    --name="$MAILBOX_POST" \
    --domain="$domain" \
    --destination-name="$MAILBOX_ADMIN" \
    --destination-domain="$domain" \
    && INDENT+="    " \
rcm-ispconfig-control-manage-email-alias $isfast --ispconfig-domain-exists-sure \
    --ispconfig-soap-exists-sure \
    --name="$MAILBOX_WEB" \
    --domain="$domain" \
    --destination-name="$MAILBOX_ADMIN" \
    --destination-domain="$domain" \
    && INDENT+="    " \
rcm-ispconfig-setup-wrapper-digitalocean $isfast --digitalocean-domain-exists-sure \
    --ip-address="$ip_address" \
    --domain="$domain" \
    --type=spf \
    --hostname=@ \
    --mail-provider="$fqdn" \
    && INDENT+="    " \
rcm-ispconfig-setup-wrapper-digitalocean $isfast --digitalocean-domain-exists-sure --ispconfig-domain-exists-sure \
    --ip-address="$ip_address" \
    --domain="$domain" \
    --type=dmarc \
    --email="${MAILBOX_POST}@${domain}" \
    && INDENT+="    " \
rcm-ispconfig-setup-wrapper-digitalocean $isfast --digitalocean-domain-exists-sure --ispconfig-domain-exists-sure \
    --ip-address="$ip_address" \
    --domain="$domain" \
    --type=dkim  \
    --dns-record-auto \
    ; [ ! $? -eq 0 ] && x

chapter Send Welcome email.
code postqueue -f
postqueue -f
____

chapter Take a break.
_ Everything is OK, "let's" dump variables.; _.
sleepExtended 3
____

INDENT+="    " \
rcm-ispconfig-setup-dump-variables $isfast \
    --additional-info=digitalocean \
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
# --non-interactive
# )
# VALUE=(
# --timezone
# --hostname
# --domain
# --ip-address
# --digitalocean-token
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
