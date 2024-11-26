#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then domain="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --ispconfig-soap-exists-sure) ispconfig_soap_exists_sure=1; shift ;;
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

# Command.
command="$1"; shift
if [ -n "$command" ];then
    case "$command" in
        add|delete|isset|get_dns_record) ;;
        *) echo -e "\e[91m""Command ${command} is unknown.""\e[39m"; exit 1
    esac
fi

# Functions.
printVersion() {
    echo '0.9.6'
}
printHelp() {
    title RCM ISPConfig Control
    _ 'Variation '; yellow Manage Domain; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << 'EOF'
Usage: rcm-ispconfig-control-manage-domain [command] [options]

Available commands: add, delete, isset, get_dns_record.

Options:
   --domain
        Set the domain to control.

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
   DKIM_SELECTOR
        Default to default.
   MAILBOX_WEB
        Default to webmaster
   ISPCONFIG_REMOTE_USER_ROOT
        Default to root
   ISPCONFIG_FQDN_LOCALHOST
        Default to ispconfig.localhost

Dependency:
   php
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-control-manage-domain
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

# Requirement, validate, and populate value.
chapter Dump variable.
DKIM_SELECTOR=${DKIM_SELECTOR:=default}
code 'DKIM_SELECTOR="'$DKIM_SELECTOR'"'
MAILBOX_WEB=${MAILBOX_WEB:=webmaster}
code 'MAILBOX_WEB="'$MAILBOX_WEB'"'
ISPCONFIG_REMOTE_USER_ROOT=${ISPCONFIG_REMOTE_USER_ROOT:=root}
code 'ISPCONFIG_REMOTE_USER_ROOT="'$ISPCONFIG_REMOTE_USER_ROOT'"'
ISPCONFIG_FQDN_LOCALHOST=${ISPCONFIG_FQDN_LOCALHOST:=ispconfig.localhost}
code 'ISPCONFIG_FQDN_LOCALHOST="'$ISPCONFIG_FQDN_LOCALHOST'"'
code 'command="'$command'"'
delay=.5; [ -n "$fast" ] && unset delay
if [ -z "$domain" ];then
    error "Argument --domain required."; x
fi
code 'domain="'$domain'"'
code 'ispconfig_soap_exists_sure="'$ispconfig_soap_exists_sure'"'
vercomp `stat --version | head -1 | grep -o -E '\S+$'` 8.31
if [[ $? -lt 2 ]];then
    stat_cached=' --cached=never'
else
    stat_cached=''
fi
____

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
    case 'mail_domain_get_by_domain':
    case 'mail_domain_add':
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
    case 'mail_domain_get_by_domain':
        // Populate variable $session_id, $domain.
        $arguments = unserialize($_SERVER['argv'][4]);
        extract($arguments);
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            //* Set the function parameters.
            $record_record = $client->mail_domain_get_by_domain($session_id, $domain);
            echo serialize($record_record);
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            fwrite(STDERR, 'SOAP Error: '.$e->getMessage().PHP_EOL);
            exit(1);
        }
        break;
    case 'mail_domain_add':
        // Populate variable $session_id, $client_id, $params.
        $arguments = unserialize($_SERVER['argv'][4]);
        extract($arguments);
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            //* Set the function parameters.
            $domain_id = $client->mail_domain_add($session_id, $client_id, $params);
            echo "Domain ID: ".$domain_id.PHP_EOL;
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            fwrite(STDERR, 'SOAP Error: '.$e->getMessage().PHP_EOL);
            exit(1);
        }
        break;
    case 'ajax_get_json':
        $dirname = $_SERVER['argv'][2];
        $file = $_SERVER['argv'][3];
        $domain = $_SERVER['argv'][4];
        $dkim_selector = $_SERVER['argv'][5];
        chdir($dirname);
        $_GET['type'] = 'create_dkim';
        $_GET['domain_id'] = $domain;
        $_GET['dkim_selector'] = $dkim_selector;
        $_GET['dkim_public'] = '';
        include_once $file;
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

chapter Mengecek domain '`'$domain'`' di Module Mail ISPConfig.
__ Execute SOAP '`'mail_domain_get_by_domain'`'.
arguments="$(php -r "echo serialize([
    'session_id' => null,
    'domain' => '"$domain"',
]);")"
stdout=$(php -r "$php" mail_domain_get_by_domain "$options" "$credentials" "$arguments")
__ Standard Output.
code stdout="$stdout"
if php -r "$php" is_empty <<< "$stdout";then
    found=; notfound=1
else
    found=1; notfound=
