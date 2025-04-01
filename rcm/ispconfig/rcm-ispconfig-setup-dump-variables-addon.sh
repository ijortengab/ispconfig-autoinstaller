#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --additional-info=*) additional_info="${1#*=}"; shift ;;
        --additional-info) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then additional_info="$2"; shift; fi; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then domain="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --ip-address=*) ip_address="${1#*=}"; shift ;;
        --ip-address) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then ip_address="$2"; shift; fi; shift ;;
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
SUBDOMAIN_ISPCONFIG=${SUBDOMAIN_ISPCONFIG:=cp}
SUBDOMAIN_PHPMYADMIN=${SUBDOMAIN_PHPMYADMIN:=db}
SUBDOMAIN_ROUNDCUBE=${SUBDOMAIN_ROUNDCUBE:=mail}
MAILBOX_ADMIN=${MAILBOX_ADMIN:=admin}
MAILBOX_SUPPORT=${MAILBOX_SUPPORT:=support}
MAILBOX_POST=${MAILBOX_POST:=postmaster}
MARIADB_PREFIX_MASTER=${MARIADB_PREFIX_MASTER:=/usr/local/share/mariadb}
MARIADB_USERS_CONTAINER_MASTER=${MARIADB_USERS_CONTAINER_MASTER:=users}
DKIM_SELECTOR=${DKIM_SELECTOR:=default}

# Functions.
printVersion() {
    echo '0.9.18'
}
printHelp() {
    title RCM ISPConfig Setup
    _ 'Variation '; yellow Dump Variables; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
rcm-ispconfig-setup-dump-variables-addon [options]

Options:

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
   MAILBOX_POST
        Default to $MAILBOX_POST
   MARIADB_PREFIX_MASTER
        Default to $MARIADB_PREFIX_MASTER
   MARIADB_USERS_CONTAINER_MASTER
        Default to $MARIADB_USERS_CONTAINER_MASTER
   DKIM_SELECTOR
        Default to $DKIM_SELECTOR

Dependency:
   rcm-ispconfig-control-manage-domain:`printVersion`
   php

Download:
   [rcm-ispconfig-control-manage-domain](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-domain.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-setup-dump-variables-addon
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
    # global $username
    # global modified $password
    [ -n "$username" ] || { error Variable username is required; x; }
    local path="/usr/local/share/ispconfig/credential/client/${username}"
    password=$(<"$path")
}

# Require, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
code 'SUBDOMAIN_ISPCONFIG="'$SUBDOMAIN_ISPCONFIG'"'
code 'SUBDOMAIN_PHPMYADMIN="'$SUBDOMAIN_PHPMYADMIN'"'
code 'SUBDOMAIN_ROUNDCUBE="'$SUBDOMAIN_ROUNDCUBE'"'
code 'MAILBOX_ADMIN="'$MAILBOX_ADMIN'"'
code 'MAILBOX_SUPPORT="'$MAILBOX_SUPPORT'"'
code 'MAILBOX_POST="'$MAILBOX_POST'"'
code 'MARIADB_PREFIX_MASTER="'$MARIADB_PREFIX_MASTER'"'
code 'MARIADB_USERS_CONTAINER_MASTER="'$MARIADB_USERS_CONTAINER_MASTER'"'
code 'DKIM_SELECTOR="'$DKIM_SELECTOR'"'
if [ -z "$domain" ];then
    error "Argument --domain required."; x
fi
code 'domain="'$domain'"'
code 'ip_address="'$ip_address'"'
current_fqdn=$(hostname -f 2>/dev/null)
code current_fqdn="$current_fqdn"
code additional_info="$additional_info"
____

if [ -f /usr/local/share/ispconfig/domain/$domain/website ];then
    . /usr/local/share/ispconfig/domain/$domain/website

fi
[ -n "$URL_ISPCONFIG" ] || URL_ISPCONFIG=http://ispconfig.localhost/
if [ -f /usr/local/share/phpmyadmin/domain/$domain/website ];then
    . /usr/local/share/phpmyadmin/domain/$domain/website
fi
[ -n "$URL_PHPMYADMIN" ] || URL_PHPMYADMIN=http://phpmyadmin.localhost/
if [ -f /usr/local/share/roundcube/domain/$domain/website ];then
    . /usr/local/share/roundcube/domain/$domain/website
fi
[ -n "$URL_ROUNDCUBE" ] || URL_ROUNDCUBE=http://roundcube.localhost/

chapter Website available.
_ ' - ISPConfig  :' "$URL_ISPCONFIG"; _.
_ ' - PHPMyAdmin :' "$URL_PHPMYADMIN"; _.
_ ' - Roundcube  :' "$URL_ROUNDCUBE"; _.
____

chapter ISPConfig Credentials.
username="$domain"
websiteCredentialIspconfig
_ ' - 'username: "$username"; _.
_ '   'password: "$password"; _.
____

chapter Roundcube Credentials.
_ ' - 'username: $MAILBOX_ADMIN; _.
if [ -n "$domain" ];then
    user="$MAILBOX_ADMIN"
    host="$domain"
    _ '   'password: $(</usr/local/share/credential/mailbox/$host/$user); _.
else
    _ '   'password: ...; _.
fi
_ ' - 'username: $MAILBOX_SUPPORT; _.
if [ -n "$domain" ];then
    user="$MAILBOX_SUPPORT"
    host="$domain"
    _ '   'password: $(</usr/local/share/credential/mailbox/$host/$user); _.
else
    _ '   'password: ...; _.
fi
____

chapter DNS MX Record for $domain
mail_provider="$current_fqdn"
_ ' - 'hostname:; _.
_ '   'value'   ':' '; magenta "$mail_provider"; _.
____

chapter DNS TXT Record for SPF in $domain
mail_provider="$current_fqdn"
_ ' - 'hostname:; _.
_ '   'value'   ':' '; magenta "v=spf1 a:${mail_provider} ~all"; _.
____

chapter DNS TXT Record for DKIM in $domain
dns_record=$(INDENT+="    " rcm-ispconfig-control-manage-domain --fast --ispconfig-soap-exists-sure --domain="$domain" get-dns-record 2>/dev/null)
_ ' - 'hostname:' '; magenta "${DKIM_SELECTOR}._domainkey"; _.
_ '   'value'   ':' '; magenta "v=DKIM1; t=s; p=${dns_record}"; _.
____

chapter DNS TXT Record for DMARC in $domain
email="${MAILBOX_POST}@${domain}"
_ ' - 'hostname:' '; magenta "_dmarc"; _.
_ '   'value'   ':' '; magenta "v=DMARC1; p=none; rua=${email}"; _.
____

if [ -n "$ip_address" ];then
    tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-setup-dump-variables.XXXXXX)
    dig -x $ip_address +short > "$tempfile"
    output=$(cat "$tempfile" | grep -v ^\; | head -1)
    rm "$tempfile"
    if [[ ! "$output" == "${current_fqdn}." ]];then
        error Attention
        _ Your PTR Record is different with your variable of FQDN.; _.
        _ ' - FQDN : '; magenta "$current_fqdn"; _.
        _ '   PTR  : '; magenta "$output"; _.
        ____
    fi
