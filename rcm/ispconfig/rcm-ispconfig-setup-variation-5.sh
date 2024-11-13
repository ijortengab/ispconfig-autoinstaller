#!/bin/bash

# Parse arguments. Generated by parse-options.sh
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --fast) fast=1; shift ;;
        --fqdn=*) fqdn="${1#*=}"; shift ;;
        --fqdn) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then fqdn="$2"; shift; fi; shift ;;
        --ip-address=*) ip_address="${1#*=}"; shift ;;
        --ip-address) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then ip_address="$2"; shift; fi; shift ;;
        --root-sure) root_sure=1; shift ;;
        --timezone=*) timezone="${1#*=}"; shift ;;
        --timezone) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then timezone="$2"; shift; fi; shift ;;
        --url-ispconfig=*) url_ispconfig="${1#*=}"; shift ;;
        --url-ispconfig) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_ispconfig="$2"; shift; fi; shift ;;
        --url-phpmyadmin=*) url_phpmyadmin="${1#*=}"; shift ;;
        --url-phpmyadmin) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_phpmyadmin="$2"; shift; fi; shift ;;
        --url-roundcube=*) url_roundcube="${1#*=}"; shift ;;
        --url-roundcube) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_roundcube="$2"; shift; fi; shift ;;
        --with-phpmyadmin=*) install_phpmyadmin="${1#*=}"; shift ;;
        --with-phpmyadmin) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then install_phpmyadmin="$2"; shift; else install_phpmyadmin=1; fi; shift ;;
        --without-phpmyadmin=*) install_phpmyadmin="${1#*=}"; shift ;;
        --without-phpmyadmin) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then install_phpmyadmin="$2"; shift; else install_phpmyadmin=0; fi; shift ;;
        --with-roundcube=*) install_roundcube="${1#*=}"; shift ;;
        --with-roundcube) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then install_roundcube="$2"; shift; else install_roundcube=1; fi; shift ;;
        --without-roundcube=*) install_roundcube="${1#*=}"; shift ;;
        --without-roundcube) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then install_roundcube="$2"; shift; else install_roundcube=0; fi; shift ;;
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

# Command.
command="$1"; shift
if [ -n "$command" ];then
    case "$command" in
        suggest-url|get-ipv4) ;;
        *)
            # Bring back command as argument position.
            set -- "$command" "$@"
            # Reset command.
            command=
    esac
fi

