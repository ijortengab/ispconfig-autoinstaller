#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

blue ISPConfig Remote User
____

# Dependencies.
command -v "ispconfig.sh" >/dev/null || { __; red Command "ispconfig.sh" not found.; x; }

command -v databaseCredentialIspconfig >/dev/null || {
databaseCredentialIspconfig() {
    if [ -f /usr/local/share/ispconfig/credential/database ];then
        local ISPCONFIG_DB_NAME ISPCONFIG_DB_USER ISPCONFIG_DB_USER_PASSWORD
        . /usr/local/share/ispconfig/credential/database
        ispconfig_db_name=$ISPCONFIG_DB_NAME
        ispconfig_db_user=$ISPCONFIG_DB_USER
        ispconfig_db_user_password=$ISPCONFIG_DB_USER_PASSWORD
    else
        ispconfig_db_user_password=$(pwgen -s 32 -1)
        mkdir -p /usr/local/share/ispconfig/credential
        cat << EOF > /usr/local/share/ispconfig/credential/database
ISPCONFIG_DB_USER_PASSWORD=$ispconfig_db_user_password
EOF
        chmod 0500 /usr/local/share/ispconfig/credential
        chmod 0400 /usr/local/share/ispconfig/credential/database
    fi
}
}

yellow Mengecek credentials ISPConfig.
ispconfig_db_user_host="$ISPCONFIG_DB_USER_HOST"
magenta ispconfig_db_user_host="$ispconfig_db_user_host"
databaseCredentialIspconfig
if [[ -z "$ispconfig_db_name" || -z "$ispconfig_db_user" || -z "$ispconfig_db_user_password" ]];then
    __; red Informasi credentials tidak lengkap: '`'/usr/local/share/ispconfig/credential/database'`'.; exit
else
    magenta ispconfig_db_name="$ispconfig_db_name"
    magenta ispconfig_db_user="$ispconfig_db_user"
    magenta ispconfig_db_user_password="$ispconfig_db_user_password"
fi

# Get the remote_userid from table remote_user in ispconfig database.
#
# Globals:
#   ispconfig_db_user, ispconfig_db_user_password,
#   ispconfig_db_user_host, ispconfig_db_name
#
# Arguments:
#   $1: Filter by remote_username.
#
# Output:
#   Write remote_userid to stdout.
getRemoteUserIdIspconfigByRemoteUsername() {
    local remote_username="$1"
    local sql="SELECT remote_userid FROM remote_user WHERE remote_username = '$remote_username';"
    local u="$ispconfig_db_user"
    local p="$ispconfig_db_user_password"
    local remote_userid=$(mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        -h "$ispconfig_db_user_host" "$ispconfig_db_name" -r -N -s -e "$sql"
    )
    echo "$remote_userid"
}

# Insert the remote_username to table remote_user in ispconfig database.
#
# Globals:
#   Used: ispconfig_install_dir
#         ispconfig_db_user_host
#         ispconfig_db_user
#         ispconfig_db_name
#         ispconfig_db_user_password
#   Modified: identity_id
#
# Arguments:
#   $1: remote_username
#   $2: remote_password
#   $3: remote_functions
#
# Return:
#   0 if exists.
#   1 if not exists.
insertRemoteUsernameIspconfig() {
    local remote_username="$1"
    local _remote_password="$2"
    local _remote_functions="$3"
    CONTENT=$(cat <<- EOF
require '${ispconfig_install_dir}/interface/lib/classes/auth.inc.php';
echo (new auth)->crypt_password('$_remote_password');
EOF
    )
    local remote_password=$(php -r "$CONTENT")
    local remote_functions=$(tr '\n' ';' <<< "$_remote_functions")
    local sql="INSERT INTO remote_user
(sys_userid, sys_groupid, sys_perm_user, sys_perm_group, sys_perm_other, remote_username, remote_password, remote_access, remote_ips, remote_functions)
VALUES
(1, 1, 'riud', 'riud', '', '$remote_username', '$remote_password', 'y', '127.0.0.1', '$remote_functions');"
    local u="$ispconfig_db_user"
    local p="$ispconfig_db_user_password"
    mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        -h "$ispconfig_db_user_host" "$ispconfig_db_name" -e "$sql"
    remote_userid=$(getRemoteUserIdIspconfigByRemoteUsername "$remote_username")
    if [ -n "$remote_userid" ];then
        return 0
    fi
    return 1
}

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
isRemoteUsernameIspconfigExist() {
    local remote_username="$1"
    remote_userid=$(getRemoteUserIdIspconfigByRemoteUsername "$remote_username")
    if [ -n "$remote_userid" ];then
        return 0
    fi
    return 1
}
____

