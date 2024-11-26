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
    title RCM ISPConfig Setup
    _ 'Variation '; yellow Internal Command; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << 'EOF'
Usage: rcm-ispconfig-setup-internal-command [options]

Options:

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
   ISPCONFIG_INSTALL_DIR
        Default to /usr/local/ispconfig
   ISPCONFIG_DB_USER_HOST
        Default to localhost
   ISPCONFIG_REMOTE_USER_ROOT
        Default to root
   ISPCONFIG_FQDN_LOCALHOST
        Default to ispconfig.localhost

Dependency:
   mysql
   pwgen
   php
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-setup-internal-command
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
link_symbolic() {
    local source="$1"
    local target="$2"
    local sudo="$3"
    local create
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
        local source_relative=$(realpath -s --relative-to="$target_parent" "$source")
        if [ -n "$sudo" ];then
            code sudo -u '"'$sudo'"' ln -s '"'$source_relative'"' '"'$target'"'
            sudo -u "$sudo" ln -s "$source_relative" "$target"
        else
            code ln -s '"'$source_relative'"' '"'$target'"'
            ln -s "$source_relative" "$target"
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
getRemoteUserIdIspconfigByRemoteUsername() {
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
isRemoteUsernameIspconfigExist() {
    # Insert the remote_username to table remote_user in ispconfig database.
    #
    # Globals:
    #   Used: ispconfig_install_dir
    #         ispconfig_db_user_host
    #         ispconfig_db_user
    #         ispconfig_db_name
    #         ispconfig_db_user_password
    #   Modified: remote_userid
    #
    # Arguments:
    #   $1: remote_username
    #   $2: remote_password
    #   $3: remote_functions
    #
    # Return:
    #   0 if exists.
    #   1 if not exists.
    local remote_username="$1"
    remote_userid=$(getRemoteUserIdIspconfigByRemoteUsername "$remote_username")
    if [ -n "$remote_userid" ];then
        return 0
    fi
    return 1
}

# Requirement, validate, and populate value.
chapter Dump variable.
delay=.5; [ -n "$fast" ] && unset delay
__FILE__=$(resolve_relative_path "$0")
__DIR__=$(dirname "$__FILE__")
BINARY_DIRECTORY=${BINARY_DIRECTORY:=$__DIR__}
code 'BINARY_DIRECTORY="'$BINARY_DIRECTORY'"'
ISPCONFIG_REMOTE_USER_ROOT=${ISPCONFIG_REMOTE_USER_ROOT:=root}
code 'ISPCONFIG_REMOTE_USER_ROOT="'$ISPCONFIG_REMOTE_USER_ROOT'"'
ISPCONFIG_FQDN_LOCALHOST=${ISPCONFIG_FQDN_LOCALHOST:=ispconfig.localhost}
NEW_VERSION=`printVersion`
code 'NEW_VERSION="'$NEW_VERSION'"'
mktemp=
____

chapter Mengecek '`'ispconfig.php'`' command.
fullpath=/usr/local/share/ispconfig/bin/ispconfig.php
dirname=/usr/local/share/ispconfig/bin
isFileExists "$fullpath"
____

update=
if [ -n "$found" ];then
    chapter Mengecek versi '`'ispconfig.php'`' command.
    code ispconfig.php --version
    if [ -z "$mktemp" ];then
        mktemp=$(mktemp -p /dev/shm)
    fi
    "$fullpath" --version | tee $mktemp
    old_version=$(head -1 $mktemp)
    if [[ "$old_version" =~ [^0-9\.]+ ]];then
        old_version=0
    fi
    vercomp $NEW_VERSION $old_version
    if [[ $? -eq 1 ]];then
        __ Command perlu diupdate. Versi saat ini ${NEW_VERSION}.
        found=
        notfound=1
        update=1
    else
        __ Command tidak perlu diupdate. Versi saat ini ${NEW_VERSION}.
    fi
    ____
fi

if [ -n "$notfound" ];then
    chapter Create Drupal Command '`'ispconfig.php'`'.
    mkdir -p "$dirname"
    touch "$fullpath"
    chmod a+x "$fullpath"
    cat << 'EOF' > "$fullpath"
#!/usr/bin/php
<?php
define('ISPCONFIG_REMOTE_USER_ROOT', '__ISPCONFIG_REMOTE_USER_ROOT__');
define('ISPCONFIG_FQDN_LOCALHOST', '__ISPCONFIG_FQDN_LOCALHOST__');
define('NEW_VERSION', '__NEW_VERSION__');
$argc > 1 or die('Command required.'.PHP_EOL);
if (in_array('--version', $argv)) {
    echo NEW_VERSION.PHP_EOL; exit;
}

// Run Command.
$command = $argv[1];
switch ($command) {
    case 'mail_domain':
        $output = shell_exec('id -u ispconfig');
        $eid = rtrim($output);
        $user = posix_getpwuid($eid);
        $home = $user['dir'];
        chdir($home.'/interface/web');
        require_once '../lib/config.inc.php';
        require_once '../lib/app.inc.php';
        // The variable $app is ready.
        break;
    case 'login':
    case 'mail_user_add':
    case 'mail_user_get':
    case 'mail_domain_get_by_domain':
        $path = '/usr/local/share/ispconfig/credential/remote/'.ISPCONFIG_REMOTE_USER_ROOT;
        if (!file_exists($path)) {
            fwrite(STDERR, 'File not found: '.$path.PHP_EOL);
            exit(1);
        }
        preg_match_all('/(.*)=(.*)/', file_get_contents($path), $matches);
        list($username, $password) = $matches[2];
        $options = [
            'location' => 'http://'.ISPCONFIG_FQDN_LOCALHOST.'/remote/index.php',
            'uri' => 'http://'.ISPCONFIG_FQDN_LOCALHOST.'/remote/',
            'trace' => 1,
            'exceptions' => 1,
        ];
        break;
}
switch ($command) {
    case 'mail_domain':
        $results = $app->db->queryAllRecords("SELECT domain FROM mail_domain");
        foreach ($results as $result) {
            echo $result['domain'].PHP_EOL;
        }
        break;

    case 'login':
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
                echo 'Logged successfull. Session ID: '.$session_id.PHP_EOL;
            }
            if($client->logout($session_id)) {
                echo 'Logged out.'.PHP_EOL;
            }
        } catch (SoapFault $e) {
            fwrite(STDERR, 'SOAP Error: '.$e->getMessage().PHP_EOL);
            exit(1);
        }
        break;
    case 'mail_domain_get_by_domain':
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            // Copy arguments.
            $arguments = $argv;
            array_shift($arguments); // Remove full path of script.
            array_shift($arguments); // Remove commands.
            $argument = array_shift($arguments); // Harusnya value dari domain.
            if (!$argument) {
                throw new RuntimeException('Argument <email> is required.');
            }
            $record_record = $client->mail_domain_get_by_domain($session_id, $argument);
            print_r($record_record);
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            fwrite(STDERR, 'SOAP Error: '.$e->getMessage().PHP_EOL);
            exit(1);
        } catch (Exception $e) {
            fwrite(STDERR, 'Error: '.$e->getMessage().PHP_EOL);
            exit(1);
        }
        break;
    case 'mail_user_get':
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            // Copy arguments.
            $arguments = $argv;
            array_shift($arguments); // Remove full path of script.
            array_shift($arguments); // Remove commands.
            $params = [];
            while ($each = array_shift($arguments)) {
                preg_match('/^--(.*)=(.*)$/', $each, $matches_2);
                if (count($matches_2) == 3) {
                    list( , $key, $value) = $matches_2;
                    $params[$key] = $value;
                }
            }
            if (!array_key_exists('email', $params)) {
                throw new RuntimeException('Argument --email=* is required.');
            }
            $record_record = $client->mail_user_get($session_id, $params);
            print_r($record_record);
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            fwrite(STDERR, 'SOAP Error: '.$e->getMessage().PHP_EOL);
            exit(1);
        } catch (Exception $e) {
            fwrite(STDERR, 'Error: '.$e->getMessage().PHP_EOL);
            exit(1);
        }
        break;
    case 'mail_user_add':
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            // Copy arguments.
            $arguments = $argv;
            array_shift($arguments); // Remove full path of script.
            array_shift($arguments); // Remove commands.
            $argument = array_shift($arguments); // Harusnya value dari client_id.
            if (is_numeric($argument)) {
                $client_id = (int) $argument;
            }
            else {
                $client_id = 0;
                array_unshift($arguments, $argument);
            }
            $params = [];
            while ($each = array_shift($arguments)) {
                preg_match('/^--(.*)=(.*)$/', $each, $matches_2);
                if (count($matches_2) == 3) {
                    list( , $key, $value) = $matches_2;
                    $params[$key] = $value;
                }
            }
            if (!array_key_exists('email', $params)) {
                throw new RuntimeException('Argument --email=* is required.');
            }
            if (!array_key_exists('password', $params)) {
                throw new RuntimeException('Argument --password=* is required.');
            }
            if (!array_key_exists('login', $params)) {
                $params['login'] = $params['email'];
            }
            preg_match('/^(.*)@(.*)$/', $params['email'], $matches_3);
            if (!count($matches_3) == 3) {
                throw new InvalidArgumentException('Format --email=* is not valid.');
            }
            list(, $user, $host) = $matches_3;
            $default = [
                'server_id' => '1',
                'name' => $user,
                'uid' => '5000',
                'gid' => '5000',
                'maildir' => "/var/vmail/$host/$user",
                'maildir_format' => 'maildir',
                'quota' => '0',
                'cc' => '',
                'forward_in_lda' => 'y',
                'sender_cc' => '',
                'homedir' => '/var/vmail',
                'autoresponder' => 'n',
                'autoresponder_start_date' => NULL,
                'autoresponder_end_date' => NULL,
                'autoresponder_subject' => '',
                'autoresponder_text' => '',
                'move_junk' => 'Y',
                'purge_trash_days' => 0,
                'purge_junk_days' => 0,
                'custom_mailfilter' => NULL,
                'postfix' => 'y',
                'greylisting' => 'n',
                'access' => 'y',
                'disableimap' => 'n',
                'disablepop3' => 'n',
                'disabledeliver' => 'n',
                'disablesmtp' => 'n',
                'disablesieve' => 'n',
                'disablesieve-filter' => 'n',
                'disablelda' => 'n',
                'disablelmtp' => 'n',
                'disabledoveadm' => 'n',
                'disablequota-status' => 'n',
                'disableindexer-worker' => 'n',
                'last_quota_notification' => NULL,
                'backup_interval' => 'none',
                'backup_copies' => '1',
            ];
            $params += $default;
            $record_record = $client->mail_user_add($session_id, $client_id, $params);
            print_r($record_record);
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            fwrite(STDERR, 'SOAP Error: '.$e->getMessage().PHP_EOL);
            exit(1);
        } catch (Exception $e) {
            fwrite(STDERR, 'Error: '.$e->getMessage().PHP_EOL);
            exit(1);
        }
        break;
}
EOF
    sed -i "s|__ISPCONFIG_REMOTE_USER_ROOT__|${ISPCONFIG_REMOTE_USER_ROOT}|g" "$fullpath"
    sed -i "s|__ISPCONFIG_FQDN_LOCALHOST__|${ISPCONFIG_FQDN_LOCALHOST}|g" "$fullpath"
    sed -i "s|__NEW_VERSION__|${NEW_VERSION}|g" "$fullpath"
    fileMustExists "$fullpath"
    ____
