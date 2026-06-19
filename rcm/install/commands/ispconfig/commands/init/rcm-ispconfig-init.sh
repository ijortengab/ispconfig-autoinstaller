#!/bin/bash

RCM_EXTENSION_VERSION=0.11.0-alpha.4

# Usage Functions.
usage() {
    cat << EOF
Usage: rcm-ispconfig-setup-mode-init [command] [options]

Options:
   --dns-plugin *
        Select how to create the DNS record.
        Values available from command: rcm-plugin(list --interface=dns).
   --tls-plugin
        Select how to obtain TLS Certificate for https protocol.
        if the URL doesn't clearly contain https, it means it's using https.
        if left blank, it means the certificate will not be obtained or set in web server configuration.
        Values available from command: rcm-plugin(list --interface=tls).
   --domain *
        Domain name of the server.
        Together with --hostname will make a Fully Qualified Domain Name (FQDN).
   --hostname *
        Hostname of the server, for example: \`server1\`.
   --url-ispconfig
        Add ISPConfig public domain. The value can be domain or URL and must be part of FQDN.
        ISPConfig automatically has address at http://ispconfig.localhost/.
        Value available from command: rcm-ispconfig-setup-mode-init(helper suggest-url ispconfig [--domain] [--hostname]), or other.
   --url-phpmyadmin
        Add PHPMyAdmin public domain. The value can be domain or URL and must be part of FQDN.
        PHPMyAdmin automatically has address at http://phpmyadmin.localhost/.
        Value available from command: rcm-ispconfig-setup-mode-init(helper suggest-url phpmyadmin [--domain] [--hostname] [--url-ispconfig]), or other.
   --url-roundcube
        Add Roundcube public domain. The value can be domain or URL and must be part of FQDN.
        Roundcube automatically has address at http://roundcube.localhost/.
        Value available from command: rcm-ispconfig-setup-mode-init(helper suggest-url roundcube [--domain] [--hostname] [--url-ispconfig]), or other.
   --os-setup=OS
        Select the variation OS setup. Values available from command: rcm(plugin list ispconfig/os-setup).
   --timezone
        Set the timezone of this machine. Available values: Asia/Gaza, Asia/Ujung_Pandang, Asia/Jakarta, Asia/Makassar, Asia/Pontianak, Asia/Jayapura, or other.

Other Options (For expert only):
   --without-update-system ^
        Skip execute update system. Default to --with-update-system.
   --with-upgrade-system ^
        Execute upgrade system. Default to --without-upgrade-system.

Global Options.
   --version
        Print version of this script.
   --help
        Show this help.

RCM Config:
   --no-timer

Dependency:
   rcm-ispconfig:$RCM_EXTENSION_VERSION
   rcm-ispconfig-autoinstaller-nginx:$RCM_EXTENSION_VERSION
   rcm-roundcube-setup-ispconfig-integration:$RCM_EXTENSION_VERSION
   rcm-amavis-setup-ispconfig:$RCM_EXTENSION_VERSION
   rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php:$RCM_EXTENSION_VERSION
   rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root:$RCM_EXTENSION_VERSION
   rcm-ispconfig-setup-dump-variables-init:$RCM_EXTENSION_VERSION
   rcm-plugin
   rcm-dig-apt
   rcm-dig-has-address
   rcm-nginx-apt
   rcm-mariadb-apt
   rcm-php-apt
   rcm-php-setup-adjust-cli-version
   rcm-postfix-apt

Download:
   [rcm-ispconfig](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/rcm-ispconfig.sh)
   [rcm-ispconfig-autoinstaller-nginx](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-autoinstaller-nginx.sh)
   [rcm-roundcube-setup-ispconfig-integration](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/roundcube/rcm-roundcube-setup-ispconfig-integration.sh)
   [rcm-amavis-setup-ispconfig](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/amavis/rcm-amavis-setup-ispconfig.sh)
   [rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php.sh)
   [rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root.sh)
   [rcm-ispconfig-setup-dump-variables-init](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-dump-variables-init.sh)

Pre Prompt:
   rcm-plugin(init --interface=dns)
   rcm-plugin(init --interface=tls)
   rcm-plugin(add --interface=dns --name=manual --command=rcm-ispconfig --version=$RCM_EXTENSION_VERSION --temporary)
   rcm-plugin(add --interface=tls --name=manual --command=rcm-ispconfig --version=$RCM_EXTENSION_VERSION --temporary)

Post Prompt:
   rcm-plugin(execute --interface=dns --name=[--dns-plugin] --method=prompt)
   rcm-plugin(execute --interface=tls --name=[--tls-plugin] --method=prompt --ignore-fail-on-empty-name)
EOF
}

# Prevent scripts from being executed directly.
[ -f "${RCM_LIB}/require.sh" ] && source "${RCM_LIB}/require.sh" || { usage >&2; exit 1; }

# Parse arguments. Generated by parse-options.sh
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --bypass-validation-is-installed) bypass_validation_is_installed=1; shift ;;
        --dns-plugin=*) dns_plugin="${1#*=}"; shift ;;
        --dns-plugin) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then dns_plugin="$2"; shift; fi; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then domain="$2"; shift; fi; shift ;;
        --hostname=*) hostname="${1#*=}"; shift ;;
        --hostname) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then hostname="$2"; shift; fi; shift ;;
        --os-setup=*) os_setup="${1#*=}"; shift ;;
        --os-setup) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then os_setup="$2"; shift; fi; shift ;;
        --timezone=*) timezone="${1#*=}"; shift ;;
        --timezone) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then timezone="$2"; shift; fi; shift ;;
        --tls-plugin=*) tls_plugin="${1#*=}"; shift ;;
        --tls-plugin) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then tls_plugin="$2"; shift; fi; shift ;;
        --url-ispconfig=*) url_ispconfig="${1#*=}"; shift ;;
        --url-ispconfig) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_ispconfig="$2"; shift; fi; shift ;;
        --url-phpmyadmin=*) url_phpmyadmin="${1#*=}"; shift ;;
        --url-phpmyadmin) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_phpmyadmin="$2"; shift; fi; shift ;;
        --url-roundcube=*) url_roundcube="${1#*=}"; shift ;;
        --url-roundcube) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_roundcube="$2"; shift; fi; shift ;;
        --without-update-system) update_system=0; shift ;;
        --with-update-system) update_system=1; shift ;;
        --without-upgrade-system) upgrade_system=0; shift ;;
        --with-upgrade-system) upgrade_system=1; shift ;;
        --) shift
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    *) _new_arguments+=("$1"); shift ;;
                esac
            done
            ;;
        --[^-]*) shift ;;
        helper)
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    *) _new_arguments+=("$1"); shift ;;
                esac
            done
            ;;
        *) _new_arguments+=("$1"); shift ;;
    esac
done
set -- "${_new_arguments[@]}"
unset _new_arguments

# Command.
if [ -n "$1" ];then
    command=
    case "$1" in
        helper) command="$1"; shift ;;
    esac
    if [ -z "$command" ];then
        error Command unknown: '`'"$1"'`'.; x
    fi
fi

# Define variables and constants.
DKIM_SELECTOR=${DKIM_SELECTOR:=default}
RCM_TLD_SPECIAL=${RCM_TLD_SPECIAL:=example test onion invalid local localhost alt}
SUBDOMAIN_ISPCONFIG=${SUBDOMAIN_ISPCONFIG:=cp}
SUBDOMAIN_PHPMYADMIN=${SUBDOMAIN_PHPMYADMIN:=db}
SUBDOMAIN_ROUNDCUBE=${SUBDOMAIN_ROUNDCUBE:=mail}
[ -n "$fast" ] && isfast=' --fast' || isfast=''

# @todo
# hapus dependency rcm-amavis-setup-ispconfig, karena by plugin.
# rename rcm-ispconfig-setup-dump-variables-init menjadi mode

# Help and Version.
[ -n "$help" ] && { usage; exit 0; }
[ -n "$version" ] && { e $RCM_EXTENSION_VERSION; x; }

# Functions.
ArrayDiff() {
    # Computes the difference of arrays.
    #
    # Globals:
    #   Modified: _return
    #
    # Arguments:
    #   1 = Parameter of the array to compare from.
    #   2 = Parameter of the array to compare against.
    #
    # Returns:
    #   None
    #
    # Example:
    #   ```
    #   my=("cherry" "manggo" "blackberry" "manggo" "blackberry")
    #   yours=("cherry" "blackberry")
    #   ArrayDiff my[@] yours[@]
    #   # Get result in variable `$_return`.
    #   # _return=("manggo" "manggo")
    #   ```
    local e
    local source=("${!1}")
    local reference=("${!2}")
    _return=()
    # inArray is alternative of ArraySearch.
    inArray () {
        local e match="$1"
        shift
        for e; do [[ "$e" == "$match" ]] && return 0; done
        return 1
    }
    if [[ "${#reference[@]}" -gt 0 ]];then
        for e in "${source[@]}";do
            if ! inArray "$e" "${reference[@]}";then
                _return+=("$e")
            fi
        done
    else
        _return=("${source[@]}")
    fi
}
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
urlAlternative() {
    [[ $(type -t Rcm_parse_url) == function ]] || { error Function Rcm_parse_url not found.; x; }
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
command-helper() {
    local helper=$1; shift
    if [ "$helper" == do-nothing ];then
        return
    fi
    if [ -n "$helper" ];then
        if [[ $(type -t "helper-${helper}") == function ]];then
            helper-${helper} "$@"
            exit 0
        else
            error Helper unknown: '`'"$helper"'`'.; x
        fi
    fi
}
helper-suggest-url() {
    [[ $(type -t ArrayDiff) == function ]] || { error Function ArrayDiff not found.; x; }
    [[ $(type -t urlAlternative) == function ]] || { error Function urlAlternative not found.; x; }
    local PHP_URL_SCHEME PHP_URL_USER PHP_URL_PASS PHP_URL_HOST PHP_URL_PORT PHP_URL_PATH
    local which=$1
    case "$which" in
        ispconfig)
            _; _.
            ___; yellow Attention; _, . ISPConfig cannot install inside subpath.; _.
            local fqdn=$3.$2
            urlAlternative "$fqdn" 8080
            urlAlternative "$fqdn" 8081
            urlAlternative "$fqdn" 8443
            ;;
        phpmyadmin)
            local fqdn=$3.$2 url_ispconfig=$4
            [ $url_ispconfig == - ] && url_ispconfig=
            # Set to skip, return exit code non zero.
            local array=()
            for each in 8080 8081 8443; do
                array+=($(urlAlternative "$fqdn" "$each"))
                array+=($(urlAlternative "$fqdn" "$each" /phpmyadmin))
                array+=($(urlAlternative "$fqdn" "$each" "/${SUBDOMAIN_PHPMYADMIN}"))
            done
            if [ -n "$url_ispconfig" ];then
                local _array=("$url_ispconfig")
                ArrayDiff array[@] _array[@]
                array=("${_return[@]}")
            fi
            for each in "${array[@]}"; do
                echo "$each"
            done
            ;;
        roundcube)
            local fqdn=$3.$2 url_ispconfig=$4
            [ $url_ispconfig == - ] && url_ispconfig=
            # Set to skip, return exit code non zero.
            local array=()
            for each in 8080 8081 8443; do
                array+=($(urlAlternative "$fqdn" "$each"))
                array+=($(urlAlternative "$fqdn" "$each" /roundcube))
                array+=($(urlAlternative "$fqdn" "$each" "/${SUBDOMAIN_ROUNDCUBE}"))
            done
            if [ -n "$url_ispconfig" ];then
                local _array=("$url_ispconfig")
                ArrayDiff array[@] _array[@]
                array=("${_return[@]}")
            fi
            for each in "${array[@]}"; do
                echo "$each"
            done
    esac
}