remoteUserCredentialIspconfig() {
    local user="$1"
    if [ -f /usr/local/share/ispconfig/credential/remote/$user ];then
        local ISPCONFIG_REMOTE_USER_PASSWORD
        . /usr/local/share/ispconfig/credential/remote/$user
        ispconfig_remote_user_password=$ISPCONFIG_REMOTE_USER_PASSWORD
    else
        ispconfig_remote_user_password=$(pwgen -s 32 -1)
        mkdir -p /usr/local/share/ispconfig/credential/remote
        cat << EOF > /usr/local/share/ispconfig/credential/remote/$user
ISPCONFIG_REMOTE_USER_PASSWORD=$ispconfig_remote_user_password
EOF
        chmod 0500 /usr/local/share/ispconfig/credential
        chmod 0500 /usr/local/share/ispconfig/credential/remote
        chmod 0400 /usr/local/share/ispconfig/credential/remote/$user
    fi
}

yellow Mengecek Remote User ISPConfig '"'$remote_user_root'"'
notfound=
if isRemoteUsernameIspconfigExist "$remote_user_root" ;then
    __ Found '(remote_userid:'$remote_userid')'.
else
    __ Not Found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Insert Remote User ISPConfig '"'$remote_user_root'"'
    functions='server_get,server_config_set,get_function_list,client_templates_get_all,server_get_serverid_by_ip,server_ip_get,server_ip_add,server_ip_update,server_ip_delete,system_config_set,system_config_get,config_value_get,config_value_add,config_value_update,config_value_replace,config_value_delete
