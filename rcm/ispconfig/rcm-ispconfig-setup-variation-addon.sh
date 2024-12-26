#!/bin/bash

# Parse arguments. Generated by parse-options.sh
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then domain="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --ip-address=*) ip_address="${1#*=}"; shift ;;
        --ip-address) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then ip_address="$2"; shift; fi; shift ;;
        --non-interactive) non_interactive=1; shift ;;
        --root-sure) root_sure=1; shift ;;
        --url-ispconfig=*) url_ispconfig="${1#*=}"; shift ;;
        --url-ispconfig) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_ispconfig="$2"; shift; fi; shift ;;
        --url-phpmyadmin=*) url_phpmyadmin="${1#*=}"; shift ;;
        --url-phpmyadmin) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_phpmyadmin="$2"; shift; fi; shift ;;
        --url-roundcube=*) url_roundcube="${1#*=}"; shift ;;
        --url-roundcube) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_roundcube="$2"; shift; fi; shift ;;
        --with-ispconfig=*) install_ispconfig="${1#*=}"; shift ;;
        --with-ispconfig) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then install_ispconfig="$2"; shift; else install_ispconfig=1; fi; shift ;;
        --without-ispconfig=*) install_ispconfig="${1#*=}"; shift ;;
        --without-ispconfig) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then install_ispconfig="$2"; shift; else install_ispconfig=0; fi; shift ;;
        --without-phpmyadmin=*) install_phpmyadmin="${1#*=}"; shift ;;
        --without-phpmyadmin) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then install_phpmyadmin="$2"; shift; else install_phpmyadmin=0; fi; shift ;;
        --with-phpmyadmin=*) install_phpmyadmin="${1#*=}"; shift ;;
        --with-phpmyadmin) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then install_phpmyadmin="$2"; shift; else install_phpmyadmin=1; fi; shift ;;
        --without-roundcube=*) install_roundcube="${1#*=}"; shift ;;
        --without-roundcube) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then install_roundcube="$2"; shift; else install_roundcube=0; fi; shift ;;
        --with-roundcube=*) install_roundcube="${1#*=}"; shift ;;
        --with-roundcube) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then install_roundcube="$2"; shift; else install_roundcube=1; fi; shift ;;
        --[^-]*) shift ;;
        *) _new_arguments+=("$1"); shift ;;
    esac
done
set -- "${_new_arguments[@]}"
unset _new_arguments

# Command.
if [ -n "$1" ];then
    case "$1" in
        suggest-url|get-ipv4) command="$1"; shift ;;
    esac
