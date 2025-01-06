#!/bin/bash

# Parse arguments. Generated by parse-options.sh._new_arguments=()
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --email=*) email="${1#*=}"; shift ;;
        --email) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then email="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --get-client-id) get_client_id=1; shift ;;
        --ispconfig-soap-exists-sure) ispconfig_soap_exists_sure=1; shift ;;
        --password=*) password="${1#*=}"; shift ;;
        --password) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then password="$2"; shift; fi; shift ;;
        --username=*) username="${1#*=}"; shift ;;
        --username) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then username="$2"; shift; fi; shift ;;
        --) shift
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

# Command.
if [ -n "$1" ];then
    case "$1" in
        get-client-id) command="$1"; shift ;;
    esac
fi

# Functions.
resolve_relative_path() {
    if [ -d "$1" ];then
        cd "$1" || return 1
        pwd
    elif [ -e "$1" ];then
        if [ ! "${1%/*}" = "$1" ]; then
            cd "${1%/*}" || return 1
        fi
        echo "$(pwd)/${1##*/}"
    else
        return 1
    fi
}
userInputBooleanDefaultYes() {
    __;  _, '['; yellow Enter; _, ']'; _, ' '; yellow Y; _, 'es and continue.'; _.
    __;  _, '['; yellow Esc; _, ']'; _, ' '; yellow N; _, 'o and skip.'; _.
    boolean=
    while true; do
        __; read -rsn 1 -p "Select: " char
        if [ -z "$char" ];then
            char=y
        fi
        case $char in
            y|Y) echo "$char"; boolean=1; break;;
            n|N) echo "$char"; break ;;
            $'\33') echo "n"; break ;;
            *) echo
        esac
    done
}