fi

link_symbolic "$fullpath" "$BINARY_DIRECTORY/ispconfig.php"

chapter Mengecek '`'ispconfig.php'`' autocompletion.
fullpath=/etc/profile.d/ispconfig-php-completion.sh
dirname=/etc/profile.d
isFileExists "$fullpath"
if [ -n "$found" ];then
    if [ -n "$update" ];then
        __ Autocompletion perlu diupdate.
        found=
        notfound=1
    else
        __ Autocompletion tidak perlu diupdate.
    fi
fi
____

if [ -n "$notfound" ];then
    chapter Create ISPConfig Command '`'ispconfig.php'`' autocompletion.
    mkdir -p "$dirname"
    touch "$fullpath"
    chmod a+x "$fullpath"
    cat << 'EOF' > "$fullpath"
#!/bin/bash
_ispconfig_php() {
    local cur prev
    cur=${COMP_WORDS[COMP_CWORD]}
    prev=${COMP_WORDS[COMP_CWORD-1]}
    case ${COMP_CWORD} in
        1)
            COMPREPLY=($(compgen -W "login mail_domain mail_domain_get_by_domain mail_user_get mail_user_add" -- ${cur}))
            ;;
        *)
            command=${COMP_WORDS[1]}
            case "$command" in
                mail_user_get)
                    if [ -z "$cur" ];then
                        COMPREPLY=($(compgen -W "--email= --email=-" -- ${cur}))
                    fi
                    ;;
                mail_user_add)
                    if [ -z "$cur" ];then
                        COMPREPLY=($(compgen -W "--email= --password=" -- ${cur}))
                    elif [ "$cur" == -- ];then
                        COMPREPLY=($(compgen -W "--email= --password=" -- ${cur}))
                    else
                        COMPREPLY=($(compgen -W "--email= --email=- --password= --password=-" -- ${cur}))
                    fi
                    ;;
            esac
            ;;
    esac
}
complete -F _ispconfig_php ispconfig.php
EOF
    fileMustExists "$fullpath"
    ____
fi

if [ -n "$mktemp" ];then
    rm "$mktemp"
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
# )
# FLAG_VALUE=(
# )
# EOF
# clear