# Define variables.
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
   --fqdn *
        Fully Qualified Domain Name of this server, for example: \`server1.example.org\`.
   --ip-address *
        Set the IP Address. Used to verify A record in DNS.
        Value available from command: rcm-ispconfig-setup-variation-5(get-ipv4).
   --url-ispconfig *
        The address to set up ISPConfig, for example: \`cp.example.org\` or \`https://example.org:8080/ispconfig/\`.
        Value available from command: rcm-ispconfig-setup-variation-5(suggest-url ispconfig [--fqdn]), or other.
   --with-phpmyadmin ^
        Enable PHPMyAdmin. By default, --without-phpmyadmin is used.
   --url-phpmyadmin *
        The address to set up PHPMyAdmin, for example: \`db.example.org\` or \`https://example.org:8080/phpmyadmin/\`.
        Value available from command: rcm-ispconfig-setup-variation-5(suggest-url phpmyadmin [--with-phpmyadmin] [--url-ispconfig]), or other.
   --with-roundcube ^
        Enable Roundcube. By default, --without-roundcube is used.
   --url-roundcube *
        The address to set up Roundcube, for example: \`mail.example.org\` or \`https://example.org:8080/roundcube/\`.
        Value available from command: rcm-ispconfig-setup-variation-5(suggest-url roundcube [--with-roundcube] [--url-ispconfig]), or other.
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
   rcm-dig-autoinstaller
   rcm-dig-has-address
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
   [rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-mulitple-root](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-mulitple-root.sh)
   [rcm-ispconfig-control-manage-domain](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-domain.sh)
   [rcm-ispconfig-control-manage-email-mailbox](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-email-mailbox.sh)
   [rcm-ispconfig-control-manage-email-alias](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-email-alias.sh)
   [rcm-ispconfig-setup-dump-variables](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-dump-variables.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Functions.
Rcm_parse_url() {
    # Reset
    PHP_URL_SCHEME=
    PHP_URL_HOST=
    PHP_URL_PORT=
    PHP_URL_USER=
    PHP_URL_PASS=
    PHP_URL_PATH=
    PHP_URL_QUERY=
    PHP_URL_FRAGMENT=
    PHP_URL_SCHEME="$(echo "$1" | grep :// | sed -e's,^\(.*\)://.*,\1,g')"
    _PHP_URL_SCHEME_SLASH="${PHP_URL_SCHEME}://"
    _PHP_URL_SCHEME_REVERSE="$(echo ${1/${_PHP_URL_SCHEME_SLASH}/})"
    if grep -q '#' <<< "$_PHP_URL_SCHEME_REVERSE";then
        PHP_URL_FRAGMENT=$(echo $_PHP_URL_SCHEME_REVERSE | cut -d# -f2)
        _PHP_URL_SCHEME_REVERSE=$(echo $_PHP_URL_SCHEME_REVERSE | cut -d# -f1)
    fi
    if grep -q '\?' <<< "$_PHP_URL_SCHEME_REVERSE";then
        PHP_URL_QUERY=$(echo $_PHP_URL_SCHEME_REVERSE | cut -d? -f2)
        _PHP_URL_SCHEME_REVERSE=$(echo $_PHP_URL_SCHEME_REVERSE | cut -d? -f1)
    fi
    _PHP_URL_USER_PASS="$(echo $_PHP_URL_SCHEME_REVERSE | grep @ | cut -d@ -f1)"
    PHP_URL_PASS=`echo $_PHP_URL_USER_PASS | grep : | cut -d: -f2`
    if [ -n "$PHP_URL_PASS" ]; then
        PHP_URL_USER=`echo $_PHP_URL_USER_PASS | grep : | cut -d: -f1`
    else
        PHP_URL_USER=$_PHP_URL_USER_PASS
    fi
    _PHP_URL_HOST_PORT="$(echo ${_PHP_URL_SCHEME_REVERSE/$_PHP_URL_USER_PASS@/} | cut -d/ -f1)"
    PHP_URL_HOST="$(echo $_PHP_URL_HOST_PORT | sed -e 's,:.*,,g')"
    if grep -q -E ':[0-9]+$' <<< "$_PHP_URL_HOST_PORT";then
        PHP_URL_PORT="$(echo $_PHP_URL_HOST_PORT | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
    fi
    _PHP_URL_HOST_PORT_LENGTH=${#_PHP_URL_HOST_PORT}
    _LENGTH="$_PHP_URL_HOST_PORT_LENGTH"
    if [ -n "$_PHP_URL_USER_PASS" ];then
        _PHP_URL_USER_PASS_LENGTH=${#_PHP_URL_USER_PASS}
        _LENGTH=$((_LENGTH + 1 + _PHP_URL_USER_PASS_LENGTH))
    fi
    PHP_URL_PATH="${_PHP_URL_SCHEME_REVERSE:$_LENGTH}"

    # Debug
    # e '"$PHP_URL_SCHEME"' "$PHP_URL_SCHEME"
    # e '"$PHP_URL_HOST"' "$PHP_URL_HOST"
    # e '"$PHP_URL_PORT"' "$PHP_URL_PORT"
    # e '"$PHP_URL_USER"' "$PHP_URL_USER"
    # e '"$PHP_URL_PASS"' "$PHP_URL_PASS"
    # e '"$PHP_URL_PATH"' "$PHP_URL_PATH"
    # e '"$PHP_URL_QUERY"' "$PHP_URL_QUERY"
    # e '"$PHP_URL_FRAGMENT"' "$PHP_URL_FRAGMENT"
}
siblingHost() {
    local url=$1 subdomain=$2
    Rcm_parse_url $url
    local hostname=$(echo "$PHP_URL_HOST" | sed -E 's|^([^\.]+)\..*|\1|g')
    local domain=$(echo "$PHP_URL_HOST" | cut -d. -f2-)
    if [ "$hostname" == "$SUBDOMAIN_ISPCONFIG" ];then
        echo "${subdomain}.${domain}"
    else
        echo "${subdomain}.${PHP_URL_HOST}"
    fi
}
urlAlternative() {
    local url=$1 path=$2
    local scheme port
    Rcm_parse_url $url
    [ -n "$PHP_URL_SCHEME" ] && scheme="$PHP_URL_SCHEME" || scheme=https
    [ -n "$PHP_URL_PORT" ] && port="$PHP_URL_PORT" || port=8080
    local hostname=$(echo "$PHP_URL_HOST" | sed -E 's|^([^\.]+)\..*|\1|g')
    local domain=$(echo "$PHP_URL_HOST" | cut -d. -f2-)
    if [ "$hostname" == "$SUBDOMAIN_ISPCONFIG" ];then
        echo "${scheme}://${domain}:${port}${path}"
    else
        echo "${scheme}://${PHP_URL_HOST}:${port}${path}"
    fi
}
suggest-url() {
    local which=$1
    case "$which" in
        ispconfig)
            e
            __; yellow Attention; _, . ISPConfig cannot install inside subpath.; _.
            local fqdn=$2
            Rcm_parse_url $fqdn
            local domain=$(echo "$PHP_URL_HOST" | cut -d. -f2-)
            siblingHost "$domain" $SUBDOMAIN_ISPCONFIG
            urlAlternative "$domain"
            ;;
        phpmyadmin)
            local with_phpmyadmin=$2 url_ispconfig=$3
            [ $with_phpmyadmin == 0 ] && with_phpmyadmin=
            [ $url_ispconfig == - ] && url_ispconfig=
            # Set to skip, return exit code non zero.
            [ -z "$with_phpmyadmin" ] && exit 1
            siblingHost "$url_ispconfig" $SUBDOMAIN_PHPMYADMIN
            urlAlternative "$url_ispconfig" /phpmyadmin
            urlAlternative "$url_ispconfig" /$SUBDOMAIN_PHPMYADMIN
            ;;
        roundcube)
            local with_roundcube=$2 url_ispconfig=$3
            [ $with_roundcube == 0 ] && with_roundcube=
            [ $url_ispconfig == - ] && url_ispconfig=
            # Set to skip, return exit code non zero.
            [ -z "$with_roundcube" ] && exit 1
            siblingHost "$url_ispconfig" $SUBDOMAIN_ROUNDCUBE
            urlAlternative "$url_ispconfig" /roundcube
            urlAlternative "$url_ispconfig" /$SUBDOMAIN_ROUNDCUBE
            ;;
    esac
}
get-ipv4() {
    _ip=`wget -T 3 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/"`
    if [ -n "$_ip" ];then
        echo "$_ip"
    else
        ip addr show | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*"
    fi
}
# Execute command.
if [[ -n "$command" && $(type -t "$command") == function ]];then
    "$command" "$@"
    exit 0
