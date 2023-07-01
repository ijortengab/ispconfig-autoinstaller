#!/bin/bash

# Prerequisite.
[ -f "$0" ] || { echo -e "\e[91m" "Cannot run as dot command. Hit Control+c now." "\e[39m"; read; exit 1; }

# Parse arguments. Generated by parse-options.sh
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --binary-directory-exists-sure) binary_directory_exists_sure=1; shift ;;
        --fast) fast=1; shift ;;
        --root-sure) root_sure=1; shift ;;
        --variation=*) variation="${1#*=}"; shift ;;
        --variation) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then variation="$2"; shift; fi; shift ;;
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

# Functions.
[[ $(type -t IspconfigAutoinstaller_printVersion) == function ]] || IspconfigAutoinstaller_printVersion() {
    echo '0.1.8'
}
[[ $(type -t IspconfigAutoinstaller_printHelp) == function ]] || IspconfigAutoinstaller_printHelp() {
    cat << EOF
ISPConfig Auto-Installer
https://github.com/ijortengab/ispconfig-autoinstaller
Version `IspconfigAutoinstaller_printVersion`

EOF
    cat << 'EOF'
Usage: ispconfig-autoinstaller.sh

Options:
   --variation=n
        Auto select variation.
   --binary-directory-exists-sure
        Bypass binary directory checking.
   --
        Every arguments after double dash will pass to gpl-ispconfig-setup-variation${n}.sh command.
        Example: ispconfig-autoinstaller.sh -- --timezone=Asia/Jakarta

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
   BINARY_DIRECTORY
        Default to $HOME/bin

Dependency:
   wget
EOF
}

# Help and Version.
[ -n "$help" ] && { IspconfigAutoinstaller_printHelp; exit 1; }
[ -n "$version" ] && { IspconfigAutoinstaller_printVersion; exit 1; }

# Dependency.
while IFS= read -r line; do
    command -v "${line}" >/dev/null || { echo -e "\e[91m""Unable to proceed, ${line} command not found." "\e[39m"; exit 1; }
done <<< `IspconfigAutoinstaller_printHelp | sed -n '/^Dependency:/,$p' | sed -n '2,/^$/p' | sed 's/^ *//g'`