# Execute command.
if [ -n "$command" ];then
    if [[ $(type -t "command-${command}") == function ]];then
        command-${command} "$@"
        exit 0
    else
        error Command unknown: '`'"$command"'`'.; x
    fi
fi

# ------------------------------------------------------------------------------

# Title.
title rcm-ispconfig-setup-mode-init
____

# Dependency.

# Source: ISPConfigDebianOS::runPerfectSetup()
if [ -z "$bypass_validation_is_installed" ];then
    chapter Mengecek existing ISPConfig.
    path=/usr/local/ispconfig/server/lib/config.inc.php
    code 'path="'$path'"'
    if [ -f "$path" ]; then
        __ File '`'$path'`' found.
        error The server already has ISPConfig installed. Aborting.; x
    else
        __ File '`'$path'`' not found.;
        __ Installation is continue.
    fi
    ____
fi

# Functions.
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
urlCompleteComponent() {
    local tld_special _url_port _tld _url_path_correct
    [[ $(type -t Rcm_parse_url) == function ]] || { error Function Rcm_parse_url not found.; x; }
    [[ $(type -t ArraySearch) == function ]] || { error Function ArraySearch not found.; x; }
    [[ -n "$url" ]] || { error Global variable url is not found or empty value.; x; }
    [[ -n "$RCM_TLD_SPECIAL" ]] || { error Global variable RCM_TLD_SPECIAL is not found or empty value.; x; }
    Rcm_parse_url "$url"
    if [ -z "$PHP_URL_HOST" ];then
        error Argument --url is not valid: '`'"$url"'`'.; x
    fi
    [ -n "$PHP_URL_SCHEME" ] && url_scheme="$PHP_URL_SCHEME" || url_scheme=https
    if [ -z "$PHP_URL_PORT" ];then
        case "$url_scheme" in
            http) url_port=80;;
            https) url_port=443;;
        esac
    else
        url_port="$PHP_URL_PORT"
    fi
    url_host="$PHP_URL_HOST"
    url_path="$PHP_URL_PATH"
    url_path_clean=
    url_path_clean_trailing=
    if [[ "$url_path" == '/' ]];then
        url_path=
    fi
    if [ -n "$url_path" ];then
        # Trim leading and trailing slash.
        url_path_clean=$(echo "$url_path" | sed -E 's|(^/+\|/+$)||g')
        url_path_clean_trailing=$(echo "$url_path" | sed -E 's|/+$||g')
        # Must leading with slash.
        # Karena akan digunakan pada nginx configuration.
        _url_path_correct="/${url_path_clean}"
        if [ ! "$url_path_clean_trailing" == "$_url_path_correct" ];then
            error "Argument --url-path not valid."; x
        fi
    fi
    _tld="${url_host##*.}"
    # Explode by space.
    read -ra tld_special -d '' <<< "$RCM_TLD_SPECIAL"
    is_tld_special=
    if ArraySearch "$_tld" tld_special[@];then
        # Paksa menjadi http.
        url_scheme=http
        if [ -z "$PHP_URL_PORT" ];then
            url_port=80
        fi
        is_tld_special=1
    fi
    _url_port=
    if [ -n "$url_port" ];then
        if [[ "$url_scheme" == https && "$url_port" == 443 ]];then
            _url_port=
        elif [[ "$url_scheme" == http && "$url_port" == 80 ]];then
            _url_port=
        else
            _url_port=":${url_port}"
        fi
    fi
    # Modify variable url, auto add scheme.
    # Modify variable url, auto trim trailing slash, auto add port.
    url="${url_scheme}://${url_host}${_url_port}${url_path_clean_trailing}"
}