fi

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
ArrayUnique() {
    local e source=("${!1}")
    # inArray is alternative of ArraySearch.
    inArray () {
        local e match="$1"
        shift
        for e; do [[ "$e" == "$match" ]] && return 0; done
        return 1
    }
    _return=()
    for e in "${source[@]}";do
        if ! inArray "$e" "${_return[@]}";then
            _return+=("$e")
        fi
    done
}
ArraySearch() {
    local index match="$1"
    local source=("${!2}")
    for index in "${!source[@]}"; do
       if [[ "${source[$index]}" == "${match}" ]]; then
           _return=$index; return 0
       fi
    done
    return 1
}

# Require, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
[[ "$update_system" == "0" ]] && is_without_update_system=' --without-update-system' || is_without_update_system=''
[[ "$upgrade_system" == "0" ]] && is_without_upgrade_system=' --without-upgrade-system' || is_without_upgrade_system=''
code 'SUBDOMAIN_ISPCONFIG="'$SUBDOMAIN_ISPCONFIG'"'
code 'SUBDOMAIN_PHPMYADMIN="'$SUBDOMAIN_PHPMYADMIN'"'
code 'SUBDOMAIN_ROUNDCUBE="'$SUBDOMAIN_ROUNDCUBE'"'
code 'MAILBOX_ADMIN="'$MAILBOX_ADMIN'"'
code 'MAILBOX_SUPPORT="'$MAILBOX_SUPPORT'"'
code 'MAILBOX_WEB="'$MAILBOX_WEB'"'
code 'MAILBOX_HOST="'$MAILBOX_HOST'"'
code 'MAILBOX_POST="'$MAILBOX_POST'"'
code 'timezone="'$timezone'"'
if [ -z "$fqdn" ];then
    error "Argument --fqdn required."; x
