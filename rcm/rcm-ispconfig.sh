#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
_n=
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --dns-record=*) dns_record="${1#*=}"; shift ;;
        --dns-record) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then dns_record="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --mode=*) mode="${1#*=}"; shift ;;
        --mode) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then mode="$2"; shift; fi; shift ;;
        --non-interactive) non_interactive=1; shift ;;
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
_() { echo -n "$INDENT" >&2; echo -n "#"' ' >&2; [ -n "$1" ] && echo -n "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "# ${RCM_INDENT}" >&2; [ -n "$1" ] && echo "$@" >&2; }
___() { echo -n "$INDENT" >&2; echo -n "# ${RCM_INDENT}${RCM_INDENT}" >&2; [ -n "$1" ] && echo "$@" >&2 || echo -n  >&2; }
____() { echo >&2; [ -n "$RCM_DELAY" ] && sleep "$RCM_DELAY"; }

# Define variables and constants.
RCM_DELAY=${RCM_DELAY:=.5}; [ -n "$fast" ] && unset RCM_DELAY
RCM_INDENT='    '; [ "$(tput cols)" -le 80 ] && RCM_INDENT='  '
DKIM_SELECTOR=${DKIM_SELECTOR:=default}
[ -n "$RCM_TABLE_DOWNLOADS" ] && table_downloads="$RCM_TABLE_DOWNLOADS"

# Functions.
printVersion() {
    echo '0.9.22'
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
   --dns-record *
        Select how to create the DNS record.
        Available value: manual, digitalocean-api.
   --variation *
        Select the variation bundle setup. Values available from command: rcm-ispconfig(eligible [--mode] [--dns-record]).

Global Options.
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.
   --non-interactive
        Skip prompt for every options.
   --
        Every arguments after double dash will pass to rcm-ispconfig-setup-variation-* command.

Dependency:
   rcm:0.17.0

Download:
   [rcm-ispconfig-setup-variation-1](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-variation-1.sh)
   [rcm-ispconfig-setup-variation-2](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-variation-2.sh)
   [rcm-ispconfig-setup-variation-3](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-variation-3.sh)
   [rcm-ispconfig-setup-variation-4](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-variation-4.sh)
   [rcm-ispconfig-setup-variation-5](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-variation-5.sh)
   [rcm-ispconfig-setup-variation-6](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-variation-6.sh)
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
    if [ ! "$mode" == init ];then
        return 1
    fi
    local dns_record=$1
    eligible=()
    if [ -f /etc/os-release ];then
        . /etc/os-release
    fi

    _; _.
    ___; _, 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 11 && "$dns_record" == 'digitalocean-api' ]] && color=green2 || color=red; $color debian11a;
    _, . Debian' '; hN 11; _, , '       'PHP' '; hN 7.4; _, , '         'ISPConfig' '; hN 3.2.7; _, ,; _.
    ___; _,  '                    ' PHPMyAdmin' '; hN 5.2.0; _, , Roundcube' '; hN 1.6.0; _, , ' 'DigitalOcean API DNS.; _.
    eligible+=("debian11a;debian;11;digitalocean-api")
    ___; _, 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 11 && "$dns_record" == 'manual' ]] && color=green2 || color=red; $color debian11b;
    _, . Debian' '; hN 11; _, , '       'PHP' '; hN 8.1; _, , '         'ISPConfig' '; hN 3.2.11p2; _, ,; _.
    ___; _,  '                    ' PHPMyAdmin' '; hN 5.2.1; _, , Roundcube' '; hN 1.6.6; _, , ' 'Manual DNS.; _.
    eligible+=("debian11b;debian;11;manual")
    ___; _, 'Variation '; [[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 && "$dns_record" == 'digitalocean-api' ]] && color=green2 || color=red; $color ubuntu22a;
    _, . Ubuntu' '; hN 22.04; _, , '    'PHP' '; hN 7.4; _, , '         'ISPConfig' '; hN 3.2.7; _, ,; _.
    ___; _,  '                    ' PHPMyAdmin' '; hN 5.2.0; _, , Roundcube' '; hN 1.6.0; _, , ' 'DigitalOcean API DNS.; _.
    eligible+=("ubuntu22a;ubuntu;22.04;digitalocean-api")
    ___; _, 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 12 && "$dns_record" == 'digitalocean-api' ]] && color=green2 || color=red; $color debian12a;
    _, . Debian' '; hN 12; _, , '       'PHP' '; hN 8.1; _, , '         'ISPConfig' '; hN 3.2.10; _, ,; _.
    ___; _,  '                    ' PHPMyAdmin' '; hN 5.2.1; _, , Roundcube' '; hN 1.6.2; _, , ' 'DigitalOcean API DNS.; _.
    eligible+=("debian12a;debian;12;digitalocean-api")
    ___; _, 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 12 && "$dns_record" == 'manual' ]] && color=green2 || color=red; $color debian12b;
    _, . Debian' '; hN 12; _, , '       'PHP' '; hN 8.3; _, , '         'ISPConfig' '; hN 3.2.11p2; _, ,; _.
    ___; _,  '                    ' PHPMyAdmin' '; hN 5.2.1; _, , Roundcube' '; hN 1.6.6; _, , ' 'Manual DNS.; _.
    eligible+=("debian12b;debian;12;manual")
    ___; _, 'Variation '; [[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 && "$dns_record" == 'manual' ]] && color=green2 || color=red; $color ubuntu24a;
    _, . Ubuntu' '; hN 24.04; _, , '    'PHP' '; hN 8.3; _, , '         'ISPConfig' '; hN 3.2.12p1; _, ,; _.
    ___; _,  '                    ' PHPMyAdmin' '; hN 5.2.2; _, , Roundcube' '; hN 1.6.10; _, , Manual DNS.; _.
    eligible+=("ubuntu24a;ubuntu;24.04;manual")
    for each in "${eligible[@]}";do
        variation=$(cut -d';' -f1 <<< "$each")
        _id=$(cut -d';' -f2 <<< "$each")
        _version_id=$(cut -d';' -f3 <<< "$each")
        _dns_record=$(cut -d';' -f4 <<< "$each")
        if [[ "$_id" == "$ID" && "$_version_id" == "$VERSION_ID" && "$dns_record" == "$_dns_record" ]];then
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
    declare -i max
    declare -i min

    max=$(tput cols)
    # Angka 2 adalah tambahan dari ' \'.
    _max=$((100 + ${#INDENT} + 2))
    if [ $max -gt $_max ];then
        max=100
        min=80
    else
        max=$((max - ${#INDENT} - 2))
        min="$max"
    fi

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
green2() {
    local word=$1
    hN "$word" green
}
hN() {
    # hightlightNumber
    local other=$2
    [ -z "$other" ] && other=_,
    local number=yellow
    local word=$1 segment
    local current last
    for ((i = 0 ; i < ${#word} ; i++)); do
        if [[ ${word:$i:1} =~ ^[0-9]+$ ]];then
            current=number
        else
            current=other
        fi
        if [[ -n "$last" && ! "$last" == "$current" ]];then
            ${!last} $segment
            segment=
        fi
        last="$current"
        segment+=${word:$i:1}
    done
    ${!last} $segment
}

# Execute command.
if [[ -n "$command" && $(type -t "command-${command}") == function ]];then
    command-${command} "$@"
    exit 0
fi

# Title.
title rcm-ispconfig
____

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'`cut -d: -f1 <<< "${line}"`'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Require, validate, and populate value.
chapter Dump variable.
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
if [ -z "$mode" ];then
    error "Argument --mode required."; x
fi
code 'mode="'$mode'"'
if [ "$mode" == init ];then
    if [ -z "$variation" ];then
        error "Argument --variation required."; x
    fi
fi
if [ -n "$variation" ];then
    case "$variation" in
        debian11a|debian12a|debian11b|debian12b) ;;
        ubuntu22a|ubuntu24a) ;;
        *) error "Argument --variation not valid."; x ;;
    esac
fi
code 'variation="'$variation'"'
if [ -n "$dns_record" ];then
	case "$dns_record" in
		digitalocean-api) ;;
		manual) ;;
        *) error "Argument --dns-record not valid."; x ;;
	esac
fi
if [ -z "$dns_record" ];then
    error "Argument --dns-record required."; x
fi
code 'dns_record="'$dns_record'"'
print_version=`printVersion`
____

case "$mode" in
    init)
        case "$dns_record" in
            digitalocean-api)
                case "$variation" in
                    debian11a) rcm_operand=ispconfig-setup-variation-1 ;;
                    ubuntu22a) rcm_operand=ispconfig-setup-variation-2 ;;
                    debian12a) rcm_operand=ispconfig-setup-variation-3 ;;
                    *) error "Argument --variation not valid."; x ;;
                esac
                ;;
            manual)
                case "$variation" in
                    debian11b) rcm_operand=ispconfig-setup-variation-4 ;;
                    debian12b) rcm_operand=ispconfig-setup-variation-5 ;;
                    ubuntu24a) rcm_operand=ispconfig-setup-variation-6 ;;
                    *) error "Argument --variation not valid."; x ;;
                esac
                ;;
        esac
        ;;
    addon)
        case "$dns_record" in
            digitalocean-api)
                rcm_operand=ispconfig-setup-variation-addon-2
                ;;
            manual)
                rcm_operand=ispconfig-setup-variation-addon
        esac
        ;;
esac

chapter Execute:
case "$rcm_operand" in
    *)
        words_array=(rcm ${isfast} ${isnoninteractive} ${isverbose} $rcm_operand:$print_version -- "$@")
esac
wordWrapCommand
____

_help=$(printHelp 2>/dev/null)
_download=$(echo "$_help" | sed -n '/^Download:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g')
if [ -n "$_download" ];then
    [ -n "$table_downloads" ] && table_downloads+=$'\n'
    table_downloads+="$_download"
fi
export RCM_TABLE_DOWNLOADS="$table_downloads"

case "$rcm_operand" in
    *)
        INDENT+="    " BINARY_DIRECTORY="$BINARY_DIRECTORY" rcm${isfast}${isnoninteractive}${isverbose} $rcm_operand:$print_version -- "$@"
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
# --non-interactive
# )
# VALUE=(
# --mode
# --variation
# --dns-record
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
