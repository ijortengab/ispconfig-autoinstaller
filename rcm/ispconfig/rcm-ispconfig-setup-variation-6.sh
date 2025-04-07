#!/bin/bash

# Parse arguments. Generated by parse-options.sh
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --bypass-validation-is-installed) bypass_validation_is_installed=1; shift ;;
        --fast) fast=1; shift ;;
        --fqdn=*) fqdn="${1#*=}"; shift ;;
        --fqdn) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then fqdn="$2"; shift; fi; shift ;;
        --ip-address=*) ip_address="${1#*=}"; shift ;;
        --ip-address) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then ip_address="$2"; shift; fi; shift ;;
        --timezone=*) timezone="${1#*=}"; shift ;;
        --timezone) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then timezone="$2"; shift; fi; shift ;;
        --url-ispconfig=*) url_ispconfig="${1#*=}"; shift ;;
        --url-ispconfig) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_ispconfig="$2"; shift; fi; shift ;;
        --url-phpmyadmin=*) url_phpmyadmin="${1#*=}"; shift ;;
        --url-phpmyadmin) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_phpmyadmin="$2"; shift; fi; shift ;;
        --url-roundcube=*) url_roundcube="${1#*=}"; shift ;;
        --url-roundcube) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_roundcube="$2"; shift; fi; shift ;;
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
_() { echo -n "$INDENT" >&2; echo -n "#"' ' >&2; [ -n "$1" ] && echo -n "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "# ${RCM_INDENT}" >&2; [ -n "$1" ] && echo "$@" >&2; }
___() { echo -n "$INDENT" >&2; echo -n "# ${RCM_INDENT}${RCM_INDENT}" >&2; [ -n "$1" ] && echo "$@" >&2 || echo -n  >&2; }
____() { echo >&2; [ -n "$RCM_DELAY" ] && sleep "$RCM_DELAY"; }

# Define variables and constants.
RCM_DELAY=${RCM_DELAY:=.5}; [ -n "$fast" ] && unset RCM_DELAY
RCM_INDENT='    '; [ "$(tput cols)" -le 80 ] && RCM_INDENT='  '
SUBDOMAIN_ISPCONFIG=${SUBDOMAIN_ISPCONFIG:=cp}
SUBDOMAIN_PHPMYADMIN=${SUBDOMAIN_PHPMYADMIN:=db}
SUBDOMAIN_ROUNDCUBE=${SUBDOMAIN_ROUNDCUBE:=mail}

# Functions.
printVersion() {
    echo '0.9.21'
}
printHelp() {
    title RCM ISPConfig Setup
    _ 'Variation '; yellow 6; _, . Ubuntu 24.04, ISPConfig 3.2.12p1, PHPMyAdmin 5.2.2, Roundcube 1.6.10, PHP 8.3, Manual DNS.; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-setup-variation-6 [options]

Options:
   --fqdn *
        Fully Qualified Domain Name of this server, for example: \`server1.example.org\`.
   --ip-address *
        Set the IP Address. Used to verify A record in DNS.
        Value available from command: rcm-ispconfig-setup-variation-6(get-ipv4).
   --url-ispconfig
        Add ISPConfig public domain. The value can be domain or URL.
        ISPConfig automatically has address at http://ispconfig.localhost/.
        Value available from command: rcm-ispconfig-setup-variation-6(suggest-url ispconfig [--fqdn]), or other.
   --url-phpmyadmin
        Add PHPMyAdmin public domain. The value can be domain or URL.
        PHPMyAdmin automatically has address at http://phpmyadmin.localhost/.
        Value available from command: rcm-ispconfig-setup-variation-6(suggest-url phpmyadmin [--fqdn] [--url-ispconfig]), or other.
   --url-roundcube
        Add Roundcube public domain. The value can be domain or URL.
        Roundcube automatically has address at http://roundcube.localhost/.
        Value available from command: rcm-ispconfig-setup-variation-6(suggest-url roundcube [--fqdn] [--url-ispconfig]), or other.
   --timezone
        Set the timezone of this machine. Available values: Asia/Jakarta, or other.

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.
   --bypass-validation-is-installed
        Bypass ISPConfig installed validation.

Environment Variables:
   SUBDOMAIN_ISPCONFIG
        Default to $SUBDOMAIN_ISPCONFIG
   SUBDOMAIN_PHPMYADMIN
        Default to $SUBDOMAIN_PHPMYADMIN
   SUBDOMAIN_ROUNDCUBE
        Default to $SUBDOMAIN_ROUNDCUBE

Dependency:
   wget
   rcm-ubuntu-24.04-setup-basic
   rcm-mariadb-apt
   rcm-nginx-apt
   rcm-php-apt
   rcm-php-setup-adjust-cli-version
   rcm-postfix-apt
   rcm-certbot-apt
   rcm-dig-apt
   rcm-dig-has-address
   rcm-dig-watch-domain-exists
   rcm-ispconfig-autoinstaller-nginx:`printVersion`
   rcm-ispconfig-setup-remote-user-root:`printVersion`
   rcm-roundcube-setup-ispconfig-integration:`printVersion`
   rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php:`printVersion`
   rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root:`printVersion`
   rcm-ispconfig-setup-dump-variables-init:`printVersion`

Download:
   [rcm-ispconfig-autoinstaller-nginx](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-autoinstaller-nginx.sh)
   [rcm-ispconfig-setup-remote-user-root](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-remote-user-root.sh)
   [rcm-roundcube-setup-ispconfig-integration](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/roundcube/rcm-roundcube-setup-ispconfig-integration.sh)
   [rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php.sh)
   [rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root.sh)
   [rcm-ispconfig-setup-dump-variables-init](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-dump-variables-init.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

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
            _; _.
            ___; yellow Attention; _, . ISPConfig cannot install inside subpath.; _.
            local fqdn=$2
            # Rcm_parse_url $fqdn
            # local domain=$(echo "$PHP_URL_HOST" | cut -d. -f2-)
            # siblingHost "$domain" $SUBDOMAIN_ISPCONFIG
            urlAlternative "$fqdn" 8080
            urlAlternative "$fqdn" 8081
            urlAlternative "$fqdn" 8443
            # echo "https://${PHP_URL_HOST}:8080"
            ;;
        phpmyadmin)
            local fqdn=$2 url_ispconfig=$3
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
            local fqdn=$2 url_ispconfig=$3
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
title rcm-ispconfig-setup-variation-6
____

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'`cut -d: -f1 <<< "${line}"`'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

if [ -z "$bypass_validation_is_installed" ];then
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
fi

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
code 'SUBDOMAIN_ISPCONFIG="'$SUBDOMAIN_ISPCONFIG'"'
code 'SUBDOMAIN_PHPMYADMIN="'$SUBDOMAIN_PHPMYADMIN'"'
code 'SUBDOMAIN_ROUNDCUBE="'$SUBDOMAIN_ROUNDCUBE'"'
code 'timezone="'$timezone'"'
if [ -z "$fqdn" ];then
    error "Argument --fqdn required."; x
fi
if [ -z "$ip_address" ];then
    error "Argument --ip-address required."; x
fi
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
fqdn_array=()
fqdn_path_array=()
code url_ispconfig="$url_ispconfig"
if [ -n "$url_ispconfig" ];then
    Rcm_parse_url "$url_ispconfig"
    if [ -z "$PHP_URL_HOST" ];then
        error Argument --url-ispconfig is not valid: '`'"$url_ispconfig"'`'.; x
    elif [ -n "$PHP_URL_PATH" ];then
        error Argument --url-ispconfig is cannot have subpath: '`'"$url_ispconfig"'`'.; x
    elif [ ! "$PHP_URL_HOST" == "$fqdn" ];then
        error Argument --url-ispconfig is not part of FQDN: '`'"$url_ispconfig"'`'.; x
    else
        [ -n "$PHP_URL_SCHEME" ] && scheme="$PHP_URL_SCHEME" || scheme=https
        [ -n "$PHP_URL_PORT" ] && port="$PHP_URL_PORT" || port=443
        [ -n "$PHP_URL_PATH" ] && fqdn_path_array+=("$PHP_URL_HOST")
        ispconfig_url_scheme="$scheme"
        ispconfig_url_host="$PHP_URL_HOST"
        ispconfig_url_port="$port"
        ispconfig_url_path="$PHP_URL_PATH"
        fqdn_array+=("$PHP_URL_HOST")
        # Modify variable url_ispconfig.
        [ -n "$PHP_URL_SCHEME" ] || url_ispconfig="${scheme}://${url_ispconfig}"
        code url_ispconfig="$url_ispconfig"
    fi
fi
code url_phpmyadmin="$url_phpmyadmin"
if [ -n "$url_phpmyadmin" ];then
    Rcm_parse_url "$url_phpmyadmin"
    if [ -z "$PHP_URL_HOST" ];then
        error Argument --url-phpmyadmin is not valid: '`'"$url_phpmyadmin"'`'.; x
    elif [ ! "$PHP_URL_HOST" == "$fqdn" ];then
        error Argument --url-phpmyadmin is not part of FQDN: '`'"$url_phpmyadmin"'`'.; x
    else
        [ -n "$PHP_URL_SCHEME" ] && scheme="$PHP_URL_SCHEME" || scheme=https
        [ -n "$PHP_URL_PORT" ] && port="$PHP_URL_PORT" || port=443
        [ -n "$PHP_URL_PATH" ] && fqdn_path_array+=("$PHP_URL_HOST")
        phpmyadmin_url_scheme="$scheme"
        phpmyadmin_url_host="$PHP_URL_HOST"
        phpmyadmin_url_port="$port"
        phpmyadmin_url_path="$PHP_URL_PATH"
        fqdn_array+=("$PHP_URL_HOST")
        # Modify variable url_phpmyadmin.
        [ -n "$PHP_URL_SCHEME" ] || url_phpmyadmin="${scheme}://${url_phpmyadmin}"
        code url_phpmyadmin="$url_phpmyadmin"
    fi
fi
code url_roundcube="$url_roundcube"
if [ -n "$url_roundcube" ];then
    Rcm_parse_url "$url_roundcube"
    if [ -z "$PHP_URL_HOST" ];then
        error Argument --url-roundcube is not valid: '`'"$url_roundcube"'`'.; x
    elif [ ! "$PHP_URL_HOST" == "$fqdn" ];then
        error Argument --url-roundcube is not part of FQDN: '`'"$url_roundcube"'`'.; x
    else
        [ -n "$PHP_URL_SCHEME" ] && scheme="$PHP_URL_SCHEME" || scheme=https
        [ -n "$PHP_URL_PORT" ] && port="$PHP_URL_PORT" || port=443
        [ -n "$PHP_URL_PATH" ] && fqdn_path_array+=("$PHP_URL_HOST")
        roundcube_url_scheme="$scheme"
        roundcube_url_host="$PHP_URL_HOST"
        roundcube_url_port="$port"
        roundcube_url_path="$PHP_URL_PATH"
        fqdn_array+=("$PHP_URL_HOST")
        # Modify variable url_roundcube.
        [ -n "$PHP_URL_SCHEME" ] || url_roundcube="${scheme}://${url_roundcube}"
        code url_roundcube="$url_roundcube"
    fi
fi
code 'fqdn_array=('"${fqdn_array[@]}"')'
ArrayUnique fqdn_array[@]
fqdn_array=("${_return[@]}")
unset _return
code 'fqdn_array=('"${fqdn_array[@]}"')'
code 'fqdn_path_array=('"${fqdn_path_array[@]}"')'
ArrayUnique fqdn_path_array[@]
fqdn_path_array=("${_return[@]}")
unset _return
code 'fqdn_path_array=('"${fqdn_path_array[@]}"')'
php_version=8.3
code php_version="$php_version"
phpmyadmin_version=5.2.2
code phpmyadmin_version="$phpmyadmin_version"
roundcube_version=1.6.10
code roundcube_version="$roundcube_version"
ispconfig_version=3.2.12p1
code ispconfig_version="$ispconfig_version"
code ip_address="$ip_address"
if ! grep -q -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$ip_address";then
    error IP Address version 4 format is not valid; x
fi
____

INDENT+="    " \
rcm-dig-apt $isfast \
    ; [ ! $? -eq 0 ] && x

chapter Take a break.
_ Begin to Validate DNS Record.; _.
sleepExtended 3
____

INDENT+="    " \
rcm-dig-is-record-exists $isfast --name-exists-sure \
    --reverse \
    --domain="$fqdn" \
    --type=cname \
    --hostname="@" \
    --hostname-origin="*" \
    && INDENT+="    " \
rcm-dig-is-record-exists $isfast --name-exists-sure \
    --domain="$fqdn" \
    --type=a \
    --ip-address="$ip_address" \
    ; [ ! $? -eq 0 ] && x

for each in "${fqdn_array[@]}";do
    INDENT+="    " \
    rcm-dig-watch-domain-exists $isfast \
        --domain="$each" \
        --waiting-time="60" \
        && INDENT+="    " \
    rcm-dig-has-address $isfast \
        --fqdn="$each" \
        --ip-address="$ip_address" \
        ; [ ! $? -eq 0 ] && x
done

chapter Take a break.
_ Setup LEMP Stack.; _.
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
rcm-ubuntu-24.04-setup-basic $isfast \
    --timezone="$timezone" \
    --without-update-system \
    --without-upgrade-system \
    && INDENT+="    " \
rcm-mariadb-apt $isfast \
    && INDENT+="    " \
rcm-nginx-apt $isfast \
    && INDENT+="    " \
rcm-php-apt $isfast \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-php-setup-adjust-cli-version $isfast \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-postfix-apt $isfast \
    --fqdn="$fqdn" \
    && INDENT+="    " \
rcm-certbot-apt $isfast \
    ; [ ! $? -eq 0 ] && x

chapter Take a break.
_ Begin to Install ISPConfig and Friends.; _.
sleepExtended 3
____

INDENT+="    " \
rcm-ispconfig-autoinstaller-nginx $isfast \
    --certbot-authenticator=nginx \
    --fqdn="$fqdn" \
    --ispconfig-version="$ispconfig_version" \
    --roundcube-version="$roundcube_version" \
    --phpmyadmin-version="$phpmyadmin_version" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-ispconfig-setup-remote-user-root $isfast \
    && INDENT+="    " \
rcm-roundcube-setup-ispconfig-integration $isfast \
    ; [ ! $? -eq 0 ] && x

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
            rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root $isfast \
                --project="$each" \
                --php-version="$php_version" \
                --url-scheme="$url_scheme" \
                --url-host="$url_host" \
                --url-port="$url_port" \
                --url-path="$url_path" \
                ; [ ! $? -eq 0 ] && x
        else
            INDENT+="    " \
            rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast \
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
_ Everything is OK, "let's" dump variables.; _.
sleepExtended 3
____

chapter Saving URL information.
if [ -n "$url_ispconfig" ];then
    code mkdir -p /usr/local/share/ispconfig/
    mkdir -p /usr/local/share/ispconfig/
    cat << EOF > /usr/local/share/ispconfig/website
    URL_ISPCONFIG=$url_ispconfig
EOF
    fileMustExists /usr/local/share/ispconfig/website
fi
if [ -n "$url_phpmyadmin" ];then
    code mkdir -p /usr/local/share/phpmyadmin/
    mkdir -p /usr/local/share/phpmyadmin/
    cat << EOF > /usr/local/share/phpmyadmin/website
URL_PHPMYADMIN=$url_phpmyadmin
EOF
    fileMustExists /usr/local/share/phpmyadmin/website
fi
if [ -n "$url_roundcube" ];then
    code mkdir -p /usr/local/share/roundcube/
    mkdir -p /usr/local/share/roundcube/
    cat << EOF > /usr/local/share/roundcube/website
URL_ROUNDCUBE=$url_roundcube
EOF
    fileMustExists /usr/local/share/roundcube/website
fi
____

INDENT+="    " \
rcm-ispconfig-setup-dump-variables-init $isfast \
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
# --bypass-validation-is-installed
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
# )
# EOF
# clear
