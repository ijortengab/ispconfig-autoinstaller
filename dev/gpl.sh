# !/bin/bash

source /home/ijortengab/gist/var-dump.function.sh

# todo, check lagi db password ispconfig saat di dump file

# Reference:
# - https://www.howtoforge.com/perfect-server-debian-10-buster-apache-bind-dovecot-ispconfig-3-1/
# - https://www.howtoforge.com/perfect-server-debian-10-nginx-bind-dovecot-ispconfig-3.1/

# parse-options.sh \
# --without-end-options-double-dash \
# --compact \
# --clean \
# --no-hash-bang \
# --no-rebuild-arguments \
# --no-original-arguments \
# --no-error-invalid-options \
# --no-error-require-arguments << EOF | clip
# VALUE=(
# --timezone
# --phpmyadmin-version
# --roundcube-version
# )
# EOF
while [[ $# -gt 0 ]]; do
    case "$1" in
        --phpmyadmin-version=*) phpmyadmin_version="${1#*=}"; shift ;;
        --phpmyadmin-version) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then phpmyadmin_version="$2"; shift; fi; shift ;;
        --roundcube-version=*) roundcube_version="${1#*=}"; shift ;;
        --roundcube-version) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then roundcube_version="$2"; shift; fi; shift ;;
        --timezone=*) timezone="${1#*=}"; shift ;;
        --timezone) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then timezone="$2"; shift; fi; shift ;;
        --[^-]*) shift ;;
        *) shift ;;
    esac
done

# this_file=$(realpath "$0")
# directory_this_file=$(dirname "$this_file")

# VarDump this_file directory_this_file

# exit
# if [ -n "$1" ];then
    # module_name="$1"
    # @todo, tidak boleh ada spasi.
    # echo module dijalnkan
    # exit
# fi
# "$this_file" mantab "$@" mantab
# echo aku
# echo $1
# echo bisa
# exit

[ -n "$timezone" ] || { timezone='Asia/Jakarta'; }
[ -n "$phpmyadmin_version" ] || { phpmyadmin_version='5.2.0'; }
[ -n "${roundcube_version}" ] || { roundcube_version='1.6.0'; }
NOW=$(date +%Y%m%d-%H%M%S)
PHP_VERSION=7.4
PHPMYADMIN_DB_NAME=phpmyadmin
ROUNDCUBE_DB_NAME=roundcubemail
PHPMYADMIN_DB_USER_HOST=localhost
ROUNDCUBE_DB_USER_HOST=localhost
ISPCONFIG_DB_USER_HOST=localhost
PHPMYADMIN_DB_USER=pma
ROUNDCUBE_DB_USER=roundcube
PHPMYADMIN_NGINX_CONFIG_FILE=phpmyadmin
ROUNDCUBE_NGINX_CONFIG_FILE=roundcube
ISPCONFIG_NGINX_CONFIG_FILE=ispconfig
PHPMYADMIN_SUBDOMAIN_LOCALHOST=phpmyadmin.localhost
ROUNDCUBE_SUBDOMAIN_LOCALHOST=roundcube.localhost
ISPCONFIG_SUBDOMAIN_LOCALHOST=ispconfig.localhost
POSTFIX_CONFIG_FILE=/etc/postfix/master.cf
MYSQL_ROOT_PASSWD=/root/.mysql-root-passwd.txt
MYSQL_ROOT_PASSWD_INI=/root/.mysql-root-passwd.ini
ISPCONFIG_INSTALL_DIR=/usr/local/ispconfig

# @todo
FQDN=server1.mantab.com

red() { echo -ne "\e[91m"; echo -n "$@"; echo -e "\e[39m"; }
green() { echo -ne "\e[92m"; echo -n "$@"; echo -e "\e[39m"; }
yellow() { echo -ne "\e[93m"; echo -n "$@"; echo -e "\e[39m"; }
blue() { echo -ne "\e[94m"; echo -n "$@"; echo -e "\e[39m"; }
magenta() { echo -ne "\e[95m"; echo -n "$@"; echo -e "\e[39m"; }
x() { exit 1; }
e() { echo "$@"; }
__() { echo -n '    '; [ -n "$1" ] && echo "$@" || echo -n ; }
____() { echo; }

# global used:
# global modified:
# function used: __, green, red, x
fileMustExists() {
    if [ -f "$1" ];then
        __; green File '`'$(basename "$1")'`' ditemukan.
    else
        __; red File '`'$(basename "$1")'`' tidak ditemukan.; x
    fi
}