# Require, validate, and populate value.
chapter Variable dump.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
code 'SUBDOMAIN_ISPCONFIG="'$SUBDOMAIN_ISPCONFIG'"'
code 'SUBDOMAIN_PHPMYADMIN="'$SUBDOMAIN_PHPMYADMIN'"'
code 'SUBDOMAIN_ROUNDCUBE="'$SUBDOMAIN_ROUNDCUBE'"'
code 'timezone="'$timezone'"'
code 'php_version="'$php_version'"'
code 'phpmyadmin_version="'$phpmyadmin_version'"'
code 'roundcube_version="'$roundcube_version'"'
if [ -z "$dns_plugin" ];then
    error "Argument --dns-plugin required."; x
else
    dns_plugin_available=()
    while read line; do
        dns_plugin_available+=($line)
    done <<< `rcm-plugin list --interface=dns`
    if ! ArraySearch "$dns_plugin" dns_plugin_available[@];then
        error "Argument --dns-plugin not valid."; x
    fi
fi
code 'dns_plugin="'$dns_plugin'"'
if [ -n "$tls_plugin" ];then
    tls_plugin_available=()
    while read line; do
        tls_plugin_available+=($line)
    done <<< `rcm-plugin list --interface=tls`
    if ! ArraySearch "$tls_plugin" tls_plugin_available[@];then
        error "Argument --tls-plugin not valid."; x
    fi
