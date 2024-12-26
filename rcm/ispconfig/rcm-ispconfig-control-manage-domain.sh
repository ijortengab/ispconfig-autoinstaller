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
        --get-domain-id) get_domain_id=1; shift ;;
        --ispconfig-soap-exists-sure) ispconfig_soap_exists_sure=1; shift ;;
        --root-sure) root_sure=1; shift ;;
        --[^-]*) shift ;;
        *) _new_arguments+=("$1"); shift ;;
    esac
done
set -- "${_new_arguments[@]}"
unset _new_arguments

# Command.
if [ -n "$1" ];then
    case "$1" in
        get-dns-record|get-domain-id) command="$1"; shift ;;
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
____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

# Functions.
printVersion() {
    echo '0.9.10'
}
printHelp() {
    title RCM ISPConfig Control
    _ 'Variation '; yellow Manage Domain; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-control-manage-domain [command] [options]

Available commands: get-dns-record.

Options:
   --domain
        Set the domain to control.

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
   MAILBOX_WEB
        Default to webmaster
   ISPCONFIG_REMOTE_USER_ROOT
        Default to root
   ISPCONFIG_FQDN_LOCALHOST
        Default to ispconfig.localhost

Dependency:
   rcm-ispconfig:`printVersion`
   rcm-php-ispconfig:`printVersion`
   rcm-ispconfig-control-manage-client:`printVersion`

Download:
   [rcm-ispconfig](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/rcm-ispconfig.sh)
   [rcm-php-ispconfig](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/php/rcm-php-ispconfig.php)
   [rcm-ispconfig-control-manage-client](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-client.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Functions before execute command.
command-get-dns-record() {
    # global $domain, $tempfile
    if [ -z "$domain" ];then
        error "Argument --domain required."; x
    fi
    local tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-control-manage-domain.XXXXXX)
    code rcm-php-ispconfig soap --empty-array-is-false mail_domain_get_by_domain '"'$domain'"'
    rcm-php-ispconfig soap --empty-array-is-false mail_domain_get_by_domain "$domain" 2>&1 &> "$tempfile"
    local exit_code=$?
    if [ $exit_code -eq 0 ];then
        dkim_public=$(rcm-php-ispconfig echo [0][dkim_public] < "$tempfile")
        dns_record=$(echo "$dkim_public" | sed -e "/-----BEGIN PUBLIC KEY-----/d" -e "/-----END PUBLIC KEY-----/d" | tr '\r' ' '  | tr '\n' ' ' | sed 's/\ //g')
        echo "$dns_record"
    else
        while IFS= read line; do e "$line"; _.; done < "$tempfile"
    fi
    rm "$tempfile"
}
command-get-domain-id() {
    # global $domain, $tempfile
    if [ -z "$domain" ];then
        error "Argument --domain required."; x
    fi
    local tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-control-manage-domain.XXXXXX)
    code rcm-php-ispconfig soap --empty-array-is-false mail_domain_get_by_domain '"'$domain'"'
    rcm-php-ispconfig soap --empty-array-is-false mail_domain_get_by_domain "$domain" 2>&1 &> "$tempfile"
    local exit_code=$?
    if [ $exit_code -eq 0 ];then
        rcm-php-ispconfig echo [0][domain_id] < "$tempfile"
    else
        while IFS= read line; do e "$line"; _.; done < "$tempfile"
    fi
    rm "$tempfile"
}

# Execute command.
if [[ -n "$command" && $(type -t "command-${command}") == function ]];then
    command-${command} "$@"
    exit 0
fi

# Title.
title rcm-ispconfig-control-manage-domain
____

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'$line'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Validation and bypass validation. Validation after title.
if [ -z "$root_sure" ];then
    chapter Mengecek akses root.
    if [[ "$EUID" -ne 0 ]]; then
        error This script needs to be run with superuser privileges.; x
    else
        __ Privileges.
    fi
    ____
fi