# global used:
# global modified: found, notfound
# function used: __
isFileExists() {
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

pregQuote() {
    local string="$1"
    # karakter dot (.), menjadi slash dot (\.)
    sed "s/\./\\\./g" <<< "$string"
}

# @todo, ubah juga function ini drupal.
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

blue '######################################################################'
blue '#                                                                    #'
blue '# GAK PAKE LAMA                                                      #'
blue '#                                                                    #'
blue '######################################################################'
____

e Version 0.1.0
____

yellow User variable.
magenta 'timezone="'$timezone'"'
magenta 'phpmyadmin_version="'$phpmyadmin_version'"'
magenta 'roundcube_version="'${roundcube_version}'"'
____

yellow Define variable.
magenta 'PHP_VERSION="'$PHP_VERSION'"'
magenta 'PHPMYADMIN_DB_NAME="'$PHPMYADMIN_DB_NAME'"'
magenta 'PHPMYADMIN_DB_USER_HOST="'$PHPMYADMIN_DB_USER_HOST'"'
magenta 'ROUNDCUBE_DB_USER_HOST="'$ROUNDCUBE_DB_USER_HOST'"'
magenta 'ISPCONFIG_DB_USER_HOST="'$ISPCONFIG_DB_USER_HOST'"'
magenta 'PHPMYADMIN_DB_USER="'$PHPMYADMIN_DB_USER'"'
magenta 'ROUNDCUBE_DB_USER="'$ROUNDCUBE_DB_USER'"'
magenta 'PHPMYADMIN_NGINX_CONFIG_FILE="'$PHPMYADMIN_NGINX_CONFIG_FILE'"'
magenta 'ROUNDCUBE_NGINX_CONFIG_FILE="'$ROUNDCUBE_NGINX_CONFIG_FILE'"'
magenta 'ISPCONFIG_NGINX_CONFIG_FILE="'$ISPCONFIG_NGINX_CONFIG_FILE'"'
magenta 'PHPMYADMIN_SUBDOMAIN_LOCALHOST="'$PHPMYADMIN_SUBDOMAIN_LOCALHOST'"'
magenta 'ROUNDCUBE_SUBDOMAIN_LOCALHOST="'$ROUNDCUBE_SUBDOMAIN_LOCALHOST'"'
magenta 'ISPCONFIG_SUBDOMAIN_LOCALHOST="'$ISPCONFIG_SUBDOMAIN_LOCALHOST'"'
magenta 'POSTFIX_CONFIG_FILE="'$POSTFIX_CONFIG_FILE'"'
magenta 'MYSQL_ROOT_PASSWD="'$MYSQL_ROOT_PASSWD'"'
magenta 'MYSQL_ROOT_PASSWD_INI="'$MYSQL_ROOT_PASSWD_INI'"'
____

yellow Mengecek akses root.
if [[ "$EUID" -ne 0 ]]; then
	red This script needs to be run with superuser privileges.; exit
else
    __ Privileges.
fi
____

yellow Mengecek '$PATH'
notfound=
if grep -q '/usr/sbin' <<< "$PATH";then
  __ '$PATH' sudah lengkap.
else
  __ '$PATH' belum lengkap.
  notfound=1
fi
if [[ -n "$notfound" ]];then
    yellow Memperbaiki '$PATH'
    PATH=/usr/local/sbin:/usr/sbin:/sbin:$PATH
    if grep -q '/usr/sbin' <<< "$PATH";then
      __; green '$PATH' sudah lengkap.
    else
      __; green '$PATH' belum lengkap.
      notfound=1
    fi
fi
____

yellow Mengecek shell default
is_dash=
if [[ $(realpath /bin/sh) == '/usr/bin/dash' ]];then
    __ '`'sh'`' command is linked to dash.
    is_dash=1
else
    __ '`'sh'`' command is linked to $(realpath /bin/sh).
fi
____

if [[ -n "$is_dash" ]];then
    yellow Disable dash
    __ '`sh` command link to dash. Disable now.'
    echo "dash dash/sh boolean false" | debconf-set-selections
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
    if [[ $(realpath /bin/sh) == '/usr/bin/dash' ]];then
        __; red '`'sh'`' command link to dash.; exit

    else
        __; green '`'sh'`' command link to $(realpath /bin/sh).
    fi
    ____
fi

yellow Mengecek timezone.
current_timezone=$(timedatectl status | grep 'Time zone:' | grep -o -P "Time zone:\s\K(\S+)")
adjust=
if [[ "$current_timezone" == "$timezone" ]];then
    __ Timezone is match: ${current_timezone}
else
    __ Timezone is different: ${current_timezone}
    adjust=1
fi
____

if [[ -n "$adjust" ]];then
    yellow Adjust timezone.
    timedatectl set-timezone "$timezone"
    current_timezone=$(timedatectl status | grep 'Time zone:' | grep -o -P "Time zone:\s\K(\S+)")
    if [[ "$current_timezone" == "$timezone" ]];then
        __; green Timezone is match: ${current_timezone}
    else
        __; red Timezone is different: ${current_timezone}; exit
    fi
    ____
fi

yellow Update Repository
for string in \
'deb http://deb.debian.org/debian/ bullseye main' \
'deb-src http://deb.debian.org/debian/ bullseye main' \
'deb http://security.debian.org/debian-security bullseye-security main' \
'deb-src http://security.debian.org/debian-security bullseye-security main' \
'deb http://deb.debian.org/debian/ bullseye-updates main' \
'deb-src http://deb.debian.org/debian/ bullseye-updates main'
do
    if [[ -n $(grep "# $string" /etc/apt/sources.list) ]];then
        sed -i 's,^# '"$string"','"$string"',' /etc/apt/sources.list
        update_now=1
    elif [[ -z $(grep "$string" /etc/apt/sources.list) ]];then
        CONTENT+="$string"$'\n'
        update_now=1
    fi
done
[ -z "$CONTENT" ] || {
    CONTENT=$'\n'"# Customize. ${NOW}"$'\n'"$CONTENT"
    echo "$CONTENT" >> /etc/apt/sources.list
}
if [[ $update_now == 1 ]];then
    magenta apt -y update
    magenta apt -y upgrade
    apt -y update
    apt -y upgrade
else
    __ Repository updated.
fi
____

aptinstalled=$(apt --installed list 2>/dev/null)
downloadApplication() {
    yellow Melakukan instalasi aplikasi "$@".
    local aptnotfound=
    for i in "$@"; do
        if ! grep -q "^$i/" <<< "$aptinstalled";then
            aptnotfound+=" $i"
        fi
    done
    if [ -n "$aptnotfound" ];then
        __ Menginstal.
        magenta apt install -y"$aptnotfound"
        apt install -y $aptnotfound
        aptinstalled=$(apt --installed list 2>/dev/null)
    else
        __ Aplikasi sudah terinstall seluruhnya.
    fi
}
validateApplication() {
    local aptnotfound=
    for i in "$@"; do
        if ! grep -q "^$i/" <<< "$aptinstalled";then
            aptnotfound+=" $i"
        fi
    done
    if [ -n "$aptnotfound" ];then
        __; red Gagal menginstall aplikasi:"$aptnotfound"; exit
    fi
}
application=
application+=' lsb-release apt-transport-https ca-certificates'
application+=' sudo patch curl wget net-tools apache2-utils openssl rkhunter '
application+=' binutils dnsutils pwgen daemon apt-listchanges lrzip p7zip '
application+=' p7zip-full zip unzip bzip2 lzop arj nomarch cabextract'
application+=' libnet-ident-perl libnet-dns-perl libauthen-sasl-perl'
application+=' libdbd-mysql-perl libio-string-perl libio-socket-ssl-perl'
# application+=' unrar' # disabled because non-free
downloadApplication $application
validateApplication $application;
____

yellow Mengecek apakah nginx installed.
notfound=
if grep -q "^nginx/" <<< "$aptinstalled";then
    __ nginx installed.
else
    __ nginx not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menginstall nginx
    magenta apt install nginx -y
    apt install nginx -y
    aptinstalled=$(apt --installed list 2>/dev/null)
    if grep -q "^nginx/" <<< "$aptinstalled";then
        __; green nginx installed.
    else
        __; red nginx not found.; exit
    fi
    ____
fi

yellow Mengecek apakah mariadb-server installed.
notfound=
if grep -q "^mariadb-server/" <<< "$aptinstalled";then
    __ mariadb-server installed.
else
    __ mariadb-server not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menginstall mariadb-server
    magenta apt install mariadb-server -y
    apt install mariadb-server -y
    aptinstalled=$(apt --installed list 2>/dev/null)
    if grep -q "^mariadb-server/" <<< "$aptinstalled";then
        __; green mariadb-server installed.
    else
        __; red mariadb-server not found.; exit
    fi
    ____
fi

yellow Mengecek apakah mariadb-client installed.
notfound=
if grep -q "^mariadb-client/" <<< "$aptinstalled";then
    __ mariadb-client installed.
else
    __ mariadb-client not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menginstall mariadb-client
    magenta apt install mariadb-client -y
    apt install mariadb-client -y
    aptinstalled=$(apt --installed list 2>/dev/null)
    if grep -q "^mariadb-client/" <<< "$aptinstalled";then
        __; green mariadb-client installed.
    else
        __; red mariadb-client not found.; exit
    fi
    ____
fi

yellow Mengecek konfigurasi MariaDB '`'/etc/mysql/mariadb.conf.d/50-server.cnf'`'.
if [ -f /etc/mysql/mariadb.conf.d/50-server.cnf ];then
    if grep -q '^\s*bind-address\s*=\s*127.0.0.1\s*$' /etc/mysql/mariadb.conf.d/50-server.cnf;then
        __ Disable bind-address localhost '[disabling]'.
        sed -i 's/^bind-address/# bind-address/g' /etc/mysql/mariadb.conf.d/50-server.cnf
    elif grep -q '^\s*#\s*bind-address\s*=\s*127.0.0.1\s*$' /etc/mysql/mariadb.conf.d/50-server.cnf;then
        __ Disable bind-address localhost '[existing]'.
    else
        __ Not found: bind-address localhost
    fi
else
    __; red File '`'/etc/mysql/mariadb.conf.d/50-server.cnf'`' tidak ditemukan.; exit
fi
____

yellow Mengecek konfigurasi MariaDB '`'/etc/security/limits.conf'`'.
if [ -f /etc/security/limits.conf ];then
    append=
    if grep -q -E '^\s*#\s*mysql\s+soft\s+nofile\s+65535\s*$' /etc/security/limits.conf;then
        __ Enable line '`'mysql soft nofile 65535'`' '[enabling]'.
        sed -i -E 's/^\s*#\s*mysql\s+soft\s+nofile\s+65535\s*$/mysql soft nofile 65535/' /etc/security/limits.conf
    elif grep -q -E '^\s*mysql\s+soft\s+nofile\s+65535\s*$' /etc/security/limits.conf;then
        __ Enable line '`'mysql soft nofile 65535'`' '[existing]'.
    else
        __ Append line '`'mysql soft nofile 65535'`'.
        append=1
    fi
    if grep -q -E '^\s*#\s*mysql\s+hard\s+nofile\s+65535\s*$' /etc/security/limits.conf;then
        __ Enable line '`'mysql hard nofile 65535'`' '[enabling]'.
        sed -i -E 's/^\s*#\s*mysql\s+hard\s+nofile\s+65535\s*$/mysql hard nofile 65535/' /etc/security/limits.conf
    elif grep -q -E '^\s*mysql\s+hard\s+nofile\s+65535\s*$' /etc/security/limits.conf;then
        __ Enable line '`'mysql hard nofile 65535'`' '[existing]'.
    else
        __ Append line '`'mysql hard nofile 65535'`'.
        append=1
    fi
    if [ -n "$append" ];then
        echo    "" >> /etc/security/limits.conf
        echo    "# Added at ${NOW}" >> /etc/security/limits.conf
        grep -q -E '^\s*mysql\s+soft\s+nofile\s+65535\s*$' /etc/security/limits.conf || \
            echo    "mysql soft nofile 65535" >> /etc/security/limits.conf
        grep -q -E '^\s*mysql\s+hard\s+nofile\s+65535\s*$' /etc/security/limits.conf || \
            echo    "mysql hard nofile 65535" >> /etc/security/limits.conf
    fi
else
    __; red File '`'/etc/security/limits.conf'`' tidak ditemukan.; exit
fi
____

yellow Mengecek konfigurasi MariaDB '`'/etc/systemd/system/mysql.service.d/limits.conf'`'.
notfound=
if [ -f /etc/systemd/system/mysql.service.d/limits.conf ];then
    __ File ditemukan.
else
    __ File tidak ditemukan.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Membuat unit file service '`'/etc/systemd/system/mysql.service.d/limits.conf'`'.
    mkdir -p /etc/systemd/system/mysql.service.d/
    cat << EOF > /etc/systemd/system/mysql.service.d/limits.conf
[Service]
LimitNOFILE=infinity
EOF
    magenta systemctl daemon-reload
    magenta systemctl restart mariadb
    systemctl daemon-reload
    systemctl restart mariadb
    if [ -f /etc/systemd/system/mysql.service.d/limits.conf ];then
        __; green File ditemukan.
    else
        __; red File tidak ditemukan.; exit
    fi
    ____
fi

installphp() {
    local PHP_VERSION=$1
    local PRETTY_NAME NAME VERSION_ID VERSION VERSION_CODENAME
    local ID ID_LIKE HOME_URL SUPPORT_URL BUG_REPORT_URL PRIVACY_POLICY_URL
    local UBUNTU_CODENAME
    . /etc/os-release
    magenta 'ID="'$ID'"'
    magenta 'VERSION_ID="'$VERSION_ID'"'
    case $ID in
        debian)
            case "$VERSION_ID" in
                11)
                    case "$PHP_VERSION" in
                        7.4)
                            yellow Menginstall php7.4
                            magenta apt install php7.4 -y
                            apt install php7.4 -y
                            ;;
                    esac
                ;;
            esac
            ;;
        ubuntu)
            case "$VERSION_ID" in
                22.04)
                    case "$PHP_VERSION" in
                        7.4)
                            addRepositoryPpaOndrejPhp
                            yellow Menginstall php7.4
                            magenta apt install php7.4 -y
                            apt install php7.4 -y
                            ;;
                        8.1)
                            yellow Menginstall php8.1
                            magenta apt install php -y
                            apt install php -y
                            # libapache2-mod-php8.1 php php8.1 php8.1-cli php8.1-common php8.1-opcache php8.1-readline
                    esac
                ;;
                *) red OS "$ID" version "$VERSION_ID" not supported; exit;
            esac
            ;;
        *) red OS "$ID" not supported; exit;
    esac
}

yellow Mengecek apakah PHP version 7.4 installed.
notfound=
string=php7.4
string_quoted=$(pregQuote "$string")
if grep -q "^${string_quoted}/" <<< "$aptinstalled";then
    __ PHP 7.4 installed.
else
    __ PHP 7.4 not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menginstall PHP 7.4
    installphp 7.4
    aptinstalled=$(apt --installed list 2>/dev/null)
    if grep -q "^${string_quoted}/" <<< "$aptinstalled";then
        __; green PHP 7.4 installed.
    else
        __; red PHP 7.4 not found.; exit
    fi
    ____
fi

yellow Mengecek UnitFileState service Apache2. # Menginstall PHP di Debian, biasanya auto install juga Apache2.
msg=$(systemctl show apache2.service --no-page | grep UnitFileState | grep -o -P "UnitFileState=\K(\S+)")
disable=
if [[ -z "$msg" ]];then
    __ UnitFileState service Apache2 not found.
elif [[ "$msg"  == 'enabled' ]];then
    __ UnitFileState service Apache2 enabled.
    disable=1
else
    __ UnitFileState service Apache2: $msg.
fi
____

if [ -n "$disable" ];then
    yellow Mematikan service Apache2.
    magenta systemctl disable --now apache2
    systemctl disable --now apache2
    msg=$(systemctl show apache2.service --no-page | grep UnitFileState | grep -o -P "UnitFileState=\K(\S+)")
    if [[ $msg == 'disabled' ]];then
        __; green Berhasil disabled.
    else
        __; red Gagal disabled.
        __ UnitFileState state: $msg.
        exit
    fi
    ____
fi

yellow Mengecek ActiveState service Nginx. # Kadang bentrok dengan Apache2.
msg=$(systemctl show nginx.service --no-page | grep ActiveState | grep -o -P "ActiveState=\K(\S+)")
restart=
if [[ -z "$msg" ]];then
    __; red Service nginx tidak ditemukan.; exit
elif [[ "$msg"  == 'active' ]];then
    __ Service nginx active.
else
    __ Service ActiveState nginx: $msg.
    restart=1
fi
____

if [ -n "$restart" ];then
    yellow Menjalankan service nginx.
    magenta systemctl enable --now nginx
    systemctl enable --now nginx
    msg=$(systemctl show nginx.service --no-page | grep ActiveState | grep -o -P "ActiveState=\K(\S+)")
    if [[ $msg == 'active' ]];then
        __; green Berhasil activated.
    else
        __; red Gagal activated.
        __ ActiveState state: $msg.
        exit
    fi
    ____
fi

downloadApplication php7.4-{common,gd,mysql,imap,cli,fpm,curl,intl,pspell,sqlite3,tidy,xmlrpc,xsl,zip,mbstring,soap,opcache}
validateApplication php7.4-{common,gd,mysql,imap,cli,fpm,curl,intl,pspell,sqlite3,tidy,xmlrpc,xsl,zip,mbstring,soap,opcache}
____

yellow Mengecek apakah postfix installed.
notfound=
if grep -q "^postfix/" <<< "$aptinstalled";then
    __ Postfix installed.
else
    __ postfix not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    # @todo, butuh fqcdn
    # atau kita skip dulu deh.
    # @ todo postfix here.
    # @todo, sementara kita gunakan rojimantabjiwa.com
    yellow Menginstall Postfix
    FQDN='rojimantabjiwa.com'
    debconf-set-selections <<< "postfix postfix/mailname string ${FQDN}"
    debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
    magenta apt install postfix -y
    apt install postfix -y
    aptinstalled=$(apt --installed list 2>/dev/null)
    if grep -q "^postfix/" <<< "$aptinstalled";then
        __; green postfix installed.
    else
        __; red postfix not found.; exit
    fi
    ____
fi

# @todo, debian 11 menggunakan getmail6 sementara getmail4 tidak ada
# apt-cache policy getmail
# todo, beritahu user kalo script ini hanya berlaku
# jika ISP membuka port 25 outgoing
application=
application+=' postfix-mysql postfix-doc'
application+=' dovecot-core dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve dovecot-lmtpd'
application+=' getmail amavisd-new postgrey spamassassin'
downloadApplication $application
validateApplication $application
____

