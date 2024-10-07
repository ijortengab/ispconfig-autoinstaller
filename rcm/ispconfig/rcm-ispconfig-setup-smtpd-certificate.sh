#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --certbot-authenticator=*) certbot_authenticator="${1#*=}"; shift ;;
        --certbot-authenticator) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then certbot_authenticator="$2"; shift; fi; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then domain="$2"; shift; fi; shift ;;
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
e() { echo -n "$INDENT" >&2; echo "#" "$@" >&2; }
_() { echo -n "$INDENT" >&2; echo -n "#" "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "#" '    ' >&2; [ -n "$1" ] && echo "$@" >&2 || echo -n  >&2; }
____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

# Functions.
printVersion() {
    echo '0.9.3'
}
printHelp() {
    title RCM ISPConfig Setup
    _ 'Variation '; yellow SMTPD Certificate; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << 'EOF'
Usage: rcm-ispconfig-setup-smtpd-certificate [options]

Options:
   --domain *
        Set the domain.
   --certbot-authenticator *
        Available value: digitalocean, nginx.

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
   MAILBOX_HOST
        Default to hostmaster

Dependency:
   rcm-certbot-obtain-authenticator-nginx
   rcm-certbot-obtain-authenticator-digitalocean
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { echo -e "\e[91m""Unable to proceed, "'`'"${line}"'`'" command not found." "\e[39m"; exit 1; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Functions.
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
link_symbolic() {
    local source="$1"
    local target="$2"
    local sudo="$3"
    local create
    _success=
    [ -e "$source" ] || { error Source not exist: $source.; x; }
    [ -n "$target" ] || { error Target not defined.; x; }
    [[ $(type -t backupFile) == function ]] || { error Function backupFile not found.; x; }

    chapter Membuat symbolic link.
    __ source: '`'$source'`'
    __ target: '`'$target'`'
    if [ -h "$target" ];then
        __ Path target saat ini sudah merupakan symbolic link: '`'$target'`'
        __; _, Mengecek apakah link merujuk ke '`'$source'`':
        _dereference=$(stat ${stat_cached} "$target" -c %N)
        match="'$target' -> '$source'"
        if [[ "$_dereference" == "$match" ]];then
            _, ' 'Merujuk.; _.
        else
            _, ' 'Tidak merujuk.; _.
            __ Melakukan backup.
            backupFile move "$target"
            create=1
        fi
    elif [ -e "$target" ];then
        __ File/directory bukan merupakan symbolic link.
        __ Melakukan backup.
        backupFile move "$target"
        create=1
    else
        create=1
    fi
    if [ -n "$create" ];then
        __ Membuat symbolic link '`'$target'`'.
        if [ -n "$sudo" ];then
            __; magenta sudo -u '"'$sudo'"' ln -s '"'$source'"' '"'$target'"'; _.
            sudo -u "$sudo" ln -s "$source" "$target"
        else
            __; magenta ln -s '"'$source'"' '"'$target'"'; _.
            ln -s "$source" "$target"
        fi
        __ Verifikasi
        if [ -h "$target" ];then
            _dereference=$(stat ${stat_cached} "$target" -c %N)
            match="'$target' -> '$source'"
            if [[ "$_dereference" == "$match" ]];then
                __; green Symbolic link berhasil dibuat.; _.
                _success=1
            else
                __; red Symbolic link gagal dibuat.; x
            fi
        fi
    fi
    ____
}

# Title.
title rcm-ispconfig-setup-smtpd-certificate
____

# Require, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
delay=.5; [ -n "$fast" ] && unset delay
MAILBOX_HOST=${MAILBOX_HOST:=hostmaster}
code 'MAILBOX_HOST="'$MAILBOX_HOST'"'
if [ -z "$domain" ];then
    error "Argument --domain required."; x
fi
code 'domain="'$domain'"'
if [ -z "$certbot_authenticator" ];then
    error "Argument --certbot-authenticator required."; x
fi
case "$certbot_authenticator" in
    digitalocean) ;;
    nginx) ;;
    *) certbot_authenticator=
esac
if [ -z "$certbot_authenticator" ];then
    error "Argument --certbot-authenticator is not valid.";
    _ Available value:' '; yellow digitalocean; _, ', '; yellow nginx; _, .; _.
    x
fi
code 'certbot_authenticator="'$certbot_authenticator'"'
certificate_name="$domain"
code 'certificate_name="'$certificate_name'"'
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

if [[ "$certbot_authenticator" == 'digitalocean' ]]; then
    INDENT+="    " \
    rcm-certbot-obtain-authenticator-digitalocean $isfast --root-sure \
        --certbot-dns-digitalocean-sure \
        --domain="$domain" \
        ; [ ! $? -eq 0 ] && x
    # @todo, cek harusnya parent sudah validate certbot-dns-digitalocean
    # sehingga bisa kita kasih option --certbot-dns-digitalocean-sure
elif [[ "$certbot_authenticator" == 'nginx' ]]; then
    INDENT+="    " \
    rcm-certbot-obtain-authenticator-nginx $isfast --root-sure \
        --domain="$domain" \
        ; [ ! $? -eq 0 ] && x
fi

restart=
link_symbolic "/etc/letsencrypt/live/${certificate_name}/fullchain.pem" \
    /etc/postfix/smtpd.cert
[ -n "$_success" ] && restart=1
link_symbolic "/etc/letsencrypt/live/${certificate_name}/privkey.pem" \
    /etc/postfix/smtpd.key
[ -n "$_success" ] && restart=1
if [ -n "$restart" ];then
    chapter Restart Postfix
    code systemctl restart postfix
    systemctl restart postfix
    ____
fi

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
# --certbot-authenticator
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# CSV=(
# )
# EOF
# clear