admin_record_permissions
client_get_id,login,logout,mail_alias_get,mail_fetchmail_add,mail_fetchmail_delete,mail_fetchmail_get,mail_fetchmail_update,mail_policy_get,mail_spamfilter_blacklist_add,mail_spamfilter_blacklist_delete,mail_spamfilter_blacklist_get,mail_spamfilter_blacklist_update,mail_spamfilter_user_add,mail_spamfilter_user_get,mail_spamfilter_user_update,mail_spamfilter_whitelist_add,mail_spamfilter_whitelist_delete,mail_spamfilter_whitelist_get,mail_spamfilter_whitelist_update,mail_user_filter_add,mail_user_filter_delete,mail_user_filter_get,mail_user_filter_update,mail_user_get,mail_user_update,server_get,server_get_app_version
client_get_all,client_get,client_add,client_update,client_delete,client_get_sites_by_user,client_get_by_username,client_get_by_customer_no,client_change_password,client_get_id,client_delete_everything,client_get_emailcontact
domains_domain_get,domains_domain_add,domains_domain_update,domains_domain_delete,domains_get_all_by_user
quota_get_by_user,trafficquota_get_by_user,mailquota_get_by_user,databasequota_get_by_user
mail_domain_get,mail_domain_add,mail_domain_update,mail_domain_delete,mail_domain_set_status,mail_domain_get_by_domain
mail_aliasdomain_get,mail_aliasdomain_add,mail_aliasdomain_update,mail_aliasdomain_delete
mail_mailinglist_get,mail_mailinglist_add,mail_mailinglist_update,mail_mailinglist_delete
mail_user_get,mail_user_add,mail_user_update,mail_user_delete
mail_alias_get,mail_alias_add,mail_alias_update,mail_alias_delete
mail_forward_get,mail_forward_add,mail_forward_update,mail_forward_delete
mail_catchall_get,mail_catchall_add,mail_catchall_update,mail_catchall_delete
mail_transport_get,mail_transport_add,mail_transport_update,mail_transport_delete
mail_relay_get,mail_relay_add,mail_relay_update,mail_relay_delete
mail_whitelist_get,mail_whitelist_add,mail_whitelist_update,mail_whitelist_delete
mail_blacklist_get,mail_blacklist_add,mail_blacklist_update,mail_blacklist_delete
mail_spamfilter_user_get,mail_spamfilter_user_add,mail_spamfilter_user_update,mail_spamfilter_user_delete
mail_policy_get,mail_policy_add,mail_policy_update,mail_policy_delete
mail_fetchmail_get,mail_fetchmail_add,mail_fetchmail_update,mail_fetchmail_delete
mail_spamfilter_whitelist_get,mail_spamfilter_whitelist_add,mail_spamfilter_whitelist_update,mail_spamfilter_whitelist_delete
mail_spamfilter_blacklist_get,mail_spamfilter_blacklist_add,mail_spamfilter_blacklist_update,mail_spamfilter_blacklist_delete
mail_user_filter_get,mail_user_filter_add,mail_user_filter_update,mail_user_filter_delete
mail_user_backup
mail_filter_get,mail_filter_add,mail_filter_update,mail_filter_delete
monitor_jobqueue_count
sites_cron_get,sites_cron_add,sites_cron_update,sites_cron_delete
sites_database_get,sites_database_add,sites_database_update,sites_database_delete, sites_database_get_all_by_user,sites_database_user_get,sites_database_user_add,sites_database_user_update,sites_database_user_delete, sites_database_user_get_all_by_user
sites_web_folder_get,sites_web_folder_add,sites_web_folder_update,sites_web_folder_delete,sites_web_folder_user_get,sites_web_folder_user_add,sites_web_folder_user_update,sites_web_folder_user_delete
sites_ftp_user_get,sites_ftp_user_server_get,sites_ftp_user_add,sites_ftp_user_update,sites_ftp_user_delete
sites_shell_user_get,sites_shell_user_add,sites_shell_user_update,sites_shell_user_delete
sites_web_domain_get,sites_web_domain_add,sites_web_domain_update,sites_web_domain_delete,sites_web_domain_set_status
sites_web_domain_backup
sites_web_aliasdomain_get,sites_web_aliasdomain_add,sites_web_aliasdomain_update,sites_web_aliasdomain_delete
sites_web_subdomain_get,sites_web_subdomain_add,sites_web_subdomain_update,sites_web_subdomain_delete
sites_aps_update_package_list,sites_aps_available_packages_list,sites_aps_change_package_status,sites_aps_install_package,sites_aps_get_package_details,sites_aps_get_package_file,sites_aps_get_package_settings,sites_aps_instance_get,sites_aps_instance_delete
sites_webdav_user_get,sites_webdav_user_add,sites_webdav_user_update,sites_webdav_user_delete
dns_zone_get,dns_zone_get_id,dns_zone_add,dns_zone_update,dns_zone_delete,dns_zone_set_status,dns_templatezone_add
dns_a_get,dns_a_add,dns_a_update,dns_a_delete
dns_aaaa_get,dns_aaaa_add,dns_aaaa_update,dns_aaaa_delete
dns_alias_get,dns_alias_add,dns_alias_update,dns_alias_delete
dns_caa_get,dns_caa_add,dns_caa_update,dns_caa_delete
dns_cname_get,dns_cname_add,dns_cname_update,dns_cname_delete
dns_dname_get,dns_dname_add,dns_dname_update,dns_dname_delete
dns_ds_get,dns_ds_add,dns_ds_update,dns_ds_delete
dns_hinfo_get,dns_hinfo_add,dns_hinfo_update,dns_hinfo_delete
dns_loc_get,dns_loc_add,dns_loc_update,dns_loc_delete
dns_mx_get,dns_mx_add,dns_mx_update,dns_mx_delete
dns_naptr_get,dns_naptr_add,dns_naptr_update,dns_naptr_delete
dns_ns_get,dns_ns_add,dns_ns_update,dns_ns_delete
dns_ptr_get,dns_ptr_add,dns_ptr_update,dns_ptr_delete
dns_rp_get,dns_rp_add,dns_rp_update,dns_rp_delete
dns_srv_get,dns_srv_add,dns_srv_update,dns_srv_delete
dns_sshfp_get,dns_sshfp_add,dns_sshfp_update,dns_sshfp_delete
dns_tlsa_get,dns_tlsa_add,dns_tlsa_update,dns_tlsa_delete
dns_txt_get,dns_txt_add,dns_txt_update,dns_txt_delete
vm_openvz'
    remoteUserCredentialIspconfig $remote_user_root
    if [[ -z "$ispconfig_remote_user_password" ]];then
        __; red Informasi credentials tidak lengkap: '`'/usr/local/share/ispconfig/credential/remote/$remote_user_root'`'.; x
    else
        magenta ispconfig_remote_user_password="$ispconfig_remote_user_password"
    fi
    # Populate Variable.
    . ispconfig.sh export >/dev/null
    magenta ispconfig_install_dir="$ispconfig_install_dir"
    if insertRemoteUsernameIspconfig  "$remote_user_root" "$ispconfig_remote_user_password" "$functions" ;then
        __; green Remote username "$remote_user_root" created '(remote_userid:'$remote_userid')'.
    else
        __; red Remote username "$remote_user_root" failed to create.; x
    fi