fi
code 'tls_plugin="'$tls_plugin'"'
if [ -z "$domain" ];then
    error "Argument --domain required."; x
fi
code domain="$domain"
if [ -z "$hostname" ];then
    error "Argument --hostname required."; x
fi
code hostname="$hostname"
fqdn="${hostname}.${domain}"
code fqdn="$fqdn"
Rcm_parse_url "$fqdn"
for each in PHP_URL_SCHEME PHP_URL_PORT PHP_URL_USER PHP_URL_PASS PHP_URL_PATH PHP_URL_QUERY PHP_URL_FRAGMENT; do
    value=${!each}
    if [ -n "$value" ];then
        error Argument --fqdn cannot have component "$each": '`'"$fqdn"'`'.; x
    fi
done
hostname=$(echo "$PHP_URL_HOST" | sed -E 's|^([^\.]+)\..*|\1|g')
code hostname="$hostname"
code url_ispconfig="$url_ispconfig"
if [ -n "$url_ispconfig" ];then
    url="$url_ispconfig"
    urlCompleteComponent
    # code 'url_scheme="'$url_scheme'"'
    # code 'url_host="'$url_host'"'
    # code 'url_port="'$url_port'"'
    # code 'url_path="'$url_path'"'
    # code 'url_path_clean="'$url_path_clean'"'
    # code 'url_path_clean_trailing="'$url_path_clean_trailing'"'
    if [ -n "$url_path" ];then
        error Argument --url-ispconfig is cannot have subpath: '`'"$url_path"'`'.; x
    elif [ ! "$url_host" == "$fqdn" ];then
        error Argument --url-ispconfig is not part of FQDN: '`'"$url_ispconfig"'`'.; x
    fi
    url_ispconfig="$url"
    code 'url_ispconfig="'$url_ispconfig'"'