fi
if [ -z "$ip_address" ];then
    error "Argument --ip-address required."; x
fi
if [ -z "$url_ispconfig" ];then
    error "Argument --url-ispconfig required."; x
fi
if [ "$install_phpmyadmin" == 1 ];then
    if [ -z "$url_phpmyadmin" ];then
        error "Argument --url-phpmyadmin required."; x
    fi
fi
if [ "$install_roundcube" == 1 ];then
    if [ -z "$url_roundcube" ];then
        error "Argument --url-roundcube required."; x
    fi
fi
code fqdn="$fqdn"
code url_ispconfig="$url_ispconfig"
code install_phpmyadmin="$install_phpmyadmin"
code url_phpmyadmin="$url_phpmyadmin"
code install_roundcube="$install_roundcube"
code url_roundcube="$url_roundcube"
code update_system="$update_system"
code upgrade_system="$upgrade_system"
Rcm_parse_url "$fqdn"
hostname=$(echo "$PHP_URL_HOST" | sed -E 's|^([^\.]+)\..*|\1|g')
domain=$(echo "$PHP_URL_HOST" | cut -d. -f2-)
code hostname="$hostname"
code domain="$domain"
for each in PHP_URL_SCHEME PHP_URL_PORT PHP_URL_USER PHP_URL_PASS PHP_URL_PATH PHP_URL_QUERY PHP_URL_FRAGMENT; do
    value=${!each}
    if [ -n "$value" ];then
        error Argument --fqdn cannot have component "$each": '`'"$fqdn"'`'.; x
    fi
done
fqdn_array_raw=()
fqdn_path_array_raw=()
Rcm_parse_url "$url_ispconfig"
if [ -z "$PHP_URL_HOST" ];then
    error Argument --url-ispconfig is not valid: '`'"$url_ispconfig"'`'.; x
elif [ -n "$PHP_URL_PATH" ];then
    error Argument --url-ispconfig is cannot have subpath: '`'"$url_ispconfig"'`'.; x
else
    [ -n "$PHP_URL_SCHEME" ] && scheme="$PHP_URL_SCHEME" || scheme=http
    [ -n "$PHP_URL_PORT" ] && port="$PHP_URL_PORT" || port=80
    [ -n "$PHP_URL_PATH" ] && fqdn_path_array_raw+=("$PHP_URL_HOST")
    ispconfig_url_scheme="$scheme"
    ispconfig_url_host="$PHP_URL_HOST"
    ispconfig_url_port="$port"
    ispconfig_url_path="$PHP_URL_PATH"
    fqdn_array_raw+=("$PHP_URL_HOST")
fi
if [ "$install_phpmyadmin" == 1 ];then
    Rcm_parse_url "$url_phpmyadmin"
    if [ -z "$PHP_URL_HOST" ];then
        error Argument --url-phpmyadmin is not valid: '`'"$url_phpmyadmin"'`'.; x
    else
        [ -n "$PHP_URL_SCHEME" ] && scheme="$PHP_URL_SCHEME" || scheme=https
        [ -n "$PHP_URL_PORT" ] && port="$PHP_URL_PORT" || port=443
        [ -n "$PHP_URL_PATH" ] && fqdn_path_array_raw+=("$PHP_URL_HOST")
        phpmyadmin_url_scheme="$scheme"
        phpmyadmin_url_host="$PHP_URL_HOST"
        phpmyadmin_url_port="$port"
        phpmyadmin_url_path="$PHP_URL_PATH"
        fqdn_array_raw+=("$PHP_URL_HOST")

    fi
fi
if [ "$install_roundcube" == 1 ];then
    Rcm_parse_url "$url_roundcube"
    if [ -z "$PHP_URL_HOST" ];then
        error Argument --url-roundcube is not valid: '`'"$url_roundcube"'`'.; x
    else
        [ -n "$PHP_URL_SCHEME" ] && scheme="$PHP_URL_SCHEME" || scheme=https
        [ -n "$PHP_URL_PORT" ] && port="$PHP_URL_PORT" || port=443
        [ -n "$PHP_URL_PATH" ] && fqdn_path_array_raw+=("$PHP_URL_HOST")
        roundcube_url_scheme="$scheme"
        roundcube_url_host="$PHP_URL_HOST"
        roundcube_url_port="$port"
        roundcube_url_path="$PHP_URL_PATH"
        fqdn_array_raw+=("$PHP_URL_HOST")
    fi
