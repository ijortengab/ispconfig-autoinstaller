#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
_n=
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --digitalocean) digitalocean=1; shift ;;
        --fast) fast=1; shift ;;
        --mode=*) mode="${1#*=}"; shift ;;
        --mode) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then mode="$2"; shift; fi; shift ;;
        --non-interactive) non_interactive=1; shift ;;
        --root-sure) root_sure=1; shift ;;
        --variation=*) variation="${1#*=}"; shift ;;
        --variation) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then variation="$2"; shift; fi; shift ;;
        --verbose|-v) verbose="$((verbose+1))"; shift ;;
        --)
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
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -[^-]*) OPTIND=1
            while getopts ":v" opt; do
                case $opt in
                    v) verbose="$((verbose+1))" ;;
                esac
            done
            _n="$((OPTIND-1))"
            _n=${!_n}
            shift "$((OPTIND-1))"
            if [[ "$_n" == '--' ]];then
                while [[ $# -gt 0 ]]; do
                    case "$1" in
                        *) _new_arguments+=("$1"); shift ;;
                    esac
                done
            fi
            ;;
        --) shift
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
unset _n

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
        mode-available|eligible) ;;
        *)
            # Bring back command as argument position.
            set -- "$command" "$@"
            # Reset command.
            command=
    esac
fi

# Functions.
printVersion() {
    echo '0.9.3'
}
printHelp() {
    title ISPConfig Auto-Installer
    _ 'Homepage '; yellow https://github.com/ijortengab/ispconfig-autoinstaller; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig [command] [options]

Options:
   --mode *
        Select the setup mode. Values available from command: rcm-ispconfig(mode-available).
   --digitalocean ^
        Select this if your server use DigitalOcean DNS.
   --variation *
        Select the variation setup. Values available from command: rcm-ispconfig(eligible [--mode] [--digitalocean]).

Global Options.
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.
   --root-sure
        Bypass root checking.
   --non-interactive
        Skip prompt for every options.
   --
        Every arguments after double dash will pass to rcm-ispconfig-setup-variation-* command.

Dependency:
   rcm-ispconfig-setup-variation-1:`printVersion`
   rcm-ispconfig-setup-variation-2:`printVersion`
   rcm-ispconfig-setup-variation-3:`printVersion`
   rcm-ispconfig-setup-variation-4:`printVersion`
   rcm-ispconfig-setup-variation-5:`printVersion`
   rcm-ispconfig-setup-variation-addon:`printVersion`
   rcm-ispconfig-setup-variation-addon-2:`printVersion`

Download:
   [rcm-ispconfig-setup-variation-1](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-variation-1.sh)
   [rcm-ispconfig-setup-variation-2](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-variation-2.sh)
   [rcm-ispconfig-setup-variation-3](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-variation-3.sh)
   [rcm-ispconfig-setup-variation-4](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-variation-4.sh)
   [rcm-ispconfig-setup-variation-5](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-variation-5.sh)
   [rcm-ispconfig-setup-variation-addon](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-variation-addon.sh)
   [rcm-ispconfig-setup-variation-addon-2](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-variation-addon-2.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

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
eligible() {
    local mode=$1; shift
    local is_digitalocean=$1
    eligible=()
    if [ -f /etc/os-release ];then
        . /etc/os-release
    fi
    case "$mode" in
        1)
        _; _.
            case "$is_digitalocean" in
                1)
                    __; _, 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 11    ]] && color=green || color=red; $color 1;
                    _, . Debian 11, '  ' ISPConfig 3.2.7, '  ' PHPMyAdmin 5.2.0, Roundcube 1.6.0, PHP 7.4, DigitalOcean DNS. ; _.;
                    eligible+=("1;debian;11")
                    __; _, 'Variation '; [[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 ]] && color=green || color=red; $color 2;
                    _, . Ubuntu 22.04,   ISPConfig 3.2.7, '  ' PHPMyAdmin 5.2.0, Roundcube 1.6.0, PHP 7.4, DigitalOcean DNS. ; _.;
                    eligible+=("2;ubuntu;22.04")
                    __; _, 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 12    ]] && color=green || color=red; $color 3;
                    _, . Debian 12, '  ' ISPConfig 3.2.10, ' ' PHPMyAdmin 5.2.1, Roundcube 1.6.2, PHP 8.1, DigitalOcean DNS. ; _.;
                    eligible+=("3;debian;12")
                    ;;
                0)
                    __; _, 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 11    ]] && color=green || color=red; $color 4;
                    _, . Debian 11, '  ' ISPConfig 3.2.11p2,   PHPMyAdmin 5.2.1, Roundcube 1.6.6, PHP 8.1, Manual DNS.       ; _.;
                    eligible+=("4;debian;11")
                    __; _, 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 12    ]] && color=green || color=red; $color 5;
                    _, . Debian 12, '  ' ISPConfig 3.2.11p2,   PHPMyAdmin 5.2.1, Roundcube 1.6.6, PHP 8.3, Manual DNS.       ; _.;
                    eligible+=("5;debian;12")
                    ;;
            esac
            ;;
        2)
            ;;
    esac
    for each in "${eligible[@]}";do
        variation=$(cut -d';' -f1 <<< "$each")
        _id=$(cut -d';' -f2 <<< "$each")
        _version_id=$(cut -d';' -f3 <<< "$each")
        if [[ "$_id" == "all" && "$_version_id" == "all" ]];then
            echo $variation
        elif [[ "$_id" == "$ID" && "$_version_id" == "$VERSION_ID" ]];then
            echo $variation
        fi
    done
}
mode-available() {
    local is_digitalocean=$1
    mode_available=()
    php_fpm_user=ispconfig
    if id "$php_fpm_user" >/dev/null 2>&1; then
        mode_available+=(addon)
    else
        mode_available+=(setup)
    fi
    _; _.
    if ArraySearch setup mode_available[@] ]];then color=green; else color=red; fi
    __; _, 'Mode '; $color 1; _, ': '; _, setup; _, . Install ISPConfig + LEMP Stack Setup. ; _.;
    __; _, '               '; _, LEMP Stack '('Linux, Nginx, MySQL, PHP')'.; _.;
    if ArraySearch addon mode_available[@] ]];then color=green; else color=red; fi
    __; _, 'Mode '; $color 2; _, ': '; _, addon; _, . Add on Domain. ; _.;
    for each in setup addon; do
        if ArraySearch $each mode_available[@] ]];then echo $each; fi
    done
}