fi
code url_phpmyadmin="$url_phpmyadmin"
if [ -n "$url_phpmyadmin" ];then
    url="$url_phpmyadmin"
    urlCompleteComponent
    # code 'url_scheme="'$url_scheme'"'
    # code 'url_host="'$url_host'"'
    # code 'url_port="'$url_port'"'
    # code 'url_path="'$url_path'"'
    # code 'url_path_clean="'$url_path_clean'"'
    # code 'url_path_clean_trailing="'$url_path_clean_trailing'"'
    if [ ! "$url_host" == "$fqdn" ];then
        error Argument --url-ispconfig is not part of FQDN: '`'"$url_ispconfig"'`'.; x
    fi
    url_phpmyadmin="$url"
    code 'url_phpmyadmin="'$url_phpmyadmin'"'
fi
code url_roundcube="$url_roundcube"
if [ -n "$url_roundcube" ];then
    url="$url_roundcube"
    urlCompleteComponent
    # code 'url_scheme="'$url_scheme'"'
    # code 'url_host="'$url_host'"'
    # code 'url_port="'$url_port'"'
    # code 'url_path="'$url_path'"'
    # code 'url_path_clean="'$url_path_clean'"'
    # code 'url_path_clean_trailing="'$url_path_clean_trailing'"'
    if [ ! "$url_host" == "$fqdn" ];then
        error Argument --url-ispconfig is not part of FQDN: '`'"$url_ispconfig"'`'.; x
    fi
    url_roundcube="$url"
    code 'url_roundcube="'$url_roundcube'"'
