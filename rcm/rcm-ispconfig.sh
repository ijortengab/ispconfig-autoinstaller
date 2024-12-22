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
        generate-key)
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
        generate-key)
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

# Command.
if [ -n "$1" ];then
    case "$1" in
        mode-available|eligible|generate-key) command="$1"; shift ;;
    esac
fi

# Parse arguments per command. Generated by parse-options.sh
case "$command" in
    generate-key)
        _new_arguments=()
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --domain=*) domain="${1#*=}"; shift ;;
                --domain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then domain="$2"; shift; fi; shift ;;
                --serialize-array) serialize_array=1; shift ;;
                --[^-]*) shift ;;
                *) _new_arguments+=("$1"); shift ;;
            esac
        done
        set -- "${_new_arguments[@]}"
        unset _new_arguments
esac

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

# Define constants.
DKIM_SELECTOR=${DKIM_SELECTOR:=default}

# Functions.
printVersion() {
    echo '0.9.9'
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
command-eligible() {
    local mode=$1; shift
    local is_digitalocean=$1
    eligible=()
    if [ -f /etc/os-release ];then
        . /etc/os-release
    fi
    case "$mode" in
        init)
        _; _.
            case "$is_digitalocean" in
                1)
                    ___; _, 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 11    ]] && color=green || color=red; $color d1;
                    _, . Debian 11, PHP 7.4, ISPConfig 3.2.7,; _.
                    ___; _,  '             ' PHPMyAdmin 5.2.0, Roundcube 1.6.0, DigitalOcean DNS.; _.
                    eligible+=("d1;debian;11")
                    ___; _, 'Variation '; [[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 ]] && color=green || color=red; $color u2;
                    _, . Ubuntu 22.04, PHP 7.4, ISPConfig 3.2.7,; _.
                    ___; _,  '             ' PHPMyAdmin 5.2.0, Roundcube 1.6.0, DigitalOcean DNS.; _.
                    eligible+=("u2;ubuntu;22.04")
                    ___; _, 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 12    ]] && color=green || color=red; $color d3;
                    _, . Debian 12, PHP 8.1, ISPConfig 3.2.10,; _.
                    ___; _,  '             ' PHPMyAdmin 5.2.1, Roundcube 1.6.2, DigitalOcean DNS.; _.
                    eligible+=("d3;debian;12")
                    ;;
                0)
                    ___; _, 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 11    ]] && color=green || color=red; $color d4;
                    _, . Debian 11, PHP 8.1, ISPConfig 3.2.11p2,; _.
                    ___; _,  '             ' PHPMyAdmin 5.2.1, Roundcube 1.6.6, Manual DNS.; _.
                    eligible+=("d4;debian;11")
                    ___; _, 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 12    ]] && color=green || color=red; $color d5;
                    _, . Debian 12, PHP 8.3, ISPConfig 3.2.11p2,; _.
                    ___; _,  '             ' PHPMyAdmin 5.2.1, Roundcube 1.6.6, Manual DNS.; _.
                    eligible+=("d5;debian;12")
                    ;;
            esac
            ;;
        addon)
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
command-mode-available() {
    local is_digitalocean=$1
    mode_available=()
    php_fpm_user=ispconfig
    if id "$php_fpm_user" >/dev/null 2>&1; then
        mode_available+=(addon)
    else
        mode_available+=(init)
    fi
    _; _.
    if ArraySearch init mode_available[@] ]];then color=green; else color=red; fi
    ___; _, 'Mode '; $color init; _, .; _, '  'Install ISPConfig + LEMP Stack Setup. ; _.;
    ___; _, '            '; _, LEMP Stack '('Linux, Nginx, MySQL, PHP')'.; _.;
    if ArraySearch addon mode_available[@] ]];then color=green; else color=red; fi
    ___; _, 'Mode '; $color addon; _, .; _, ' 'Add on Domain. ; _.;
    for each in init addon; do
        if ArraySearch $each mode_available[@] ]];then echo $each; fi
    done
}
wordWrapCommand() {
    # global words_array
    local inline_description="$1"
    local current_line first_line
    declare -i min; min=80
    declare -i max; max=100
    declare -i i; i=0
    local count="${#words_array[@]}"
    current_line=
    first_line=1
    for each in "${words_array[@]}"; do
        i+=1
        [ "$i" == "$count" ] && last=1 || last=
        if [ -z "$current_line" ]; then
            if [ -z "$first_line" ];then
                current_line="    ${each}"
                e; magenta "    $each";
            else
                first_line=
                if [ -n "$inline_description" ];then
                    e; _, "${inline_description} "; magenta "$each"
                    current_line="${inline_description} ${each}"
                else
                    e; magenta "$each"
                    current_line="$each"
                fi
            fi
            if [ -n "$last" ];then
                _.
            fi
        else
            _current_line="${current_line} ${each}"
            if [ "${#_current_line}" -le $min ];then
                if [ -n "$last" ];then
                    _, ' '; magenta "$each"; _.
                else
                    _, ' '; magenta "$each"
                fi
                current_line+=" ${each}"
            elif [ "${#_current_line}" -le $max ];then
                if [ -n "$last" ];then
                    _, ' '; magenta "${each}"''; _.
                else
                    _, ' '; magenta "${each}"' \'; _.
                fi
                current_line=
            else
                magenta ' \'; _.; e; magenta "    $each"
                current_line="    ${each}"
                if [ -n "$last" ];then
                    _.
                fi
            fi
        fi
    done
}
command-generate-key() {
    title rcm-ispconfig generate-key
    ____

    chapter Dump variable.
    if [ -z "$domain" ];then
        error "Argument --domain required."; x
    fi
    code 'domain="'$domain'"'
    php_fpm_user=ispconfig
    code 'php_fpm_user="'$php_fpm_user'"'
    prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
    code 'prefix="'$prefix'"'
    tempfile=$(mktemp -p "$prefix/interface/web/mail" -t rcm-ispconfig-ajax-get-json.XXXXXX)
    code 'tempfile="'$tempfile'"'
    cp "${prefix}/interface/web/mail/ajax_get_json.php" "$tempfile"
    chmod go-r "$tempfile"
    chmod go-w "$tempfile"
    chmod go-x "$tempfile"
    sed -i "/\$app->auth->check_module_permissions('mail');/d" "$tempfile"
    sed -i "s,if (\$dkim_strength==''),if (\$dkim_strength==0),g" "$tempfile"
    dirname="${prefix}/interface/web/mail"
    php=$(cat <<'EOF'
$mode = $_SERVER['argv'][1];
switch ($mode) {
    case 'ajax_get_json':
        $dirname = $_SERVER['argv'][2];
        $file = $_SERVER['argv'][3];
        $domain = $_SERVER['argv'][4];
        $dkim_selector = $_SERVER['argv'][5];
        chdir($dirname);
        $_GET['type'] = 'create_dkim';
        $_GET['domain_id'] = $domain;
        $_GET['dkim_selector'] = $dkim_selector;
        $_GET['dkim_public'] = '';
        include_once $file;
        break;
    default:
        fwrite(STDERR, 'Unknown mode.'.PHP_EOL);
        exit(1);
        break;
}
EOF
    )
    ____

    php -r "$php" ajax_get_json "$dirname" "$tempfile" "$domain" "$DKIM_SELECTOR"
    # @todo: serialize_array
    [ -n "$tempfile" ] && rm "$tempfile"
}