# Common Functions.
[[ $(type -t red) == function ]] || red() { echo -ne "\e[91m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
[[ $(type -t green) == function ]] || green() { echo -ne "\e[92m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
[[ $(type -t yellow) == function ]] || yellow() { echo -ne "\e[93m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
[[ $(type -t blue) == function ]] || blue() { echo -ne "\e[94m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
[[ $(type -t magenta) == function ]] || magenta() { echo -ne "\e[95m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
[[ $(type -t error) == function ]] || error() { echo -n "$INDENT" >&2; red "$@" >&2; echo >&2; }
[[ $(type -t success) == function ]] || success() { echo -n "$INDENT" >&2; green "$@" >&2; echo >&2; }
[[ $(type -t chapter) == function ]] || chapter() { echo -n "$INDENT" >&2; yellow "$@" >&2; echo >&2; }
[[ $(type -t title) == function ]] || title() { echo -n "$INDENT" >&2; blue "$@" >&2; echo >&2; }
[[ $(type -t code) == function ]] || code() { echo -n "$INDENT" >&2; magenta "$@" >&2; echo >&2; }
[[ $(type -t x) == function ]] || x() { echo >&2; exit 1; }
[[ $(type -t e) == function ]] || e() { echo -n "$INDENT" >&2; echo "$@" >&2; }
[[ $(type -t _) == function ]] || _() { echo -n "$INDENT" >&2; echo -n "$@" >&2; }
[[ $(type -t _,) == function ]] || _,() { echo -n "$@" >&2; }
[[ $(type -t _.) == function ]] || _.() { echo >&2; }
[[ $(type -t __) == function ]] || __() { echo -n "$INDENT" >&2; echo -n '    ' >&2; [ -n "$1" ] && echo "$@" >&2 || echo -n  >&2; }
[[ $(type -t ____) == function ]] || ____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

# Functions.
[[ $(type -t fileMustExists) == function ]] || fileMustExists() {
    # global used:
    # global modified:
    # function used: __, success, error, x
    if [ -f "$1" ];then
        __; green File '`'$(basename "$1")'`' ditemukan.; _.
    else
        __; red File '`'$(basename "$1")'`' tidak ditemukan.; x
    fi
}
[[ $(type -t ArraySearch) == function ]] || ArraySearch() {
    # Find element in Array. Searches the array for a given value and returns the
    # first corresponding key if successful.
    #
    # Globals:
    #   Modified: _return
    #
    # Arguments:
    #   1 = The searched value.
    #   2 = Parameter of the array.
    #
    # Returns:
    #   0 if value found in the array.
    #   1 otherwise.
    #
    # Example:
    #   ```
    #   my=("cherry" "manggo" "blackberry" "manggo" "blackberry")
    #   ArraySearch "manggo" my[@]
    #   if ArraySearch "blackberry" my[@];then
    #       echo 'FOUND'
    #   else
    #       echo 'NOT FOUND'
    #   fi
    #   # Get result in variable `$_return`.
    #   # _return=2
    #   ```
    local index match="$1"
    local source=("${!2}")
    for index in "${!source[@]}"; do
       if [[ "${source[$index]}" == "${match}" ]]; then
           _return=$index; return 0
       fi
    done
    return 1
}
[[ $(type -t IspconfigAutoinstaller_RcmDownloader) == function ]] || IspconfigAutoinstaller_RcmDownloader() {
    chapter RCM Downloader.
    if [[ -f "$BINARY_DIRECTORY/rcm" && ! -s "$BINARY_DIRECTORY/rcm" ]];then
        __ Empty file detected.
        __; magenta rm "$BINARY_DIRECTORY/rcm"; _.
        rm "$BINARY_DIRECTORY/rcm"
    fi
    if [ ! -f "$BINARY_DIRECTORY/rcm" ];then
        __ Memulai download.
        __; magenta wget git.io/rcm; _.
        wget -q git.io/rcm -O "$BINARY_DIRECTORY/rcm"
        if [ ! -s "$BINARY_DIRECTORY/rcm" ];then
            __; magenta rm "$BINARY_DIRECTORY/rcm"; _.
            rm "$BINARY_DIRECTORY/rcm"
            __; red HTTP Response: 404 Not Found; x
        fi
        __; magenta chmod a+x "$BINARY_DIRECTORY/rcm"; _.
        chmod a+x "$BINARY_DIRECTORY/rcm"
    elif [[ ! -x "$BINARY_DIRECTORY/rcm" ]];then
        __; magenta chmod a+x "$BINARY_DIRECTORY/rcm"; _.
        chmod a+x "$BINARY_DIRECTORY/rcm"
    fi
    fileMustExists "$BINARY_DIRECTORY/rcm"
    ____
}

# Prompt.
if [ -z "$fast" ];then
    yellow It is highly recommended that you use; _, ' ' ; magenta --fast; _, ' ' ; yellow option.; _.
    countdown=5
    while [ "$countdown" -ge 0 ]; do
        printf "\r\033[K" >&2
        printf %"$countdown"s | tr " " "." >&2
        printf "\r"
        countdown=$((countdown - 1))
        sleep .8
    done
    ____
fi

# Title.
title ISPConfig Auto-Installer
e https://github.com/ijortengab/ispconfig-autoinstaller
_ 'Version '; yellow `IspconfigAutoinstaller_printVersion`; _.
____

# Requirement, validate, and populate value.
chapter Dump variable.
delay=.5; [ -n "$fast" ] && unset delay
BINARY_DIRECTORY=${BINARY_DIRECTORY:=$HOME/bin}
code 'BINARY_DIRECTORY="'$BINARY_DIRECTORY'"'
code 'variation="'$variation'"'
if [ -f /etc/os-release ];then
    . /etc/os-release
fi
code 'ID="'$ID'"'
code 'VERSION_ID="'$VERSION_ID'"'
code '-- '"$@"
____

if [ -z "$root_sure" ];then
    chapter Mengecek akses root.
    if [[ "$EUID" -ne 0 ]]; then
        error This script needs to be run with superuser privileges.; x
    else
        __ Privileges.; root_sure=1
    fi
    ____
fi

if [ -z "$binary_directory_exists_sure" ];then
    chapter Mempersiapkan directory binary.
    __; code BINARY_DIRECTORY=$BINARY_DIRECTORY
    notfound=
    if [ -d "$BINARY_DIRECTORY" ];then
        __ Direktori '`'$BINARY_DIRECTORY'`' ditemukan.
        binary_directory_exists_sure=1
    else
        __ Direktori '`'$BINARY_DIRECTORY'`' tidak ditemukan.
        notfound=1
    fi
    ____

    if [ -n "$notfound" ];then
        chapter Membuat directory.
        mkdir -p "$BINARY_DIRECTORY"
        if [ -d "$BINARY_DIRECTORY" ];then
            __; green Direktori '`'$BINARY_DIRECTORY'`' ditemukan.; _.
            binary_directory_exists_sure=1
        else
            __; red Direktori '`'$BINARY_DIRECTORY'`' tidak ditemukan.; x
        fi
        ____
    fi
fi

PATH="${BINARY_DIRECTORY}:${PATH}"

chapter Requires command.
_ Requires command: rcm
if command -v rcm > /dev/null;then
    _, ' [FOUND].'; _.
    ____
else
    _, ' [NOTFOUND].'; _.
    ____
    IspconfigAutoinstaller_RcmDownloader
fi

chapter Available:
eligible=()
_ 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 11 ]] && color=green || color=red; $color 1; _, . Debian 11, ISPConfig 3.2.7, PHPMyAdmin 5.2.0, Roundcube 1.6.0, PHP 7.4, DigitalOcean DNS. ; _.; eligible+=("1debian11")
_ 'Variation '; [[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 ]] && color=green || color=red; $color 2; _, . Ubuntu 22.04, ISPConfig 3.2.7, PHPMyAdmin 5.2.0, Roundcube 1.6.0, PHP 7.4, DigitalOcean DNS. ; _.; eligible+=("2ubuntu22.04")
____

if [ -n "$variation" ];then
    e Select variation: $variation
else
    until [[ -n "$variation" ]];do
        read -p "Select variation: " variation
        if ! ArraySearch "${variation}${ID}${VERSION_ID}" eligible[@];then
            error Not eligible.
            variation=
        fi
    done
fi
____

chapter Execute:
[ -n "$fast" ] && isfast=' --fast' || isfast=''
code rcm${isfast} rcm-ispconfig-setup-variation${variation}.sh -- "$@"
____
_ _______________________________________________________________________;_.;_.;

INDENT+="    "
command -v "rcm" >/dev/null || { error "Unable to proceed, rcm command not found."; x; }
INDENT="$INDENT" rcm${isfast} rcm-ispconfig-setup-variation${variation}.sh --root-sure --binary-directory-exists-sure -- "$@"
INDENT=${INDENT::-4}
_ _______________________________________________________________________;_.;_.;

# parse-options.sh \
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
# --binary-directory-exists-sure
# )
# VALUE=(
# --variation
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# CSV=(
# )
# EOF
# clear