fi
ArrayUnique fqdn_array_raw[@]
fqdn_array=("${_return[@]}")
unset _return
ArrayUnique fqdn_path_array_raw[@]
fqdn_path_array=("${_return[@]}")
unset _return
php_version=8.3
code php_version="$php_version"
phpmyadmin_version=5.2.1
code phpmyadmin_version="$phpmyadmin_version"
roundcube_version=1.6.6
code roundcube_version="$roundcube_version"
ispconfig_version=3.2.11p2
code ispconfig_version="$ispconfig_version"
code ip_address="$ip_address"
code 'fqdn_array=('"${fqdn_array[@]}"')'
code 'fqdn_path_array=('"${fqdn_path_array[@]}"')'
____

INDENT+="    " \
rcm-dig-autoinstaller $isfast --root-sure \
    ; [ ! $? -eq 0 ] && x

chapter Take a break.
e Begin to Validate DNS Record.
sleepExtended 3
____

INDENT+="    " \
rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
    --reverse \
    --domain="$fqdn" \
    --type=cname \
    --hostname="@" \
    --hostname-origin="*" \
    && INDENT+="    " \
rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
    --domain="$fqdn" \
    --type=a \
    --ip-address="$ip_address" \
    && INDENT+="    " \
rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
    --domain="$domain" \
    --type=mx \
    --hostname=@ \
    --mail-provider="$fqdn" \
    ; [ ! $? -eq 0 ] && x

for each in "${fqdn_array[@]}";do
    INDENT+="    " \
    rcm-dig-watch-domain-exists $isfast --root-sure \
        --domain="$each" \
        --waiting-time="60" \
        && INDENT+="    " \
    rcm-dig-has-address $isfast --root-sure \
        --fqdn="$each" \
        --ip-address="$ip_address" \
        ; [ ! $? -eq 0 ] && x
done

chapter Take a break.
e Setup LEMP Stack.
sleepExtended 3
____

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
rcm-debian-12-setup-basic $isfast --root-sure \
    --timezone="$timezone" \
    $is_without_update_system \
    $is_without_upgrade_system \
    && INDENT+="    " \
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

for each in ispconfig phpmyadmin roundcube;do
    parameter="${each}_url_scheme"
    url_scheme="${!parameter}"
    if [[ "$url_scheme" == http || "$url_scheme" == https ]];then
        parameter="${each}_url_host"
        url_host="${!parameter}"
        parameter="${each}_url_port"
        url_port="${!parameter}"
        parameter="${each}_url_path"
        url_path="${!parameter}"

        if ArraySearch "$url_host" fqdn_path_array[@];then
            INDENT+="    " \
            rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-mulitple-root $isfast --root-sure \
                --project="$each" \
                --php-version="$php_version" \
                --url-scheme="$url_scheme" \
                --url-host="$url_host" \
                --url-port="$url_port" \
                --url-path="$url_path" \
                ; [ ! $? -eq 0 ] && x
        else
            INDENT+="    " \
            rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast --root-sure \
                --project="$each" \
                --php-version="$php_version" \
                --url-scheme="$url_scheme" \
                --url-host="$url_host" \
                --url-port="$url_port" \
                ; [ ! $? -eq 0 ] && x
        fi
    fi
done

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
# )
# VALUE=(
# --timezone
# --fqdn
# --ip-address
# --url-ispconfig
# --url-phpmyadmin
# --url-roundcube
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# CSV=(
    # 'long:--with-phpmyadmin,parameter:install_phpmyadmin,type:flag_value'
    # 'long:--without-phpmyadmin,parameter:install_phpmyadmin,type:flag_value,flag_option:reverse'
    # 'long:--with-roundcube,parameter:install_roundcube,type:flag_value'
    # 'long:--without-roundcube,parameter:install_roundcube,type:flag_value,flag_option:reverse'
    # 'long:--with-update-system,parameter:update_system'
    # 'long:--without-update-system,parameter:update_system,flag_option:reverse'
    # 'long:--with-upgrade-system,parameter:upgrade_system'
    # 'long:--without-upgrade-system,parameter:upgrade_system,flag_option:reverse'
# )
# EOF
# clear