yellow Mengecek UnitFileState service SpamAssassin. # Menginstall PHP di Debian, biasanya auto install juga SpamAssassin.
msg=$(systemctl show spamassassin.service --no-page | grep UnitFileState | grep -o -P "UnitFileState=\K(\S+)")
disable=
if [[ -z "$msg" ]];then
    __ UnitFileState service SpamAssassin not found.
elif [[ "$msg"  == 'enabled' ]];then
    __ UnitFileState service SpamAssassin enabled.
    disable=1
else
    __ UnitFileState service SpamAssassin: $msg.
fi
____

if [ -n "$disable" ];then
    yellow Mematikan service SpamAssassin.
    magenta systemctl disable --now spamassassin
    systemctl disable --now spamassassin
    msg=$(systemctl show spamassassin.service --no-page | grep UnitFileState | grep -o -P "UnitFileState=\K(\S+)")
    if [[ $msg == 'disabled' ]];then
        __; green Berhasil disabled.
    else
        __; red Gagal disabled.
        __ UnitFileState state: $msg.
        exit
    fi
    ____
fi

ArraySearch() {
    local index match="$1"
    local source=("${!2}")
    for index in "${!source[@]}"; do
       if [[ "${source[$index]}" == "${match}" ]]; then
           _return=$index; return 0
       fi
    done
    return 1
}

ArrayDiff() {
    local e
    local source=("${!1}")
    local reference=("${!2}")
    _return=()
    # inArray is alternative of ArraySearch.
    inArray () {
        local e match="$1"
        shift
        for e; do [[ "$e" == "$match" ]] && return 0; done
        return 1
    }
    if [[ "${#reference[@]}" -gt 0 ]];then
        for e in "${source[@]}";do
            if ! inArray "$e" "${reference[@]}";then
                _return+=("$e")
            fi
        done
    else
        _return=("${source[@]}")
    fi
}

ArrayIntersect() {
    local e
    local source=("${!1}")
    local reference=("${!2}")
    _return=()
    # inArray is alternative of ArraySearch.
    inArray () {
        local e match="$1"
        shift
        for e; do [[ "$e" == "$match" ]] && return 0; done
        return 1
    }
    if [[ "${#reference[@]}" -gt 0 ]];then
        for e in "${source[@]}";do
            if inArray "$e" "${reference[@]}";then
                _return+=("$e")
            fi
        done
    else
        _return=("${source[@]}")
    fi
}

pregQuoteSpace() {
    local string="$1"
    echo "$string" | sed -E "s,\s+,\\\s+,g"
}

# Reference: http://www.postfix.org/master.5.html
# SYNTAX
# The general format of the master.cf file is as follows:
# 1. Empty  lines and whitespace-only lines are ignored, as are lines
#    whose first non-whitespace character is a `#'.
# 2. A logical line starts with  non-whitespace  text.  A  line  that
#    starts with whitespace continues a logical line.
# 3. Each  logical  line defines a single Postfix service.  Each ser-
#    vice is identified by its name  and  type  as  described  below.
#    When multiple lines specify the same service name and type, only
#    the last one is remembered.  Otherwise, the order  of  master.cf
#    service definitions does not matter.
#
# Source: https://github.com/servisys/ispconfig_setup/blob/master/distros/debian11/install_postfix.sh
# service    type private unpriv chroot wakeup maxproc command + args
# submission inet n       -      y      -      -       smtpd
reference_contents=$(cat << 'EOF'
submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_tls_auth_only=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
smtps     inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
EOF
)

# global modified append_contents
# global used POSTFIX_CONFIG_FILE reference_contents
postfixConfigEditor() {
    local mode=$1
    append_contents=
    # Rules 1. Cleaning line start with hash (#).
    local input_contents=$(sed -e '/^\s*#.*$/d' -e '/^\s*$/d' <"$POSTFIX_CONFIG_FILE")
    while IFS= read -r line; do
        reference_list_services_headonly=$(grep -v -E "^[[:blank:]]+" <<< "$reference_contents")
    done <<< "$reference_contents"
    while IFS= read -r reference_each_service_headonly; do
        reference_each_service_headonly_simple_space=$(sed -E 's,\s+, ,g' <<< "$reference_each_service_headonly")
        __ Mengecek service: "$reference_each_service_headonly_simple_space"
        reference_each_service_headonly_quoted=$(pregQuoteSpace "$reference_each_service_headonly")
        count=0
        # Grep new line. Credit: https://stackoverflow.com/a/49192452
        input_each_service_fullbody_multiple=$(grep -zoP '(^|\n)'"$reference_each_service_headonly_quoted"'.*(\n[\s]+.*)+' <<< "$input_contents" | xargs -0 | sed '/^\s*$/d')
        input_each_service_fullbody_flatty_multiple=
        # Replace new line. Credit: https://unix.stackexchange.com/a/114948
        [ -n "$input_each_service_fullbody_multiple" ] && {
            input_each_service_fullbody_flatty_multiple=$(sed -E ':a;N;$!ba;s/\n\s+/ /g'  <<< "$input_each_service_fullbody_multiple")
            count=$(cat <<< "$input_each_service_fullbody_flatty_multiple" | wc -l)
        }
        __ Menemukan $count baris.
        if [ $count -eq 0 ];then
            reference_each_service_fullbody=$(grep -zoP '(^|\n)'"$reference_each_service_headonly_quoted"'.*(\n[\s]+.*)+' <<< "$reference_contents" | xargs -0 | sed '/^\s*$/d')
            append_contents+="$reference_each_service_fullbody"$'\n'
            continue
        fi
        # Rules 3. Bisa jadi terdapat lebih dari satu kali. Kita ambil yang paling bawah.
        input_each_service_fullbody_flatty=$(tail -1 <<< "$input_each_service_fullbody_flatty_multiple")
        input_each_service_argumentsonly_flatty=$(sed -E -e "s/$reference_each_service_headonly_quoted//" <<< "$input_each_service_fullbody_flatty")
        # Populate array of keys and value from input.
        input_each_service_list_arguments=$(grep -oP '\s+-o\s+\K([^\s]+)' <<< "$input_each_service_argumentsonly_flatty" )
        input_each_service_list_arguments_keys=()
        input_each_service_list_arguments_values=()
        while IFS= read -r each; do
            if [[ $each = *" "* ]];then # Skip contain space
                continue;
            fi
            if grep -q -E '^[^=]+=.*' <<< "$each";then
                _key=$(echo "$each" | cut -d'=' -f 1)
                _value=$(echo "$each" | cut -d'=' -f 2)
                input_each_service_list_arguments_keys+=("$_key")
                input_each_service_list_arguments_values+=("$_value")
            fi
        done <<< "$input_each_service_list_arguments"
        reference_each_service_fullbody=$(grep -zoP '(^|\n)'"$reference_each_service_headonly_quoted"'.*(\n[\s]+.*)+' <<< "$reference_contents" | xargs -0)
        reference_each_service_fullbody_flatty=$(sed -E ':a;N;$!ba;s/\n\s+/ /g'  <<< "$reference_each_service_fullbody")
        reference_each_service_argumentsonly_flatty=$(sed -E -e "s/$reference_each_service_headonly_quoted//" <<< "$reference_each_service_fullbody_flatty" )
        # Populate array of keys and value from reference.
        reference_each_service_list_arguments=$(grep -oP '\s+-o\s+\K([^\s]+)' <<< "$reference_each_service_argumentsonly_flatty" )
        reference_each_service_list_arguments_keys=()
        reference_each_service_list_arguments_values=()
        while IFS= read -r each; do
            if [[ $each = *" "* ]];then # Skip contian space
                continue;
            fi
            if grep -q -E '^[^=]+=.*' <<< "$each";then
                _key=$(echo "$each" | cut -d'=' -f 1)
                _value=$(echo "$each" | cut -d'=' -f 2)
                reference_each_service_list_arguments_keys+=("$_key")
                reference_each_service_list_arguments_values+=("$_value")
            fi
        done <<< "$reference_each_service_list_arguments"
        ArrayDiff reference_each_service_list_arguments_keys[@] input_each_service_list_arguments_keys[@]
        array_diff_result=("${_return[@]}"); unset _return # Clear karena parameter akan digunakan lagi oleh ArraySearch.
        ArrayIntersect reference_each_service_list_arguments_keys[@] input_each_service_list_arguments_keys[@]
        array_intersect_result=("${_return[@]}"); unset _return # Clear karena parameter akan digunakan lagi oleh ArraySearch.
        is_modified=
        if [ "${#array_diff_result[@]}" -gt 0 ];then
            is_modified=1
            for each in "${array_diff_result[@]}"; do
                ArraySearch "$each" reference_each_service_list_arguments_keys[@]
                reference_key="$_return"; unset _return; # Clear.
                reference_value="${reference_each_service_list_arguments_values[$reference_key]}"
                input_each_service_list_arguments_keys+=("$each")
                input_each_service_list_arguments_values+=("$reference_value")
            done
        fi
        if [ "${#array_intersect_result[@]}" -gt 0 ];then
            for each in "${array_intersect_result[@]}"; do
                ArraySearch "$each" reference_each_service_list_arguments_keys[@]
                reference_key="$_return"; unset _return; # Clear.
                reference_value="${reference_each_service_list_arguments_values[$reference_key]}"
                ArraySearch "$each" input_each_service_list_arguments_keys[@]
                input_key="$_return"; unset _return; # Clear.
                input_value="${input_each_service_list_arguments_values[$input_key]}"
                if [[ ! "$reference_value" == "$input_value" ]];then
                    is_modified=1
                    input_each_service_list_arguments_values[$input_key]="$reference_value"
                fi
            done
        fi
        if [ -n "$is_modified" ];then
            append_contents+="$reference_each_service_headonly"$'\n'
            for ((i = 0 ; i < ${#input_each_service_list_arguments_keys[@]} ; i++)); do
                key="${input_each_service_list_arguments_keys[$i]}"
                value="${input_each_service_list_arguments_values[$i]}"
                append_contents+="  -o ${key}=${value}"$'\n'
            done
        fi
    done <<< "$reference_list_services_headonly"
    if [[ $mode == 'is_different' && -n "$append_contents" ]];then
        return 0
    fi
    return 1
}

yellow Mengecek konfigurasi Postfix.
is_different=
if postfixConfigEditor is_different;then
    is_different=1
    __ Diperlukan modifikasi file '`'$POSTFIX_CONFIG_FILE'`'.
else
    __ File '`'$POSTFIX_CONFIG_FILE'`' tidak ada perubahan.
fi
____

if [ -n "$is_different" ];then
    yellow Memodifikasi file '`'$POSTFIX_CONFIG_FILE'`'.
    __ Backup file $POSTFIX_CONFIG_FILE
    backupFile copy $POSTFIX_CONFIG_FILE
    echo "$append_contents" >> $POSTFIX_CONFIG_FILE
    if postfixConfigEditor is_different;then
        __; red Modifikasi file '`'$POSTFIX_CONFIG_FILE'`' gagal.; exit
    else
        __; green Modifikasi file '`'$POSTFIX_CONFIG_FILE'`' berhasil.
        __; magenta /etc/init.d/postfix restart
        /etc/init.d/postfix restart
        #@todo, mungkin bisa diganti pake systemctl
    fi
    ____
fi

yellow Memastikan command exists
__ sudo mysql nginx php postfix
command -v "sudo" >/dev/null || { red "sudo command not found."; exit 1; }
command -v "mysql" >/dev/null || { red "mysql command not found."; exit 1; }
command -v "nginx" >/dev/null || { red "nginx command not found."; exit 1; }
command -v "php" >/dev/null || { red "php command not found."; exit 1; }
command -v "postfix" >/dev/null || { red "postfix command not found."; exit 1; }
____

yellow Mencari informasi nginx.
conf_path=$(nginx -V 2>&1 | grep -o -P -- '--conf-path=\K(\S+)')
magenta conf_path="$conf_path"
user_nginx=$(cat "$conf_path" | grep -o -P 'user\s+\K([^;]+);' | sed 's/;//')
magenta user_nginx="$user_nginx"
____

yellow Mengecek password MySQL untuk root.
found=
if [ -f "$MYSQL_ROOT_PASSWD" ];then
    mysql_root_passwd=$(<"$MYSQL_ROOT_PASSWD")
    [ -n "$mysql_root_passwd" ] && found=1
    __ Password ditemukan: "$mysql_root_passwd"
fi
if [ -z "$found" ];then
    mysql_root_passwd=$(pwgen -s 32 -1)
    echo "$mysql_root_passwd" > "$MYSQL_ROOT_PASSWD"
    printf "[client]\nuser = %s\npassword = %s\n" "root" "$mysql_root_passwd" > "$MYSQL_ROOT_PASSWD_INI"
    chmod 0400 "$MYSQL_ROOT_PASSWD"
    chmod 0400 "$MYSQL_ROOT_PASSWD_INI"
    __; green Password berhasil dibuat: "$mysql_root_passwd"
fi
____

# global used MYSQL_ROOT_PASSWD_INI
# global used mysql_root_passwd
ToggleMysqlRootPassword() {
    local switch=$1
    # echo \$switch "$switch"
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
    # echo \$is_password "$is_password"
    [ -n "$switch" ] || {
        case "$is_password" in
            yes) switch=no ;;
            no) switch=yes ;;
        esac
    }
    # echo \$switch "$switch"
    case "$switch" in
        yes) [[ "$is_password" == yes ]] && return 0 || {
            __ Password MySQL untuk root sedang dipasang.
            if mysql \
                -e "set password for root@localhost=PASSWORD('$mysql_root_passwd');" > /dev/null 2>&1;then
                __; green Password berhasil dipasang;
            else
                __; red Password gagal dipasang; exit
            fi
        } ;;
        no) [[ "$is_password" == no ]] && return 0 || {
            __ Password MySQL untuk root sedang dicopot.
            if mysql \
                --defaults-extra-file="$MYSQL_ROOT_PASSWD_INI" \
                -e "set password for root@localhost=PASSWORD('');" > /dev/null 2>&1;then
                __; green Password berhasil dicopot.
            else
                __; red Password gagal dicopot.; exit
            fi
        } ;;
    esac
}

