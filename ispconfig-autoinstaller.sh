#!/bin/bash

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
printVersion() {
    echo '0.2.2'
}
printHelp() {
    cat << EOF
ISPConfig Auto-Installer
https://github.com/ijortengab/ispconfig-autoinstaller
Version `printVersion`

EOF
    cat << 'EOF'
Usage: ispconfig-autoinstaller.sh

Options:
   --variation=n
        Auto select variation.
   --binary-directory-exists-sure
        Bypass binary directory checking.
   --
        Every arguments after double dash will pass to rcm-ispconfig-setup-variation${n}.sh command.
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
        Default to $__DIR__

Dependency:
   wget
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Dependency.
while IFS= read -r line; do
    command -v "${line}" >/dev/null || { echo -e "\e[91m""Unable to proceed, ${line} command not found." "\e[39m"; exit 1; }
done <<< `printHelp | sed -n '/^Dependency:/,$p' | sed -n '2,/^$/p' | sed 's/^ *//g'`

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
ArraySearch() {
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
RcmDownloader() {
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
    ## Bring back to the real filename.
    mv "$BINARY_DIRECTORY/rcm" "$BINARY_DIRECTORY/rcm.sh"
    cd "$BINARY_DIRECTORY"
    ln -sf rcm.sh rcm
    cd - >/dev/null
    fileMustExists "$BINARY_DIRECTORY/rcm"
    ____
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

# Prompt.
if [ -z "$fast" ];then
    yellow It is highly recommended that you use; _, ' ' ; magenta --fast; _, ' ' ; yellow option.; _.
    sleepExtended 2
    ____
fi

# Title.
title ISPConfig Auto-Installer
e https://github.com/ijortengab/ispconfig-autoinstaller
_ 'Version '; yellow `printVersion`; _.
____

# Requirement, validate, and populate value.
chapter Dump variable.
delay=.5; [ -n "$fast" ] && unset delay
__FILE__=$(resolve_relative_path "$0")
__DIR__=$(dirname "$__FILE__")
BINARY_DIRECTORY=${BINARY_DIRECTORY:=$__DIR__}
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
    RcmDownloader
fi

chapter Available:
eligible=()
_ 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 11 ]] && color=green || color=red; $color 1; _, . Debian 11, ISPConfig 3.2.7, PHPMyAdmin 5.2.0, Roundcube 1.6.0, PHP 7.4, DigitalOcean DNS. ; _.; eligible+=("1;debian;11")
_ 'Variation '; [[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 ]] && color=green || color=red; $color 2; _, . Ubuntu 22.04, ISPConfig 3.2.7, PHPMyAdmin 5.2.0, Roundcube 1.6.0, PHP 7.4, DigitalOcean DNS. ; _.; eligible+=("2;ubuntu;22.04")
_ 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 12 ]] && color=green || color=red; $color 3; _, . Debian 12, ISPConfig 3.2.10, PHPMyAdmin 5.2.1, Roundcube 1.6.2, PHP 8.1, DigitalOcean DNS. ; _.; eligible+=("3;debian;12")
_ 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 11 ]] && color=green || color=red; $color 4; _, . Debian 11, ISPConfig 3.2.11p2, PHPMyAdmin 5.2.1, Roundcube 1.6.6, PHP 8.1, Manual DNS. ; _.; eligible+=("4;debian;11")
_ 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 12 ]] && color=green || color=red; $color 5; _, . Debian 12, ISPConfig 3.2.11p2, PHPMyAdmin 5.2.1, Roundcube 1.6.6, PHP 8.3, Manual DNS. ; _.; eligible+=("5;debian;12")
____

if [ -n "$variation" ];then
    e Select variation: $variation
else
    until [[ -n "$variation" ]];do
        read -p "Select variation: " variation
        if ! ArraySearch "${variation};${ID};${VERSION_ID}" eligible[@];then
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
