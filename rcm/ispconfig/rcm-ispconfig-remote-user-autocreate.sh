#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --fast) fast=1; shift ;;
        --function=*) function+=("${1#*=}"); shift ;;
        --function) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then function+=("$2"); shift; fi; shift ;;
        --ispconfig-sure) ispconfig_sure=1; shift ;;
        --password=*) password="${1#*=}"; shift ;;
        --password) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then password="$2"; shift; fi; shift ;;
        --username=*) username="${1#*=}"; shift ;;
        --username) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then username="$2"; shift; fi; shift ;;
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

# Functions.
printVersion() {
    echo '0.9.16'
}
printHelp() {
    title RCM ISPConfig Setup
    _ 'Variation '; yellow Internal Command; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-remote-user-autocreate [options]

Options:
   --phpmyadmin-version
        Set the version of PHPMyAdmin
   --roundcube-version
        Set the version of RoundCube
   --ispconfig-version
        Set the version of ISPConfig.

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.

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
title rcm-ispconfig-remote-user-autocreate
____

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'`cut -d: -f1 <<< "${line}"`'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Functions.
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
    #   db_user, db_user_password,
    #   db_name
    #
    # Arguments:
    #   $1: Filter by remote_username.
    #
    # Output:
    #   Write remote_userid to stdout.
    local remote_username="$1"
    local sql="SELECT remote_userid FROM remote_user WHERE remote_username = '$remote_username';"
    local u="$db_user"
    local p="$db_user_password"
    local remote_userid=$(mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        "$db_name" -r -N -s -e "$sql"
    )
    echo "$remote_userid"
}
insertRemoteUsernameIspconfig() {
    #
    # Globals:
    #   db_user, db_user_password,
    #   db_name
    #   prefix
    local remote_username="$1"
    local _remote_password="$2"
    local _remote_functions="$3"
    local php=$(cat <<'EOF'
$mode = $_SERVER['argv'][1];
switch ($mode) {
    case 'password_hash' :
        $path = $_SERVER['argv'][2];
        $string = $_SERVER['argv'][3];
        require($path);
        echo (new auth)->crypt_password($string);
        break;
}
EOF
    )
    local path="${prefix}/interface/lib/classes/auth.inc.php"
    local remote_password=$(php -r "$php" password_hash "$path" "$_remote_password")
    local remote_functions=$(tr '\n' ';' <<< "$_remote_functions")
    local sql="INSERT INTO remote_user
(sys_userid, sys_groupid, sys_perm_user, sys_perm_group, sys_perm_other, remote_username, remote_password, remote_access, remote_ips, remote_functions)
VALUES
(1, 1, 'riud', 'riud', '', '$remote_username', '$remote_password', 'y', '127.0.0.1', '$remote_functions');"
    local u="$db_user"
    local p="$db_user_password"
    mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        "$db_name" -e "$sql"
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
    #   Used:
    #   Modified:
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

# Require, validate, and populate value.
chapter Dump variable.

if [ -z "$username" ];then
    error "Argument --username required."; x
fi
code 'username="'$username'"'
if [ -z "$password" ];then
    error "Argument --password required."; x
fi
code 'password="'$password'"'
if [[ ${#function[@]} -eq 0 ]];then
    error "Argument --function required."; x
fi
declare -i min; min=80
declare -i max; max=100
current_line=
function_string=
for each in "${function[@]}";do
    if [ -z "$current_line" ]; then
        current_line="$each"
        function_string+="$each"
    else
        _current_line="${current_line},${each}"
        if [ "${#_current_line}" -le $min ];then
            current_line+=",${each}"
            function_string+=",${each}"
        elif [ "${#_current_line}" -le $max ];then
            function_string+=",${each}"$'\n'
            current_line=
        else
            function_string+=$'\n'"${each}"
            current_line="$each"
        fi
    fi
done
code 'function_string="'"$function_string"'"'
php_fpm_user=ispconfig
code 'php_fpm_user="'$php_fpm_user'"'
prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
code 'prefix="'$prefix'"'
____

if [ -z "$ispconfig_sure" ];then
    chapter Mengecek ISPConfig User.
    code id -u '"'$php_fpm_user'"'
    if id "$php_fpm_user" >/dev/null 2>&1; then
        __ User '`'$php_fpm_user'`' found.
    else
        error User '`'$php_fpm_user'`' not found.; x
    fi
    ____
fi

chapter Populate variable.
__ Mencari informasi database dari config.
path="${prefix}/interface/lib/config.inc.php"
isFileExists "$path"
[ -n "$notfound" ] && fileMustExists "$path"
code 'path="'$path'"'
db_name=$(php -r "include '$path';echo DB_DATABASE;")
code 'db_name="'$db_name'"'
db_user=$(php -r "include '$path';echo DB_USER;")
code 'db_user="'$db_user'"'
db_user_password=$(php -r "include '$path';echo DB_PASSWORD;")
code 'db_user_password="'$db_user_password'"'
____

chapter Mengecek Remote User ISPConfig '"'$username'"'
notfound=
if isRemoteUsernameIspconfigExist "$username" ;then
    __ Found '(remote_userid:'$remote_userid')'.
elif insertRemoteUsernameIspconfig  "$username" "$password" "$function_string" ;then
    __; green Remote username "$username" created '(remote_userid:'$remote_userid')'.; _.
else
    __; red Remote username "$username" failed to create.; x
fi
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
# --ispconfig-sure
# )
# VALUE=(
# --username
# --password
# )
# MULTIVALUE=(
# --function
# )
# FLAG_VALUE=(
# )
# EOF
# clear
