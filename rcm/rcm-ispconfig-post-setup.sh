#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then domain="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --root-sure) root_sure=1; shift ;;
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
_() { echo -n "$INDENT" >&2; echo -n "#" "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "#" '    ' >&2; [ -n "$1" ] && echo "$@" >&2 || echo -n  >&2; }
____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

# Functions.
printVersion() {
    echo '0.9.6'
}
printHelp() {
    title ISPConfig Auto-Installer
    _ 'Variation '; yellow Post Setup; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << 'EOF'
Usage: rcm-ispconfig-post-setup [command] [options]

Options:
   --domain
        Set the domain to control. Values available from command: ispconfig.php(mail_domain).

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
   DKIM_SELECTOR
        Default to default.
   MAILBOX_POST
        Default to postmaster

Dependency:
   php
   ispconfig.php
   rcm-dig-is-record-exists
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-post-setup
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
backupDir() {
    local oldpath="$1" i newpath
    i=1
    newpath="${oldpath}.${i}"
    if [ -e "$newpath" ]; then
        let i++
        newpath="${oldpath}.${i}"
        while [ -e "$newpath" ] ; do
            let i++
            newpath="${oldpath}.${i}"
        done
    fi
    mv "$oldpath" "$newpath"
}
link_symbolic() {
    local source="$1"
    local target="$2"
    local sudo="$3"
    local source_mode="$4"
    local create
    [ "$sudo" == - ] && sudo=
    [ "$source_mode" == absolute ] || source_mode=
    [ -e "$source" ] || { error Source not exist: $source.; x; }
    [ -f "$source" ] || { error Source exists but not file: $source.; x; }
    [ -n "$target" ] || { error Target not defined.; x; }
    [[ $(type -t backupFile) == function ]] || { error Function backupFile not found.; x; }
    [[ $(type -t backupDir) == function ]] || { error Function backupDir not found.; x; }
    chapter Membuat symbolic link.
    __ source: '`'$source'`'
    __ target: '`'$target'`'
    if [ -f "$target" ];then
        if [ -h "$target" ];then
            __ Path target saat ini sudah merupakan file symbolic link: '`'$target'`'
            local _readlink=$(readlink "$target")
            __; magenta readlink "$target"; _.
            _ $_readlink; _.
            if [[ "$_readlink" =~ ^[^/\.] ]];then
                local target_parent=$(dirname "$target")
                local _dereference="${target_parent}/${_readlink}"
            elif [[ "$_readlink" =~ ^[\.] ]];then
                local target_parent=$(dirname "$target")
                local _dereference="${target_parent}/${_readlink}"
                _dereference=$(realpath -s "$_dereference")
            else
                _dereference="$_readlink"
            fi
            __; _, Mengecek apakah link merujuk ke '`'$source'`':' '
            if [[ "$source" == "$_dereference" ]];then
                _, merujuk.; _.
            else
                _, tidak merujuk.; _.
                __ Melakukan backup.
                backupFile move "$target"
                create=1
            fi
        else
            __ Melakukan backup regular file: '`'"$target"'`'.
            backupFile move "$target"
            create=1
        fi
    elif [ -d "$target" ];then
        __ Melakukan backup direktori: '`'"$target"'`'.
        backupDir "$target"
        create=1
    else
        create=1
    fi
    if [ -n "$create" ];then
        __ Membuat symbolic link: '`'$target'`'.
        local target_parent=$(dirname "$target")
        code mkdir -p "$target_parent"
        mkdir -p "$target_parent"
        if [ -z "$source_mode" ];then
            source=$(realpath -s --relative-to="$target_parent" "$source")
        fi
        if [ -n "$sudo" ];then
            code sudo -u '"'$sudo'"' ln -s '"'$source'"' '"'$target'"'
            sudo -u "$sudo" ln -s "$source" "$target"
        else
            code ln -s '"'$source'"' '"'$target'"'
            ln -s "$source" "$target"
        fi
        if [ $? -eq 0 ];then
            __; green Symbolic link berhasil dibuat.; _.
        else
            __; red Symbolic link gagal dibuat.; x
        fi
    fi
    ____
}
vercomp() {
    # https://www.google.com/search?q=bash+compare+version
    # https://stackoverflow.com/a/4025065
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]];then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}
remoteUserCredentialIspconfig() {
    local ISPCONFIG_REMOTE_USER_PASSWORD ISPCONFIG_REMOTE_USER_NAME
    local user="$1"
    local path=/usr/local/share/ispconfig/credential/remote/$user
    isFileExists "$path"
    [ -n "$notfound" ] && fileMustExists "$path"
    # Populate.
    . "$path"
    ispconfig_remote_user_name=$ISPCONFIG_REMOTE_USER_NAME
    ispconfig_remote_user_password=$ISPCONFIG_REMOTE_USER_PASSWORD
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

# Requirement, validate, and populate value.
chapter Dump variable.
DKIM_SELECTOR=${DKIM_SELECTOR:=default}
code 'DKIM_SELECTOR="'$DKIM_SELECTOR'"'
MAILBOX_POST=${MAILBOX_POST:=postmaster}
code 'MAILBOX_POST="'$MAILBOX_POST'"'
delay=.5; [ -n "$fast" ] && unset delay
if [ -z "$domain" ];then
    error "Argument --domain required."; x
fi
code 'domain="'$domain'"'
vercomp `stat --version | head -1 | grep -o -E '\S+$'` 8.31
if [[ $? -lt 2 ]];then
    stat_cached=' --cached=never'
else
    stat_cached=''
fi
____

current_fqdn=$(hostname -f 2>/dev/null)
mail_provider="$current_fqdn"
data="v=spf1 a:${mail_provider} ~all"
data_spf="$data"
chapter DNS TXT Record for SPF in $domain
_ ' - 'hostname:; _.
_ '   'value'   ':' '; magenta "$data"; _.
____

dns_record=$(INDENT+="    " rcm-ispconfig-control-manage-domain --fast --root-sure --ispconfig-soap-exists-sure --domain="$domain" get_dns_record 2>/dev/null)
data="v=DKIM1; t=s; p=${dns_record}"
data_dkim="$data"
chapter DNS TXT Record for DKIM in $domain
_ ' - 'hostname:' '; magenta "${DKIM_SELECTOR}._domainkey"; _.
_ '   'value'   ':' '; magenta "$data"; _.
____

email="${MAILBOX_POST}@${domain}"
data="v=DMARC1; p=none; rua=${email}"
data_dmarc="$data"
chapter DNS TXT Record for DMARC in $domain
email="${MAILBOX_POST}@${domain}"
_ ' - 'hostname:' '; magenta "_dmarc"; _.
_ '   'value'   ':' '; magenta "$data"; _.
____

chapter Watching Begin
__ Make sure all DNS Record '(TXT)' about SPF, DKIM, and DMARC is exist.
finish=
_ Begin: $(date +%Y%m%d-%H%M%S); _.
Rcm_BEGIN=$SECONDS
____

until [ -n "$finish" ];do
    _finish=""

    INDENT+="    " \
    rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
        --domain="$domain" \
        --type=txt \
        --hostname="@" \
        --value="$data_spf" \
        --value-summarize="SPF" \
    ; [ $? -eq 0 ] && _finish+="1"

    INDENT+="    " \
    rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
        --domain="$domain" \
        --type=txt \
        --hostname="${DKIM_SELECTOR}._domainkey" \
        --value="$data_dkim" \
        --value-summarize="DKIM" \
    ; [ $? -eq 0 ] && _finish+="1"

    INDENT+="    " \
    rcm-dig-is-record-exists $isfast --root-sure --name-exists-sure \
        --domain="$domain" \
        --type=txt \
        --hostname="_dmarc" \
        --value="$data_dmarc" \
        --value-summarize="DMARC" \
    ; [ $? -eq 0 ] && _finish+=1

    if [[ "$_finish" == 111 ]];then
        chapter Watching End
        success ALL of DNS Records already exist '(TXT)'.
        _ End: $(date +%Y%m%d-%H%M%S); _.
        Rcm_END=$SECONDS
        duration=$(( Rcm_END - Rcm_BEGIN ))
        hours=$((duration / 3600)); minutes=$(( (duration % 3600) / 60 )); seconds=$(( (duration % 3600) % 60 ));
        runtime=`printf "%02d:%02d:%02d" $hours $minutes $seconds`
        _ Duration: $runtime; if [ $duration -gt 60 ];then _, " (${duration} seconds)"; fi; _, '.'; _.
        finish=1
        ____
    else
        error All of DNS Record of '`'$domain'`' '(TXT) is not exists.'.
        _ We are still waiting.; _.
        sleepExtended 60
    fi
done
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
# --domain
# )
# CSV=(
# )
# EOF
# clear