fi
[ -z "$update_system" ] && update_system=1
[ "$update_system" == 0 ] && update_system=
[ "$upgrade_system" == 0 ] && upgrade_system=
[ -n "$update_system" ] && is_update_system=' --without-update-system-' || is_update_system=' --without-update-system'
[ -n "$upgrade_system" ] && is_upgrade_system=' --without-upgrade-system-' || is_upgrade_system=' --without-upgrade-system'
____

# chapter Take a break.
# _ Begin to Validate DNS Zone for FQDN.; _.
# sleepExtended 3 30
# ____

# Prepare for anything including setup required application.
INDENT+='    ' \
rcm-plugin $isfast execute --interface=dns --name="$dns_plugin" --method='server_setup_pre' \
    ; [ ! $? -eq 0 ] && x
____

export RCM_HOSTNAME="$hostname"
export RCM_DOMAIN="$domain"
INDENT+='    ' \
rcm-plugin $isfast execute --interface=dns --name="$dns_plugin" --method='is_a_record_exists_not_cname' \
    ; [ ! $? -eq 0 ] && x
____

# chapter Take a break.
# _ Setup LEMP Stack.; _.
# sleepExtended 3 30
# ____

chapter Mengecek FQDN '(Fully-Qualified Domain Name)'
code fqdn="$fqdn"
current_fqdn=$(hostname -f 2>/dev/null)
code hostname -f
e "$current_fqdn"; _.
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

include `rcm plugin get-socket ispconfig/os-setup $os_setup init`

INDENT+='    ' \
RCM_PROMPT_CHAIN= \
RCM_ENVIRONMENT_VARIABLES= \
rcm-nginx-apt $isfast \
    && INDENT+='    ' \
rcm-mariadb-apt $isfast \
    && INDENT+='    ' \
rcm-php-apt $isfast \
    --php-version="$php_version" \
    && INDENT+='    ' \
rcm-php-setup-adjust-cli-version $isfast \
    --php-version="$php_version" \
    && INDENT+='    ' \
rcm-postfix-apt $isfast \
    --fqdn="$fqdn" \
    ; [ ! $? -eq 0 ] && x

INDENT+='    ' \
rcm-plugin $isfast execute --interface=dns --name="$dns_plugin" --method='server_setup_post' \
    ; [ ! $? -eq 0 ] && x

# TLS Plugin tidak wajib, sehingga kita bisa menggunakan if atau --ignore-fail-on-empty-name.
INDENT+='    ' \
rcm-plugin $isfast execute --interface=tls --name="$tls_plugin" --method='server_setup_post' --ignore-fail-on-empty-name \
    ; [ ! $? -eq 0 ] && x

# chapter Take a break.
# _ Begin to Install ISPConfig and Friends.; _.
# sleepExtended 3 30
____

# Obtain Certificate.
# We hope the variable environment of NGINX_SSL_CERTIFICATE and
# NGINX_SSL_CERTIFICATE_KEY will be defined.
if [ -n "$tls_plugin" ];then
    [ -z "$tempfile" ] && tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-setup-mode-init.XXXXXX)
    export RCM_FQDN="$fqdn"
    INDENT+='    ' \
    rcm-plugin $isfast execute --interface=tls --name="$tls_plugin" \
        --method='obtain_certificate' \
        --output-file="$tempfile" \
        ; [ ! $? -eq 0 ] && x
    if [ -s "$tempfile" ];then
        # Tidak gunakan export, cukup gunakan source karena untuk kebutuhan
        # internal script ini.
        source "$tempfile"
        while IFS= read -r line; do
            code "$line"
        done < "$tempfile"
        ____
    fi
fi