fi

yellow Mengecek file '`'soap_config.php'`'.
remoteUserCredentialIspconfig $remote_user_root
if [[ -z "$ispconfig_remote_user_password" ]];then
    __; red Informasi credentials tidak lengkap: '`'/usr/local/share/ispconfig/credential/remote/$remote_user_root'`'.; x
else
    magenta ispconfig_remote_user_password="$ispconfig_remote_user_password"
fi
. ispconfig.sh export >/dev/null
magenta scripts_dir="$scripts_dir"

# VarDump scripts_dir ispconfig_remote_user_password
soap_config="${scripts_dir}/soap_config.php"

# VarDump
php=$(cat <<'EOF'
$args = $_SERVER['argv'];
$mode = $args[1];
$file = $args[2];
$arg_username = $args[3];
$arg_password = $args[4];
$arg_subdomain_localhost = $args[5];
$arg_soap_location = 'http://'.$arg_subdomain_localhost.'/remote/index.php';
$arg_soap_uri = 'http://'.$arg_subdomain_localhost.'/remote/';
// var_dump($mode);
// var_dump($file);
// var_dump($arg_username);
// var_dump($arg_password);
// var_dump($arg_soap_location);
// var_dump($arg_soap_uri);
$append = array();
include($file);
$username = isset($username) ? $username : NULL;
$password = isset($password) ? $password : NULL;
$soap_location = isset($soap_location) ? $soap_location : NULL;
$soap_uri = isset($soap_uri) ? $soap_uri : NULL;
// var_dump('---');
// var_dump($username);
// var_dump($password);
// var_dump($soap_location);
// var_dump($soap_uri);
$is_different = false;
if ($username != $arg_username) {
    $is_different = true;
}
if ($password != $arg_password) {
    $is_different = true;
}
if ($password != $arg_password) {
    $is_different = true;
}
if ($soap_location != $arg_soap_location) {
    $is_different = true;
}
if ($soap_uri != $arg_soap_uri) {
    $is_different = true;
}
switch ($mode) {
    case 'is_different':
        $is_different ? exit(0) : exit(1);
        break;
}
EOF
)

# @todo
FQDN_ISPCONFIG=$ISPCONFIG_SUBDOMAIN_LOCALHOST
# VarDump FQDN_ISPCONFIG

