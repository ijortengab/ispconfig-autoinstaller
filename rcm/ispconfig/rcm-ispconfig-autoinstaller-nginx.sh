#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --certbot-authenticator=*) certbot_authenticator="${1#*=}"; shift ;;
        --certbot-authenticator) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then certbot_authenticator="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --fqdn=*) fqdn="${1#*=}"; shift ;;
        --fqdn) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then fqdn="$2"; shift; fi; shift ;;
        --ispconfig-version=*) ispconfig_version="${1#*=}"; shift ;;
        --ispconfig-version) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then ispconfig_version="$2"; shift; fi; shift ;;
        --phpmyadmin-version=*) phpmyadmin_version="${1#*=}"; shift ;;
        --phpmyadmin-version) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then phpmyadmin_version="$2"; shift; fi; shift ;;
        --php-version=*) php_version="${1#*=}"; shift ;;
        --php-version) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then php_version="$2"; shift; fi; shift ;;
        --root-sure) root_sure=1; shift ;;
        --roundcube-version=*) roundcube_version="${1#*=}"; shift ;;
        --roundcube-version) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then roundcube_version="$2"; shift; fi; shift ;;
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
    echo '0.9.7'
}
printHelp() {
    title RCM ISPConfig Auto-Installer
    _ 'Variation '; yellow Nginx; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-ispconfig-autoinstaller-nginx [options]

Options:
   --fqdn *
        Fully Qualified Domain Name of this server, for example: \`server1.example.org\`.
   --php-version *
        Set the version of PHP FPM.
   --ispconfig-version *
        Set the version of ISPConfig.
   --roundcube-version *
        Set the version of RoundCube.
   --phpmyadmin-version *
        Set the version of PHPMyAdmin.
   --certbot-authenticator *
        Available value: digitalocean, nginx.

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
   ISPCONFIG_FQDN_LOCALHOST
        Default to ispconfig.localhost
   MYSQL_ROOT_PASSWD
        Default to $HOME/.mysql-root-passwd.txt
   MYSQL_ROOT_PASSWD_INI
        Default to $HOME/.mysql-root-passwd.ini
   ISPCONFIG_DB_USER_HOST
        Default to localhost
   ISPCONFIG_NGINX_CONFIG_FILE
        Default to ispconfig
   MARIADB_PREFIX_MASTER
        Default to /usr/local/share/mariadb
   MARIADB_USERS_CONTAINER_MASTER
        Default to users

Dependency:
   mysql
   pwgen
   php
   curl
   nginx
   rcm-mariadb-setup-ispconfig:`printVersion`
   rcm-nginx-setup-ispconfig:`printVersion`
   rcm-php-setup-ispconfig:`printVersion`
   rcm-postfix-setup-ispconfig:`printVersion`
   rcm-ispconfig-setup-smtpd-certificate:`printVersion`
   rcm-phpmyadmin-autoinstaller-nginx
   rcm-roundcube-autoinstaller-nginx
   rcm-mariadb-setup-project-database
   rcm-php-fpm-setup-project-config
   rcm-nginx-virtual-host-autocreate-php

Download:
   [rcm-mariadb-setup-ispconfig](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/mariadb/rcm-mariadb-setup-ispconfig.sh)
   [rcm-nginx-setup-ispconfig](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/nginx/rcm-nginx-setup-ispconfig.sh)
   [rcm-php-setup-ispconfig](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/php/rcm-php-setup-ispconfig.sh)
   [rcm-postfix-setup-ispconfig](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/postfix/rcm-postfix-setup-ispconfig.sh)
   [rcm-ispconfig-setup-smtpd-certificate](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-smtpd-certificate.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-ispconfig-autoinstaller-nginx
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
populateDatabaseUserPassword() {
    local path="${MARIADB_PREFIX_MASTER}/${MARIADB_USERS_CONTAINER_MASTER}/$1"
    local DB_USER DB_USER_PASSWORD
    if [ -f "$path" ];then
        . "$path"
        db_user_password=$DB_USER_PASSWORD
    fi
}
websiteCredentialIspconfig() {
    if [ -f /usr/local/share/ispconfig/credential/website ];then
        local ISPCONFIG_WEB_USER_PASSWORD
        . /usr/local/share/ispconfig/credential/website
        ispconfig_web_user_password=$ISPCONFIG_WEB_USER_PASSWORD
    else
        ispconfig_web_user_password=$(pwgen 9 -1vA0B)
        mkdir -p /usr/local/share/ispconfig/credential
        cat << EOF > /usr/local/share/ispconfig/credential/website
ISPCONFIG_WEB_USER_PASSWORD=$ispconfig_web_user_password
EOF
        chmod 0500 /usr/local/share/ispconfig/credential
        chmod 0400 /usr/local/share/ispconfig/credential/website
    fi
}
toggleMysqlRootPassword() {
    # global used MYSQL_ROOT_PASSWD_INI
    # global used mysql_root_passwd
    local switch=$1
    local is_password=
    # mysql \
        # --defaults-extra-file="$MYSQL_ROOT_PASSWD_INI" \
        # -e "show variables like 'version';" ; echo $?
    # mysql \
        # -e "show variables like 'version';" ; echo $?
    if mysql \
        --defaults-extra-file="$MYSQL_ROOT_PASSWD_INI" \
        -e "show variables like 'version';" > /dev/null 2>&1;then
        is_password=yes
    fi
    if mysql \
        -e "show variables like 'version';" > /dev/null 2>&1;then
        is_password=no
    fi
    [ -n "$switch" ] || {
        case "$is_password" in
            yes) switch=no ;;
            no) switch=yes ;;
        esac
    }
    case "$switch" in
        yes) [[ "$is_password" == yes ]] && return 0 || {
            __; _, Password MySQL untuk root sedang dipasang:' '
            if mysql \
                -e "set password for root@localhost=PASSWORD('$mysql_root_passwd');" > /dev/null 2>&1;then
                green Password berhasil dipasang; _.
            else
                error Password gagal dipasang; x
            fi
        } ;;
        no) [[ "$is_password" == no ]] && return 0 || {
            __; _, Password MySQL untuk root sedang dicopot:' '
            if mysql \
                --defaults-extra-file="$MYSQL_ROOT_PASSWD_INI" \
                -e "set password for root@localhost=PASSWORD('');" > /dev/null 2>&1;then
                green Password berhasil dicopot.; _.
            else
                error Password gagal dicopot.; x
            fi
        } ;;
    esac
}
modifyFileDebian11() {
    local file=/tmp/ispconfig3_install/install/dist/conf/debian110.conf.php
    isFileExists "$file"
    [ -n "$notfound" ] && fileMustExists "$file"
    if [[ ! "$php_version" == 7.4 ]];then
        sed -i \
            -e 's,"7\.4","'$php_version'",g' \
            -e 's,/7\.4/,/'$php_version'/,g' \
            -e 's,php7\.4,php'$php_version',g' \
            "$file"
    fi
    # Edit informasi cron dan ufw yang terlewat.
    string="//* cron"
    number_1=$(grep -n -F "$string" "$file" | head -1 | cut -d: -f1)
    number_1plus=$((number_1 - 1))
    number_1plus2=$((number_1 + 1))
    part1=$(sed -n '1,'$number_1plus'p' "$file")
    part2=$(sed -n $number_1plus2',$p' "$file")
    additional=$(cat << 'EOF'

//* ufw
$conf['ufw']['installed'] = false;

//* cron
$conf['cron']['installed'] = false;
EOF
        )
    echo "$part1"$'\n'"$additional"$'\n'"$part2" > "$file"
}
modifyFileDebian12() {
    local file=/tmp/ispconfig3_install/install/dist/conf/debian120.conf.php
    isFileExists "$file"
    [ -n "$notfound" ] && fileMustExists "$file"
    if [[ ! "$php_version" == 8.2 ]];then
        sed -i \
            -e 's,"8\.2","'$php_version'",g' \
            -e 's,/8\.2/,/'$php_version'/,g' \
            -e 's,php8\.2,php'$php_version',g' \
            "$file"
    fi
    # Edit informasi cron dan ufw yang terlewat.
    string="//* cron"
    number_1=$(grep -n -F "$string" "$file" | head -1 | cut -d: -f1)
    number_1plus=$((number_1 - 1))
    number_1plus2=$((number_1 + 1))
    part1=$(sed -n '1,'$number_1plus'p' "$file")
    part2=$(sed -n $number_1plus2',$p' "$file")
    additional=$(cat << 'EOF'

//* ufw
$conf['ufw']['installed'] = false;

//* cron
$conf['cron']['installed'] = false;
EOF
        )
    echo "$part1"$'\n'"$additional"$'\n'"$part2" > "$file"
}
createFileDebian12() {
    local source=/tmp/ispconfig3_install/install/dist/conf/debian110.conf.php
    local file=/tmp/ispconfig3_install/install/dist/conf/debian120.conf.php
    if [ ! -f "$file" ];then
        fileMustExists "$source"
        __ Membuat file '`'debian120.conf.php'`'.
        cp "$source" "$file"
        fileMustExists "$file"
        sed -i \
            -e 's,Debian 11,Debian 12,g' \
            -e 's,debian110,debian120,g' \
            -e 's,"7\.4","'$php_version'",g' \
            -e 's,/7\.4/,/'$php_version'/,g' \
            -e 's,php7\.4,php'$php_version',g' \
            "$file"
    fi
    # Edit informasi cron dan ufw yang terlewat.
    string="//* cron"
    number_1=$(grep -n -F "$string" "$file" | head -1 | cut -d: -f1)
    number_1plus=$((number_1 - 1))
    number_1plus2=$((number_1 + 1))
    part1=$(sed -n '1,'$number_1plus'p' "$file")
    part2=$(sed -n $number_1plus2',$p' "$file")
    additional=$(cat << 'EOF'

//* ufw
$conf['ufw']['installed'] = false;

//* cron
$conf['cron']['installed'] = false;
EOF
        )
    echo "$part1"$'\n'"$additional"$'\n'"$part2" > "$file"
}
editInstallLibDebian12() {
    file=/tmp/ispconfig3_install/install/lib/install.lib.php
    string="elseif(substr(trim(file_get_contents('/etc/debian_version')),0,2) == '12')"
    edit=1
    if grep -q -F "$string" "$file";then
        __ File sudah diedit agar terdapat informasi Debian 12: $(basename "$file").
        edit=
    fi
    if [ -n "$edit" ];then
        __ Mengedit file: $(basename "$file").
        string="elseif(substr(trim(file_get_contents('/etc/debian_version')),0,2) == '11')"
        number_1=$(grep -n -F "$string" "$file" | head -1 | cut -d: -f1)
        number_1plus=$((number_1 + 6))
        number_1plus2=$((number_1 + 7))
        part1=$(sed -n '1,'$number_1plus'p' "$file")
        part2=$(sed -n $number_1plus2',$p' "$file")
        additional=$(cat << 'EOF'
            } elseif(substr(trim(file_get_contents('/etc/debian_version')),0,2) == '12') {
                $distname = 'Debian';
                $distver = 'Bookworm';
                $distconfid = 'debian120';
                $distid = 'debian60';
                $distbaseid = 'debian';
                swriteln("Operating System: Debian 12.0 (Bookworm) or compatible\n");
EOF
        )
        echo "$part1"$'\n'"$additional"$'\n'"$part2" > "$file"
        __ Verifikasi.
        if grep -q -F "$string" "$file";then
            __; green File berhasil diedit agar terdapat informasi Debian 12: $(basename "$file").; _.
        else
            __; red File gagal diedit: $(basename "$file"); _.
        fi
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
[ -n "$fast" ] && isfast=' --fast' || isfast=''
ISPCONFIG_FQDN_LOCALHOST=${ISPCONFIG_FQDN_LOCALHOST:=ispconfig.localhost}
code 'ISPCONFIG_FQDN_LOCALHOST="'$ISPCONFIG_FQDN_LOCALHOST'"'
MYSQL_ROOT_PASSWD=${MYSQL_ROOT_PASSWD:=$HOME/.mysql-root-passwd.txt}
code 'MYSQL_ROOT_PASSWD="'$MYSQL_ROOT_PASSWD'"'
MYSQL_ROOT_PASSWD_INI=${MYSQL_ROOT_PASSWD_INI:=$HOME/.mysql-root-passwd.ini}
code 'MYSQL_ROOT_PASSWD_INI="'$MYSQL_ROOT_PASSWD_INI'"'
ISPCONFIG_DB_USER_HOST=${ISPCONFIG_DB_USER_HOST:=localhost}
code 'ISPCONFIG_DB_USER_HOST="'$ISPCONFIG_DB_USER_HOST'"'
ISPCONFIG_NGINX_CONFIG_FILE=${ISPCONFIG_NGINX_CONFIG_FILE:=ispconfig}
code 'ISPCONFIG_NGINX_CONFIG_FILE="'$ISPCONFIG_NGINX_CONFIG_FILE'"'
MARIADB_PREFIX_MASTER=${MARIADB_PREFIX_MASTER:=/usr/local/share/mariadb}
code 'MARIADB_PREFIX_MASTER="'$MARIADB_PREFIX_MASTER'"'
MARIADB_USERS_CONTAINER_MASTER=${MARIADB_USERS_CONTAINER_MASTER:=users}
code 'MARIADB_USERS_CONTAINER_MASTER="'$MARIADB_USERS_CONTAINER_MASTER'"'
delay=.5; [ -n "$fast" ] && unset delay
if [ -z "$ispconfig_version" ];then
    error "Argument --ispconfig-version required."; x
fi
code 'ispconfig_version="'$ispconfig_version'"'
if [ -z "$roundcube_version" ];then
    error "Argument --roundcube-version required."; x
fi
code 'roundcube_version="'$roundcube_version'"'
if [ -z "$phpmyadmin_version" ];then
    error "Argument --phpmyadmin-version required."; x
fi
code 'phpmyadmin_version="'$phpmyadmin_version'"'
if [ -z "$php_version" ];then
    error "Argument --php-version required."; x
fi
code 'php_version="'$php_version'"'
if [ -z "$fqdn" ];then
    error "Argument --fqdn required."; x
fi
code 'fqdn="'$fqdn'"'
case "$certbot_authenticator" in
    digitalocean) ;;
    nginx) ;;
    *) certbot_authenticator=
esac
if [ -z "$certbot_authenticator" ];then
    error "Argument --certbot-authenticator required.";
    _ Available value:' '; yellow digitalocean; _, ', '; yellow nginx; _, .; _.
    x
fi
code 'certbot_authenticator="'$certbot_authenticator'"'
____

INDENT+="    " \
rcm-mariadb-setup-ispconfig $isfast --root-sure \
    && INDENT+="    " \
rcm-nginx-setup-ispconfig $isfast --root-sure \
    && INDENT+="    " \
rcm-php-setup-ispconfig $isfast --root-sure \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-postfix-setup-ispconfig $isfast --root-sure \
    && INDENT+="    " \
rcm-ispconfig-setup-smtpd-certificate $isfast --root-sure \
    --certbot-authenticator="$certbot_authenticator" \
    --fqdn="$fqdn" \
    && INDENT+="    " \
rcm-phpmyadmin-autoinstaller-nginx $isfast --root-sure \
    --phpmyadmin-version="$phpmyadmin_version" \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-roundcube-autoinstaller-nginx $isfast --root-sure \
    --roundcube-version="$roundcube_version" \
    --php-version="$php_version" \
    ; [ ! $? -eq 0 ] && x

chapter Mengecek ISPConfig User.
php_fpm_user=ispconfig
do_install=
code id -u '"'$php_fpm_user'"'
if id "$php_fpm_user" >/dev/null 2>&1; then
    __ User '`'$php_fpm_user'`' found.
else
    __ User '`'$php_fpm_user'`' not found.;
    do_install=1
fi
____

if [ -n "$do_install" ];then
    chapter Mendownload ISPConfig
    __ Mendownload ISPConfig
    cd /tmp
    if [ ! -f /tmp/ISPConfig-$ispconfig_version.tar.gz ];then
        wget https://www.ispconfig.org/downloads/ISPConfig-$ispconfig_version.tar.gz
    fi
    isFileExists /tmp/ISPConfig-$ispconfig_version.tar.gz
    [ -n "$notfound" ] && fileMustExists /tmp/ISPConfig-$ispconfig_version.tar.gz
    if [ ! -f /tmp/ispconfig3_install/install/install.php ];then
        tar xfz ISPConfig-$ispconfig_version.tar.gz
    fi
    cd - >/dev/null
    isFileExists /tmp/ispconfig3_install/install/install.php
    [ -n "$notfound" ] && fileMustExists /tmp/ispconfig3_install/install/install.php

    if [ -f /etc/os-release ];then
        . /etc/os-release
    fi
    code 'ID="'$ID'"'
    code 'VERSION_ID="'$VERSION_ID'"'
    code 'ispconfig_version="'$ispconfig_version'"'
    case $ID in
        debian)
            case "$VERSION_ID" in
                11)
                    case "$ispconfig_version" in
                        3.2.7) ;;
                        3.2.11p2) ;;
                        *) error ISPConfig Version "$ispconfig_version" not supported; x;
                    esac
                    modifyFileDebian11
                    ;;
                12)
                    case "$ispconfig_version" in
                        3.2.9)
                            createFileDebian12
                            editInstallLibDebian12
                            ;;
                        3.2.10)
                            createFileDebian12
                            editInstallLibDebian12
                            ;;
                        3.2.11p2)
                            modifyFileDebian12
                            ;;
                        *) error ISPConfig Version "$ispconfig_version" not supported; x;
                    esac
                    ;;
                *)
                    error OS "$ID" Version "$VERSION_ID" not supported; x;
            esac
            ;;
        ubuntu)
            case "$VERSION_ID" in
                22.04)
                    case "$ispconfig_version" in
                        3.2.7) ;;
                        *) error ISPConfig Version "$ispconfig_version" not supported; x;
                    esac
                    ;;
                *)
                    error OS "$ID" Version "$VERSION_ID" not supported; x;
            esac
            ;;
        *) error OS "$ID" not supported; x;
    esac

    source=/tmp/ispconfig3_install/docs/autoinstall_samples/autoinstall.ini.sample
    path=/tmp/ispconfig3_install/install/autoinstall.ini
    filename=autoinstall.ini
    if [ ! -f "$path" ];then
        __ Membuat file '`'$filename'`'.
        fileMustExists "$source"
        cp "$source" "$path"
        fileMustExists "$path"
        sed -i -E \
            -e ':a;N;$!ba;s|\[expert\]|[expert]\nconfigure_webserver=n|g' \
            "$path"
    fi
    isFileExists "$path"
    [ -n "$notfound" ] && fileMustExists "$path"
    ____

    php=$(cat <<'EOF'
$args = $_SERVER['argv'];
$mode = $_SERVER['argv'][1];
switch ($mode) {
    case 'is_different':
        $file = $_SERVER['argv'][2];
        $array = unserialize($_SERVER['argv'][3]);
        $autoinstall = parse_ini_file($file);
        if (!isset($autoinstall)) {
            exit(255);
        }
        $is_different = !empty(array_diff_assoc($array, $autoinstall));
        $is_different ? exit(0) : exit(1);
        break;
    case 'get' :
        $file = $_SERVER['argv'][2];
        $key = $_SERVER['argv'][3];
        $autoinstall = parse_ini_file($file);
        echo array_key_exists($key, $autoinstall) ? $autoinstall[$key] : '';
        break;
}
EOF
    )
    db_user=`php -r "$php" get "$path" mysql_ispconfig_user`
    db_name=`php -r "$php" get "$path" mysql_database`
    INDENT+="    " \
    rcm-mariadb-setup-project-database $isfast --root-sure \
        --project-name="$db_user" \
        --without-autocreate-db \
        ; [ ! $? -eq 0 ] && x

    # Get password from mariadb local share.
    populateDatabaseUserPassword "$db_user"
    if [[ -z "$db_user_password" ]];then
        __; red Informasi credentials tidak lengkap: '`'$path'`'.; x
    else
        code db_user_password="$db_user_password"
    fi

    path=/usr/local/share/ispconfig/credential/website
    chapter Mengecek website credentials: '`'$path'`'.
    websiteCredentialIspconfig
    if [[ -z "$ispconfig_web_user_password" ]];then
        __; red Informasi credentials tidak lengkap: '`'$path'`'.; x
    else
        code ispconfig_web_user_password="$ispconfig_web_user_password"
    fi
    ____

    chapter Mengecek apakah database ISPConfig siap digunakan.
    msg=$(mysql --silent --skip-column-names -e "select schema_name from information_schema.schemata where schema_name = '$db_name'")
    if [[ $msg == $db_name ]];then
        __ Database ditemukan.
        msg=$(mysql --silent --skip-column-names db_name -e "show tables;" | wc -l)
        if [[ $msg -gt 0 ]];then
            __; red Database sudah terdapat table sejumlah '`'$msg'`'.; x
        fi
    else
        __ Database tidak ditemukan
    fi
    ____

    path=/tmp/ispconfig3_install/install/autoinstall.ini
    filename=autoinstall.ini
    chapter Modifikasi file '`'$filename'`'.
    __; _, Verifikasi file '`'autoinstall.ini'`':' '
    mysql_root_passwd="$(<$MYSQL_ROOT_PASSWD)"
    reference="$(php -r "echo serialize([
        'install_mode' => 'expert',
        'configure_webserver' => 'n',
        'configure_apache' => 'n',
        'configure_nginx' => 'n',
        'configure_firewall' => 'n',
        'hostname' => '$fqdn',
        'mysql_root_password' => '$mysql_root_passwd',
        'http_server' => 'nginx',
        'ispconfig_use_ssl' => 'n',
        'mysql_ispconfig_password' => '$db_user_password',
        'ispconfig_admin_password' => '$ispconfig_web_user_password',
    ]);")"
    is_different=
    if php -r "$php" is_different \
        /tmp/ispconfig3_install/install/autoinstall.ini \
        "$reference";then
        is_different=1
        _, diperlukan modifikasi file '`'autoinstall.ini'`'.;_.
    else
        if [ $? -eq 255 ];then
            error Terjadi kesalahan dalam parsing file '`'autoinstall.ini'`'.; x
        fi
        _, file '`'autoinstall.ini'`' tidak ada perubahan.; _.
    fi
    if [ -n "$is_different" ];then
        __; _, Memodifikasi file '`'autoinstall.ini'`':' '
        backupFile copy /tmp/ispconfig3_install/install/autoinstall.ini
        sed -e "s,^install_mode=.*$,install_mode=expert," \
            -e "s,^configure_webserver=.*$,configure_webserver=n," \
            -e "s,^configure_apache=.*$,configure_apache=n," \
            -e "s,^configure_nginx=.*$,configure_nginx=n," \
            -e "s,^configure_firewall=.*$,configure_firewall=n," \
            -e "s,^hostname=.*$,hostname=${fqdn}," \
            -e "s,^mysql_root_password=.*$,mysql_root_password=${mysql_root_passwd}," \
            -e "s,^http_server=.*$,http_server=nginx," \
            -e "s,^ispconfig_use_ssl=.*$,ispconfig_use_ssl=n," \
            -e "s,^ispconfig_admin_password=.*$,ispconfig_admin_password=${ispconfig_web_user_password}," \
            -e "s,^mysql_ispconfig_password=.*$,mysql_ispconfig_password=${db_user_password}," \
            -i /tmp/ispconfig3_install/install/autoinstall.ini
        if php -r "$php" is_different \
            /tmp/ispconfig3_install/install/autoinstall.ini \
            "$reference";then
            red modifikasi file '`'autoinstall.ini'`' gagal.; x
        else
            green modifikasi file '`'autoinstall.ini'`' berhasil.; _.
        fi
    fi
    ____

    path=/tmp/ispconfig3_install/install/install.php
    filename=install.php
    chapter Modifikasi file '`'$filename'`'.
    if grep -q -F '$inst->configure_postfix();' "$path";then
        __; _, Memodifikasi file '`'$filename'`':' '
        sed 's|$inst->configure_postfix();|$inst->configure_postfix("dont-create-certs");|' \
            -i "$path"
        sleep 1
        if grep -q -F '$inst->configure_postfix("dont-create-certs");' "$path";then
            green modifikasi file '`'$filename'`' berhasil.; _.
        else
            red modifikasi file '`'$filename'`' gagal.; x
        fi
    else
        __ File '`'$filename'`' tidak perlu modifikasi.
    fi
    ____

    chapter Menginstall ISPConfig
    __ Memasang password MySQL untuk root
    toggleMysqlRootPassword yes

    __ Mulai autoinstall.
    cd /tmp/ispconfig3_install/install
    php install.php --autoinstall=autoinstall.ini
    cd - >/dev/null

    prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
    path="$prefix/interface/web/index.php"
    filename=index.php
    __ Mengecek existing '`'$filename'`'
    fileMustExists "$path"
    ____

    chapter Post Install
    __ Mencopot password MySQL untuk root
    toggleMysqlRootPassword no
    ____
fi

chapter Prepare arguments.
if [ -z "$prefix" ];then
    prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
fi
# gak tahu deh dapet dari mana ini value.
# $php_project_name adalah section, maka perlu cari di installer,
# apakah section nya menggunakan ispconfig value.
php_project_name="ispconfig"
code 'php_project_name="'$php_project_name'"'
____; socket_filename=$(INDENT+="    " rcm-php-fpm-setup-project-config $isfast --root-sure --php-version="$php_version" --php-fpm-user="$php_fpm_user" --project-name="$php_project_name" get listen)
code 'socket_filename="'$socket_filename'"'
if [ -z "$socket_filename" ];then
    __; red Socket Filename of PHP-FPM not found.; x
fi
root="$prefix/interface/web"
code 'root="'$root'"'
filename="$ISPCONFIG_NGINX_CONFIG_FILE"
code 'filename="'$filename'"'
url_scheme=http
url_port=80
url_host="$ISPCONFIG_FQDN_LOCALHOST"
code 'url_scheme="'$url_scheme'"'
code 'url_host="'$url_host'"'
code 'url_port="'$url_port'"'
____

INDENT+="    " \
rcm-nginx-virtual-host-autocreate-php $isfast --root-sure \
    --root="$root" \
    --filename="$filename" \
    --fastcgi-pass="unix:${socket_filename}" \
    --url-host="$url_host" \
    --url-scheme="$url_scheme" \
    --url-port="$url_port" \
    ; [ ! $? -eq 0 ] && x

chapter Mengecek address host local '`'$ISPCONFIG_FQDN_LOCALHOST'`'.
notfound=
string="$ISPCONFIG_FQDN_LOCALHOST"
string_quoted=$(sed "s/\./\\\./g" <<< "$string")
if grep -q -E "^\s*127\.0\.0\.1\s+${string_quoted}" /etc/hosts;then
    __ Address Host local terdapat pada local DNS resolver '`'/etc/hosts'`'.
else
    __ Address Host local tidak terdapat pada local DNS resolver '`'/etc/hosts'`'.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    chapter Menambahkan host '`'$ISPCONFIG_FQDN_LOCALHOST'`'.
    echo "127.0.0.1"$'\t'"${ISPCONFIG_FQDN_LOCALHOST}" >> /etc/hosts
    if grep -q -E "^\s*127\.0\.0\.1\s+${string_quoted}" /etc/hosts;then
        __; green Address Host local terdapat pada local DNS resolver '`'/etc/hosts'`'.; _.
    else
        __; red Address Host local tidak terdapat pada local DNS resolver '`'/etc/hosts'`'.; x
    fi
    ____
fi

chapter Mengecek HTTP Response Code.
code curl http://127.0.0.1 -H '"'Host: ${ISPCONFIG_FQDN_LOCALHOST}'"'
code=$(curl -L \
    -o /dev/null -s -w "%{http_code}\n" \
    http://127.0.0.1 -H "Host: ${ISPCONFIG_FQDN_LOCALHOST}")
[[ $code =~ ^[2,3] ]] && {
    __ HTTP Response code '`'$code'`' '('Required')'.
} || {
    __; red Terjadi kesalahan. HTTP Response code '`'$code'`'.; x
}
code curl http://${ISPCONFIG_FQDN_LOCALHOST}
code=$(curl -L \
    -o /dev/null -s -w "%{http_code}\n" \
    http://127.0.0.1 -H "Host: ${ISPCONFIG_FQDN_LOCALHOST}")
__ HTTP Response code '`'$code'`'.
____

reload=

chapter Menghapus port 8080 buatan ISPConfig
path=/etc/nginx/sites-enabled/000-ispconfig.vhost
isFileExists "$path"
if [ -L "$path" ];then
    __ Menghapus symlink "$path"
    code rm "$path"
    rm "$path"
    reload=1
fi
____

chapter Menghapus virtual host acme challange buatan ISPConfig
path=/etc/nginx/sites-enabled/999-acme.vhost
isFileExists "$path"
if [ -L "$path" ];then
    __ Menghapus symlink "$path"
    code rm "$path"
    rm "$path"
    reload=1
fi
____

if [ -n "$reload" ];then
    chapter Reload nginx configuration.
    __ Cleaning broken symbolic link.
    code find /etc/nginx/sites-enabled -xtype l -delete -print
    find /etc/nginx/sites-enabled -xtype l -delete -print
    if nginx -t 2> /dev/null;then
        code nginx -s reload
        nginx -s reload; sleep .5
    else
        error Terjadi kesalahan konfigurasi nginx. Gagal reload nginx.; x
    fi
    ____
fi

chapter Copy ISPConfig PHP scripts.
isDirExists "${prefix}/remoting_client"
if [ -n "$notfound" ];then
    code cp -r /tmp/ispconfig3_install/remoting_client -T "${prefix}/remoting_client"
    cp -r /tmp/ispconfig3_install/remoting_client -T "${prefix}/remoting_client"
    dirMustExists "${prefix}/remoting_client"
fi
[ -d "${prefix}/remoting_client" ] || dirMustExists "${prefix}/remoting_client"
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
# )
# VALUE=(
# --fqdn
# --ispconfig-version
# --php-version
# --phpmyadmin-version
# --roundcube-version
# --certbot-authenticator
# )
# FLAG_VALUE=(
# )
# CSV=(
# )
# EOF
# clear