# Functions.
printVersion() {
    echo '0.9.12'
}
printHelp() {
    title RCM ISPConfig Control
    _ 'Variation '; yellow Manage Client; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-control-manage-client [command] [options]
       rcm-ispconfig-control-manage-client get-client-id --username=<username>

Available commands: get-client-id.

Options:
   --username *
        Set the username.
   --email *
        Set the email.
   --password
        Set the password.
        Leave blank to autogenerate password.
   --
        Every arguments after double dash will pass to \`rcm-php-ispconfig soap client_add\` command.

Other Options:
   --ispconfig-soap-exists-sure
        By pass test connect to the SOAP server.
   --get-client-id
        Print client_id to STDOUT.

Options for command get-client-id:
   --username *
        Set the username.

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.

Dependency:
   pwgen
   rcm-php-ispconfig:`printVersion`

Download:
   [rcm-php-ispconfig](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/php/rcm-php-ispconfig.php)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Functions before execute command.
command-get-client-id() {
    # global $username
    title rcm-ispconfig-control-manage-client get-client-id
    ____

    if [ -z "$username" ];then
        error "Argument --username required."; x
    fi
    local tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-control-manage-client.XXXXXX)
    code rcm-php-ispconfig soap client_get_by_username '"'$username'"'
    rcm-php-ispconfig soap client_get_by_username "$username" 2>&1 &> "$tempfile"
    local exit_code=$?
    if [ $exit_code -eq 0 ];then
        client_id=$(rcm-php-ispconfig echo [client_id] < "$tempfile")
        echo $client_id
    else
        while IFS= read line; do e "$line"; _.; done < "$tempfile"
    fi
    rm "$tempfile"
    ____
}

# Execute command.
if [[ -n "$command" && $(type -t "command-${command}") == function ]];then
    command-${command} "$@"
    exit 0
fi

# Title.
title rcm-ispconfig-control-manage-client
____

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'`cut -d: -f1 <<< "${line}"`'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Functions.
websiteCredentialIspconfig() {
    # global $username
    # global modified $password
    [ -n "$username" ] || { error Variable username is required; x; }
    local path="/usr/local/share/ispconfig/credential/client/${username}"
    local dirname="/usr/local/share/ispconfig/credential/client"
    __; magenta 'path="'$path'"'; _.
    if [ -z "$password" ];then
        password=$(pwgen 9 -1vA0B)
    fi
    if [ -f "$path" ];then
        local _password=$(<"$path")
        if [[ ! "$_password" == "$password" ]];then
            echo "$password" > "$path"
        fi
    else
        mkdir -p "$dirname"
        echo "$password" > "$path"
        chmod 0500 "$dirname"
        chmod 0400 "$path"
    fi
}
isExists() {
    # global $username, $tempfile
    # global modified $client_id
    [ -n "$username" ] || { error Variable username is required; x; }
    [ -n "$tempfile" ] || { error Variable tempfile is required; x; }

    code rcm-php-ispconfig soap client_get_by_username '"'$username'"'
    rcm-php-ispconfig soap client_get_by_username "$username" 2>&1 &> "$tempfile"
    local exit_code=$?
    if [ $exit_code -eq 0 ];then
        client_id=$(rcm-php-ispconfig echo [client_id] < "$tempfile")
        __; magenta client_id=$client_id; _.
    else
        while IFS= read line; do e "$line"; _.; done < "$tempfile"
    fi
    return $exit_code
}
create() {
    # global $username, $email, $tempfile
    # global modified $client_id
    [ -n "$username" ] || { error Variable username is required; x; }
    [ -n "$email" ] || { error Variable email is required; x; }
    [ -n "$tempfile" ] || { error Variable tempfile is required; x; }
    websiteCredentialIspconfig
    __; magenta 'password="'$password'"'; _.
    code rcm-php-ispconfig soap client_add '"'$username'"' --email='"'$email'"' --username='"'$username'"' --password='"'$password'"' "$@"
    rcm-php-ispconfig soap client_add --email="$email" --username="$username" --password="$password" "$@" 2>&1 &> "$tempfile"
    local exit_code=$?
    if [ $exit_code -eq 0 ];then
        client_id=$(cat "$tempfile" | rcm-php-ispconfig echo)
        __; magenta client_id=$client_id; _.
    else
        while IFS= read line; do e "$line"; _.; done < "$tempfile"
    fi
    return $exit_code
}

# Requirement, validate, and populate value.
chapter Dump variable.
if [ -z "$username" ];then
    error "Argument --username required."; x
fi
code 'username="'$username'"'
code 'password="'$password'"'
if [ -z "$email" ];then
    error "Argument --email required."; x
fi
code 'email="'$email'"'
code 'ispconfig_soap_exists_sure="'$ispconfig_soap_exists_sure'"'
tempfile=
____

if [ -z "$ispconfig_soap_exists_sure" ];then
    chapter Test koneksi SOAP.
    code rcm-php-ispconfig soap login
    if [ -z "$tempfile" ];then
        tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-control-manage-client.XXXXXX)
    fi
    if rcm-php-ispconfig soap login 2> "$tempfile";then
        while IFS= read line; do e "$line"; _.; done < "$tempfile"
        __ Login berhasil.
    else
        rm "$tempfile"
        error Login gagal; x
    fi
    ____
fi

chapter Autocreate client '`'$username'`' di Module Client ISPConfig.
if [ -z "$tempfile" ];then
    tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-control-manage-client.XXXXXX)
fi
if isExists;then
    __ Client '`'$username'`' telah terdaftar di ISPConfig.
elif create "$@";then
    success Client '`'$username'`' berhasil terdaftar di ISPConfig.
else
    error Client '`'$username'`' gagal terdaftar di ISPConfig.; x
fi
____

# Bedanya command get-client-id dengan --get-client-id
# Command get-client-id jika tidak exists, maka null.
# Jika option --get-client-id, maka jika tidak exists, akan dibuat dulu.
if [ -n "$get_client_id" ];then
    echo "$client_id"
fi

[ -n "$tempfile" ] && rm "$tempfile"

exit 0

# parse-options.sh \
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
# --ispconfig-soap-exists-sure
# --get-client-id
# )
# VALUE=(
# --username
# --password
# --email
# )
# CSV=(
# )
# EOF
# clear
