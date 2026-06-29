#!/bin/bash

# Dependency.
[ -v RCM_PUBLIC_DOMAIN ] || { red "Unable to proceed, variable \$RCM_PUBLIC_DOMAIN does not exist."; x; }
[ -n "$RCM_PHP_VERSION" ] || { red "Unable to proceed, variable \$RCM_PHP_VERSION is empty."; x; }
require rcm mariadb add project

# Define variables and constants.
public_domain="$RCM_PUBLIC_DOMAIN"
php_version="$RCM_PHP_VERSION"
php_fpm_user=ispconfig
ispconfig_install_dir=/usr/local/ispconfig
MYSQL_ROOT_PASSWD=${MYSQL_ROOT_PASSWD:=$HOME/.mysql-root-passwd.txt}
MYSQL_ROOT_PASSWD_INI=${MYSQL_ROOT_PASSWD_INI:=$HOME/.mysql-root-passwd.ini}
MARIADB_PREFIX_MASTER=${MARIADB_PREFIX_MASTER:=/usr/local/share/mariadb}
MARIADB_USERS_CONTAINER_MASTER=${MARIADB_USERS_CONTAINER_MASTER:=users}

# Functions.
populate-database-user-password() {
    [ -z "$1" ] && x Warning: Missing argument 1 for populate-database-user-password'()'.
    local path="$1"
    # Reset.
    DB_USER=
    DB_USER_PASSWORD=
    if [ -f "$path" ];then
        . "$path"
    fi
}
website-credential-ispconfig() {
    [ -z "$1" ] && x Warning: Missing argument 1 for website-credential-ispconfig'()'.
    local path="$1"
    local password
    # Reset.
    ISPCONFIG_WEB_USER_PASSWORD=
    if [ -f "$path" ];then
        . "$path"
    else
        password=$(pwgen 9 -1vA0B)
        mkdir -p $(dirname "$path")
        cat << EOF > "$path"
ISPCONFIG_WEB_USER_PASSWORD=$password
EOF
        chmod 0500 $(dirname "$path")
        chmod 0400 "$path"
        . "$path"
    fi
}
toggle-mysql-root-password() {
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
configure-php-fpm-systemd-overrides() {
    # global $php_version
    # Reference:
    # - https://forum.howtoforge.com/threads/ispconfig-3-php-fatal-error-after-deb-sury-org-php-upgrade-ids-temp-folder-becomes-read-only-syst.95140/
    # - https://git.ispconfig.org/ispconfig/ispconfig3/-/commit/cc1c709acd3d851be6147ceb6c895c01a2bdd51d
    # systemctl list-unit-files "php*-fpm.service" --no-legend 2>/dev/null
    service_name="php${php_version}-fpm.service"
    override_dir='/etc/systemd/system/'$service_name'.d';
    mkdir -p "$override_dir"
    override_file="${override_dir}/ispconfig.conf"
    ispconfig_temp_dir="${ispconfig_install_dir}/interface/temp";
    cat > "$override_file" << EOF
[Service]
ReadWritePaths=__ISPCONFIG_TEMP_DIR__
EOF
    sed -i 's|__ISPCONFIG_TEMP_DIR__|'"$ispconfig_temp_dir"'|' "$override_file"
    systemctl daemon-reload 2>&1
    systemctl is-active --quiet "$service_name" && systemctl restart "$service_name"
}

chapter Merakit INI file autoinstaller.
source=/tmp/ispconfig3_install/docs/autoinstall_samples/autoinstall.ini.sample
target=/tmp/ispconfig3_install/install/autoinstall.ini
code 'target="'$target'"'
rcm-file "$target" isExists
if [ -n "$notfound" ];then
    rcm-file "$source" terminateIfNotExists
    cp "$source" "$target"
    rcm-file "$target" mustExists
    sed -i -E \
        -e ':a;N;$!ba;s|\[expert\]|[expert]\nconfigure_webserver=n|g' \
        "$target"
fi
rcm-file "$target" terminateIfNotExists
____

db_user=`parse-ini-file get "$target" expert mysql_ispconfig_user`
db_name=`parse-ini-file get "$target" install mysql_database`

project_name="$db_user"
INDENT+="    " \
rcm mariadb add project \
    --project-name="$project_name" \
    --without-autocreate-db \
    ; [ ! $? -eq 0 ] && x

# Get password from mariadb local share.
path="${MARIADB_PREFIX_MASTER}/${MARIADB_USERS_CONTAINER_MASTER}/${db_user}"
populate-database-user-password "$path"
chapter Mengecek database credentials: '`'$path'`'.
if [[ -z "$DB_USER_PASSWORD" ]];then
    __; red Informasi credentials tidak lengkap: '`'$path'`'.; x
else
    code db_user_password="$DB_USER_PASSWORD"
    db_user_password="$DB_USER_PASSWORD"
fi
____

path=/usr/local/share/ispconfig/credential/website
chapter Mengecek website credentials: '`'$path'`'.
website-credential-ispconfig "$path"
if [[ -z "$ISPCONFIG_WEB_USER_PASSWORD" ]];then
    __; red Informasi credentials tidak lengkap: '`'$path'`'.; x
else
    code ispconfig_web_user_password="$ISPCONFIG_WEB_USER_PASSWORD"
    ispconfig_web_user_password="$ISPCONFIG_WEB_USER_PASSWORD"
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
reference=$(cat << EOF
[install]
install_mode=expert
hostname=$fqdn
mysql_root_password=$mysql_root_passwd
http_server=nginx
ispconfig_use_ssl=n
ispconfig_admin_password=$ispconfig_web_user_password

[expert]
configure_webserver=n
configure_apache=n
configure_nginx=n
configure_firewall=n
mysql_ispconfig_password=$db_user_password
EOF
)
is_different=
if parse-ini-file is_different "$target" "$reference";then
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
    backup-file copy /tmp/ispconfig3_install/install/autoinstall.ini
    parse-ini-file merge "$target" "$reference"

    if php -r "$php" is_different "$target" "$reference";then
        red modifikasi file '`'autoinstall.ini'`' gagal.; x
    else
        green modifikasi file '`'autoinstall.ini'`' berhasil.; _.
    fi
fi
____

if [ -n "$public_domain" ];then

    path=/tmp/ispconfig3_install/install/install.php
    filename=install.php
    chapter Modifikasi file '`'$filename'`'.
    code 'path="'$path'"'
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

fi

chapter Menginstall ISPConfig
__ Memasang password MySQL untuk root
toggle-mysql-root-password yes

__ Mulai autoinstall.
cd /tmp/ispconfig3_install/install
code php install.php --autoinstall=autoinstall.ini
php install.php --autoinstall=autoinstall.ini
cd - >/dev/null
____

chapter Mengecek ISPConfig User.
code id -u '"'$php_fpm_user'"'
if id "$php_fpm_user" >/dev/null 2>&1; then
    __ User '`'$php_fpm_user'`' found.
else
    __ User '`'$php_fpm_user'`' not found.; x
fi
prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
path="$prefix/interface/web/index.php"
filename=index.php
__ Mengecek existing '`'$filename'`'
[ -f "$path" ] || { error File must exists: "$path".; x; }
____

chapter Post Install
__ Mencopot password MySQL untuk root
toggle-mysql-root-password no
__ Menambahkan direktori temporary ISPConfig.
configure-php-fpm-systemd-overrides
____
