#!/bin/bash

# Parse arguments. Generated by parse-options.sh
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --digitalocean-domain-exists-sure) digitalocean_domain_exists_sure=1; shift ;;
        --dns-record=*) dns_record="${1#*=}"; shift ;;
        --dns-record) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then dns_record="$2"; shift; fi; shift ;;
        --dns-record-auto) dns_record_auto=1; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then domain="$2"; shift; fi; shift ;;
        --email=*) email="${1#*=}"; shift ;;
        --email) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then email="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --hostname=*) hostname="${1#*=}"; shift ;;
        --hostname) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then hostname="$2"; shift; fi; shift ;;
        --ip-address=*) ip_address="${1#*=}"; shift ;;
        --ip-address) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then ip_address="$2"; shift; fi; shift ;;
        --ispconfig-domain-exists-sure) ispconfig_domain_exists_sure=1; shift ;;
        --mail-provider=*) mail_provider="${1#*=}"; shift ;;
        --mail-provider) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then mail_provider="$2"; shift; fi; shift ;;
        --type=*) type="${1#*=}"; shift ;;
        --type) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then type="$2"; shift; fi; shift ;;
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
__() { echo -n "$INDENT" >&2; echo -n "# ${RCM_INDENT}" >&2; [ -n "$1" ] && echo "$@" >&2; }
____() { echo >&2; [ -n "$RCM_DELAY" ] && sleep "$RCM_DELAY"; }

# Define variables and constants.
RCM_DELAY=${RCM_DELAY:=.5}; [ -n "$fast" ] && unset RCM_DELAY
RCM_INDENT='    '; [ "$(tput cols)" -le 80 ] && RCM_INDENT='  '
DKIM_SELECTOR=${DKIM_SELECTOR:=default}

# Functions.
printVersion() {
    echo '0.9.22'
}
printHelp() {
    title RCM ISPConfig Setup
    _ 'Variation '; yellow Wrapper DigitalOcean; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-setup-wrapper-digitalocean [options]

Options:
   --domain
        Set the domain name.
   --hostname
        Set the hostname.
   --type
        Available value: spf, dkim, dmarc.
   --mail-provider
        Required by SPF.
   --email
        Required by DMARC.
   --dns-record
        Required by DKIM.
   --dns-record-auto ^
        Get DNS record automatically.
   --ispconfig-domain-exists-sure ^
        Bypass domain exists checking by ISPConfig SOAP.
   --digitalocean-domain-exists-sure ^
        Bypass domain exists checking by DigitalOcean API.

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.

Environment Variables:
   DKIM_SELECTOR
        Default to $DKIM_SELECTOR

Dependency:
   rcm-ispconfig-control-manage-domain:`printVersion`
   rcm-digitalocean-api-manage-domain
   php

Download:
   [rcm-ispconfig-control-manage-domain](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-domain.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-setup-wrapper-digitalocean
____

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'`cut -d: -f1 <<< "${line}"`'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Requirement, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
code 'DKIM_SELECTOR="'$DKIM_SELECTOR'"'
code 'action="'$action'"'
case "$type" in
    spf|dkim|dmarc) ;;
    *) type=
esac
until [[ -n "$type" ]];do
    _ Available value:' '; yellow spf, dkim, dmarc.; _.
    _; read -p "Argument --type required: " type
    case "$type" in
        spf|dkim|dmarc) ;;
        *) type=
    esac
done
code 'type="'$type'"'
case "$type" in
    spf)
        until [[ -n "$mail_provider" ]];do
            _; read -p "Argument --mail-provider required: " mail_provider
        done
        ;;
    dmarc)
        until [[ -n "$email" ]];do
            _; read -p "Argument --email required: " email
        done
        ;;
    dkim)
        until [[ -n "$dns_record" || -n "$dns_record_auto" ]];do
            _; read -p "Argument --dns-record required: " dns_record
        done
        ;;
esac
hostname=${hostname:=@}
code 'hostname="'$hostname'"'
code 'mail_provider="'$mail_provider'"'
if [ -z "$domain" ];then
    error "Argument --domain required."; x
fi
code 'domain="'$domain'"'
code 'digitalocean_domain_exists_sure="'$digitalocean_domain_exists_sure'"'
code 'ispconfig_domain_exists_sure="'$ispconfig_domain_exists_sure'"'
____

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

if [ -z "$ispconfig_domain_exists_sure" ];then
    INDENT+="    " \
    rcm-ispconfig-control-manage-domain $isfast \
        isset \
        --domain="$domain" \
        ; [ $? -eq 0 ] && ispconfig_domain_exists_sure=1

    if [ -n "$ispconfig_domain_exists_sure" ];then
        __; green Domain is exists.; _.
    else
        __; red Domain is not exists.; x
    fi
fi

if [ -z "$digitalocean_domain_exists_sure" ];then
    INDENT+="    " \
    rcm-digitalocean-api-manage-domain $isfast \
        --domain="$domain" \
        --ip-address="$ip_address" \
        ; [ ! $? -eq 0 ] && x

    if [ -n "$digitalocean_domain_exists_sure" ];then
        __; green Domain '`'"$domain"'`' found in DNS Digital Ocean.; _.
    else
        __; red Domain '`'"$domain"'`' not found in DNS Digital Ocean.; x
    fi
    ____
fi

php=$(cat <<-'EOF'
$data = $_SERVER['argv'][1];
echo '"'.implode('""', str_split($data, 200)).'"';
EOF
)

if [[ $type == spf ]];then
    data="v=spf1 a:${mail_provider} ~all"
    data=$(php -r "$php" "$data" )

    INDENT+="    " \
    rcm-digitalocean-api-manage-domain-record $isfast \
        add \
        --domain="$domain" \
        --type=txt \
        --hostname=@ \
        --value="$data" \
        --value-summarize=SPF \
        ; [ ! $? -eq 0 ] && x
fi
if [[ $type == dmarc ]];then
    data="v=DMARC1; p=none; rua=${email}"
    data=$(php -r "$php" "$data" )

    INDENT+="    " \
    rcm-digitalocean-api-manage-domain-record $isfast \
        add \
        --domain="$domain" \
        --type=txt \
        --hostname=_dmarc \
        --value="$data" \
        --value-summarize=DMARC \
        ; [ ! $? -eq 0 ] && x
fi
if [[ $type == dkim ]];then
    if [ -n "$dns_record_auto" ];then
        dns_record=$(INDENT+="    " rcm-ispconfig-control-manage-domain --fast --ispconfig-soap-exists-sure --domain="$domain" get-dns-record 2>/dev/null)
    fi
    if [ -z "$dns_record" ];then
        __; red DNS record not found.; x
    fi
    data="v=DKIM1; t=s; p=${dns_record}"
    data=$(php -r "$php" "$data" )

    INDENT+="    " \
    rcm-digitalocean-api-manage-domain-record $isfast \
        add \
        --domain="$domain" \
        --type=txt \
        --hostname=$DKIM_SELECTOR._domainkey \
        --value="$data" \
        --value-summarize=DKIM \
        ; [ ! $? -eq 0 ] && x
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
# --ispconfig-domain-exists-sure
# --digitalocean-domain-exists-sure
# --dns-record-auto
# )
# VALUE=(
# --domain
# --hostname
# --type
# --mail-provider
# --email
# --dns-record
# --ip-address
# )
# FLAG_VALUE=(
# )
# CSV=(
# )
# EOF
# clear
