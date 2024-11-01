#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then domain="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --ispconfig-domain-exists-sure) ispconfig_domain_exists_sure=1; shift ;;
        --ispconfig-soap-exists-sure) ispconfig_soap_exists_sure=1; shift ;;
        --name=*) name="${1#*=}"; shift ;;
        --name) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then name="$2"; shift; fi; shift ;;
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
    echo '0.9.4'
}
printHelp() {
    title RCM ISPConfig Control
    _ 'Variation '; yellow Manage Email Mailbox; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-control-manage-email-mailbox [options]

Options:
   --name
        The name of mailbox.
   --domain
        The domain of mailbox.

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

Dependency:
   rcm-ispconfig-control-manage-domain:`printVersion`
   php
   mysql

Download:
   [rcm-ispconfig-control-manage-domain](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-control-manage-domain.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-control-manage-email-mailbox
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
remoteUserCredentialIspconfig() {
    local ISPCONFIG_REMOTE_USER_PASSWORD ISPCONFIG_REMOTE_USER_NAME
    local user="$1"
    local path=/usr/local/share/ispconfig/credential/remote/$user
    isFileExists "$path"
    [ -n "$notfound" ] && fileMustExists "$path"
    # Populate.
    . "$path"
    ispconfig_remote_user_name=$ISPCONFIG_REMOTE_USER_NAME
    ispconfig_remote_user_password=$ISPCONFIG_REMOTE_USER_PASSWORD
}
getMailUserIdIspconfigByEmail() {
    local email="$1"@"$2"
    __ Execute SOAP '`'mail_user_get'`'.
    arguments="$(php -r "echo serialize([
        'session_id' => null,
        'params' => [
            'email' => '${email}',
        ],
    ]);")"
    stdout=$(php -r "$php" mail_user_get "$options" "$credentials" "$arguments")
    __ Standard Output.
    magenta "$stdout"; _.
    if php -r "$php" is_empty <<< "$stdout";then
        return
    else
        echo `php -r "$php" get mailuser_id <<< "$stdout"`
    fi
}
isEmailIspconfigExist() {
    mailuser_id=$(getMailUserIdIspconfigByEmail "$1" "$2")
    if [ -n "$mailuser_id" ];then
        return 0
    fi
    return 1
}
mailboxCredential() {
    local host="$1"
    local user="$2"
    if [ -f /usr/local/share/credential/mailbox/$host/$user ];then
        local MAILBOX_USER_PASSWORD
        . /usr/local/share/credential/mailbox/$host/$user
        mailbox_user_password=$MAILBOX_USER_PASSWORD
    else
        mailbox_user_password=$(pwgen 9 -1vA0B)
        mkdir -p /usr/local/share/credential/mailbox/$host/
        cat << EOF > /usr/local/share/credential/mailbox/$host/$user
MAILBOX_USER_PASSWORD=$mailbox_user_password
EOF
        chmod 0500 /usr/local/share/credential
        chmod 0500 /usr/local/share/credential/mailbox
        chmod 0500 /usr/local/share/credential/mailbox/$host
        chmod 0400 /usr/local/share/credential/mailbox/$host/$user
    fi
}
insertEmailIspconfig() {
    local user="$1"
    local host="$2"
    __ Mengecek credentials Mailbox.
    mailboxCredential $host $user
    if [[ -z "$mailbox_user_password" ]];then
        __; red Informasi credentials tidak lengkap: '`'/usr/local/share/credential/mailbox/$host/$user'`'.; x
    else
        __; magenta mailbox_user_password="$mailbox_user_password"; _.
    fi
    __ Execute SOAP '`'mail_user_add'`'.
    arguments="$(php -r "echo serialize([
        'session_id' => null,
        'client_id' => 0,
        'params' => [
            'server_id' => '1',
            'email' => '$user@$host',
            'login' => '$user@$host',
            'password' => '$mailbox_user_password',
            'name' => '$user',
            'uid' => '5000',
            'gid' => '5000',
            'maildir' => '/var/vmail/$host/$user',
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
        ],
    ]);")"
    mailuser_id=$(php -r "$php" mail_user_add "$options" "$credentials" "$arguments")
    if [ -n "$mailuser_id" ];then
        return 0
    fi
    return 1
}

# Require, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
ISPCONFIG_REMOTE_USER_ROOT=${ISPCONFIG_REMOTE_USER_ROOT:=root}
code 'ISPCONFIG_REMOTE_USER_ROOT="'$ISPCONFIG_REMOTE_USER_ROOT'"'
ISPCONFIG_FQDN_LOCALHOST=${ISPCONFIG_FQDN_LOCALHOST:=ispconfig.localhost}
code 'ISPCONFIG_FQDN_LOCALHOST="'$ISPCONFIG_FQDN_LOCALHOST'"'
if [ -z "$domain" ];then
    error "Argument --domain required."; x
fi
code 'domain="'$domain'"'
if [ -z "$name" ];then
    error "Argument --name required."; x
fi
code 'name="'$name'"'
code 'ispconfig_domain_exists_sure="'$ispconfig_domain_exists_sure'"'
code 'ispconfig_soap_exists_sure="'$ispconfig_soap_exists_sure'"'
____

if [ -z "$ispconfig_domain_exists_sure" ];then
    INDENT+="    " \
    rcm-ispconfig-control-manage-domain $isfast --root-sure \
        isset \
        --domain="$domain" \
        ; [ $? -eq 0 ] && ispconfig_domain_exists_sure=1
    if [ -n "$ispconfig_domain_exists_sure" ];then
        __; green Domain is exists.; _.
    else
        __; red Domain is not exists.; x
    fi
fi

php=$(cat <<'EOF'
$mode = $_SERVER['argv'][1];
switch ($mode) {
    case 'is_empty':
    case 'get':
        $stdin = '';
        while (FALSE !== ($line = fgets(STDIN))) {
           $stdin .= $line;
        }
        $result = @unserialize($stdin);
        if ($result === false) {
            echo('Unserialize failed: '. $stdin.PHP_EOL);
            exit(1);
        }
        break;
    case 'login':
    case 'mail_user_get':
    case 'mail_user_add':
        $options = unserialize($_SERVER['argv'][2]);
        // Populate variable $username, $password.
        $credentials = unserialize($_SERVER['argv'][3]);
        extract($credentials);
        break;
}
switch ($mode) {
    case 'get':
        $key = $_SERVER['argv'][2];
        $result = array_shift($result);
        if (array_key_exists($key, $result)) {
            echo $result[$key];
        }
        break;
    case 'is_empty':
        empty($result) ? exit(0) : exit(1);
        break;
    case 'login':
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
                echo 'Logged successfull. Session ID:'.$session_id.PHP_EOL;
            }
            if($client->logout($session_id)) {
                echo "Logged out.".PHP_EOL;
            }
            exit(0);
        } catch (SoapFault $e) {
            fwrite(STDERR, 'SOAP Error: '.$e->getMessage().PHP_EOL);
            exit(1);
        }
        break;
    case 'mail_user_add':
        // Populate variable $session_id, $client_id, $params.
        $arguments = unserialize($_SERVER['argv'][4]);
        extract($arguments);
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            //* Set the function parameters.
            $mailuser_id = $client->mail_user_add($session_id, $client_id, $params);
            echo $mailuser_id;
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            fwrite(STDERR, 'SOAP Error: '.$e->getMessage().PHP_EOL);
            exit(1);
        }

        break;
    case 'mail_user_get':
        // Populate variable $session_id, $domain.
        $arguments = unserialize($_SERVER['argv'][4]);
        extract($arguments);
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            //* Set the function parameters.
            $record_record = $client->mail_user_get($session_id, $params);
            echo serialize($record_record);
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            fwrite(STDERR, 'SOAP Error: '.$e->getMessage().PHP_EOL);
            exit(1);
        }
        break;
    default:
        fwrite(STDERR, 'Unknown mode.'.PHP_EOL);
        exit(1);
        break;
}
EOF
)