fi

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
___() { echo -n "$INDENT" >&2; echo -n "#" '        ' >&2; [ -n "$1" ] && echo "$@" >&2 || echo -n  >&2; }
____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

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
    echo '0.9.10'
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
        Set the IP Address. Used to verify A record in DNS.
        Value available from command: rcm-ispconfig-setup-variation-addon(get-ipv4).
   --with-ispconfig ^
        Add ISPConfig public domain.
   --url-ispconfig *
        The value can be domain or URL.
        For example: \`cp.example.org\` or \`https://example.org:8080/\`.
        Value available from command: rcm-ispconfig-setup-variation-addon(suggest-url ispconfig [--with-ispconfig] [--domain]), or other.
   --with-phpmyadmin ^
        Add PHPMyAdmin public domain.
   --url-phpmyadmin *
        The value can be domain or URL.
        For example: \`db.example.org\` or \`https://example.org:8081/phpmyadmin/\`.
        Value available from command: rcm-ispconfig-setup-variation-addon(suggest-url phpmyadmin [--with-phpmyadmin] [--url-ispconfig] [--domain]), or other.
   --with-roundcube ^
        Add Roundcube public domain.
   --url-roundcube *
        The value can be domain or URL.
        For example: \`mail.example.org\` or \`https://example.org:8081/roundcube/\`.
        Value available from command: rcm-ispconfig-setup-variation-addon(suggest-url roundcube [--with-roundcube] [--url-ispconfig] [--domain]), or other.

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
   rcm-ispconfig-control-manage-domain:`printVersion`
   rcm-ispconfig-control-manage-email-mailbox:`printVersion`
   rcm-ispconfig-control-manage-email-alias:`printVersion`
   rcm-ispconfig-setup-dump-variables-addon:`printVersion`
   rcm-ispconfig-setup-internal-command:`printVersion`
   rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root:`printVersion`
   rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php:`printVersion`
   rcm-dig-is-name-exists
   rcm-dig-is-record-exists
   rcm-dig-watch-domain-exists
   rcm-dig-has-address

Download:
   [rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php.sh)
   [rcm-ispconfig-control-manage-domain](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-domain.sh)
   [rcm-ispconfig-control-manage-email-mailbox](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-email-mailbox.sh)
   [rcm-ispconfig-control-manage-email-alias](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-email-alias.sh)
   [rcm-ispconfig-setup-dump-variables-addon](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-dump-variables-addon.sh)
   [rcm-ispconfig-setup-internal-command](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-internal-command.sh)
   [rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php.sh)
   [rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root.sh)
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
    local PHP_URL_SCHEME PHP_URL_USER PHP_URL_PASS PHP_URL_HOST PHP_URL_PORT PHP_URL_PATH
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
    local url=$1 port=$2 path=$3
    local PHP_URL_SCHEME PHP_URL_USER PHP_URL_PASS PHP_URL_HOST PHP_URL_PORT PHP_URL_PATH
    local scheme
    Rcm_parse_url $url
    if [ "$port" == - ];then
        port="$PHP_URL_PORT"
    fi
    [ -z "$port" ] && port=8080
    [ -n "$PHP_URL_SCHEME" ] && scheme="$PHP_URL_SCHEME" || scheme=https
    local hostname=$(echo "$PHP_URL_HOST" | sed -E 's|^([^\.]+)\..*|\1|g')
    local domain=$(echo "$PHP_URL_HOST" | cut -d. -f2-)
    if [ "$hostname" == "$SUBDOMAIN_ISPCONFIG" ];then
        echo "${scheme}://${domain}:${port}${path}"
    else
        echo "${scheme}://${PHP_URL_HOST}:${port}${path}"
    fi
}
command-suggest-url() {
    local PHP_URL_SCHEME PHP_URL_USER PHP_URL_PASS PHP_URL_HOST PHP_URL_PORT PHP_URL_PATH
    local which=$1
    case "$which" in
        ispconfig)
            local with_ispconfig=$2 domain=$3
            [ $with_ispconfig == 0 ] && with_ispconfig=
            [ $domain == - ] && domain=
            # Set to skip, return exit code non zero.
            [ -z "$with_ispconfig" ] && exit 1
            _; _.
            ___; yellow Attention; _, . ISPConfig cannot install inside subpath.; _.
            Rcm_parse_url $domain
            siblingHost "$domain" $SUBDOMAIN_ISPCONFIG
            urlAlternative "$domain"
            ;;
        phpmyadmin)
            local with_phpmyadmin=$2 url_ispconfig=$3 domain=$4
            [ $with_phpmyadmin == 0 ] && with_phpmyadmin=
            [ $url_ispconfig == - ] && url_ispconfig=
            [ -z "$url_ispconfig" ] && url_ispconfig="$domain"
            # Set to skip, return exit code non zero.
            [ -z "$with_phpmyadmin" ] && exit 1
            siblingHost "$url_ispconfig" $SUBDOMAIN_PHPMYADMIN
            urlAlternative "$url_ispconfig" 8081 /phpmyadmin
            urlAlternative "$url_ispconfig" 8081 /$SUBDOMAIN_PHPMYADMIN
            echo "${domain}/phpmyadmin"
            echo "${domain}/${SUBDOMAIN_PHPMYADMIN}"
            ;;
        roundcube)
            local with_roundcube=$2 url_ispconfig=$3 domain=$4
            [ $with_roundcube == 0 ] && with_roundcube=
            [ $url_ispconfig == - ] && url_ispconfig=
            [ -z "$url_ispconfig" ] && url_ispconfig="$domain"
            # Set to skip, return exit code non zero.
            [ -z "$with_roundcube" ] && exit 1
            siblingHost "$url_ispconfig" $SUBDOMAIN_ROUNDCUBE
            urlAlternative "$url_ispconfig" 8081 /roundcube
            urlAlternative "$url_ispconfig" 8081 /$SUBDOMAIN_ROUNDCUBE
            echo "${domain}/roundcube"
            echo "${domain}/${SUBDOMAIN_ROUNDCUBE}"
            ;;
    esac
}
command-get-ipv4() {
    _ip=`wget -T 3 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/"`
    if [ -n "$_ip" ];then
        echo "$_ip"
    else
        ip addr show | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*"
    fi
}