is_different=
if php -r "$php" is_different \
    "$soap_config" \
    $remote_user_root \
    $ispconfig_remote_user_password \
    $FQDN_ISPCONFIG;then
    is_different=1
    __ Diperlukan modifikasi file '`'soap_config.php'`'.
else
    __ File '`'soap_config.php'`' tidak ada perubahan.
fi
____

if [ -n "$is_different" ];then
    __ Memodifikasi file '`'soap_config.php'`'.
    __ Backup file "$soap_config"
    backupFile move "$soap_config"
    cat <<EOF > "$soap_config"
<?php

\$username = '$remote_user_root';
\$password = '$ispconfig_remote_user_password';
\$soap_location = 'http://$FQDN_ISPCONFIG/remote/index.php';
\$soap_uri = 'http://$FQDN_ISPCONFIG/remote/';
EOF
    if php -r "$php" is_different \
        "$soap_config" \
        $remote_user_root \
        $ispconfig_remote_user_password \
        $FQDN_ISPCONFIG;then
        __; red Modifikasi file '`'soap_config.php'`' gagal.; exit
    else
        __; green Modifikasi file '`'soap_config.php'`' berhasil.
    fi
    ____
fi

yellow Mengecek Remote User ISPConfig '"'$remote_user_roundcube'"'
notfound=
if isRemoteUsernameIspconfigExist "$remote_user_roundcube" ;then
    __ Found '(remote_userid:'$remote_userid')'.
else
    __ Not Found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Insert Remote User ISPConfig '"'$remote_user_roundcube'"'
    functions='server_get,server_config_set,get_function_list,client_templates_get_all,server_get_serverid_by_ip,server_ip_get,server_ip_add,server_ip_update,server_ip_delete,system_config_set,system_config_get,config_value_get,config_value_add,config_value_update,config_value_replace,config_value_delete
client_get_all,client_get,client_add,client_update,client_delete,client_get_sites_by_user,client_get_by_username,client_get_by_customer_no,client_change_password,client_get_id,client_delete_everything,client_get_emailcontact
mail_user_get,mail_user_add,mail_user_update,mail_user_delete
mail_alias_get,mail_alias_add,mail_alias_update,mail_alias_delete
mail_forward_get,mail_forward_add,mail_forward_update,mail_forward_delete
mail_spamfilter_user_get,mail_spamfilter_user_add,mail_spamfilter_user_update,mail_spamfilter_user_delete
mail_policy_get,mail_policy_add,mail_policy_update,mail_policy_delete
mail_fetchmail_get,mail_fetchmail_add,mail_fetchmail_update,mail_fetchmail_delete
mail_spamfilter_whitelist_get,mail_spamfilter_whitelist_add,mail_spamfilter_whitelist_update,mail_spamfilter_whitelist_delete
mail_spamfilter_blacklist_get,mail_spamfilter_blacklist_add,mail_spamfilter_blacklist_update,mail_spamfilter_blacklist_delete
mail_user_filter_get,mail_user_filter_add,mail_user_filter_update,mail_user_filter_delete'
    remoteUserCredentialIspconfig $remote_user_roundcube
    if [[ -z "$ispconfig_remote_user_password" ]];then
        __; red Informasi credentials tidak lengkap: '`'/usr/local/share/ispconfig/credential/remote/$remote_user_roundcube'`'.; x
    else
        magenta ispconfig_remote_user_password="$ispconfig_remote_user_password"
    fi
    # Populate Variable.
    . ispconfig.sh export >/dev/null
    magenta ispconfig_install_dir="$ispconfig_install_dir"
    if insertRemoteUsernameIspconfig  "$remote_user_roundcube" "$ispconfig_remote_user_password" "$functions" ;then
        __; green Remote username "$remote_user_root" created '(remote_userid:'$remote_userid')'.
    else
        __; red Remote username "$remote_user_roundcube" failed to create.; x
    fi
    ____
fi