yellow Memastikan password MySQL untuk root tidak dipasang
ToggleMysqlRootPassword no
____

blue PHPMyAdmin
sleep .5
____

yellow Mengecek database '`'$PHPMYADMIN_DB_NAME'`'.
msg=$(mysql --silent --skip-column-names -e "select schema_name from information_schema.schemata where schema_name = '$PHPMYADMIN_DB_NAME'")
notfound=
if [[ $msg == $PHPMYADMIN_DB_NAME ]];then
    __ Database ditemukan.
else
    __ Database tidak ditemukan
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Membuat database.
    mysql -e "create database $PHPMYADMIN_DB_NAME character set utf8 collate utf8_general_ci;"
    msg=$(mysql --silent --skip-column-names -e "select schema_name from information_schema.schemata where schema_name = '$PHPMYADMIN_DB_NAME'")
    if [[ $msg == $PHPMYADMIN_DB_NAME ]];then
        __; green Database ditemukan.
    else
        __; red Database tidak ditemukan; exit
    fi
    ____
fi

databaseCredentialPhpmyadmin() {
    if [ -f /usr/local/share/phpmyadmin/credential/database ];then
        local PHPMYADMIN_DB_USER PHPMYADMIN_DB_USER_PASSWORD PHPMYADMIN_BLOWFISH
        . /usr/local/share/phpmyadmin/credential/database
        phpmyadmin_db_user=$PHPMYADMIN_DB_USER
        phpmyadmin_db_user_password=$PHPMYADMIN_DB_USER_PASSWORD
        phpmyadmin_blowfish=$PHPMYADMIN_BLOWFISH
    else
        phpmyadmin_db_user=$PHPMYADMIN_DB_USER # global variable
        phpmyadmin_db_user_password=$(pwgen -s 32 -1)
        phpmyadmin_blowfish=$(pwgen -s 32 -1)
        mkdir -p /usr/local/share/phpmyadmin/credential
        cat << EOF > /usr/local/share/phpmyadmin/credential/database
PHPMYADMIN_DB_USER=$phpmyadmin_db_user
PHPMYADMIN_DB_USER_PASSWORD=$phpmyadmin_db_user_password
PHPMYADMIN_BLOWFISH=$phpmyadmin_blowfish
EOF
        chmod 0500 /usr/local/share/phpmyadmin/credential
        chmod 0400 /usr/local/share/phpmyadmin/credential/database
    fi
}

yellow Mengecek database credentials PHPMyAdmin.
databaseCredentialPhpmyadmin
if [[ -z "$phpmyadmin_db_user" || -z "$phpmyadmin_db_user_password" || -z "$phpmyadmin_blowfish" ]];then
    __; red Informasi credentials tidak lengkap: '`'/usr/local/share/phpmyadmin/credential/database'`'.; exit
else
    magenta phpmyadmin_db_user="$phpmyadmin_db_user"
    magenta phpmyadmin_db_user_password="$phpmyadmin_db_user_password"
    magenta phpmyadmin_blowfish="$phpmyadmin_blowfish"
fi
____

yellow Mengecek user database '`'$phpmyadmin_db_user'`'.
msg=$(mysql --silent --skip-column-names -e "select COUNT(*) FROM mysql.user WHERE user = '$phpmyadmin_db_user';")
notfound=
if [ $msg -gt 0 ];then
    __ User database ditemukan.
else
    __ User database tidak ditemukan.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Membuat user database '`'$phpmyadmin_db_user'`'.
    mysql -e "create user '${phpmyadmin_db_user}'@'${PHPMYADMIN_DB_USER_HOST}' identified by '${phpmyadmin_db_user_password}';"
    msg=$(mysql --silent --skip-column-names -e "select COUNT(*) FROM mysql.user WHERE user = '$phpmyadmin_db_user';")
    if [ $msg -gt 0 ];then
        __; green User database ditemukan.
    else
        __; red User database tidak ditemukan; exit
    fi
    ____
fi

yellow Mengecek grants user '`'$phpmyadmin_db_user'`' ke database '`'$PHPMYADMIN_DB_NAME'`'.
notfound=
msg=$(mysql "$PHPMYADMIN_DB_NAME" --silent --skip-column-names -e "show grants for ${phpmyadmin_db_user}@${PHPMYADMIN_DB_USER_HOST}")
if grep -q "GRANT.*ON.*${PHPMYADMIN_DB_NAME}.*TO.*${phpmyadmin_db_user}.*@.*${PHPMYADMIN_DB_USER_HOST}.*" <<< "$msg";then
    __ Granted.
else
    __ Not granted.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Memberi grants user '`'$phpmyadmin_db_user'`' ke database '`'$PHPMYADMIN_DB_NAME'`'.
    mysql -e "grant all privileges on \`${PHPMYADMIN_DB_NAME}\`.* TO '${phpmyadmin_db_user}'@'${PHPMYADMIN_DB_USER_HOST}';"
    msg=$(mysql "$PHPMYADMIN_DB_NAME" --silent --skip-column-names -e "show grants for ${phpmyadmin_db_user}@${PHPMYADMIN_DB_USER_HOST}")
    if grep -q "GRANT.*ON.*${PHPMYADMIN_DB_NAME}.*TO.*${phpmyadmin_db_user}.*@.*${PHPMYADMIN_DB_USER_HOST}.*" <<< "$msg";then
        __; green Granted.
    else
        __; red Not granted.; exit
    fi
    ____
fi

yellow Mengecek file '`'composer.json'`' untuk project '`'phpmyadmin/phpmyadmin'`'
notfound=
if [ -f /usr/local/share/phpmyadmin/${phpmyadmin_version}/composer.json ];then
    __ File '`'composer.json'`' ditemukan.