# Execute command.
if [[ -n "$command" && $(type -t "command-${command}") == function ]];then
    command-${command} "$@"
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
        init|addon) ;;
        *) error "Argument --mode not valid."; x ;;
    esac
fi
if [ -n "$variation" ];then
    case "$variation" in
        d1|u2|d3|d4|d5) ;;
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
    init)
        if [ -n "$digitalocean" ];then
            case "$variation" in
                d1) rcm_operand=ispconfig-setup-variation-1 ;;
                u2) rcm_operand=ispconfig-setup-variation-2 ;;
                d3) rcm_operand=ispconfig-setup-variation-3 ;;
                *) error "Argument --variation not valid."; x ;;
            esac
        else
            case "$variation" in
                d4) rcm_operand=ispconfig-setup-variation-4 ;;
                d5) rcm_operand=ispconfig-setup-variation-5 ;;
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
        words_array=(rcm ${isfast} ${isnoninteractive} ${isverbose} $rcm_operand -- "$@")
esac
wordWrapCommand
____

case "$rcm_operand" in
    *)
        INDENT+="    " BINARY_DIRECTORY="$BINARY_DIRECTORY" rcm${isfast}${isnoninteractive}${isverbose} $rcm_operand --root-sure --binary-directory-exists-sure --non-immediately -- "$@"
esac
____

exit 0

# parse-options.sh \
# --compact \
# --clean \
# --no-hash-bang \
# --no-original-arguments \
# --no-error-invalid-options \
# --with-end-options-specific-operand \
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
# OPERAND=(
# generate-key
# )
# EOF
# clear

# parse-options.sh \
# --compact \
# --clean \
# --no-hash-bang \
# --without-end-options-double-dash \
# --no-original-arguments \
# --no-error-invalid-options \
# --no-error-require-arguments << EOF | clip
# FLAG=(
# --serialize-array
# )
# VALUE=(
# --domain
# )
# EOF
# clear