chapter Populate variable.
remoteUserCredentialIspconfig $ISPCONFIG_REMOTE_USER_ROOT
if [[ -z "$ispconfig_remote_user_name" || -z "$ispconfig_remote_user_password" ]];then
    __; red Informasi credentials tidak lengkap: '`'/usr/local/share/ispconfig/credential/remote/$ISPCONFIG_REMOTE_USER_ROOT'`'.; x
else
    code ispconfig_remote_user_name="$ispconfig_remote_user_name"
    code ispconfig_remote_user_password="$ispconfig_remote_user_password"
fi
options="$(php -r "echo serialize([
    'location' => '"http://${ISPCONFIG_FQDN_LOCALHOST}/remote/index.php"',
    'uri' => '"http://${ISPCONFIG_FQDN_LOCALHOST}/remote/"',
    'trace' => 1,
    'exceptions' => 1,
]);")"
credentials="$(php -r "echo serialize([
    'username' => '"$ispconfig_remote_user_name"',
    'password' => '"$ispconfig_remote_user_password"',
]);")"
____

if [ -z "$ispconfig_soap_exists_sure" ];then
    chapter Test koneksi SOAP.
    if php -r "$php" login "$options" "$credentials";then
        __ Login berhasil.
    else
        error Login gagal; x
    fi
    ____
fi

user="$name"
host="$domain"
chapter Mengecek mailbox "$user"@"$host"
if isEmailIspconfigExist "$user" "$host";then
    __ Email "$user"@"$host" already exists.
    __; magenta mailuser_id=$mailuser_id; _.
elif insertEmailIspconfig "$user" "$host";then
    __; green "$user"@"$host" created.; _.
    __; magenta mailuser_id=$mailuser_id; _.
else
    __; red Email "$user"@"$host" failed to create.; x
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
# --root-sure
# --ispconfig-domain-exists-sure
# --ispconfig-soap-exists-sure
# )
# VALUE=(
# --name
# --domain
# )
# FLAG_VALUE=(
# )
# EOF
# clear
