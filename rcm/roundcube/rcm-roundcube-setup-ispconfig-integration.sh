#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --fast) fast=1; shift ;;
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
ROUNDCUBE_FQDN_LOCALHOST=${ROUNDCUBE_FQDN_LOCALHOST:=roundcube.localhost}
ISPCONFIG_FQDN_LOCALHOST=${ISPCONFIG_FQDN_LOCALHOST:=ispconfig.localhost}
ISPCONFIG_REMOTE_USER_ROUNDCUBE=${ISPCONFIG_REMOTE_USER_ROUNDCUBE:=roundcube}

# Functions.
printVersion() {
    echo '0.9.12'
}
printHelp() {
    title RCM Roundcube Setup
    _ 'Variation '; yellow ISPConfig Integration; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-roundcube-setup-ispconfig-integration [options]

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.

Environment Variables:
   ISPCONFIG_REMOTE_USER_ROUNDCUBE
        Default to $ISPCONFIG_REMOTE_USER_ROUNDCUBE
   ISPCONFIG_FQDN_LOCALHOST
        Default to $ISPCONFIG_FQDN_LOCALHOST
   ROUNDCUBE_FQDN_LOCALHOST
        Default to $ROUNDCUBE_FQDN_LOCALHOST

Dependency:
   mysql
   pwgen
   php
   unzip
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-roundcube-setup-ispconfig-integration
____

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'`cut -d: -f1 <<< "${line}"`'`'.; x; }
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
Rcm_ispconfig_list_functions() {
    cat << 'RCM_ISPCONFIG_LIST_FUNCTIONS'
server_get
server_config_set
get_function_list
client_templates_get_all
server_get_serverid_by_ip
server_ip_get
server_ip_add
server_ip_update
server_ip_delete
system_config_set
system_config_get
config_value_get
config_value_add
config_value_update
config_value_replace
config_value_delete
client_get_all
client_get
client_add
client_update
client_delete
client_get_sites_by_user
client_get_by_username
client_get_by_customer_no
client_change_password
client_get_id
client_delete_everything
client_get_emailcontact
mail_user_get
mail_user_add
mail_user_update
mail_user_delete
mail_alias_get
mail_alias_add
mail_alias_update
mail_alias_delete
mail_forward_get
mail_forward_add
mail_forward_update
mail_forward_delete
mail_spamfilter_user_get
mail_spamfilter_user_add
mail_spamfilter_user_update
mail_spamfilter_user_delete
mail_policy_get
mail_policy_add
mail_policy_update
mail_policy_delete
mail_fetchmail_get
mail_fetchmail_add
mail_fetchmail_update
mail_fetchmail_delete
mail_spamfilter_whitelist_get
mail_spamfilter_whitelist_add
mail_spamfilter_whitelist_update
mail_spamfilter_whitelist_delete
mail_spamfilter_blacklist_get
mail_spamfilter_blacklist_add
mail_spamfilter_blacklist_update
mail_spamfilter_blacklist_delete
mail_user_filter_get
mail_user_filter_add
mail_user_filter_update
mail_user_filter_delete
RCM_ISPCONFIG_LIST_FUNCTIONS
}
dirMustExists() {
    # global used:
    # global modified:
    # function used: __, success, error, x
    if [ -d "$1" ];then
        __; green Direktori '`'$(basename "$1")'`' ditemukan.; _.
    else
        __; red Direktori '`'$(basename "$1")'`' tidak ditemukan.; x
    fi
}
isDirExists() {
    # global used:
    # global modified: found, notfound
    # function used: __
    found=
    notfound=
    if [ -d "$1" ];then
        __ Direktori '`'$(basename "$1")'`' ditemukan.
        found=1
    else
        __ Direktori '`'$(basename "$1")'`' tidak ditemukan.
        notfound=1
    fi
}

# Requirement, validate, and populate value.
chapter Dump variable.
code 'ROUNDCUBE_FQDN_LOCALHOST="'$ROUNDCUBE_FQDN_LOCALHOST'"'
code 'ISPCONFIG_REMOTE_USER_ROUNDCUBE="'$ISPCONFIG_REMOTE_USER_ROUNDCUBE'"'
code 'ISPCONFIG_FQDN_LOCALHOST="'$ISPCONFIG_FQDN_LOCALHOST'"'
nginx_user=
conf_nginx=`command -v nginx > /dev/null && command -v nginx > /dev/null && nginx -V 2>&1 | grep -o -P -- '--conf-path=\K(\S+)'`
if [ -f "$conf_nginx" ];then
    nginx_user=`grep -o -P '^user\s+\K([^;]+)' "$conf_nginx"`
fi
code 'nginx_user="'$nginx_user'"'
if [ -z "$nginx_user" ];then
    error "Variable \$nginx_user failed to populate."; x
fi
php_fpm_user="$nginx_user"
code 'php_fpm_user="'$php_fpm_user'"'
prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
code 'prefix="'$prefix'"'
project_container="$ROUNDCUBE_FQDN_LOCALHOST"
code 'project_container="'$project_container'"'
root="$prefix/${project_container}/web"
code 'root="'$root'"'
root_realpath=$(realpath "$root")
code 'root_realpath="'$root_realpath'"'
if [[ ! $(basename "$root_realpath") == public_html ]];then
    error Direktori tidak bernama '`'public_html'`'.; x
fi
root_source=$(dirname "$root_realpath")
code 'root_source="'$root_source'"'
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
remoteUserCredentialIspconfig $ISPCONFIG_REMOTE_USER_ROUNDCUBE
if [[ -z "$ispconfig_remote_user_name" || -z "$ispconfig_remote_user_password" ]];then
    __; red Informasi credentials tidak lengkap: '`'/usr/local/share/ispconfig/credential/remote/$ISPCONFIG_REMOTE_USER_ROUNDCUBE'`'.; x
else
    code ispconfig_remote_user_name="$ispconfig_remote_user_name"
    code ispconfig_remote_user_password="$ispconfig_remote_user_password"
fi
magenta 'count='$count; _, ' # ${#functions}'; _.
____

INDENT+="    " \
rcm-ispconfig-remote-user-autocreate $isfast --ispconfig-sure \
    --username="$ispconfig_remote_user_name" \
    --password="$ispconfig_remote_user_password" \
    $functions_arg \
    ; [ ! $? -eq 0 ] && x
path="${root_source}/plugins/ispconfig3_account/config/config.inc.php"
filename=config.inc.php
chapter Mengecek existing '`'$filename'`'
isFileExists "$path"
____

if [ -n "$notfound" ];then
    chapter Menginstall Plugin Integrasi Roundcube dan ISPConfig
    php_fpm_user="$nginx_user"
    code 'php_fpm_user="'$php_fpm_user'"'
    code sudo -u $php_fpm_user mkdir -p '"'$root_source'"'
    sudo -u $php_fpm_user mkdir -p "$root_source"
    cd $root_source
    __ Mendownload Plugin
    path="${root_source}/ispconfig3_roundcube-master.zip"
    isFileExists "$path"
    if [ -n "$notfound" ];then
        code sudo -u $php_fpm_user wget "https://github.com/w2c/ispconfig3_roundcube/archive/master.zip" -O ispconfig3_roundcube-master.zip
        sudo -u $php_fpm_user wget "https://github.com/w2c/ispconfig3_roundcube/archive/master.zip" -O ispconfig3_roundcube-master.zip
        fileMustExists "$path"
    fi
    [ -f "$path" ] || fileMustExists "$path"
    __ Extract File.
    path_zip="$path"
    path="${root_source}/ispconfig3_roundcube-master"
    isDirExists "$path"
    if [ -n "$notfound" ];then
        code sudo -u $php_fpm_user unzip -u -qq "$path_zip"
        sudo -u $php_fpm_user unzip -u -qq "$path_zip"
        dirMustExists "$path"
    fi
    [ -d "$path" ] || dirMustExists "$path"
    __ Memindahkan hasil download ke plugin.
    code find ispconfig3_roundcube-master -maxdepth 1 -mindepth 1 -type d -path "'"ispconfig3_roundcube-master/ispconfig3_*"'" '-exec mv -t plugins {} \;'
    find ispconfig3_roundcube-master -maxdepth 1 -mindepth 1 -type d -path 'ispconfig3_roundcube-master/ispconfig3_*' -exec mv -t plugins {} \;
    path="${root_source}/plugins/ispconfig3_account/config/config.inc.php"
    isFileExists "$path"
    if [ -n "$notfound" ];then
        source="${root_source}/plugins/ispconfig3_account/config/config.inc.php.dist"
        fileMustExists "$source"
        code sudo -u $php_fpm_user cp "$source" "$path"
        sudo -u $php_fpm_user cp "$source" "$path"
        fileMustExists "$path"
    fi
    cd - >/dev/null
    ____
fi
[ -f "$path" ] || fileMustExists "$path"

php=$(cat <<'EOF'
$mode = $_SERVER['argv'][1];
switch ($mode) {
    case 'array_is_different':
    case 'append':
        $file = $_SERVER['argv'][2];
        $key = $_SERVER['argv'][3];
        $reference = unserialize($_SERVER['argv'][4]);
        include($file);
        $config = isset($config) ? $config : [];
        if (!array_key_exists($key, $config)) {
            $config[$key] = [];
        }
        if (!is_array($config[$key])) {
            $config[$key] = (array) $config[$key];
        }
        $is_different = !empty(array_diff($reference, $config[$key]));
        break;
    case 'is_different':
    case 'save':
        # Populate variable $is_different.
        $file = $_SERVER['argv'][2];
        $reference = unserialize($_SERVER['argv'][3]);
        include($file);
        $config = isset($config) ? $config : [];
        $is_different = !empty(array_diff_assoc(array_map('serialize',$reference), array_map('serialize',$config)));
        break;
}
switch ($mode) {
    case 'is_different':
    case 'array_is_different':
        $is_different ? exit(0) : exit(1);
        break;
    case 'append':
        if (!$is_different) {
            exit(0);
        }
        $contents = file_get_contents($file);
        $need_edit = array_diff($reference, $config[$key]);
        $new_lines = [];
        // Method append tidak bisa menghapus existing.
        foreach ($need_edit as $value) {
            $new_line = "__PARAMETER__[__KEY__][] = __VALUE__; # managed by RCM";
            $new_line = str_replace(['__PARAMETER__','__KEY__','__VALUE__'],['$config', var_export($key, true), var_export($value, true)], $new_line);
            $new_lines[] = $new_line;
        }
        if (substr($contents, -1) != "\n") {
            $contents .= "\n";
        }
        $contents .= implode("\n", $new_lines);
        $contents .= "\n";
        file_put_contents($file, $contents);
        break;
    case 'save':
        if (!$is_different) {
            exit(0);
        }
        $contents = file_get_contents($file);
        $need_edit = array_diff_assoc($reference, $config);
        $new_lines = [];
        // Method save bisa menghapus existing.
        foreach ($need_edit as $key => $value) {
            $new_line = "__PARAMETER__[__KEY__] = __VALUE__; # managed by RCM";
            // Jika indexed array dan hanya satu , maka buat one line.
            if (is_array($value) && array_key_exists(0, $value) && count($value) === 1) {
                $new_line = str_replace(['__PARAMETER__','__KEY__','__VALUE__'],['$config', var_export($key, true), "['".$value[0]."']"], $new_line);
            }
            else {
                $new_line = str_replace(['__PARAMETER__','__KEY__','__VALUE__'],['$config', var_export($key, true), var_export($value, true)], $new_line);
            }
            $is_one_line = preg_match('/\n/', $new_line) ? false : true;
            $find_existing = "__PARAMETER__[__KEY__] = __VALUE__; # managed by RCM";
            $find_existing = str_replace(['__PARAMETER__','__KEY__'],['$config', var_export($key, true)], $find_existing);
            $find_existing = preg_quote($find_existing);
            $find_existing = str_replace('__VALUE__', '.*', $find_existing);
            $find_existing = '/\s*'.$find_existing.'/';
            if ($is_one_line && preg_match_all($find_existing, $contents, $matches, PREG_PATTERN_ORDER)) {
                $contents = str_replace($matches[0], '', $contents);
            }
            $new_lines[] = $new_line;
        }
        if (substr($contents, -1) != "\n") {
            $contents .= "\n";
        }
        $contents .= implode("\n", $new_lines);
        $contents .= "\n";
        file_put_contents($file, $contents);
        break;
}
EOF
)

chapter Mengecek informasi file konfigurasi RoundCube plugin '`'ispconfig3_account'`'.
path="${root_source}/plugins/ispconfig3_account/config/config.inc.php"
code 'path="'$path'"'
reference="$(php -r "echo serialize([
    'identity_limit' => false,
    'remote_soap_user' => '$ispconfig_remote_user_name',
    'remote_soap_pass' => '$ispconfig_remote_user_password',
    'soap_url' => 'http://${ISPCONFIG_FQDN_LOCALHOST}/remote/',
    'soap_validate_cert' => false,
]);")"
is_different=
if php -r "$php" is_different "$path" "$reference";then
    is_different=1
    __ Diperlukan modifikasi file '`'config.inc.php'`'.
else
    __ File '`'config.inc.php'`' tidak ada perubahan.
fi
____

if [ -n "$is_different" ];then
    chapter Memodifikasi file '`'config.inc.php'`'.
    __ Backup file "$path"
    backupFile copy "$path"
    php -r "$php" save "$path" "$reference"
    if php -r "$php" is_different "$path" "$reference";then
        __; red Modifikasi file '`'config.inc.php'`' gagal.; x
    else
        __; green Modifikasi file '`'config.inc.php'`' berhasil.; _.
    fi
    ____
fi

chapter Mengecek informasi file konfigurasi RoundCube.
path="${root_source}/config/config.inc.php"
code 'path="'$path'"'
reference="$(php -r "echo serialize([
    'ispconfig3_account',
    'ispconfig3_autoreply',
    'ispconfig3_pass',
    'ispconfig3_filter',
    'ispconfig3_forward',
    'ispconfig3_wblist',
    'identity_select',
]);")"
is_different=
if php -r "$php" array_is_different "$path" plugins "$reference";then
    is_different=1
    __ Diperlukan modifikasi file '`'config.inc.php'`'.
else
    __ File '`'config.inc.php'`' tidak ada perubahan.
fi
____

if [ -n "$is_different" ];then
    chapter Memodifikasi file '`'config.inc.php'`'.
    __ Backup file "$path"
    backupFile copy "$path"
    php -r "$php" append "$path" plugins "$reference"
    if php -r "$php" array_is_different "$path" plugins "$reference";then
        __; red Modifikasi file '`'config.inc.php'`' gagal.; x
    else
        __; green Modifikasi file '`'config.inc.php'`' berhasil.; _.
    fi
    ____
fi

chapter Mengecek informasi file konfigurasi RoundCube.
path="${root_source}/config/config.inc.php"
code 'path="'$path'"'
reference="$(php -r "echo serialize([
    'identity_select_headers' => ['To'],
]);")"
is_different=
if php -r "$php" is_different "$path" "$reference";then
    is_different=1
    __ Diperlukan modifikasi file '`'config.inc.php'`'.
else
    __ File '`'config.inc.php'`' tidak ada perubahan.
fi
____

if [ -n "$is_different" ];then
    chapter Memodifikasi file '`'config.inc.php'`'.
    __ Backup file "$path"
    backupFile copy "$path"
    php -r "$php" save "$path" "$reference"
    if php -r "$php" is_different "$path" "$reference";then
        __; red Modifikasi file '`'config.inc.php'`' gagal.; x
    else
        __; green Modifikasi file '`'config.inc.php'`' berhasil.; _.
    fi
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
# )
# VALUE=(
# )
# FLAG_VALUE=(
# )
# EOF
# clear