fi

chapter Manual Action
_ Command to create a new mailbox. Example:; _.
__; magenta soap-ispconfig mail_user_add --email=support@${domain} --password=$(pwgen -1 12); _.
_ Command to implement '`'soap-ispconfig'`' command autocompletion immediately:; _.
__; magenta source /etc/profile.d/soap-ispconfig-completion.sh; _.
if [ -n "$ip_address" ];then
    _ Command to check PTR Record:; _.
    __; magenta dig -x "$ip_address" +short; _.
fi
_ If you want to see the credentials again, please execute this command:; _.
[[ -n "$ip_address" ]] && is_ip_address=' --ip-address='"$ip_address" || is_ip_address=
__; magenta rcm-ispconfig-setup-dump-variables-addon${isfast} --domain="$domain"; _.
_ It is recommended for you to make sure DNS TXT Record about Mail Server '('MX, SPF, DKIM, DMARC')' has exists,; _.
_ '    'please execute this command:; _.
__; magenta rcm${isfast} install ispconfig-post-setup --source ispconfig; _.
__; magenta rcm${isfast} ispconfig-post-setup -- --domain="$domain"; _.
____

if [[ "$additional_info" == digitalocean ]];then
    chapter Suggestion.
    _ If you user of DigitalOcean, change your droplet name with FQDN to automatically set as PTR Record.; _.
    _ More info: https://www.digitalocean.com/community/questions/how-do-i-setup-a-ptr-record; _.
    ____
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
# --domain
# --ip-address
# --additional-info
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# CSV=(
# )
# EOF
# clear
