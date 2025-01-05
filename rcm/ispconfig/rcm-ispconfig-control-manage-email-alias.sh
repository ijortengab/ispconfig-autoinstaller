#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --destination-domain=*) destination_domain="${1#*=}"; shift ;;
        --destination-domain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then destination_domain="$2"; shift; fi; shift ;;
        --destination-name=*) destination_name="${1#*=}"; shift ;;
        --destination-name) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then destination_name="$2"; shift; fi; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then domain="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --ispconfig-domain-exists-sure) ispconfig_domain_exists_sure=1; shift ;;
        --ispconfig-soap-exists-sure) ispconfig_soap_exists_sure=1; shift ;;
        --name=*) name="${1#*=}"; shift ;;
        --name) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then name="$2"; shift; fi; shift ;;
        --root-sure) root_sure=1; shift ;;
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

# Functions.
printVersion() {
    echo '0.9.12'
}
printHelp() {
    title RCM ISPConfig Control
    _ 'Variation '; yellow Manage Email Alias; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-control-manage-email-alias [options]

Options:
   --name
        The name of email alias.
   --domain
        The domain of email alias.
   --destination-name
        The destination name of email alias.
   --destination-domain
        The destination domain of email alias.
   --
        Every arguments after double dash will pass to \`rcm-php-ispconfig soap mail_alias_add\` command.

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.
   --root-sure
        Bypass root checking.
   --ispconfig-domain-exists-sure
        Bypass domain exists checking.

Environment Variables:
   ISPCONFIG_REMOTE_USER_ROOT
        Default to root
   ISPCONFIG_FQDN_LOCALHOST
        Default to ispconfig.localhost
   MARIADB_PREFIX_MASTER
        Default to /usr/local/share/mariadb
   MARIADB_USERS_CONTAINER_MASTER
        Default to users

Dependency:
   rcm-ispconfig-control-manage-domain:`printVersion`
   rcm-php-ispconfig:`printVersion`
   php
   mysql

Download:
   [rcm-ispconfig-control-manage-domain](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-domain.sh)
   [rcm-php-ispconfig](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/php/rcm-php-ispconfig.php)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-control-manage-email-alias
____

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'$line'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

if [ -z "$root_sure" ];then
    chapter Mengecek akses root.
    if [[ "$EUID" -ne 0 ]]; then
        error This script needs to be run with superuser privileges.; x
    else
        __ Privileges.
    fi
    ____
fi

# Functions.
populateDatabaseUserPassword() {
    local path="${MARIADB_PREFIX_MASTER}/${MARIADB_USERS_CONTAINER_MASTER}/$1"
    local DB_USER DB_USER_PASSWORD
    if [ -f "$path" ];then
        . "$path"
        db_user_password=$DB_USER_PASSWORD
    fi
}
getUserIdRoundcubeByUsername() {
    # Get the user_id from table users in roundcube database.
    #
    # Globals:
    #   db_user, db_user_password,
    #   db_user_host, db_name
    #
    # Arguments:
    #   $1: Filter by username.
    #
    # Output:
    #   Write user_id to stdout.
    local username="$1"
    local sql="SELECT user_id FROM users WHERE username = '$username';"
    local u="$db_user"
    local p="$db_user_password"
    local user_id=$(mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        "$db_name" -r -N -s -e "$sql"
    )
    echo "$user_id"
}
isUsernameRoundcubeExist() {
    # Check if the username from table users exists in roundcube database.
    #
    # Globals:
    #   Used: db_user, db_user_password,
    #         db_user_host, db_name
    #   Modified: user_id
    #
    # Arguments:
    #   $1: username to be checked.
    #
    # Return:
    #   0 if exists.
    #   1 if not exists.
    local username="$1"
    user_id=$(getUserIdRoundcubeByUsername "$username")
    if [ -n "$user_id" ];then
        return 0
    fi
    return 1
}
insertUsernameRoundcube() {
    # Insert the username to table users in roundcube database.
    #
    # Globals:
    #   Used: db_user, db_user_password,
    #         db_user_host, db_name
    #   Modified: user_id
    #
    # Arguments:
    #   $1: username to be checked.
    #   $2: mail host (if omit, default to localhost)
    #   $3: language (if omit, default to en_US)
    #
    # Return:
    #   0 if exists.
    #   1 if not exists.
    local username="$1"
    local mail_host="$2"; [ -n "$mail_host" ] || mail_host=localhost
    local language="$3"; [ -n "$language" ] || language=en_US
    local now=$(date +%Y-%m-%d\ %H:%M:%S)
    local sql="INSERT INTO users
        (created, last_login, username, mail_host, language)
        VALUES
        ('$now', '$now', '$username', '$mail_host', '$language');"
    local u="$db_user"
    local p="$db_user_password"
    mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        "$db_name" -e "$sql"
    user_id=$(getUserIdRoundcubeByUsername "$username")
    if [ -n "$user_id" ];then
        return 0
    fi
    return 1
}
getIdentityIdRoundcubeByEmail() {
    # Get the user_id from table users in roundcube database.
    #
    # Globals:
    #   db_user, db_user_password,
    #   db_user_host, db_name
    #
    # Arguments:
    #   $1: Filter by standard.
    #   $2: Filter by email.
    #   $3: Filter by user_id.
    #
    # Output:
    #   Write identity_id to stdout.
    local standard="$1"
    local email="$2"
    local user_id="$3"
    local sql="SELECT identity_id FROM identities WHERE standard = '$standard' and email = '$email' and user_id = '$user_id';"
    local u="$db_user"
    local p="$db_user_password"
    local identity_id=$(mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        "$db_name" -r -N -s -e "$sql"
    )
    echo "$identity_id"
}
isIdentitiesRoundcubeExist() {
    # Check if the username from table users exists in roundcube database.
    #
    # Globals:
    #   Used: db_user, db_user_password,
    #         db_user_host, db_name
    #   Modified: identity_id
    #
    # Arguments:
    #   $1: username to be checked.
    #
    # Return:
    #   0 if exists.
    #   1 if not exists.
    local standard="$1"
    local email="$2"
    local user_id="$3"
    identity_id=$(getIdentityIdRoundcubeByEmail "$standard" "$email" "$user_id")
    if [ -n "$identity_id" ];then
        return 0
    fi
    return 1
}
insertIdentitiesRoundcube() {
    # Insert the username to table users in roundcube database.
    #
    # Globals:
    #   Used: db_user, db_user_password,
    #         db_user_host, db_name
    #   Modified: identity_id
    #
    # Arguments:
    #   $1: standard
    #   $2: email
    #   $3: user_id
    #   $4: name
    #   $5: organization
    #   $6: reply_to
    #   $7: bcc
    #   $8: html_signature (if omit, default to 0)
    #
    # Return:
    #   0 if exists.
    #   1 if not exists.
    local standard="$1"
    local email="$2"
    local user_id="$3"
    local name="$4"
    local organization="$5"
    local reply_to="$6"
    local bcc="$7"
    local html_signature="$8"; [ -n "$html_signature" ] || html_signature=0
    local now=$(date +%Y-%m-%d\ %H:%M:%S)
    local sql="INSERT INTO identities
        (user_id, changed, del, standard, name, organization, email, \`reply-to\`, bcc, html_signature)
        VALUES
        ('$user_id', '$now', 0, $standard, '$name', '$organization', '$email', '$reply_to', '$reply_to', $html_signature);"
    local u="$db_user"
    local p="$db_user_password"
    mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        "$db_name" -e "$sql"
    identity_id=$(getIdentityIdRoundcubeByEmail "$standard" "$email" "$user_id")
    if [ -n "$identity_id" ];then
        return 0
    fi
    return 1
}
isMailboxExists() {
    # global $user, $host, $tempfile
    # global modified $mailuser_id
    [ -n "$user" ] || { error Variable user is required; x; }
    [ -n "$host" ] || { error Variable host is required; x; }
    [ -n "$tempfile" ] || { error Variable tempfile is required; x; }
    local email="${user}@${host}"
    code rcm-php-ispconfig soap --empty-array-is-false mail_user_get --email='"'$email'"'
    rcm-php-ispconfig soap --empty-array-is-false mail_user_get --email="$email" 2>&1 &> "$tempfile"
    local exit_code=$?
    if [ $exit_code -eq 0 ];then
        mailuser_id=$(rcm-php-ispconfig echo [0][mailuser_id] < "$tempfile")
        __; magenta mailuser_id=$mailuser_id; _.
    else
        while IFS= read line; do e "$line"; _.; done < "$tempfile"
    fi
    return $exit_code
}
isExists() {
    # global $destination, $source, $tempfile
    # global modified $forwarding_id
    [ -n "$source" ] || { error Variable source is required; x; }
    [ -n "$destination" ] || { error Variable destination is required; x; }
    [ -n "$tempfile" ] || { error Variable tempfile is required; x; }
    code rcm-php-ispconfig soap --empty-array-is-false mail_alias_get --source='"'$source'"' --destination='"'$destination'"'
    rcm-php-ispconfig soap --empty-array-is-false mail_alias_get --source="$source" --destination="$destination" 2>&1 &> "$tempfile"
    local exit_code=$?
    if [ $exit_code -eq 0 ];then
        forwarding_id=$(rcm-php-ispconfig echo [0][forwarding_id] < "$tempfile")
        __; magenta forwarding_id=$forwarding_id; _.
    else
        while IFS= read line; do e "$line"; _.; done < "$tempfile"
    fi
    return $exit_code
}
create() {
    # global $destination, $source, $tempfile
    # global modified $forwarding_id
    [ -n "$source" ] || { error Variable source is required; x; }
    [ -n "$destination" ] || { error Variable destination is required; x; }
    [ -n "$tempfile" ] || { error Variable tempfile is required; x; }

    ____; client_id=$(INDENT+="    " rcm-ispconfig-control-manage-client $isfast get-client-id --username "$domain")
    code 'client_id="'$client_id'"'
    [ -n "$client_id" ] || { client_id=0; code 'client_id="'$client_id'"'; }
    code rcm-php-ispconfig soap mail_alias_add '"'$client_id'"' --server-id='"'1'"' --source='"'$source'"' --destination='"'$destination'"' "$@"
    rcm-php-ispconfig soap mail_alias_add "$client_id" --server-id="1" --source="$source" --destination="$destination" "$@" 2>&1 &> "$tempfile"
    local exit_code=$?
    if [ $exit_code -eq 0 ];then
        forwarding_id=$(cat "$tempfile" | rcm-php-ispconfig echo)
        __; magenta forwarding_id=$forwarding_id; _.
    else
        while IFS= read line; do e "$line"; _.; done < "$tempfile"
    fi
    return $exit_code
}

# Require, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
ISPCONFIG_REMOTE_USER_ROOT=${ISPCONFIG_REMOTE_USER_ROOT:=root}
code 'ISPCONFIG_REMOTE_USER_ROOT="'$ISPCONFIG_REMOTE_USER_ROOT'"'
ISPCONFIG_FQDN_LOCALHOST=${ISPCONFIG_FQDN_LOCALHOST:=ispconfig.localhost}
code 'ISPCONFIG_FQDN_LOCALHOST="'$ISPCONFIG_FQDN_LOCALHOST'"'
MARIADB_PREFIX_MASTER=${MARIADB_PREFIX_MASTER:=/usr/local/share/mariadb}
code 'MARIADB_PREFIX_MASTER="'$MARIADB_PREFIX_MASTER'"'
MARIADB_USERS_CONTAINER_MASTER=${MARIADB_USERS_CONTAINER_MASTER:=users}
code 'MARIADB_USERS_CONTAINER_MASTER="'$MARIADB_USERS_CONTAINER_MASTER'"'
if [ -z "$domain" ];then
    error "Argument --domain required."; x
fi
code 'domain="'$domain'"'
if [ -z "$name" ];then
    error "Argument --name required."; x
fi
code 'name="'$name'"'
if [ -z "$destination_name" ];then
    error "Argument --destination-name required."; x
fi
code 'destination_name="'$destination_name'"'
if [ -z "$destination_domain" ];then
    error "Argument --destination-domain required."; x
fi
code 'destination_domain="'$destination_domain'"'
code 'ispconfig_domain_exists_sure="'$ispconfig_domain_exists_sure'"'
code 'ispconfig_soap_exists_sure="'$ispconfig_soap_exists_sure'"'
mariadb_project_name=roundcube
code 'mariadb_project_name="'$mariadb_project_name'"'
tempfile=
____

if [ -z "$ispconfig_domain_exists_sure" ];then
    INDENT+="    " \
    rcm-ispconfig-control-manage-domain $isfast --root-sure \
        --domain="$domain" \
        ; [ ! $? -eq 0 ] && x
fi

if [ -z "$ispconfig_soap_exists_sure" ];then
    chapter Test koneksi SOAP.
    code rcm-php-ispconfig soap login
    if [ -z "$tempfile" ];then
        tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-control-manage-email-mailbox.XXXXXX)
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

chapter Populate variable.
db_name="$mariadb_project_name"
db_user="$mariadb_project_name"
code 'db_name="'$db_name'"'
code 'db_user="'$db_user'"'
populateDatabaseUserPassword "$db_user"
code 'db_user_password="'$db_user_password'"'
____

if [ -z "$tempfile" ];then
    tempfile=$(mktemp -p /dev/shm -t rcm-ispconfig-control-manage-email-mailbox.XXXXXX)
fi

user="$destination_name"
host="$destination_domain"
email="${user}@${host}"
chapter Mengecek mailbox destination '`'$email'`'
if isMailboxExists;then
    __ Email Destination '`'$email'`' found.
else
    __; red Email Destination '`'$email'`' not found.; x
fi
____

user="$name"
host="$domain"
email="${user}@${host}"
chapter Mengecek mailbox '`'$email'`'
if isMailboxExists;then
    __; red Email Mailbox '`'$email'`' already exists.; x
else
    __ Email Mailbox '`'$email'`' not found.
fi
____

destination="$destination_name"@"$destination_domain"
source="$name"@"$domain"
chapter Mengecek alias of "$source"
if isExists;then
    __ Email "$source" alias of "$destination" already exists.
elif create "$@";then
    success Email "$source" alias of "$destination" created.
else
    error Email "$source" alias of "$destination" failed to create.; x
fi
____

username="$destination_name"@"$destination_domain"
chapter Mengecek username destination "$username" di Roundcube.
if isUsernameRoundcubeExist "$username";then
    __ Username "$username" already exists.
    __; magenta user_id=$user_id; _.
elif insertUsernameRoundcube "$username";then
    __; green Username "$username" created.; _.
    __; magenta user_id=$user_id; _.
else
    __; red Username "$username" failed to create.; x
fi
____

username="$destination_name"@"$destination_domain"
chapter Mengecek Identities destination "$username" di Roundcube.
if isIdentitiesRoundcubeExist 1 "$username" "$user_id";then
    __ Identities "$username" already exists.
    __; magenta identity_id=$identity_id; _.
elif insertIdentitiesRoundcube 1 "$username" "$user_id" "$mailbox_admin";then
    __; green Identities "$username" created.; _.
    __; magenta identity_id=$identity_id; _.
else
    __; red Identities "$username" failed to create.; x
fi
____

source="$name"@"$domain"
destination="$destination_name"@"$destination_domain"
chapter Mengecek Identities "$source" di Roundcube.
__; magenta source=$source; _.
if isIdentitiesRoundcubeExist 0 "$source" "$user_id";then
    __ Identities "$source" alias of "$destination" already exists.
    __; magenta identity_id=$identity_id; _.
elif insertIdentitiesRoundcube 0 "$source" "$user_id";then
    __; green Identities "$source" alias of "$destination" created.; _.
    __; magenta identity_id=$identity_id; _.
else
    __; red Identities "$source" alias of "$user_id" failed to create.; x
fi
____

[ -n "$tempfile" ] && rm "$tempfile"

exit 0

# parse-options.sh \
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
# --ispconfig-domain-exists-sure
# --ispconfig-soap-exists-sure
# )
# VALUE=(
# --name
# --domain
# --destination-name
# --destination-domain
# )
# FLAG_VALUE=(
# )
# EOF
# clear