# Execute command.
if [[ -n "$command" && $(type -t "$command") == function ]];then
    "$command" "$@"
    exit 0
fi

# Title.
title rcm-ispconfig
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

# Require, validate, and populate value.
chapter Dump variable.
delay=.5; [ -n "$fast" ] && unset delay
[ -n "$fast" ] && isfast=' --fast' || isfast=''
[ -n "$non_interactive" ] && isnoninteractive=' --non-interactive' || isnoninteractive=''
[ -n "$verbose" ] && {
    for ((i = 0 ; i < "$verbose" ; i++)); do
        isverbose+=' --verbose'
    done
} || isverbose=
if [ -n "$mode" ];then
    case "$mode" in
        setup|addon) ;;
        *) error "Argument --mode not valid."; x ;;
    esac
fi
if [ -n "$variation" ];then
    case "$variation" in
        1|2|3|4|5) ;;
        *) error "Argument --variation not valid."; x ;;
    esac
fi
if [ -z "$mode" ];then
    error "Argument --mode required."; x
fi
code 'mode="'$mode'"'
code 'digitalocean="'$digitalocean'"'
code 'variation="'$variation'"'
____

case "$mode" in
    setup)
        if [ -n "$digitalocean" ];then
            case "$variation" in
                1|2|3)
                    rcm_operand=ispconfig-setup-variation-"$variation"
                    ;;
                *) error "Argument --variation not valid."; x ;;
            esac
        else
            case "$variation" in
                4|5)
                    rcm_operand=ispconfig-setup-variation-"$variation"
                    ;;
                *) error "Argument --variation not valid."; x ;;
            esac
        fi
        ;;
    addon)
        if [ -n "$digitalocean" ];then
            rcm_operand=ispconfig-setup-variation-addon-2
        else
            rcm_operand=ispconfig-setup-variation-addon
        fi
        ;;
esac

chapter Execute:

case "$rcm_operand" in
    *)
        code rcm${isfast}${isnoninteractive}${isverbose} $rcm_operand -- "$@"
        ____

        INDENT+="    " BINARY_DIRECTORY="$BINARY_DIRECTORY" rcm${isfast}${isnoninteractive}${isverbose} $rcm_operand --root-sure --binary-directory-exists-sure --non-immediately -- "$@"
esac
____

exit 0

# parse-options.sh \
# --without-end-options-double-dash \
# --compact \
# --clean \
# --no-hash-bang \
# --no-original-arguments \
# --no-error-invalid-options \
# --with-end-options-double-dash \
# --no-error-require-arguments << EOF | clip
# INCREMENT=(
    # '--verbose|-v'
# )
# FLAG=(
# --fast
# --version
# --help
# --root-sure
# --non-interactive
# --digitalocean
# )
# VALUE=(
# --mode
# --variation
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# EOF
# clear