fi
if [ -n "$found" ];then
    __ Domain '`'$domain'`' telah terdaftar di ISPConfig.
    if [[ $command == isset ]];then
        exit 0
    fi
    dkim=`php -r "$php" get dkim <<< "$stdout"`
    if [[ $dkim == y ]];then
        _dkim_selector=$(php -r "$php" get dkim_selector <<< "$stdout")
        if [[ ! "$DKIM_SELECTOR" == "$_dkim_selector" ]];then
            __; red Terdapat perbedaan antara dkim_selector versi database dengan user input.; _.
            __; red Menggunakan value versi database.; _.
            DKIM_SELECTOR="$_dkim_selector"
            __; magenta DKIM_SELECTOR="$DKIM_SELECTOR"; _.
        fi
    fi
    if [[ $command == get_dns_record ]];then
        dkim_public=$(php -r "$php" get dkim_public <<< "$stdout")
        dns_record=$(echo "$dkim_public" | sed -e "/-----BEGIN PUBLIC KEY-----/d" -e "/-----END PUBLIC KEY-----/d" | tr '\r' ' '  | tr '\n' ' ' | sed 's/\ //g')
        echo "$dns_record"
        exit 0
    fi
else
    __ Domain '`'$domain'`' belum terdaftar di ISPConfig.
    if [[ $command == isset ]];then
        exit 1
    fi
fi
____

json=
if [[ $command == add && -n "$notfound" ]];then
    chapter Generate DKIM Public and Private Key
    php_fpm_user=ispconfig
    code 'php_fpm_user="'$php_fpm_user'"'
    prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
    code 'prefix="'$prefix'"'
    tempfile=$(mktemp -p "$prefix/interface/web/mail" -t rcm-ispconfig-control-manage-domain.XXXXXX)
    code 'tempfile="'$tempfile'"'
    cp "${prefix}/interface/web/mail/ajax_get_json.php" "$tempfile"
    chmod go-r "$tempfile"
    chmod go-w "$tempfile"
    chmod go-x "$tempfile"
    sed -i "/\$app->auth->check_module_permissions('mail');/d" "$tempfile"
    sed -i "s,if (\$dkim_strength==''),if (\$dkim_strength==0),g" "$tempfile"
    dirname=$(dirname "$tempfile")
    json=$(php -r "$php" ajax_get_json "$dirname" "$tempfile" "$domain" "$DKIM_SELECTOR")
    __ Standard Output.
    magenta "$json"; _.
    __ Cleaning temporary file.
    code rm "$tempfile"
    rm "$tempfile"
    ____
fi

if [[ $command == add && -n "$json" ]];then
    dkim_private=$(php -r "echo (json_decode(fgets(STDIN)))->dkim_private;" <<< "$json")
    dkim_public=$(php -r "echo (json_decode(fgets(STDIN)))->dkim_public;" <<< "$json")
    dns_record=$(php -r "echo (json_decode(fgets(STDIN)))->dns_record;" <<< "$json")
    if [ -z "$dns_record" ];then
        __; red DNS record not found.; x
    fi
    chapter Mendaftarkan domain '`'$domain'`' di Module Mail ISPConfig.
    __ Execute SOAP '`'mail_domain_add'`'.
    arguments="$(php -r "echo serialize([
        'session_id' => null,
        'client_id' => 0,
        'params' => [
            'server_id' => '1',
            'domain' => '${domain}',
            'active' => 'y',
            'dkim' => 'y',
            'dkim_selector' => '${DKIM_SELECTOR}',
            'dkim_private' => '$dkim_private',
            'dkim_public' => '$dkim_public',
        ],
    ]);")"
    php -r "$php" mail_domain_add "$options" "$credentials" "$arguments"
    ____

    chapter Mengecek domain '`'$domain'`' di Module Mail ISPConfig.
    __ Execute SOAP '`'mail_domain_get_by_domain'`'.
    arguments="$(php -r "echo serialize([
        'session_id' => null,
        'domain' => '"$domain"',
    ]);")"
    stdout=$(php -r "$php" mail_domain_get_by_domain "$options" "$credentials" "$arguments")
    __ Standard Output.
    code stdout="$stdout"
    if php -r "$php" is_empty <<< "$stdout";then
        __; red Domain gagal terdaftar.; x
    else
        __; green Domain berhasil terdaftar.; _.
    fi
    ____

    chapter Membuat welcome mail.
    source='/usr/local/share/ispconfig/mail/welcome_email_'$domain'.html'
    mkdir -p '/usr/local/share/ispconfig/mail'
    cat <<- EOF > "$source"
From: Webmaster <$MAILBOX_WEB@$domain>
Subject: Welcome to your new email account.

<p>Welcome to your new email account. Your webmaster.</p>

EOF
    target="${prefix}/server/conf-custom/mail/welcome_email_${domain}.html"
    link_symbolic "$source" "$target"
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
# --ispconfig-soap-exists-sure
# )
# VALUE=(
# --domain
# )
# CSV=(
# )
# EOF
# clear