# Functions. Functions after title. For main command.
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
backupDir() {
    local oldpath="$1" i newpath
    # Trim trailing slash.
    oldpath=$(echo "$oldpath" | sed -E 's|/+$||g')
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
isExists() {
    # global $domain, $tempfile
    # global modified $domain_id
    [ -n "$domain" ] || { error Variable domain is required; x; }
    [ -n "$tempfile" ] || { error Variable tempfile is required; x; }

    code rcm-php-ispconfig soap --empty-array-is-false mail_domain_get_by_domain '"'$domain'"'
    rcm-php-ispconfig soap --empty-array-is-false mail_domain_get_by_domain "$domain" 2>&1 &> "$tempfile"
    local exit_code=$?
    if [ $exit_code -eq 0 ];then
        domain_id=$(rcm-php-ispconfig echo [0][domain_id] < "$tempfile")
        __; magenta domain_id=$domain_id; _.
    else
        while IFS= read line; do e "$line"; _.; done < "$tempfile"
    fi
    return $exit_code
}
create() {
    # global $domain, $email, $tempfile
    # global modified $client_id
    [ -n "$domain" ] || { error Variable domain is required; x; }
    [ -n "$tempfile" ] || { error Variable tempfile is required; x; }

    ____; client_id=$(INDENT+="    " rcm-ispconfig-control-manage-client $isfast --username "$domain" --email "${MAILBOX_ADMIN}@${domain}" --root-sure --ispconfig-soap-exists-sure --get-client-id -- --limit-mailaliasdomain=0 --limit-mailaliasdomain=0 --limit-maildomain=1 --startmodule=mail)
    code 'client_id="'$client_id'"'
    [ -n "$client_id" ] || { client_id=0; code 'client_id="'$client_id'"'; }

    ____; json=$(INDENT+="    " rcm-ispconfig generate-key --domain "$domain")
    dkim_private=$(php -r "echo (json_decode(fgets(STDIN)))->dkim_private;" <<< "$json")
    dkim_public=$(php -r "echo (json_decode(fgets(STDIN)))->dkim_public;" <<< "$json")
    dns_record=$(php -r "echo (json_decode(fgets(STDIN)))->dns_record;" <<< "$json")
    if [ -z "$dns_record" ];then
        __; red DNS record not found.; x
    fi
    # Terpaksa menggunakan echo karena common function tidak ada yg bisa handle
    # new line.
    e; magenta 'dkim_private="'; echo -n "$dkim_private" >&2; magenta '"'; _.
    e; magenta 'dkim_public="'; echo -n "$dkim_public" >&2; magenta '"'; _.
    code rcm-php-ispconfig soap mail_domain_add '"'$client_id'"' --server-id='"'1'"' --domain='"'$domain'"' --active='"'y'"' --dkim=y --dkim-selector='"'$DKIM_SELECTOR'"' --dkim-private='"'\$dkim_private'"' --dkim-public='"'\$dkim_public'"' "$@"
    rcm-php-ispconfig soap mail_domain_add "$client_id" --server-id="1" --domain="$domain" --active="y" --dkim=y --dkim-selector="$DKIM_SELECTOR" --dkim-private="$dkim_private" --dkim-public="$dkim_public" "$@" 2>&1 &> "$tempfile"
    local exit_code=$?
    if [ $exit_code -eq 0 ];then
        domain_id=$(cat "$tempfile" | rcm-php-ispconfig echo)
        __; magenta domain_id=$domain_id; _.
    else
        while IFS= read line; do e "$line"; _.; done < "$tempfile"
    fi
    return $exit_code
}

# Requirement, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
MAILBOX_ADMIN=${MAILBOX_ADMIN:=admin}
code 'MAILBOX_ADMIN="'$MAILBOX_ADMIN'"'
DKIM_SELECTOR=${DKIM_SELECTOR:=default}
code 'DKIM_SELECTOR="'$DKIM_SELECTOR'"'
MAILBOX_WEB=${MAILBOX_WEB:=webmaster}
code 'MAILBOX_WEB="'$MAILBOX_WEB'"'
ISPCONFIG_REMOTE_USER_ROOT=${ISPCONFIG_REMOTE_USER_ROOT:=root}
code 'ISPCONFIG_REMOTE_USER_ROOT="'$ISPCONFIG_REMOTE_USER_ROOT'"'
ISPCONFIG_FQDN_LOCALHOST=${ISPCONFIG_FQDN_LOCALHOST:=ispconfig.localhost}
code 'ISPCONFIG_FQDN_LOCALHOST="'$ISPCONFIG_FQDN_LOCALHOST'"'
delay=.5; [ -n "$fast" ] && unset delay
if [ -z "$domain" ];then
    error "Argument --domain required."; x
fi
code 'domain="'$domain'"'
code 'ispconfig_soap_exists_sure="'$ispconfig_soap_exists_sure'"'
tempfile=
vercomp `stat --version | head -1 | grep -o -E '\S+$'` 8.31
if [[ $? -lt 2 ]];then
    stat_cached=' --cached=never'
else
    stat_cached=''
fi
____

if [ -z "$ispconfig_soap_exists_sure" ];then
    chapter Test koneksi SOAP.
    code rcm-php-ispconfig soap login
    if [ -z "$tempfile" ];then
        tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-control-manage-domain.XXXXXX)
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

chapter Autocreate domain '`'$domain'`' di Module Mail ISPConfig.
if [ -z "$tempfile" ];then
    tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-control-manage-domain.XXXXXX)
fi
if isExists;then
    __ Domain '`'$domain'`' telah terdaftar di ISPConfig.
elif create "$@";then
    success Domain '`'$domain'`' berhasil terdaftar di ISPConfig.
else
    error Domain '`'$domain'`' gagal terdaftar di ISPConfig.; x
fi
____

chapter Membuat welcome mail.
php_fpm_user=ispconfig
code 'php_fpm_user="'$php_fpm_user'"'
prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
code 'prefix="'$prefix'"'
code mkdir -p '/usr/local/share/ispconfig/mail'
mkdir -p '/usr/local/share/ispconfig/mail'
source="/usr/local/share/ispconfig/mail/welcome_email_${domain}.html"
code 'source="'$source'"'
cat <<- EOF > "$source"
From: Webmaster <$MAILBOX_WEB@$domain>
Subject: Welcome to your new email account.

<p>Welcome to your new email account. Your webmaster.</p>

EOF
target="${prefix}/server/conf-custom/mail/welcome_email_${domain}.html"
code 'target="'$target'"'
____

link_symbolic "$source" "$target" - absolute
____

# Bedanya command get-domain-id dengan --get-domain-id
# Command get-domain-id jika tidak exists, maka null.
# Jika option --get-domain-id, maka jika tidak exists, akan dibuat dulu.
if [ -n "$get_domain_id" ];then
    echo "$domain_id"
fi

[ -n "$tempfile" ] && rm "$tempfile"

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
# --ispconfig-soap-exists-sure
# --get-domain-id
# )
# VALUE=(
# --domain
# )
# CSV=(
# )
# EOF
# clear