else
    __ File '`'composer.json'`' tidak ditemukan.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Mendownload PHPMyAdmin
    cd          /tmp
    wget        https://files.phpmyadmin.net/phpMyAdmin/${phpmyadmin_version}/phpMyAdmin-${phpmyadmin_version}-all-languages.tar.gz
    tar xfz     phpMyAdmin-${phpmyadmin_version}-all-languages.tar.gz
    mkdir -p    /usr/local/share/phpmyadmin/${phpmyadmin_version}
    mv          phpMyAdmin-${phpmyadmin_version}-all-languages/* -t /usr/local/share/phpmyadmin/${phpmyadmin_version}
    mv          phpMyAdmin-${phpmyadmin_version}-all-languages/.[!.]* -t /usr/local/share/phpmyadmin/${phpmyadmin_version}
    rmdir       phpMyAdmin-${phpmyadmin_version}-all-languages
    chown -R $user_nginx:$user_nginx /usr/local/share/phpmyadmin/${phpmyadmin_version}
    if [ -f /usr/local/share/phpmyadmin/${phpmyadmin_version}/composer.json ];then
        __; green File '`'composer.json'`' ditemukan.
    else
        __; red File '`'composer.json'`' tidak ditemukan.; exit
    fi
    ____
fi

yellow Mengecek apakah PHPMyAdmin sudah imported SQL.
notfound=
msg=$(mysql \
    --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "${phpmyadmin_db_user}" "${phpmyadmin_db_user_password}") \
    --silent --skip-column-names \
    $PHPMYADMIN_DB_NAME -e "show tables;" | wc -l)
if [[ $msg -gt 0 ]];then
    __ PHPMyAdmin sudah imported SQL.
else
    __ PHPMyAdmin belum imported SQL.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow PHPMyAdmin Import SQL
    mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "${phpmyadmin_db_user}" "${phpmyadmin_db_user_password}") \
        $PHPMYADMIN_DB_NAME < /usr/local/share/phpmyadmin/${phpmyadmin_version}/sql/create_tables.sql
    msg=$(mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "${phpmyadmin_db_user}" "${phpmyadmin_db_user_password}") \
        --silent --skip-column-names \
        $PHPMYADMIN_DB_NAME -e "show tables;" | wc -l)
    if [[ $msg -gt 0 ]];then
        __; green PHPMyAdmin sudah imported SQL.
    else
        __; red PHPMyAdmin belum imported SQL.; exit
    fi
    ____
fi

yellow Mengecek file konfigurasi PHPMyAdmin.
notfound=
if [ -f /usr/local/share/phpmyadmin/${phpmyadmin_version}/config.inc.php ];then
    __ File '`'config.inc.php'`' ditemukan.
else
    __ File '`'config.inc.php'`' tidak ditemukan.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Membuat file konfigurasi PHPMyAdmin.
    cp /usr/local/share/phpmyadmin/${phpmyadmin_version}/config.sample.inc.php \
        /usr/local/share/phpmyadmin/${phpmyadmin_version}/config.inc.php
    if [ -f /usr/local/share/phpmyadmin/${phpmyadmin_version}/config.inc.php ];then
        __; green File '`'config.inc.php'`' ditemukan.
        chown $user_nginx:$user_nginx /usr/local/share/phpmyadmin/${phpmyadmin_version}/config.inc.php
        chmod a-w /usr/local/share/phpmyadmin/${phpmyadmin_version}/config.inc.php
    else
        __; red File '`'config.inc.php'`' tidak ditemukan.; exit
    fi
    ____
fi

yellow Mengecek informasi file konfigurasi PHPMyAdmin pada server index 1.
php=$(cat <<'EOF'
$args = $_SERVER['argv'];
$mode = $args[1];
$file = $args[2];
$arg_blowfish = $args[3];
$arg_db_user_host = $args[4];
$arg_db_user = $args[5];
$arg_db_user_password = $args[6];
$append = array();
include($file);
$is_different = false;
$blowfish_secret = isset($cfg['blowfish_secret']) ? $cfg['blowfish_secret'] : NULL;
if (empty($blowfish_secret)) {
    $append['blowfish_secret'] = $arg_blowfish;
    $is_different = true;
}
$controlhost = isset($cfg['Servers'][1]['controlhost']) ? $cfg['Servers'][1]['controlhost'] : NULL;
// $controlport = isset($cfg['Servers'][1]['controlport']) ? $cfg['Servers'][1]['controlport'] : NULL;
$controluser = isset($cfg['Servers'][1]['controluser']) ? $cfg['Servers'][1]['controluser'] : NULL;
$controlpass = isset($cfg['Servers'][1]['controlpass']) ? $cfg['Servers'][1]['controlpass'] : NULL;
//@todo: cleaning.
//if (empty($controlhost)) {
if ($controlhost != $arg_db_user_host) {
    $append['Servers'][1]['controlhost'] = $arg_db_user_host;
    $is_different = true;
}
//if (empty($controluser)) {
if ($controluser != $arg_db_user) {
    $append['Servers'][1]['controluser'] = $arg_db_user;
    $is_different = true;
}
//if (empty($controlpass)) {
if ($controlpass != $arg_db_user_password) {
    $append['Servers'][1]['controlpass'] = $arg_db_user_password;
    $is_different = true;
}
switch ($mode) {
    case 'is_different':
        $is_different ? exit(0) : exit(1);
        break;
    case 'save':
        if ($is_different) {
            $cfg = array_replace_recursive($cfg, $append);
            $content = '$cfg = '.var_export($cfg, true).';'.PHP_EOL;
            $content = <<< EOF
<?php
$content
EOF;
            file_put_contents($file, $content);
        }
        break;
}
EOF
)
is_different=
if php -r "$php" is_different \
    /usr/local/share/phpmyadmin/${phpmyadmin_version}/config.inc.php \
    $phpmyadmin_blowfish \
    $PHPMYADMIN_DB_USER_HOST \
    $phpmyadmin_db_user \
    $phpmyadmin_db_user_password;then
    is_different=1
    __ Diperlukan modifikasi file '`'config.inc.php'`'.
else
    __ File '`'config.inc.php'`' tidak ada perubahan.
fi
____

if [ -n "$is_different" ];then
    yellow Memodifikasi file '`'config.inc.php'`'.
    __ Backup file /usr/local/share/phpmyadmin/${phpmyadmin_version}/config.inc.php
    backupFile copy /usr/local/share/phpmyadmin/${phpmyadmin_version}/config.inc.php
    php -r "$php" save \
        /usr/local/share/phpmyadmin/${phpmyadmin_version}/config.inc.php \
        $phpmyadmin_blowfish \
        $PHPMYADMIN_DB_USER_HOST \
        $phpmyadmin_db_user \
        $phpmyadmin_db_user_password
    if php -r "$php" is_different \
        /usr/local/share/phpmyadmin/${phpmyadmin_version}/config.inc.php \
        $phpmyadmin_blowfish \
        $PHPMYADMIN_DB_USER_HOST \
        $phpmyadmin_db_user \
        $phpmyadmin_db_user_password;then
        __; red Modifikasi file '`'config.inc.php'`' gagal.; exit
    else
        __; green Modifikasi file '`'config.inc.php'`' berhasil.
    fi
    ____
fi

yellow Mengecek nginx configuration apakah terdapat web root dari PHPMyAdmin
notfound=
root=/usr/local/share/phpmyadmin/${phpmyadmin_version}
string_quoted=$(pregQuote "$root")
file_config=$(grep -R -l -E "^\s*root\s+${string_quoted}\s*;" /etc/nginx/sites-enabled | head -1)
[ -n "$file_config" ] && {
    file_config=$(realpath $file_config)
    __ File config found: '`'$file_config'`'.;
} || {
    __ File config not found.;
    notfound=1
}
____

nginx_config_file=$PHPMYADMIN_NGINX_CONFIG_FILE
subdomain_localhost=$PHPMYADMIN_SUBDOMAIN_LOCALHOST
if [ -n "$notfound" ];then
    yellow Membuat nginx config.
    if [ -f /etc/nginx/sites-available/$nginx_config_file ];then
        __ Backup file /etc/nginx/sites-available/$nginx_config_file
        backupFile move /etc/nginx/sites-available/$nginx_config_file
    fi
    cat <<'EOF' > /etc/nginx/sites-available/$nginx_config_file
server {
    listen 80;
    listen [::]:80;
    root ROOT;
    index index.php;
    server_name SUBDOMAIN_LOCALHOST;
    location / {
        try_files $uri /index.php$is_args$args;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/phpPHP_VERSION-fpm.sock;
    }
}
EOF
    sed -i "s|ROOT|${root}|g" /etc/nginx/sites-available/$nginx_config_file
    sed -i "s|SUBDOMAIN_LOCALHOST|${subdomain_localhost}|g" /etc/nginx/sites-available/$nginx_config_file
    sed -i "s|PHP_VERSION|${PHP_VERSION}|g" /etc/nginx/sites-available/$nginx_config_file
    # @todo, ubah juga di drupal
    cd /etc/nginx/sites-enabled/
    ln -sf ../sites-available/$nginx_config_file
    if nginx -t 2> /dev/null;then
        nginx -s reload
    else
        red Terjadi kesalahan konfigurasi nginx. Gagal reload nginx.; exit
    fi
    file_config=$(grep -R -l -E "^\s*root\s+${string_quoted}\s*;" /etc/nginx/sites-enabled | head -1)
    [ -n "$file_config" ] && {
        file_config=$(realpath $file_config)
        __; green File config found: '`'$file_config'`'.;
    } || {
        __; red File config not found.; exit
    }
    ____
fi

yellow Mengecek subdomain '`'$subdomain_localhost'`'.
notfound=
string_quoted=$(pregQuote "$subdomain_localhost")
if grep -q -E "^\s*127\.0\.0\.1\s+${string_quoted}" /etc/hosts;then
    __ Subdomain terdapat pada local DNS resolver '`'/etc/hosts'`'.
else
    __ Subdomain tidak terdapat pada local DNS resolver '`'/etc/hosts'`'.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menambahkan subdomain '`'$subdomain_localhost'`'.
    echo "127.0.0.1"$'\t'"${subdomain_localhost}" >> /etc/hosts
    if grep -q -E "^\s*127\.0\.0\.1\s+${string_quoted}" /etc/hosts;then
        __; green Subdomain terdapat pada local DNS resolver '`'/etc/hosts'`'.
    else
        __; red Subdomain tidak terdapat pada local DNS resolver '`'/etc/hosts'`'.; exit
    fi
    ____
fi

yellow Mengecek HTTP Response Code.
if nginx -t 2> /dev/null;then
    magenta nginx -s reload
    nginx -s reload
else
    red Terjadi kesalahan konfigurasi nginx. Gagal reload nginx.; exit
fi
magenta curl http://127.0.0.1 -H '"'Host: ${subdomain_localhost}'"'
code=$(curl -L \
    -o /dev/null -s -w "%{http_code}\n" \
    http://127.0.0.1 -H "Host: ${subdomain_localhost}")
[ $code -eq 200 ] && {
    __ HTTP Response code '`'$code'`' '('Required')'.
} || {
    __; red Terjadi kesalahan. HTTP Response code '`'$code'`'.; exit
}
magenta curl http://${subdomain_localhost}
code=$(curl -L \
    -o /dev/null -s -w "%{http_code}\n" \
    http://127.0.0.1 -H "Host: ${subdomain_localhost}")
__ HTTP Response code '`'$code'`'.
____

blue RoundCube
sleep .5
____

yellow Mengecek database '`'$ROUNDCUBE_DB_NAME'`'.
msg=$(mysql --silent --skip-column-names -e "select schema_name from information_schema.schemata where schema_name = '$ROUNDCUBE_DB_NAME'")
notfound=
if [[ $msg == $ROUNDCUBE_DB_NAME ]];then
    __ Database ditemukan.
else
    __ Database tidak ditemukan
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Membuat database.
    mysql -e "create database $ROUNDCUBE_DB_NAME character set utf8 collate utf8_general_ci;"
    msg=$(mysql --silent --skip-column-names -e "select schema_name from information_schema.schemata where schema_name = '$ROUNDCUBE_DB_NAME'")
    if [[ $msg == $ROUNDCUBE_DB_NAME ]];then
        __; green Database ditemukan.
    else
        __; red Database tidak ditemukan; exit
    fi
    ____
fi

databaseCredentialRoundcube() {
    if [ -f /usr/local/share/roundcube/credential/database ];then
        local ROUNDCUBE_DB_USER ROUNDCUBE_DB_USER_PASSWORD ROUNDCUBE_BLOWFISH
        . /usr/local/share/roundcube/credential/database
        roundcube_db_user=$ROUNDCUBE_DB_USER
        roundcube_db_user_password=$ROUNDCUBE_DB_USER_PASSWORD
        roundcube_blowfish=$ROUNDCUBE_BLOWFISH
    else
        roundcube_db_user=$ROUNDCUBE_DB_USER # global variable
        roundcube_db_user_password=$(pwgen -s 32 -1)
        roundcube_blowfish=$(pwgen -s 32 -1)
        mkdir -p /usr/local/share/roundcube/credential
        cat << EOF > /usr/local/share/roundcube/credential/database
ROUNDCUBE_DB_USER=$roundcube_db_user
ROUNDCUBE_DB_USER_PASSWORD=$roundcube_db_user_password
ROUNDCUBE_BLOWFISH=$roundcube_blowfish
EOF
        chmod 0500 /usr/local/share/roundcube/credential
        chmod 0400 /usr/local/share/roundcube/credential/database
    fi
}

yellow Mengecek database credentials RoundCube.
databaseCredentialRoundcube
if [[ -z "$roundcube_db_user" || -z "$roundcube_db_user_password" || -z "$roundcube_blowfish" ]];then
    __; red Informasi credentials tidak lengkap: '`'/usr/local/share/roundcube/credential/database'`'.; exit
else
    magenta roundcube_db_user="$roundcube_db_user"
    magenta roundcube_db_user_password="$roundcube_db_user_password"
    magenta roundcube_blowfish="$roundcube_blowfish"
fi
____

yellow Mengecek user database '`'$roundcube_db_user'`'.
msg=$(mysql --silent --skip-column-names -e "select COUNT(*) FROM mysql.user WHERE user = '$roundcube_db_user';")
notfound=
if [ $msg -gt 0 ];then
    __ User database ditemukan.
else
    __ User database tidak ditemukan.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Membuat user database '`'$roundcube_db_user'`'.
    mysql -e "create user '${roundcube_db_user}'@'${ROUNDCUBE_DB_USER_HOST}' identified by '${roundcube_db_user_password}';"
    msg=$(mysql --silent --skip-column-names -e "select COUNT(*) FROM mysql.user WHERE user = '$roundcube_db_user';")
    if [ $msg -gt 0 ];then
        __; green User database ditemukan.
    else
        __; red User database tidak ditemukan; exit
    fi
    ____
fi

yellow Mengecek grants user '`'$roundcube_db_user'`' ke database '`'$ROUNDCUBE_DB_NAME'`'.
notfound=
msg=$(mysql "$ROUNDCUBE_DB_NAME" --silent --skip-column-names -e "show grants for ${roundcube_db_user}@${ROUNDCUBE_DB_USER_HOST}")
if grep -q "GRANT.*ON.*${ROUNDCUBE_DB_NAME}.*TO.*${roundcube_db_user}.*@.*${ROUNDCUBE_DB_USER_HOST}.*" <<< "$msg";then
    __ Granted.
else
    __ Not granted.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Memberi grants user '`'$roundcube_db_user'`' ke database '`'$ROUNDCUBE_DB_NAME'`'.
    mysql -e "grant all privileges on \`${ROUNDCUBE_DB_NAME}\`.* TO '${roundcube_db_user}'@'${ROUNDCUBE_DB_USER_HOST}';"
    msg=$(mysql "$ROUNDCUBE_DB_NAME" --silent --skip-column-names -e "show grants for ${roundcube_db_user}@${ROUNDCUBE_DB_USER_HOST}")
    if grep -q "GRANT.*ON.*${ROUNDCUBE_DB_NAME}.*TO.*${roundcube_db_user}.*@.*${ROUNDCUBE_DB_USER_HOST}.*" <<< "$msg";then
        __; green Granted.
    else
        __; red Not granted.; exit
    fi
    ____
fi

yellow Mengecek file '`'composer.json'`' untuk project '`'roundcube/roundcubemail'`'
notfound=
if [ -f /usr/local/share/roundcube/${roundcube_version}/composer.json ];then
    __ File '`'composer.json'`' ditemukan.
else
    __ File '`'composer.json'`' tidak ditemukan.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Mendownload RoundCube
    cd          /tmp
    wget        https://github.com/roundcube/roundcubemail/releases/download/${roundcube_version}/roundcubemail-${roundcube_version}-complete.tar.gz
    tar xfz     roundcubemail-${roundcube_version}-complete.tar.gz
    mkdir -p    /usr/local/share/roundcube/${roundcube_version}
    mv          roundcubemail-${roundcube_version}/* -t /usr/local/share/roundcube/${roundcube_version}/
    mv          roundcubemail-${roundcube_version}/.[!.]* -t /usr/local/share/roundcube/${roundcube_version}/
    rmdir       roundcubemail-${roundcube_version}
    chown -R $user_nginx:$user_nginx /usr/local/share/roundcube/${roundcube_version}
    if [ -f /usr/local/share/roundcube/${roundcube_version}/composer.json ];then
        __; green File '`'composer.json'`' ditemukan.
    else
        __; red File '`'composer.json'`' tidak ditemukan.; exit
    fi
    ____
fi

yellow Mengecek apakah RoundCube sudah imported SQL.
notfound=
msg=$(mysql \
    --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "${roundcube_db_user}" "${roundcube_db_user_password}") \
    --silent --skip-column-names \
    $ROUNDCUBE_DB_NAME -e "show tables;" | wc -l)
if [[ $msg -gt 0 ]];then
    __ RoundCube sudah imported SQL.
else
    __ RoundCube belum imported SQL.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow RoundCube Import SQL
    mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "${roundcube_db_user}" "${roundcube_db_user_password}") \
        $ROUNDCUBE_DB_NAME < /usr/local/share/roundcube/${roundcube_version}/SQL/mysql.initial.sql
    msg=$(mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "${roundcube_db_user}" "${roundcube_db_user_password}") \
        --silent --skip-column-names \
        $ROUNDCUBE_DB_NAME -e "show tables;" | wc -l)
    if [[ $msg -gt 0 ]];then
        __; green RoundCube sudah imported SQL.
    else
        __; red RoundCube belum imported SQL.; exit
    fi
    ____
fi

yellow Mengecek file konfigurasi RoundCube.
notfound=
if [ -f /usr/local/share/roundcube/${roundcube_version}/config/config.inc.php ];then
    __ File '`'config.inc.php'`' ditemukan.
else
    __ File '`'config.inc.php'`' tidak ditemukan.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Membuat file konfigurasi RoundCube.
    cp /usr/local/share/roundcube/${roundcube_version}/config/config.inc.php.sample \
        /usr/local/share/roundcube/${roundcube_version}/config/config.inc.php
    if [ -f /usr/local/share/roundcube/${roundcube_version}/config/config.inc.php ];then
        __; green File '`'config.inc.php'`' ditemukan.
        chown $user_nginx:$user_nginx /usr/local/share/roundcube/${roundcube_version}/config/config.inc.php
        chmod a-w /usr/local/share/roundcube/${roundcube_version}/config/config.inc.php
    else
        __; red File '`'config.inc.php'`' tidak ditemukan.; exit
    fi
    ____
fi

yellow Mengecek informasi file konfigurasi RoundCube.
php=$(cat <<'EOF'
$args = $_SERVER['argv'];
// var_dump($args);
$mode = $args[1];
$file = $args[2];
$arg_des_key = $args[3];
$arg_db_dsnw = $args[4];
$arg_misc_serial = $args[5];
$arg_misc = unserialize($args[5]);
$append = array();
include($file);
$is_different = false;
// var_dump($config);
// var_dump('+++');
$des_key = isset($config['des_key']) ? $config['des_key'] : NULL;
$db_dsnw = isset($config['db_dsnw']) ? $config['db_dsnw'] : NULL;
$misc = [
    'smtp_host' => isset($config['smtp_host']) ? $config['smtp_host'] : NULL,
    'smtp_user' => isset($config['smtp_user']) ? $config['smtp_user'] : NULL,
    'smtp_pass' => isset($config['smtp_pass']) ? $config['smtp_pass'] : NULL,
    'identities_level' => isset($config['identities_level']) ? $config['identities_level'] : NULL,
    'username_domain' => isset($config['username_domain']) ? $config['username_domain'] : NULL,
    'default_list_mode' => isset($config['default_list_mode']) ? $config['default_list_mode'] : NULL,
];
// var_dump('$misc');
// var_dump($misc);
// var_dump('$is_different');
// var_dump($is_different);
if ($arg_des_key != $des_key) {
    $append['des_key'] = $arg_des_key;
    $is_different = true;
}
// var_dump('$is_different');
// var_dump($is_different);
if ($arg_db_dsnw != $db_dsnw) {
    $append['db_dsnw'] = $arg_db_dsnw;
    $is_different = true;
}
// var_dump('$is_different');
// var_dump($is_different);
if ($arg_misc != $misc) {
    $append = array_replace_recursive($append, $arg_misc);
    $is_different = true;
}
// var_dump('$is_different');
// var_dump($is_different);
// var_dump('$arg_misc');
// var_dump($arg_misc);
// var_dump('$mode');
// var_dump($mode);
switch ($mode) {
    case 'is_different':
        $is_different ? exit(0) : exit(1);
        break;
    case 'save':
        if ($is_different) {
            $config = array_replace_recursive($config, $append);
            $content = '$config = '.var_export($config, true).';'.PHP_EOL;
            $content = <<< EOF
<?php
$content
EOF;
            file_put_contents($file, $content);
        }
        break;
}
EOF
)

serialize=$(php -r "echo serialize([
    'smtp_host' => 'localhost:25',
    'smtp_user' => '',
    'smtp_pass' => '',
    'identities_level' => '3',
    'username_domain' => '%t',
    'default_list_mode' => 'threads',
]);")
is_different=
if php -r "$php" is_different \
    /usr/local/share/roundcube/${roundcube_version}/config/config.inc.php \
    $roundcube_blowfish \
    "mysql://${roundcube_db_user}:${roundcube_db_user_password}@${ROUNDCUBE_DB_USER_HOST}/${ROUNDCUBE_DB_NAME}" \
    "$serialize";then
    is_different=1
    __ Diperlukan modifikasi file '`'config.inc.php'`'.
else
    __ File '`'config.inc.php'`' tidak ada perubahan.
fi
____

if [ -n "$is_different" ];then
    yellow Memodifikasi file '`'config.inc.php'`'.
    __ Backup file /usr/local/share/roundcube/${roundcube_version}/config/config.inc.php
    backupFile copy /usr/local/share/roundcube/${roundcube_version}/config/config.inc.php
    php -r "$php" save \
        /usr/local/share/roundcube/${roundcube_version}/config/config.inc.php \
        $roundcube_blowfish \
        "mysql://${roundcube_db_user}:${roundcube_db_user_password}@${ROUNDCUBE_DB_USER_HOST}/${ROUNDCUBE_DB_NAME}" \
        "$serialize"
    if php -r "$php" is_different \
        /usr/local/share/roundcube/${roundcube_version}/config/config.inc.php \
        $roundcube_blowfish \
        "mysql://${roundcube_db_user}:${roundcube_db_user_password}@${ROUNDCUBE_DB_USER_HOST}/${ROUNDCUBE_DB_NAME}" \
        "$serialize";then
        __; red Modifikasi file '`'config.inc.php'`' gagal.; exit
    else
        __; green Modifikasi file '`'config.inc.php'`' berhasil.
    fi
    ____
fi

yellow Mengecek nginx configuration apakah terdapat web root dari RoundCube
notfound=
root=/usr/local/share/roundcube/${roundcube_version}
string_quoted=$(pregQuote "$root")
file_config=$(grep -R -l -E "^\s*root\s+${string_quoted}\s*;" /etc/nginx/sites-enabled | head -1)
[ -n "$file_config" ] && {
    file_config=$(realpath $file_config)
    __ File config found: '`'$file_config'`'.;
} || {
    __ File config not found.;
    notfound=1
}
____

nginx_config_file=$ROUNDCUBE_NGINX_CONFIG_FILE
subdomain_localhost=$ROUNDCUBE_SUBDOMAIN_LOCALHOST
if [ -n "$notfound" ];then
    yellow Membuat nginx config.
    if [ -f /etc/nginx/sites-available/$nginx_config_file ];then
        __ Backup file /etc/nginx/sites-available/$nginx_config_file
        backupFile move /etc/nginx/sites-available/$nginx_config_file
    fi
    cat <<'EOF' > /etc/nginx/sites-available/$nginx_config_file
server {
    listen 80;
    listen [::]:80;
    root ROOT;
    index index.php;
    server_name SUBDOMAIN_LOCALHOST;
    location / {
        try_files $uri /index.php$is_args$args;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/phpPHP_VERSION-fpm.sock;
    }
}
EOF
    sed -i "s|ROOT|${root}|g" /etc/nginx/sites-available/$nginx_config_file
    sed -i "s|SUBDOMAIN_LOCALHOST|${subdomain_localhost}|g" /etc/nginx/sites-available/$nginx_config_file
    sed -i "s|PHP_VERSION|${PHP_VERSION}|g" /etc/nginx/sites-available/$nginx_config_file
    # @todo, ubah juga di drupal
    cd /etc/nginx/sites-enabled/
    ln -sf ../sites-available/$nginx_config_file
    if nginx -t 2> /dev/null;then
        nginx -s reload
    else
        red Terjadi kesalahan konfigurasi nginx. Gagal reload nginx.; exit
    fi
    file_config=$(grep -R -l -E "^\s*root\s+${string_quoted}\s*;" /etc/nginx/sites-enabled | head -1)
    [ -n "$file_config" ] && {
        file_config=$(realpath $file_config)
        __; green File config found: '`'$file_config'`'.;
    } || {
        __; red File config not found.; exit
    }
    ____
fi

yellow Mengecek subdomain '`'$subdomain_localhost'`'.
notfound=
string_quoted=$(pregQuote "$subdomain_localhost")
if grep -q -E "^\s*127\.0\.0\.1\s+${string_quoted}" /etc/hosts;then
    __ Subdomain terdapat pada local DNS resolver '`'/etc/hosts'`'.
else
    __ Subdomain tidak terdapat pada local DNS resolver '`'/etc/hosts'`'.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menambahkan subdomain '`'$subdomain_localhost'`'.
    echo "127.0.0.1"$'\t'"${subdomain_localhost}" >> /etc/hosts
    if grep -q -E "^\s*127\.0\.0\.1\s+${string_quoted}" /etc/hosts;then
        __; green Subdomain terdapat pada local DNS resolver '`'/etc/hosts'`'.
    else
        __; red Subdomain tidak terdapat pada local DNS resolver '`'/etc/hosts'`'.; exit
    fi
    ____
fi

yellow Mengecek HTTP Response Code.
if nginx -t 2> /dev/null;then
    magenta nginx -s reload
    nginx -s reload
else
    red Terjadi kesalahan konfigurasi nginx. Gagal reload nginx.; exit
fi
magenta curl http://127.0.0.1 -H '"'Host: ${subdomain_localhost}'"'
code=$(curl -L \
    -o /dev/null -s -w "%{http_code}\n" \
    http://127.0.0.1 -H "Host: ${subdomain_localhost}")
[ $code -eq 200 ] && {
    __ HTTP Response code '`'$code'`' '('Required')'.
} || {
    __; red Terjadi kesalahan. HTTP Response code '`'$code'`'.; exit
}
magenta curl http://${subdomain_localhost}
code=$(curl -L \
    -o /dev/null -s -w "%{http_code}\n" \
    http://127.0.0.1 -H "Host: ${subdomain_localhost}")
__ HTTP Response code '`'$code'`'.
____

blue ISPConfig
sleep .5
____

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
websiteCredentialIspconfig() {
    if [ -f /usr/local/share/ispconfig/credential/website ];then
        local ISPCONFIG_WEB_USER_PASSWORD
        . /usr/local/share/ispconfig/credential/website
        ispconfig_web_user_password=$ISPCONFIG_WEB_USER_PASSWORD
    else
        ispconfig_web_user_password=$(pwgen 6 -1vA0B)
        mkdir -p /usr/local/share/ispconfig/credential
        cat << EOF > /usr/local/share/ispconfig/credential/website
ISPCONFIG_WEB_USER_PASSWORD=$ispconfig_web_user_password
EOF
        chmod 0500 /usr/local/share/ispconfig/credential
        chmod 0400 /usr/local/share/ispconfig/credential/website
    fi
}

yellow Mengecek credentials ISPConfig.
databaseCredentialIspconfig
if [[ -z "$ispconfig_db_user_password" ]];then
    __; red Informasi credentials tidak lengkap: '`'/usr/local/share/ispconfig/credential/database'`'.; exit
else
    magenta ispconfig_db_user_password="$ispconfig_db_user_password"
fi
websiteCredentialIspconfig
if [[ -z "$ispconfig_web_user_password" ]];then
    __; red Informasi credentials tidak lengkap: '`'/usr/local/share/ispconfig/credential/website'`'.; exit
else
    magenta ispconfig_web_user_password="$ispconfig_web_user_password"
fi
____

php=$(cat <<'EOF'
$args = $_SERVER['argv'];
$mode = $args[1];
$file = $args[2];
$array = unserialize($args[3]);
$autoinstall = parse_ini_file($file);
if (!isset($autoinstall)) {
    exit(255);
}
$result = array_diff_assoc($array, $autoinstall);
$is_different = !empty(array_diff_assoc($array, $autoinstall));
switch ($mode) {
    case 'is_different':
        $is_different ? exit(0) : exit(1);
        break;
}
EOF
)

yellow Mengecek file '`'index.php'`' untuk '`'ISPConfig'`'.
notfound=
if [ -f /usr/local/ispconfig/interface/web/index.php ];then
    __ File '`'index.php'`' ditemukan.
else
    __ File '`'index.php'`' tidak ditemukan.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Mengecek apakah database ISPConfig siap digunakan.
    db_found=
    # Variable di populate oleh `databaseCredentialIspconfig()`.
    if [[ -n "$ispconfig_db_name" ]];then
        __ Mengecek database '`'$ispconfig_db_name'`'.
        msg=$(mysql --silent --skip-column-names -e "select schema_name from information_schema.schemata where schema_name = '$ispconfig_db_name'")
        if [[ $msg == $ispconfig_db_name ]];then
            __ Database ditemukan.
            db_found=1
        else
            __ Database tidak ditemukan
        fi
    fi
    if [[ -n "$db_found" ]];then
        msg=$(mysql \
            --silent --skip-column-names \
            $ispconfig_db_name -e "show tables;" | wc -l)
        if [[ $msg -gt 0 ]];then
            __; red Database sudah terdapat table sejumlah '`'$msg'`'.; x
        fi
    fi
    __ Database siap digunakan.
    ____

    yellow Menginstall ISPConfig
    if [ ! -f /tmp/ispconfig3_install/install/install.php ];then
        __ Mendownload ISPConfig
        if [ ! -f /tmp/ISPConfig-3-stable.tar.gz ];then
            wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
        fi
        cd /tmp
        __ Mengextract ISPConfig
        tar xfz ISPConfig-3-stable.tar.gz
    fi
    if [ ! -f /tmp/ispconfig3_install/install/autoinstall.ini ];then
        __ Membuat file '`'autoinstall.ini'`'.
        cp /tmp/ispconfig3_install/docs/autoinstall_samples/autoinstall.ini.sample \
           /tmp/ispconfig3_install/install/autoinstall.ini
    fi
    __ Verifikasi file '`'autoinstall.ini'`'.
    mysql_root_passwd="$(<$MYSQL_ROOT_PASSWD)"
    reference="$(php -r "echo serialize([
        'hostname' => '$FQDN',
        'mysql_root_password' => '$mysql_root_passwd',
        'http_server' => 'nginx',
        'ispconfig_use_ssl' => 'n',
        'mysql_ispconfig_password' => '$ispconfig_db_user_password',
        'ispconfig_admin_password' => '$ispconfig_web_user_password',
    ]);")"
    is_different=
    if php -r "$php" is_different \
        /tmp/ispconfig3_install/install/autoinstall.ini \
        "$reference";then
        is_different=1
        __ Diperlukan modifikasi file '`'autoinstall.ini'`'.
    else
        if [ $? -eq 255 ];then
            __; red Terjadi kesalahan dalam parsing file '`'autoinstall.ini'`'.; x
        fi
        __ File '`'autoinstall.ini'`' tidak ada perubahan.
    fi
    if [ -n "$is_different" ];then
        __ Memodifikasi file '`'autoinstall.ini'`'.
        __ Backup file /tmp/ispconfig3_install/install/autoinstall.ini
        backupFile copy /tmp/ispconfig3_install/install/autoinstall.ini
        VarDump mysql_root_passwd
        sed -e "s,^hostname=.*$,hostname=${FQDN}," \
            -e "s,^mysql_root_password=.*$,mysql_root_password=${mysql_root_passwd}," \
            -e "s,^http_server=.*$,http_server=nginx," \
            -e "s,^ispconfig_use_ssl=.*$,ispconfig_use_ssl=n," \
            -e "s,^ispconfig_admin_password=.*$,ispconfig_admin_password=${ispconfig_web_user_password}," \
            -e "s,^mysql_ispconfig_password=.*$,mysql_ispconfig_password=${ispconfig_db_user_password}," \
            -i /tmp/ispconfig3_install/install//autoinstall.ini
        if php -r "$php" is_different \
            /tmp/ispconfig3_install/install/autoinstall.ini \
            "$reference";then
            __; red Modifikasi file '`'autoinstall.ini'`' gagal.; exit
        else
            __; green Modifikasi file '`'autoinstall.ini'`' berhasil.
        fi
    fi

    __ Memasang password MySQL untuk root
    ToggleMysqlRootPassword yes

    __ Mulai autoinstall.
    php /tmp/ispconfig3_install/install/install.php \
         --autoinstall=/tmp/ispconfig3_install/install/autoinstall.ini

    __ Mengecek file '`'index.php'`' untuk '`'ISPConfig'`'.
    if [ -f /usr/local/ispconfig/interface/web/index.php ];then
        __; green File '`'index.php'`' ditemukan.
    else
        __; red File '`'index.php'`' tidak ditemukan.; x
    fi

    __ Mencopot password MySQL untuk root
    ToggleMysqlRootPassword no

    __ Menyimpan informasi database.
    ISPCONFIG_DB_USER=$(php -r "include '/usr/local/ispconfig/interface/lib/config.inc.php';echo DB_USER;")
    ISPCONFIG_DB_NAME=$(php -r "include '/usr/local/ispconfig/interface/lib/config.inc.php'; echo DB_DATABASE;")
    databaseCredentialIspconfig
    if [[ -z "$ispconfig_db_name" ]];then
            cat << EOF >> /usr/local/share/ispconfig/credential/database
ISPCONFIG_DB_NAME=$ISPCONFIG_DB_NAME
EOF
    fi
    if [[ -z "$ispconfig_db_user" ]];then
            cat << EOF >> /usr/local/share/ispconfig/credential/database
ISPCONFIG_DB_USER=$ISPCONFIG_DB_USER
EOF
    fi
    ____

    __ Mengubah kepemelikan directory '`'ISPConfig'`'.
    magenta chown -R $user_nginx:$user_nginx /usr/local/ispconfig
    chown -R $user_nginx:$user_nginx /usr/local/ispconfig

fi

yellow Mengecek credentials ISPConfig.
databaseCredentialIspconfig
if [[ -z "$ispconfig_db_name" || -z "$ispconfig_db_user" ]];then
    __; red Informasi credentials tidak lengkap: '`'/usr/local/share/ispconfig/credential/database'`'.; exit
else
    magenta ispconfig_db_name="$ispconfig_db_name"
    magenta ispconfig_db_user="$ispconfig_db_user"
fi
____

yellow Mengecek nginx configuration apakah terdapat web root dari ISPConfig
notfound=
root=/usr/local/ispconfig/interface/web
string_quoted=$(pregQuote "$root")
file_config=$(grep -R -l -E "^\s*root\s+${string_quoted}\s*;" /etc/nginx/sites-enabled | head -1)
[ -n "$file_config" ] && {
    file_config=$(realpath $file_config)
    __ File config found: '`'$file_config'`'.;
} || {
    __ File config not found.;
    notfound=1
}
____

nginx_config_file=$ISPCONFIG_NGINX_CONFIG_FILE
subdomain_localhost=$ISPCONFIG_SUBDOMAIN_LOCALHOST

if [ -n "$notfound" ];then
    yellow Membuat nginx config.
    if [ -f /etc/nginx/sites-available/$nginx_config_file ];then
        __ Backup file /etc/nginx/sites-available/$nginx_config_file
        backupFile move /etc/nginx/sites-available/$nginx_config_file
    fi
    cat <<'EOF' > /etc/nginx/sites-available/$nginx_config_file
server {
    listen 80;
    listen [::]:80;
    root ROOT;
    index index.php;
    server_name SUBDOMAIN_LOCALHOST;
    location / {
        try_files $uri $uri/ =404;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/phpPHP_VERSION-fpm.sock;
    }
}
EOF
    sed -i "s|ROOT|${root}|g" /etc/nginx/sites-available/$nginx_config_file
    sed -i "s|SUBDOMAIN_LOCALHOST|${subdomain_localhost}|g" /etc/nginx/sites-available/$nginx_config_file
    sed -i "s|PHP_VERSION|${PHP_VERSION}|g" /etc/nginx/sites-available/$nginx_config_file
    # @todo, ubah juga di drupal
    cd /etc/nginx/sites-enabled/
    ln -sf ../sites-available/$nginx_config_file
    if nginx -t 2> /dev/null;then
        nginx -s reload
    else
        red Terjadi kesalahan konfigurasi nginx. Gagal reload nginx.; exit
    fi
    file_config=$(grep -R -l -E "^\s*root\s+${string_quoted}\s*;" /etc/nginx/sites-enabled | head -1)
    [ -n "$file_config" ] && {
        file_config=$(realpath $file_config)
        __; green File config found: '`'$file_config'`'.;
    } || {
        __; red File config not found.; exit
    }
    ____
fi

yellow Mengecek subdomain '`'$subdomain_localhost'`'.
notfound=
string_quoted=$(pregQuote "$subdomain_localhost")
if grep -q -E "^\s*127\.0\.0\.1\s+${string_quoted}" /etc/hosts;then
    __ Subdomain terdapat pada local DNS resolver '`'/etc/hosts'`'.
else
    __ Subdomain tidak terdapat pada local DNS resolver '`'/etc/hosts'`'.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menambahkan subdomain '`'$subdomain_localhost'`'.
    echo "127.0.0.1"$'\t'"${subdomain_localhost}" >> /etc/hosts
    if grep -q -E "^\s*127\.0\.0\.1\s+${string_quoted}" /etc/hosts;then
        __; green Subdomain terdapat pada local DNS resolver '`'/etc/hosts'`'.
    else
        __; red Subdomain tidak terdapat pada local DNS resolver '`'/etc/hosts'`'.; exit
    fi
    ____
fi

yellow Mengecek HTTP Response Code.
if nginx -t 2> /dev/null;then
    magenta nginx -s reload
    nginx -s reload
else
    red Terjadi kesalahan konfigurasi nginx. Gagal reload nginx.; exit
fi
magenta curl -L http://127.0.0.1/ -H '"'Host: ${subdomain_localhost}'"'
code=$(curl -L \
    -o /dev/null -s -w "%{http_code}\n" \
    http://127.0.0.1/ -H "Host: ${subdomain_localhost}")
[ $code -eq 200 ] && {
    __ HTTP Response code '`'$code'`' '('Required')'.
} || {
    __; red Terjadi kesalahan. HTTP Response code '`'$code'`'.; exit
}
magenta curl http://${subdomain_localhost}/
code=$(curl -L \
    -o /dev/null -s -w "%{http_code}\n" \
    http://127.0.0.1/ -H "Host: ${subdomain_localhost}")
__ HTTP Response code '`'$code'`'.
____

yellow Dump variable from shell.
ispconfig_db_user_host="$ISPCONFIG_DB_USER_HOST"
magenta ispconfig_db_user="$ispconfig_db_user"
magenta ispconfig_db_user_host="$ispconfig_db_user_host"
magenta ispconfig_db_user_password="$ispconfig_db_user_password"
magenta ispconfig_db_name="$ispconfig_db_name"
_ispconfig_db_user=$(php -r "include '$ISPCONFIG_INSTALL_DIR/interface/lib/config.inc.php';echo DB_USER;")
_ispconfig_db_user_password=$(php -r "include '$ISPCONFIG_INSTALL_DIR/interface/lib/config.inc.php';echo DB_PASSWORD;")
_ispconfig_db_user_host=$(php -r "include '$ISPCONFIG_INSTALL_DIR/interface/lib/config.inc.php';echo DB_HOST;")
_ispconfig_db_name=$(php -r "include '$ISPCONFIG_INSTALL_DIR/interface/lib/config.inc.php';echo DB_DATABASE;")
has_different=
for string in ispconfig_db_name ispconfig_db_user ispconfig_db_user_host ispconfig_db_user_password
do
    parameter=$string
    parameter_from_shell=${!string}
    string="_${string}"
    parameter_from_php=${!string}
    if [[ ! "$parameter_from_shell" == "$parameter_from_php" ]];then
        __ Different from PHP Scripts found.
        __; echo -n Value of '`'"$parameter"'`' from shell:' '
        echo "$parameter_from_shell"
        __; echo -n Value of '`'"$parameter"'`' from PHP script:' '
        echo "$parameter_from_php"
        has_different=1
    fi
done
if [ -n "$has_different" ];then
    __; red Terdapat perbedaan value.;exit
fi
____

yellow Populate variable.

phpmyadmin_install_dir=/usr/local/share/phpmyadmin/"$phpmyadmin_version"
roundcube_install_dir=/usr/local/share/roundcube/"$roundcube_version"
scripts_dir=/usr/local/share/ispconfig/scripts
magenta phpmyadmin_install_dir="$phpmyadmin_install_dir"
magenta roundcube_install_dir="$roundcube_install_dir"
magenta scripts_dir="$scripts_dir"
____

yellow Mengecek ISPConfig PHP scripts.
isFileExists /usr/local/share/ispconfig/scripts/soap_config.php
____

if [ -n "$notfound" ];then
    yellow Copy ISPConfig PHP scripts.
    mkdir -p /usr/local/share/ispconfig/scripts
    cp -f /tmp/ispconfig3_install/remoting_client/examples/* /usr/local/share/ispconfig/scripts
    fileMustExists /usr/local/share/ispconfig/scripts/soap_config.php
    __ Memodifikasi scripts.
    cd /usr/local/share/ispconfig/scripts
    find * -maxdepth 1 -type f \
    -not -path 'soap_config.php' \
    -not -path 'rest_example.php' \
    -not -path 'ispc-import-csv-email.php' | while read line; do
    sed -i -e 's,^?>$,echo PHP_EOL;,' \
           -e "s,'<br />',PHP_EOL," \
           -e 's,"<br>",PHP_EOL,' \
           -e "s,<br />','.PHP_EOL," \
           -e "s,die('SOAP Error: '.\$e->getMessage());,die('SOAP Error: '.\$e->getMessage().PHP_EOL);," \
           -e "s,\$client_id = 1;,\$client_id = 0;," \
    ${line}
    done
    ____
fi

yellow Mengecek '`'ispconfig.sh'`' command.
isFileExists /usr/local/share/ispconfig/bin/ispconfig.sh
if command -v "ispconfig.sh" >/dev/null;then
    __ Command found.
else
    __ Command not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Create ISPConfig Command '`'ispconfig.sh'`'.
    mkdir -p /usr/local/share/ispconfig/bin
    cat << 'EOF' > /usr/local/share/ispconfig/bin/ispconfig.sh
#!/bin/bash
s=|scripts_dir|
Usage() {
    echo -e "Usage: ispconfig.sh \e[33m<command>\e[0m [<args>]" >&2
    echo >&2
    echo "Available commands: " >&2
    echo -e '   \e[33mls\e[0m       \e[35m[<prefix>]\e[0m   List PHP Script. Filter by prefix.' >&2
    echo -e '   \e[33mmktemp\e[0m   \e[35m<script>\e[0m     Create a temporary file based on Script.' >&2
    echo -e '   \e[33meditor\e[0m   \e[35m<script>\e[0m     Edit PHP Script.' >&2
    echo -e '   \e[33mphp\e[0m      \e[35m<script>\e[0m     Execute PHP Script.' >&2
    echo -e '   \e[33mcat\e[0m      \e[35m<script>\e[0m     Get the contents of PHP Script.' >&2
    echo -e '   \e[33mrealpath\e[0m \e[35m<script>\e[0m     Return the real path of PHP Script.' >&2
    echo -e '   \e[33mexport\e[0m                Export some variables.' >&2
    echo >&2
    echo -e 'Command for switch editor: \e[35mupdate-alternatives --config editor\e[0m' >&2
}
if [ -z "$1" ];then
    Usage
    exit
fi
case "$1" in
    -h|--help)
        Usage
        exit
        ;;
    ls)
        if [ -z "$2" ];then
            ls "$s"
        else
            cd "$s"
            ls "$2"*
        fi
        ;;
    mktemp)
        if [ -f "$s/$2" ];then
            filename="${2%.*}"
            temp=$(mktemp -p "$s" \
                -t "$filename"_temp_XXXXX.php)
            cd "$s"
            cp "$2" "$temp"
            echo $(basename $temp)
        fi
        ;;
    editor)
        if [ -f "$s/$2" ];then
            editor "$s/$2"
        fi
        ;;
    php)
        if [ -f "$s/$2" ];then
            php "$s/$2"
        fi
        ;;
    cat)
        if [ -f "$s/$2" ];then
            cat "$s/$2"
        fi
        ;;
    realpath)
        if [ -f "$s/$2" ];then
            echo "$s/$2"
        fi
        ;;
    export)
        echo phpmyadmin_install_dir=|phpmyadmin_install_dir|
        echo roundcube_install_dir=|roundcube_install_dir|
        echo ispconfig_install_dir=|ispconfig_install_dir|
        echo scripts_dir=|scripts_dir|
        phpmyadmin_install_dir=|phpmyadmin_install_dir|
        roundcube_install_dir=|roundcube_install_dir|
        ispconfig_install_dir=|ispconfig_install_dir|
        scripts_dir=|scripts_dir|
esac
EOF
    chmod a+x /usr/local/share/ispconfig/bin/ispconfig.sh
    sed -i 's,|phpmyadmin_install_dir|,'"${phpmyadmin_install_dir}"',' /usr/local/share/ispconfig/bin/ispconfig.sh
    sed -i 's,|roundcube_install_dir|,'"${roundcube_install_dir}"',' /usr/local/share/ispconfig/bin/ispconfig.sh
    sed -i 's,|ispconfig_install_dir|,'"${ISPCONFIG_INSTALL_DIR}"',' /usr/local/share/ispconfig/bin/ispconfig.sh
    sed -i 's,|scripts_dir|,'"${scripts_dir}"',' /usr/local/share/ispconfig/bin/ispconfig.sh
    ln -sf /usr/local/share/ispconfig/bin/ispconfig.sh /usr/local/bin/ispconfig.sh
    if command -v "ispconfig.sh" >/dev/null;then
        __; green Command found.
    else
        __; red Command not found.; x
    fi
    ____
fi

yellow Mengecek '`'ispconfig.sh'`' autocompletion.
isFileExists /etc/profile.d/ispconfig-completion.sh
____

if [ -n "$notfound" ];then
    yellow Create ISPConfig Command '`'ispconfig.sh'`' Autocompletion.
    cat << 'EOF' > /etc/profile.d/ispconfig-completion.sh
#!/bin/bash
_ispconfig_sh() {
    local scripts_dir=|scripts_dir|
    local cur
    cur=${COMP_WORDS[COMP_CWORD]}
    prev=${COMP_WORDS[COMP_CWORD-1]}
    case ${COMP_CWORD} in
        1)
            COMPREPLY=($(compgen -W "ls php editor mktemp cat realpath export" -- ${cur}))
            ;;
        2)
            if [[ "${prev}" == 'export' ]];then
                COMPREPLY=()
            elif [ -z ${cur} ];then
                COMPREPLY=($(ls "$scripts_dir" | awk -F '_' '!x[$1]++{print $1}'))
            else
                words_merge=$(ls "$scripts_dir" | xargs)
                COMPREPLY=($(compgen -W "$words_merge" -- ${cur}))
            fi
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}
complete -F _ispconfig_sh ispconfig.sh
EOF
    chmod a+x /etc/profile.d/ispconfig-completion.sh
    sed -i 's,|scripts_dir|,'"${scripts_dir}"',' /etc/profile.d/ispconfig-completion.sh
    fileMustExists /etc/profile.d/ispconfig-completion.sh
    ____
fi

yellow -- FINISH ------------------------------------------------------------
____
