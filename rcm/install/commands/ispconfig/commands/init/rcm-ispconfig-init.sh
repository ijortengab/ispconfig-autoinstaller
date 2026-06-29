#!/bin/bash

RCM_EXTENSION_VERSION=0.11.0-alpha.6

# Usage Functions.
usage() {
    cat << EOF
Usage: rcm ispconfig init [options]

Options:
   --dns-plugin *
        Select how to create the DNS record.
        Values available from command: rcm-plugin(list --interface=dns).
   --domain *
        Domain name of the server.
        Together with --hostname will make a Fully Qualified Domain Name (FQDN).
   --hostname *
        Hostname of the server, for example: \`server1\`.
   --url-ispconfig
        Add ISPConfig public domain. The value can be domain or URL and must be part of FQDN.
        ISPConfig automatically has address at http://ispconfig.localhost/.
   --url-phpmyadmin
        Add PHPMyAdmin public domain. The value can be domain or URL and must be part of FQDN.
        PHPMyAdmin automatically has address at http://phpmyadmin.localhost/.
   --url-roundcube
        Add Roundcube public domain. The value can be domain or URL and must be part of FQDN.
        Roundcube automatically has address at http://roundcube.localhost/.
   --public-domain
        Make sure that --fqdn is public domain, this will trigger TLS request and DNS verification.
   --acme-client=[TLS]
        Select acme client to obtain TLS Certificate.
        Values available from command: rcm(plugin list ispconfig/acme-client).
        Conditional: Bypass if --public-domain is not added.
   --web-server=HTTP
        Select web server to build up virtual host.
        Values available from command: rcm(plugin list ispconfig/web-server).
   --dbms=DB
        Select database management system to store the data.
        Values available from command: rcm(plugin list ispconfig/dbms).
   --mail-server=SMTP
        Select the mail transfer agent. Values available from command: rcm(plugin list ispconfig/mail-server).
   --mailbox-handler=[IMAP]
        Select the mail delivery agent. Values available from command: rcm(plugin list mailbox-handler).
   --mail-filtering=SPAM
        Select the mail filtering daemon. Values available from command: rcm(plugin list mail-filtering).
        Conditional: Bypass if --mailbox-handler has no value.
   --os-setup=OS
        Select the variation OS setup. Values available from command: rcm(plugin list ispconfig/os-setup).
   --timezone
        Set the timezone of this machine. Available values: Asia/Gaza, Asia/Ujung_Pandang, Asia/Jakarta, Asia/Makassar, Asia/Pontianak, Asia/Jayapura, or other.

Other Options (For expert only):
   --without-update-system ^
        Skip execute update system. Default to --with-update-system.
   --with-upgrade-system ^
        Execute upgrade system. Default to --without-upgrade-system.

Global Options.
   --version
        Print version of this script.
   --help
        Show this help.

RCM Config:
   --no-timer

Dependency:
   rcm-ispconfig:$RCM_EXTENSION_VERSION
   rcm-ispconfig-autoinstaller-nginx:$RCM_EXTENSION_VERSION
   rcm-roundcube-setup-ispconfig-integration:$RCM_EXTENSION_VERSION
   rcm-amavis-setup-ispconfig:$RCM_EXTENSION_VERSION
   rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php:$RCM_EXTENSION_VERSION
   rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root:$RCM_EXTENSION_VERSION
   rcm-ispconfig-setup-dump-variables-init:$RCM_EXTENSION_VERSION
   rcm-plugin
   rcm-dig-apt
   rcm-dig-has-address
   rcm-nginx-apt
   rcm-mariadb-apt
   rcm-php-apt
   rcm-php-setup-adjust-cli-version
   rcm-postfix-apt

Download:
   [rcm-ispconfig](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/rcm-ispconfig.sh)
   [rcm-ispconfig-autoinstaller-nginx](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-autoinstaller-nginx.sh)
   [rcm-roundcube-setup-ispconfig-integration](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/roundcube/rcm-roundcube-setup-ispconfig-integration.sh)
   [rcm-amavis-setup-ispconfig](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/amavis/rcm-amavis-setup-ispconfig.sh)
   [rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php.sh)
   [rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root.sh)
   [rcm-ispconfig-setup-dump-variables-init](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-dump-variables-init.sh)

Pre Prompt:
   rcm-plugin(init --interface=dns)
   rcm-plugin(init --interface=tls)
   rcm-plugin(add --interface=dns --name=manual --command=rcm-ispconfig --version=$RCM_EXTENSION_VERSION --temporary)
   rcm-plugin(add --interface=tls --name=manual --command=rcm-ispconfig --version=$RCM_EXTENSION_VERSION --temporary)

Post Prompt:
   rcm-plugin(execute --interface=dns --name=[--dns-plugin] --method=prompt)
   rcm-plugin(execute --interface=tls --name=[--tls-plugin] --method=prompt --ignore-fail-on-empty-name)
EOF
}

# Prevent scripts from being executed directly.
[ -f "${RCM_LIB}/require.sh" ] && source "${RCM_LIB}/require.sh" || { usage >&2; exit 1; }

# Parse arguments. Generated by parse-options.sh
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --acme-client=*) acme_client="${1#*=}"; shift ;;
        --acme-client) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then acme_client="$2"; shift; fi; shift ;;
        --bypass-validation-is-installed) bypass_validation_is_installed=1; shift ;;
        --dbms=*) dbms="${1#*=}"; shift ;;
        --dbms) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then dbms="$2"; shift; fi; shift ;;
        --dns-plugin=*) dns_plugin="${1#*=}"; shift ;;
        --dns-plugin) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then dns_plugin="$2"; shift; fi; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then domain="$2"; shift; fi; shift ;;
        --hostname=*) hostname="${1#*=}"; shift ;;
        --hostname) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then hostname="$2"; shift; fi; shift ;;
        --mailbox-handler=*) mailbox_handler="${1#*=}"; shift ;;
        --mailbox-handler) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then mailbox_handler="$2"; shift; fi; shift ;;
        --mail-filtering=*) mail_filtering="${1#*=}"; shift ;;
        --mail-filtering) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then mail_filtering="$2"; shift; fi; shift ;;
        --mail-server=*) mail_server="${1#*=}"; shift ;;
        --mail-server) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then mail_server="$2"; shift; fi; shift ;;
        --os-setup=*) os_setup="${1#*=}"; shift ;;
        --os-setup) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then os_setup="$2"; shift; fi; shift ;;
        --public-domain) public_domain=1; shift ;;
        --timezone=*) timezone="${1#*=}"; shift ;;
        --timezone) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then timezone="$2"; shift; fi; shift ;;
        --url-ispconfig=*) url_ispconfig="${1#*=}"; shift ;;
        --url-ispconfig) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_ispconfig="$2"; shift; fi; shift ;;
        --url-phpmyadmin=*) url_phpmyadmin="${1#*=}"; shift ;;
        --url-phpmyadmin) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_phpmyadmin="$2"; shift; fi; shift ;;
        --url-roundcube=*) url_roundcube="${1#*=}"; shift ;;
        --url-roundcube) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url_roundcube="$2"; shift; fi; shift ;;
        --without-update-system) update_system=0; shift ;;
        --with-update-system) update_system=1; shift ;;
        --without-upgrade-system) upgrade_system=0; shift ;;
        --with-upgrade-system) upgrade_system=1; shift ;;
        --web-server=*) web_server="${1#*=}"; shift ;;
        --web-server) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then web_server="$2"; shift; fi; shift ;;
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

# Define variables and constants.
DKIM_SELECTOR=${DKIM_SELECTOR:=default}
RCM_TLD_SPECIAL=${RCM_TLD_SPECIAL:=example test onion invalid local localhost alt}
SUBDOMAIN_ISPCONFIG=${SUBDOMAIN_ISPCONFIG:=cp}
SUBDOMAIN_PHPMYADMIN=${SUBDOMAIN_PHPMYADMIN:=db}
SUBDOMAIN_ROUNDCUBE=${SUBDOMAIN_ROUNDCUBE:=mail}
[ -n "$fast" ] && isfast=' --fast' || isfast=''

# @todo
# hapus dependency rcm-amavis-setup-ispconfig, karena by plugin.
# rename rcm-ispconfig-setup-dump-variables-init menjadi mode

# Help and Version.
[ -n "$help" ] && { usage; exit 0; }
[ -n "$version" ] && { e $RCM_EXTENSION_VERSION; x; }

# Require.
require vendor/ijortengab/rcm/functions/classes/rcm-file.sh
require vendor/ijortengab/rcm/functions/classes/rcm-dir.sh
require vendor/ijortengab/rcm/functions/utility/find-string.sh
require vendor/ijortengab/rcm/functions/utility/sleep-extended.sh
require vendor/ijortengab/rcm/functions/utility/apt-install.sh
require vendor/ijortengab/rcm/functions/utility/backup-file.sh
require vendor/ijortengab/rcm/functions/utility/backup-dir.sh
require vendor/ijortengab/rcm/functions/utility/link-symbolic.sh
require vendor/ijortengab/bash/functions/array-diff.sh
require vendor/ijortengab/bash/functions/array-intersect.sh
require vendor/ijortengab/bash/functions/array-search.sh
require vendor/ijortengab/bash/functions/array-remove.sh
require vendor/ijortengab/ispconfig-autoinstaller/functions/parse-ini-file.sh

# ------------------------------------------------------------------------------

# Title.
title rcm ispconfig init
____

# Dependency.

# Source: ISPConfigDebianOS::runPerfectSetup()
if [ -z "$bypass_validation_is_installed" ];then
    chapter Mengecek existing ISPConfig.
    path=/usr/local/ispconfig/server/lib/config.inc.php
    code 'path="'$path'"'
    if [ -f "$path" ]; then
        __ File '`'$path'`' found.
        error The server already has ISPConfig installed. Aborting.; x
    else
        __ File '`'$path'`' not found.;
        __ Installation is continue.
    fi
    ____
fi

# Require, validate, and populate value.
chapter Variable dump.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
code 'SUBDOMAIN_ISPCONFIG="'$SUBDOMAIN_ISPCONFIG'"'
code 'SUBDOMAIN_PHPMYADMIN="'$SUBDOMAIN_PHPMYADMIN'"'
code 'SUBDOMAIN_ROUNDCUBE="'$SUBDOMAIN_ROUNDCUBE'"'
code 'timezone="'$timezone'"'
code 'php_version="'$php_version'"'
code 'phpmyadmin_version="'$phpmyadmin_version'"'
code 'roundcube_version="'$roundcube_version'"'
if [ -z "$dns_plugin" ];then
    error "Argument --dns-plugin required."; x
else
    dns_plugin_available=()
    while read line; do
        dns_plugin_available+=($line)
    done <<< `rcm-plugin list --interface=dns`
    if ! ArraySearch "$dns_plugin" dns_plugin_available[@];then
        error "Argument --dns-plugin not valid."; x
    fi
fi
code 'dns_plugin="'$dns_plugin'"'
if [ -z "$domain" ];then
    error "Argument --domain required."; x
fi
code domain="$domain"
if [ -z "$hostname" ];then
    error "Argument --hostname required."; x
fi
code hostname="$hostname"
fqdn="${hostname}.${domain}"
code fqdn="$fqdn"
Rcm_parse_url "$fqdn"
for each in PHP_URL_SCHEME PHP_URL_PORT PHP_URL_USER PHP_URL_PASS PHP_URL_PATH PHP_URL_QUERY PHP_URL_FRAGMENT; do
    value=${!each}
    if [ -n "$value" ];then
        error Argument --fqdn cannot have component "$each": '`'"$fqdn"'`'.; x
    fi
done
hostname=$(echo "$PHP_URL_HOST" | sed -E 's|^([^\.]+)\..*|\1|g')
code hostname="$hostname"
code url_ispconfig="$url_ispconfig"
if [ -n "$url_ispconfig" ];then
    url="$url_ispconfig"
    urlCompleteComponent
    # code 'url_scheme="'$url_scheme'"'
    # code 'url_host="'$url_host'"'
    # code 'url_port="'$url_port'"'
    # code 'url_path="'$url_path'"'
    # code 'url_path_clean="'$url_path_clean'"'
    # code 'url_path_clean_trailing="'$url_path_clean_trailing'"'
    if [ -n "$url_path" ];then
        error Argument --url-ispconfig is cannot have subpath: '`'"$url_path"'`'.; x
    elif [ ! "$url_host" == "$fqdn" ];then
        error Argument --url-ispconfig is not part of FQDN: '`'"$url_ispconfig"'`'.; x
    fi
    url_ispconfig="$url"
    code 'url_ispconfig="'$url_ispconfig'"'
fi
code url_phpmyadmin="$url_phpmyadmin"
if [ -n "$url_phpmyadmin" ];then
    url="$url_phpmyadmin"
    urlCompleteComponent
    # code 'url_scheme="'$url_scheme'"'
    # code 'url_host="'$url_host'"'
    # code 'url_port="'$url_port'"'
    # code 'url_path="'$url_path'"'
    # code 'url_path_clean="'$url_path_clean'"'
    # code 'url_path_clean_trailing="'$url_path_clean_trailing'"'
    if [ ! "$url_host" == "$fqdn" ];then
        error Argument --url-ispconfig is not part of FQDN: '`'"$url_ispconfig"'`'.; x
    fi
    url_phpmyadmin="$url"
    code 'url_phpmyadmin="'$url_phpmyadmin'"'
fi
code url_roundcube="$url_roundcube"
if [ -n "$url_roundcube" ];then
    url="$url_roundcube"
    urlCompleteComponent
    # code 'url_scheme="'$url_scheme'"'
    # code 'url_host="'$url_host'"'
    # code 'url_port="'$url_port'"'
    # code 'url_path="'$url_path'"'
    # code 'url_path_clean="'$url_path_clean'"'
    # code 'url_path_clean_trailing="'$url_path_clean_trailing'"'
    if [ ! "$url_host" == "$fqdn" ];then
        error Argument --url-ispconfig is not part of FQDN: '`'"$url_ispconfig"'`'.; x
    fi
    url_roundcube="$url"
    code 'url_roundcube="'$url_roundcube'"'
fi
[ -z "$update_system" ] && update_system=1
[ "$update_system" == 0 ] && update_system=
[ "$upgrade_system" == 0 ] && upgrade_system=
[ -n "$update_system" ] && is_update_system=' --without-update-system-' || is_update_system=' --without-update-system'
[ -n "$upgrade_system" ] && is_upgrade_system=' --without-upgrade-system-' || is_upgrade_system=' --without-upgrade-system'
____

# chapter Take a break.
# _ Begin to Validate DNS Zone for FQDN.; _.
# sleepExtended 3 30
# ____

# Prepare for anything including setup required application.
INDENT+='    ' \
rcm-plugin $isfast execute --interface=dns --name="$dns_plugin" --method='server_setup_pre' \
    ; [ ! $? -eq 0 ] && x
____

export RCM_HOSTNAME="$hostname"
export RCM_DOMAIN="$domain"
INDENT+='    ' \
rcm-plugin $isfast execute --interface=dns --name="$dns_plugin" --method='is_a_record_exists_not_cname' \
    ; [ ! $? -eq 0 ] && x
____

# chapter Take a break.
# _ Setup LEMP Stack.; _.
# sleepExtended 3 30
# ____

chapter Mengecek FQDN '(Fully-Qualified Domain Name)'
code fqdn="$fqdn"
current_fqdn=$(hostname -f 2>/dev/null)
code hostname -f
e "$current_fqdn"; _.
adjust=
if [[ "$current_fqdn" == "$fqdn" ]];then
    __ Variable '$fqdn' sama dengan value system hostname saat ini '$(hostname -f)'.
else
    __ Variable '$fqdn' tidak sama dengan value system hostname saat ini '$(hostname -f)'.
    adjust=1
fi
____

if [[ -n "$adjust" ]];then
    chapter Adjust FQDN.
    code hostnamectl set-hostname "${hostname}"
    hostnamectl set-hostname "${hostname}"
    echo "127.0.1.1"$'\t'"${fqdn}"$'\t'"${hostname}" >> /etc/hosts
    sleep .5
    current_fqdn=$(hostname -f 2>/dev/null)
    if [[ "$current_fqdn" == "$fqdn" ]];then
        __; green Variable '$fqdn' sama dengan value system FQDN saat ini '$(hostname -f)'.; _.
    else
        __; red Variable '$fqdn' tidak sama dengan value system hostname saat ini '$(hostname -f)'.; x
    fi
    ____
fi

include `rcm plugin get-socket ispconfig/os-setup $os_setup init`

include `rcm plugin run-method ispconfig/acme-client $acme_client init`

include `rcm plugin run-method ispconfig/web-server $web_server init`

include `rcm plugin run-method ispconfig/dbms $dbms init`

include `rcm plugin run-method ispconfig/mail-server $mail_server init`

if [ -n "$mailbox_handler" ];then

    include `rcm plugin run-method mailbox-handler $mailbox_handler init`

    include `rcm plugin run-method mail-filtering $mail_filtering init`

fi

INDENT+='    ' \
rcm-plugin $isfast execute --interface=dns --name="$dns_plugin" --method='server_setup_post' \
    ; [ ! $? -eq 0 ] && x

# chapter Take a break.
# _ Begin to Install ISPConfig and Friends.; _.
# sleepExtended 3 30
____

chapter Take a break.
_ Begin to Setup; _.
sleep-extended 3 30
____

include `rcm plugin run-method ispconfig/mail-server $mail_server setup`

include `rcm plugin run-method ispconfig/dbms $dbms setup`

include `rcm plugin run-method ispconfig/web-server $web_server setup`

if [ -n "$public_domain" ];then

    RCM_FQDN=$(</etc/mailname)

    include `rcm plugin run-method ispconfig/acme-client $acme_client obtain`

    include `rcm plugin run-method ispconfig/acme-client $acme_client define`

    [ -n "$RCM_TLS_CERTIFICATE" ] || { red "Unable to proceed, variable \$RCM_TLS_CERTIFICATE is empty."; x; }
    [ -n "$RCM_TLS_CERTIFICATE_KEY" ] || { red "Unable to proceed, variable \$RCM_TLS_CERTIFICATE_KEY is empty."; x; }

fi

RCM_WEB_SERVER="$web_server"
RCM_PUBLIC_DOMAIN="$public_domain"

include `rcm plugin run-method ispconfig/os-setup $os_setup setup`

INDENT+='    ' \
rcm-roundcube-setup-ispconfig-integration $isfast \
    ; [ ! $? -eq 0 ] && x

if [ -n "$url_ispconfig" ];then
    INDENT+="    " \
    rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php $isfast \
        --project=ispconfig \
        --php-version="$php_version" \
        --url="$url_ispconfig" \
        --tls-certificate="$tls_certificate" \
        --tls-certificate-key="$tls_certificate_key" \
        ; [ ! $? -eq 0 ] && x
fi

if [ -n "$url_phpmyadmin" ];then
    INDENT+="    " \
    rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root $isfast \
        --project=phpmyadmin \
        --php-version="$php_version" \
        --url="$url_phpmyadmin" \
        --tls-certificate="$tls_certificate" \
        --tls-certificate-key="$tls_certificate_key" \
        ; [ ! $? -eq 0 ] && x
fi

if [ -n "$url_roundcube" ];then
    INDENT+="    " \
    rcm-ispconfig-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root $isfast \
        --project=roundcube \
        --php-version="$php_version" \
        --url="$url_roundcube" \
        --tls-certificate="$tls_certificate" \
        --tls-certificate-key="$tls_certificate_key" \
        ; [ ! $? -eq 0 ] && x
fi

chapter Take a break.
_ Everything is OK, "let's" dump variables.; _.
sleepExtended 3
____

chapter Saving URL information.
if [ -n "$url_ispconfig" ];then
    path=/usr/local/share/ispconfig/website
    parent=/usr/local/share/ispconfig
    code mkdir -p "$parent"
    mkdir -p "$parent"
    cat << EOF >> "$path"
URL_ISPCONFIG=$url_ispconfig
EOF
    [ -f "$path" ] || fileMustExists "$path"
fi
if [ -n "$url_phpmyadmin" ];then
    path=/usr/local/share/phpmyadmin/website
    parent=/usr/local/share/phpmyadmin
    code mkdir -p "$parent"
    mkdir -p "$parent"
    cat << EOF >> "$path"
URL_PHPMYADMIN=$url_phpmyadmin
EOF
    [ -f "$path" ] || fileMustExists "$path"
fi
if [ -n "$url_roundcube" ];then
    path=/usr/local/share/roundcube/website
    parent=/usr/local/share/roundcube
    code mkdir -p "$parent"
    mkdir -p "$parent"
    cat << EOF >> "$path"
URL_ROUNDCUBE=$url_roundcube
EOF
    [ -f "$path" ] || fileMustExists "$path"
fi
____

INDENT+="    " \
rcm-ispconfig-setup-dump-variables-init $isfast \
    ; [ ! $? -eq 0 ] && x

chapter Finish
____

exit 0

# parse-options.sh \
# --with-end-options-double-dash \
# --with-end-options-specific-operand \
# --compact \
# --clean \
# --no-hash-bang \
# --no-original-arguments \
# --no-error-invalid-options \
# --no-error-require-arguments << EOF | clip
# FLAG=(
# --version
# --help
# --bypass-validation-is-installed
# --public-domain
# )
# VALUE=(
# --timezone
# --web-server
# --mail-server
# --mailbox-handler
# --mail-filtering
# --dbms
# --hostname
# --domain
# --url-ispconfig
# --url-phpmyadmin
# --url-roundcube
# --dns-plugin
# --os-setup
# --acme-client
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# CSV=(
    # 'long:--with-update-system,parameter:update_system'
    # 'long:--without-update-system,parameter:update_system,flag_option:reverse'
    # 'long:--with-upgrade-system,parameter:upgrade_system'
    # 'long:--without-upgrade-system,parameter:upgrade_system,flag_option:reverse'
# )
# OPERAND=(
# )
# EOF
# clear