# Execute command.
if [[ -n "$command" && $(type -t "command-${command}") == function ]];then
    command-${command} "$@"
    exit 0
fi

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

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'$line'`'.; x; }
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
ISPCONFIG_FQDN_LOCALHOST=${ISPCONFIG_FQDN_LOCALHOST:=ispconfig.localhost}
code 'ISPCONFIG_FQDN_LOCALHOST="'$ISPCONFIG_FQDN_LOCALHOST'"'
ROUNDCUBE_FQDN_LOCALHOST=${ROUNDCUBE_FQDN_LOCALHOST:=roundcube.localhost}
code 'ROUNDCUBE_FQDN_LOCALHOST="'$ROUNDCUBE_FQDN_LOCALHOST'"'
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
    error "Argument --ip-address required."; x
fi
code 'ip_address="'$ip_address'"'
code ip_address="$ip_address"
if ! grep -q -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$ip_address";then
    error IP Address version 4 format is not valid; x
fi
if [ "$install_ispconfig" == 1 ];then
    Rcm_parse_url "$url_ispconfig"
    if [ -z "$PHP_URL_HOST" ];then
        error Argument --url-ispconfig is not valid: '`'"$url_ispconfig"'`'.; x
    elif [ -n "$PHP_URL_PATH" ];then
        error Argument --url-ispconfig is cannot have subpath: '`'"$url_ispconfig"'`'.; x
    else
        [ -n "$PHP_URL_SCHEME" ] && scheme="$PHP_URL_SCHEME" || scheme=https
        [ -n "$PHP_URL_PORT" ] && port="$PHP_URL_PORT" || port=443
        [ -n "$PHP_URL_PATH" ] && fqdn_path_array_raw+=("$PHP_URL_HOST")
        ispconfig_url_scheme="$scheme"
        ispconfig_url_host="$PHP_URL_HOST"
        ispconfig_url_port="$port"
        ispconfig_url_path="$PHP_URL_PATH"
        fqdn_array_raw+=("$PHP_URL_HOST")
        # Modify variable url_ispconfig.
        [ -n "$PHP_URL_SCHEME" ] || url_ispconfig="${scheme}://${url_ispconfig}"
        code url_ispconfig="$url_ispconfig"
    fi
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
        # Modify variable url_phpmyadmin.
        [ -n "$PHP_URL_SCHEME" ] || url_phpmyadmin="${scheme}://${url_phpmyadmin}"
        code url_phpmyadmin="$url_phpmyadmin"
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
        # Modify variable url_roundcube.
        [ -n "$PHP_URL_SCHEME" ] || url_roundcube="${scheme}://${url_roundcube}"
        code url_roundcube="$url_roundcube"
    fi
fi
ArrayUnique fqdn_array_raw[@]
fqdn_array=("${_return[@]}")
unset _return
ArrayUnique fqdn_path_array_raw[@]
fqdn_path_array=("${_return[@]}")
unset _return
code 'fqdn_array=('"${fqdn_array[@]}"')'
code 'fqdn_path_array=('"${fqdn_path_array[@]}"')'
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

chapter Take a break.
_ Begin to Validate DNS Record.; _.
sleepExtended 3
____

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

chapter Take a break.
_ Lets play with Certbot LetsEncrypt with Nginx Plugin.; _.
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
            rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root $isfast --root-sure \
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
_ Lets play with Mailbox.; _.
sleepExtended 3
____

INDENT+="    " \
rcm-ispconfig-setup-internal-command $isfast --root-sure \
    && INDENT+="    " \
rcm-ispconfig-control-manage-domain $isfast --root-sure \
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
command -v run-getmail.sh >/dev/null && {
    code run-getmail.sh
    run-getmail.sh
}
____

chapter Take a break.
_ Everything is OK, "let's" dump variables.; _.
sleepExtended 3
____

php=$(cat <<'EOF'
$mode = $_SERVER['argv'][1];
switch ($mode) {
    case 'is_different':
    case 'save':
        # Populate variable $is_different.
        $file = $_SERVER['argv'][2];
        $reference = unserialize($_SERVER['argv'][3]);
        include($file);
        $config = isset($config) ? $config : [];
        $is_different = !empty(array_diff_assoc(array_map('serialize',$reference), array_map('serialize',$config)));
        break;
}
switch ($mode) {
    case 'is_different':
        $is_different ? exit(0) : exit(1);
        break;
    case 'save':
        if (!$is_different) {
            exit(0);
        }
        $contents = file_get_contents($file);
        $need_edit = array_diff_assoc($reference, $config);
        $new_lines = [];
        foreach ($need_edit as $key => $value) {
            $new_line = "__PARAMETER__[__KEY__] = __VALUE__; # managed by RCM";
            // Jika indexed array dan hanya satu , maka buat one line.
            if (is_array($value) && array_key_exists(0, $value) && count($value) === 1) {
                $new_line = str_replace(['__PARAMETER__','__KEY__','__VALUE__'],['$config', var_export($key, true), "['".$value[0]."']"], $new_line);
            }
            else {
                $new_line = str_replace(['__PARAMETER__','__KEY__','__VALUE__'],['$config', var_export($key, true), var_export($value, true)], $new_line);
            }
            $is_one_line = preg_match('/\n/', $new_line) ? false : true;
            $find_existing = "__PARAMETER__[__KEY__] = __VALUE__; # managed by RCM";
            $find_existing = str_replace(['__PARAMETER__','__KEY__'],['$config', var_export($key, true)], $find_existing);
            $find_existing = preg_quote($find_existing);
            $find_existing = str_replace('__VALUE__', '.*', $find_existing);
            $find_existing = '/\s*'.$find_existing.'/';
            if ($is_one_line && preg_match_all($find_existing, $contents, $matches, PREG_PATTERN_ORDER)) {
                $contents = str_replace($matches[0], '', $contents);
            }
            $new_lines[] = $new_line;
        }
        if (substr($contents, -1) != "\n") {
            $contents .= "\n";
        }
        $contents .= implode("\n", $new_lines);
        $contents .= "\n";
        file_put_contents($file, $contents);
        break;
}
EOF
)

if [ -n "$roundcube_url_host" ];then
    chapter Roundcube Virtual Host.
    code 'url_roundcube="'$url_roundcube'"'
    code 'roundcube_url_host="'$roundcube_url_host'"'
    ____

    chapter Prepare arguments.
    nginx_user=
    conf_nginx=`command -v nginx > /dev/null && command -v nginx > /dev/null && nginx -V 2>&1 | grep -o -P -- '--conf-path=\K(\S+)'`
    if [ -f "$conf_nginx" ];then
        nginx_user=`grep -o -P '^user\s+\K([^;]+)' "$conf_nginx"`
    fi
    code 'nginx_user="'$nginx_user'"'
    if [ -z "$nginx_user" ];then
        error "Variable \$nginx_user failed to populate."; x
    fi
    nginx_user_home=$(getent passwd "$nginx_user" | cut -d: -f6 )
    php_fpm_user="$nginx_user"
    code 'php_fpm_user="'$php_fpm_user'"'
    prefix="$nginx_user_home"

    project_container="$ROUNDCUBE_FQDN_LOCALHOST"
    code 'project_container="'$project_container'"'
    root="$prefix/${project_container}/web"
    root_source=$(realpath "$root")
    if [ $(basename "$root_source") == "public_html" ];then
        root_source=$(dirname "$root_source")
    else
        error "Direktori public_html tidak ditemukan"; x
    fi
    php_project_name=www
    code 'php_project_name="'$php_project_name'"'
    code root="$root"
    code root_source="$root_source"
    ____

    # https://github.com/roundcube/roundcubemail/blob/master/config/defaults.inc.php
    # https://github.com/roundcube/roundcubemail/wiki/Configuration:-Multi-Domain-Setup
    chapter Mengecek file konfigurasi RoundCube.
    filename="${roundcube_url_host}.inc.php"
    path="${root_source}/config/${roundcube_url_host}.inc.php"
    isFileExists "$path"
    ____

    if [ -n "$notfound" ];then
        chapter Membuat RoundCube config file: '`'$filename'`'.
        code sudo -u '"'$php_fpm_user'"' touch '"'$path'"'
        sudo -u "$php_fpm_user" touch "$path"
        cat <<'EOF' > "$path"
<?php

// Website: __URL_ROUNDCUBE__
$config['username_domain'] = '__DOMAIN__'; # managed by RCM
EOF
        fileMustExists "$path"
        sed -i "s|__URL_ROUNDCUBE__|${url_roundcube}|g" "$path"
        sed -i "s|__DOMAIN__|${domain}|g" "$path"
        ____
    fi
    reference="$(php -r "echo serialize([
        'username_domain' => '${domain}',
    ]);")"
    is_different=
    if php -r "$php" is_different "$path" "$reference";then
        is_different=1
        __ Diperlukan modifikasi file '`'$filename'`'.
    else
        __ File '`'$filename'`' tidak ada perubahan.
    fi
    ____

    if [ -n "$is_different" ];then
        chapter Memodifikasi file '`'$filename'`'.
        __ Backup file "$path"
        backupFile copy "$path"
        php -r "$php" save "$path" "$reference"
        if php -r "$php" is_different "$path" "$reference";then
            __; red Modifikasi file '`'$filename'`' gagal.; x
        else
            __; green Modifikasi file '`'$filename'`' berhasil.; _.
        fi
        ____
    fi
fi

chapter Saving URL information.
code mkdir -p /usr/local/share/ispconfig/domain/$domain
mkdir -p /usr/local/share/ispconfig/domain/$domain
cat << EOF > /usr/local/share/ispconfig/domain/$domain/website
URL_ISPCONFIG=$url_ispconfig
EOF
fileMustExists /usr/local/share/ispconfig/domain/$domain/website
if [ "$install_phpmyadmin" == 1 ];then
    code mkdir -p /usr/local/share/phpmyadmin/domain/$domain/
    mkdir -p /usr/local/share/phpmyadmin/domain/$domain/
    cat << EOF > /usr/local/share/phpmyadmin/domain/$domain/website
URL_PHPMYADMIN=$url_phpmyadmin
EOF
    fileMustExists /usr/local/share/phpmyadmin/domain/$domain/website
fi
if [ "$install_roundcube" == 1 ];then
    code mkdir -p /usr/local/share/roundcube/domain/$domain/
    mkdir -p /usr/local/share/roundcube/domain/$domain/
    cat << EOF > /usr/local/share/roundcube/domain/$domain/website
URL_ROUNDCUBE=$url_roundcube
EOF
    fileMustExists /usr/local/share/roundcube/domain/$domain/website
fi
____

INDENT+="    " \
rcm-ispconfig-setup-dump-variables-addon $isfast --root-sure \
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
# --domain
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
    # 'long:--with-ispconfig,parameter:install_ispconfig,type:flag_value'
    # 'long:--without-ispconfig,parameter:install_ispconfig,type:flag_value,flag_option:reverse'
    # 'long:--with-phpmyadmin,parameter:install_phpmyadmin,type:flag_value'
    # 'long:--without-phpmyadmin,parameter:install_phpmyadmin,type:flag_value,flag_option:reverse'
    # 'long:--with-roundcube,parameter:install_roundcube,type:flag_value'
    # 'long:--without-roundcube,parameter:install_roundcube,type:flag_value,flag_option:reverse'
# )
# EOF
# clear