# todo, seharusnya bisa install ispconfig tanpa tls. sementara anggap lah
# wajib.
# Populate value.
# If not set in argument, try load from environment.
[ -z "$tls_certificate" ] && tls_certificate="$TLS_CERTIFICATE"
[ -z "$tls_certificate_key" ] && tls_certificate_key="$TLS_CERTIFICATE_KEY"

INDENT+='    ' \
rcm-ispconfig-autoinstaller-nginx $isfast \
    --domain="$domain" \
    --hostname="$hostname" \
    --ispconfig-version="$ispconfig_version" \
    --roundcube-version="$roundcube_version" \
    --phpmyadmin-version="$phpmyadmin_version" \
    --php-version="$php_version" \
    --tls-certificate="$tls_certificate" \
    --tls-certificate-key="$tls_certificate_key" \
    && INDENT+='    ' \
rcm-roundcube-setup-ispconfig-integration $isfast \
    ; [ ! $? -eq 0 ] && x

if [ -n "$url_ispconfig" ];then
    INDENT+="    " \
    rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast \
        --project=ispconfig \
        --php-version="$php_version" \
        --url="$url_ispconfig" \
        --tls-certificate="$tls_certificate" \
        --tls-certificate-key="$tls_certificate_key" \
        ; [ ! $? -eq 0 ] && x
fi

if [ -n "$url_phpmyadmin" ];then
    INDENT+="    " \
    rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root $isfast \
        --project=phpmyadmin \
        --php-version="$php_version" \
        --url="$url_phpmyadmin" \
        --tls-certificate="$tls_certificate" \
        --tls-certificate-key="$tls_certificate_key" \
        ; [ ! $? -eq 0 ] && x
fi

if [ -n "$url_roundcube" ];then
    INDENT+="    " \
    rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root $isfast \
        --project=roundcube \
        --php-version="$php_version" \
        --url="$url_roundcube" \
        --tls-certificate="$tls_certificate" \
        --tls-certificate-key="$tls_certificate_key" \
        ; [ ! $? -eq 0 ] && x
fi

chapter Take a break.
_ Everything is OK, "let's" dump variables.; _.
sleepExtended 3
____

chapter Saving URL information.
if [ -n "$url_ispconfig" ];then
    path=/usr/local/share/ispconfig/website
    parent=/usr/local/share/ispconfig
    code mkdir -p "$parent"
    mkdir -p "$parent"
    cat << EOF >> "$path"
URL_ISPCONFIG=$url_ispconfig
EOF
    [ -f "$path" ] || fileMustExists "$path"
fi
if [ -n "$url_phpmyadmin" ];then
    path=/usr/local/share/phpmyadmin/website
    parent=/usr/local/share/phpmyadmin
    code mkdir -p "$parent"
    mkdir -p "$parent"
    cat << EOF >> "$path"
URL_PHPMYADMIN=$url_phpmyadmin
EOF
    [ -f "$path" ] || fileMustExists "$path"
fi
if [ -n "$url_roundcube" ];then
    path=/usr/local/share/roundcube/website
    parent=/usr/local/share/roundcube
    code mkdir -p "$parent"
    mkdir -p "$parent"
    cat << EOF >> "$path"
URL_ROUNDCUBE=$url_roundcube
EOF
    [ -f "$path" ] || fileMustExists "$path"
fi
____

INDENT+="    " \
rcm-ispconfig-setup-dump-variables-init $isfast \
    ; [ ! $? -eq 0 ] && x

chapter Finish
____

exit 0

# parse-options.sh \
# --with-end-options-double-dash \
# --with-end-options-specific-operand \
# --compact \
# --clean \
# --no-hash-bang \
# --no-original-arguments \
# --no-error-invalid-options \
# --no-error-require-arguments << EOF | clip
# FLAG=(
# --version
# --help
# --bypass-validation-is-installed
# )
# VALUE=(
# --timezone
# --hostname
# --domain
# --url-ispconfig
# --url-phpmyadmin
# --url-roundcube
# --dns-plugin
# --tls-plugin
# --os-setup
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
# OPERAND=(
# helper
# )
# EOF
# clear
