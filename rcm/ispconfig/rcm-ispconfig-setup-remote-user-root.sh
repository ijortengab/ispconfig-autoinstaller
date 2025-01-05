#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
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
_() { echo -n "$INDENT" >&2; echo -n "#"' ' >&2; [ -n "$1" ] && echo "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "#" '    ' >&2; [ -n "$1" ] && echo "$@" >&2; }
____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

# Define variables and constants.
delay=.5; [ -n "$fast" ] && unset delay
ISPCONFIG_REMOTE_USER_ROOT=${ISPCONFIG_REMOTE_USER_ROOT:=root}

# Functions.
printVersion() {
    echo '0.9.12'
}
printHelp() {
    title RCM ISPConfig Setup
    _ 'Variation '; yellow Internal Command; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-setup-remote-user-root [options]

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
   ISPCONFIG_REMOTE_USER_ROOT
        Default to $ISPCONFIG_REMOTE_USER_ROOT

Dependency:
   pwgen
   rcm-ispconfig-remote-user-autocreate:`printVersion`

Download:
   [rcm-ispconfig-remote-user-autocreate](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-remote-user-autocreate.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-setup-remote-user-root
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
Rcm_ispconfig_list_functions() {
    cat << 'RCM_ISPCONFIG_LIST_FUNCTIONS'
admin_record_permissions
client_add
client_change_password
client_delete
client_delete_everything
client_get
client_get_all
client_get_by_customer_no
client_get_by_username
client_get_emailcontact
client_get_id
client_get_id
client_get_sites_by_user
client_templates_get_all
client_update
config_value_add
config_value_delete
config_value_get
config_value_replace
config_value_update
databasequota_get_by_user
dns_a_add
dns_a_delete
dns_a_get
dns_a_update
dns_aaaa_add
dns_aaaa_delete
dns_aaaa_get
dns_aaaa_update
dns_alias_add
dns_alias_delete
dns_alias_get
dns_alias_update
dns_caa_add
dns_caa_delete
dns_caa_get
dns_caa_update
dns_cname_add
dns_cname_delete
dns_cname_get
dns_cname_update
dns_dname_add
dns_dname_delete
dns_dname_get
dns_dname_update
dns_ds_add
dns_ds_delete
dns_ds_get
dns_ds_update
dns_hinfo_add
dns_hinfo_delete
dns_hinfo_get
dns_hinfo_update
dns_loc_add
dns_loc_delete
dns_loc_get
dns_loc_update
dns_mx_add
dns_mx_delete
dns_mx_get
dns_mx_update
dns_naptr_add
dns_naptr_delete
dns_naptr_get
dns_naptr_update
dns_ns_add
dns_ns_delete
dns_ns_get
dns_ns_update
dns_ptr_add
dns_ptr_delete
dns_ptr_get
dns_ptr_update
dns_rp_add
dns_rp_delete
dns_rp_get
dns_rp_update
dns_srv_add
dns_srv_delete
dns_srv_get
dns_srv_update
dns_sshfp_add
dns_sshfp_delete
dns_sshfp_get
dns_sshfp_update
dns_templatezone_add
dns_tlsa_add
dns_tlsa_delete
dns_tlsa_get
dns_tlsa_update
dns_txt_add
dns_txt_delete
dns_txt_get
dns_txt_update
dns_zone_add
dns_zone_delete
dns_zone_get
dns_zone_get_id
dns_zone_set_status
dns_zone_update
domains_domain_add
domains_domain_delete
domains_domain_get
domains_domain_update
domains_get_all_by_user
get_function_list
login
logout
mail_alias_add
mail_alias_delete
mail_alias_get
mail_alias_get
mail_alias_update
mail_aliasdomain_add
mail_aliasdomain_delete
mail_aliasdomain_get
mail_aliasdomain_update
mail_blacklist_add
mail_blacklist_delete
mail_blacklist_get
mail_blacklist_update
mail_catchall_add
mail_catchall_delete
mail_catchall_get
mail_catchall_update
mail_domain_add
mail_domain_delete
mail_domain_get
mail_domain_get_by_domain
mail_domain_set_status
mail_domain_update
mail_fetchmail_add
mail_fetchmail_add
mail_fetchmail_delete
mail_fetchmail_delete
mail_fetchmail_get
mail_fetchmail_get
mail_fetchmail_update
mail_fetchmail_update
mail_filter_add
mail_filter_delete
mail_filter_get
mail_filter_update
mail_forward_add
mail_forward_delete
mail_forward_get
mail_forward_update
mail_mailinglist_add
mail_mailinglist_delete
mail_mailinglist_get
mail_mailinglist_update
mail_policy_add
mail_policy_delete
mail_policy_get
mail_policy_get
mail_policy_update
mail_relay_add
mail_relay_delete
mail_relay_get
mail_relay_update
mail_spamfilter_blacklist_add
mail_spamfilter_blacklist_add
mail_spamfilter_blacklist_delete
mail_spamfilter_blacklist_delete
mail_spamfilter_blacklist_get
mail_spamfilter_blacklist_get
mail_spamfilter_blacklist_update
mail_spamfilter_blacklist_update
mail_spamfilter_user_add
mail_spamfilter_user_add
mail_spamfilter_user_delete
mail_spamfilter_user_get
mail_spamfilter_user_get
mail_spamfilter_user_update
mail_spamfilter_user_update
mail_spamfilter_whitelist_add
mail_spamfilter_whitelist_add
mail_spamfilter_whitelist_delete
mail_spamfilter_whitelist_delete
mail_spamfilter_whitelist_get
mail_spamfilter_whitelist_get
mail_spamfilter_whitelist_update
mail_spamfilter_whitelist_update
mail_transport_add
mail_transport_delete
mail_transport_get
mail_transport_update
mail_user_add
mail_user_backup
mail_user_delete
mail_user_filter_add
mail_user_filter_add
mail_user_filter_delete
mail_user_filter_delete
mail_user_filter_get
mail_user_filter_get
mail_user_filter_update
mail_user_filter_update
mail_user_get
mail_user_get
mail_user_update
mail_user_update
mail_whitelist_add
mail_whitelist_delete
mail_whitelist_get
mail_whitelist_update
mailquota_get_by_user
monitor_jobqueue_count
quota_get_by_user
server_config_set
server_get
server_get
server_get_app_version
server_get_serverid_by_ip
server_ip_add
server_ip_delete
server_ip_get
server_ip_update
sites_aps_available_packages_list
sites_aps_change_package_status
sites_aps_get_package_details
sites_aps_get_package_file
sites_aps_get_package_settings
sites_aps_install_package
sites_aps_instance_delete
sites_aps_instance_get
sites_aps_update_package_list
sites_cron_add
sites_cron_delete
sites_cron_get
sites_cron_update
sites_database_add
sites_database_delete
sites_database_get
sites_database_get_all_by_user
sites_database_update
sites_database_user_add
sites_database_user_delete
sites_database_user_get
sites_database_user_get_all_by_user
sites_database_user_update
sites_ftp_user_add
sites_ftp_user_delete
sites_ftp_user_get
sites_ftp_user_server_get
sites_ftp_user_update
sites_shell_user_add
sites_shell_user_delete
sites_shell_user_get
sites_shell_user_update
sites_web_aliasdomain_add
sites_web_aliasdomain_delete
sites_web_aliasdomain_get
sites_web_aliasdomain_update
sites_web_domain_add
sites_web_domain_backup
sites_web_domain_delete
sites_web_domain_get
sites_web_domain_set_status
sites_web_domain_update
sites_web_folder_add
sites_web_folder_delete
sites_web_folder_get
sites_web_folder_update
sites_web_folder_user_add
sites_web_folder_user_delete
sites_web_folder_user_get
sites_web_folder_user_update
sites_web_subdomain_add
sites_web_subdomain_delete
sites_web_subdomain_get
sites_web_subdomain_update
sites_webdav_user_add
sites_webdav_user_delete
sites_webdav_user_get
sites_webdav_user_update
system_config_get
system_config_set
trafficquota_get_by_user
vm_openvz
RCM_ISPCONFIG_LIST_FUNCTIONS
}
remoteUserCredentialIspconfig() {
    # Check if the remote_username from table remote_user exists in ispconfig database.
    #
    # Globals:
    #   Modified: remote_userid
    #
    # Arguments:
    #   $1: remote_username to be checked.
    #
    # Return:
    #   0 if exists.
    #   1 if not exists.
    local user="$1"
    if [ -f /usr/local/share/ispconfig/credential/remote/$user ];then
        local ISPCONFIG_REMOTE_USER_PASSWORD ISPCONFIG_REMOTE_USER_NAME
        . /usr/local/share/ispconfig/credential/remote/$user
        ispconfig_remote_user_name=$ISPCONFIG_REMOTE_USER_NAME
        ispconfig_remote_user_password=$ISPCONFIG_REMOTE_USER_PASSWORD
    else
        ispconfig_remote_user_name="$user"
        ispconfig_remote_user_password=$(pwgen -s 32 -1)
        mkdir -p /usr/local/share/ispconfig/credential/remote
        cat << EOF > /usr/local/share/ispconfig/credential/remote/$user
ISPCONFIG_REMOTE_USER_NAME=$user
ISPCONFIG_REMOTE_USER_PASSWORD=$ispconfig_remote_user_password
EOF
        chmod 0500 /usr/local/share/ispconfig/credential
        chmod 0500 /usr/local/share/ispconfig/credential/remote
        chmod 0400 /usr/local/share/ispconfig/credential/remote/$user
    fi
}

# Requirement, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
code 'ISPCONFIG_REMOTE_USER_ROOT="'$ISPCONFIG_REMOTE_USER_ROOT'"'
____

chapter Mengecek ISPConfig User.
php_fpm_user=ispconfig
code id -u '"'$php_fpm_user'"'
if id "$php_fpm_user" >/dev/null 2>&1; then
    __ User '`'$php_fpm_user'`' found.
else
    error User '`'$php_fpm_user'`' not found.; x
fi
____

chapter Prepare arguments.
functions=`Rcm_ispconfig_list_functions`
functions_arg=
declare -i count
i=0
while read line;do
    functions_arg+=" --function=${line}"
    count+=1
done <<< "$functions"
remoteUserCredentialIspconfig $ISPCONFIG_REMOTE_USER_ROOT
if [[ -z "$ispconfig_remote_user_name" || -z "$ispconfig_remote_user_password" ]];then
    __; red Informasi credentials tidak lengkap: '`'/usr/local/share/ispconfig/credential/remote/$ISPCONFIG_REMOTE_USER_ROOT'`'.; x
else
    code ispconfig_remote_user_name="$ispconfig_remote_user_name"
    code ispconfig_remote_user_password="$ispconfig_remote_user_password"
fi
magenta 'count='$count; _, ' # ${#functions}'; _.
____

INDENT+="    " \
rcm-ispconfig-remote-user-autocreate $isfast --root-sure --ispconfig-sure \
    --username="$ispconfig_remote_user_name" \
    --password="$ispconfig_remote_user_password" \
    $functions_arg \
    ; [ ! $? -eq 0 ] && x

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
# )
# FLAG_VALUE=(
# )
# EOF
# clear
