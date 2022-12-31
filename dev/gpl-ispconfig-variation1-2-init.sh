#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

blue Setup Server
____

yellow Mengecek akses root.
if [[ "$EUID" -ne 0 ]]; then
	red This script needs to be run with superuser privileges.; exit
else
    __ Privileges.
fi
____

yellow Mengecek '$PATH'
magenta PATH="$PATH"
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
      __; magenta PATH="$PATH"
    else
      __; red '$PATH' belum lengkap.; x
    fi
fi
____

yellow Mengecek shell default
is_dash=
if [[ $(realpath /bin/sh) =~ dash$ ]];then
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
    if [[ $(realpath /bin/sh) =~ dash$ ]];then
        __; red '`'sh'`' command link to dash.;
    else
        __; green '`'sh'`' command link to $(realpath /bin/sh).
        is_dash=
    fi
    ____
fi

if [[ -n "$is_dash" ]];then
    yellow Disable dash again.
    __ '`sh` command link to dash. Override now.'
    path=$(command -v sh)
    cd $(dirname $path)
    ln -sf bash sh
    if [[ $(realpath /bin/sh) =~ dash$ ]];then
        __; red '`'sh'`' command link to dash.; x
    else
        __; green '`'sh'`' command link to $(realpath /bin/sh).
    fi
    ____
fi

exit

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

. /etc/os-release

case $ID in
    debian)
        case "$VERSION_ID" in
            11)
                repository_required=$(cat <<EOF
deb http://deb.debian.org/debian/ bullseye main
deb-src http://deb.debian.org/debian/ bullseye main
deb http://security.debian.org/debian-security bullseye-security main
deb-src http://security.debian.org/debian-security bullseye-security main
deb http://deb.debian.org/debian/ bullseye-updates main
deb-src http://deb.debian.org/debian/ bullseye-updates main
EOF
)
            ;;
        esac
        ;;
    ubuntu)
        case "$VERSION_ID" in
            22.04)
                repository_required=$(cat <<EOF
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
deb http://archive.canonical.com/ubuntu/ jammy partner
EOF
)
            ;;
            22.10)
                repository_required=$(cat <<EOF
deb http://archive.ubuntu.com/ubuntu/ kinetic main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ kinetic-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ kinetic-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ kinetic-backports main restricted universe multiverse
deb http://archive.canonical.com/ubuntu/ kinetic partner
EOF
)
            ;;
            *) red OS "$ID" version "$VERSION_ID" not supported; exit;
        esac
        ;;
    *) red OS "$ID" not supported; exit;
esac

yellow Update Repository
while IFS= read -r string; do
    if [[ -n $(grep "# $string" /etc/apt/sources.list) ]];then
        sed -i 's,^# '"$string"','"$string"',' /etc/apt/sources.list
        update_now=1
    elif [[ -z $(grep "$string" /etc/apt/sources.list) ]];then
        CONTENT+="$string"$'\n'
        update_now=1
    fi
done <<< "$repository_required"

[ -z "$CONTENT" ] || {
    CONTENT=$'\n'"# Customize. ${NOW}"$'\n'"$CONTENT"
    echo "$CONTENT" >> /etc/apt/sources.list
}
if [[ $update_now == 1 ]];then
    magenta apt -y update
    magenta apt -y upgrade
    # https://fabianlee.org/2017/01/16/ubuntu-silent-package-installation-and-debconf/
    export DEBIAN_FRONTEND=noninteractive
    apt -y update
    apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y upgrade
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

. /etc/os-release

case $ID in
    debian)
        case "$VERSION_ID" in
            11)
                application=
                application+=' lsb-release apt-transport-https ca-certificates'
                application+=' sudo patch curl wget net-tools apache2-utils openssl rkhunter'
                application+=' binutils dnsutils pwgen daemon apt-listchanges lrzip p7zip'
                application+=' p7zip-full zip unzip bzip2 lzop arj nomarch cabextract'
                application+=' libnet-ident-perl libnet-dns-perl libauthen-sasl-perl'
                application+=' libdbd-mysql-perl libio-string-perl libio-socket-ssl-perl'
            ;;
        esac
        ;;
    ubuntu)
        case "$VERSION_ID" in
            22.04|22.10)
                application=
                application+=' lsb-release apt-transport-https ca-certificates'
                application+=' sudo patch curl wget net-tools apache2-utils openssl rkhunter'
                application+=' binutils dnsutils pwgen daemon apt-listchanges lrzip p7zip'
                application+=' p7zip-full zip unzip bzip2 lzop arj nomarch cabextract'
                application+=' libnet-ident-perl libnet-dns-perl libauthen-sasl-perl'
                application+=' libdbd-mysql-perl libio-string-perl libio-socket-ssl-perl'
            ;;
            *) red OS "$ID" version "$VERSION_ID" not supported; exit;
        esac
        ;;
    *) red OS "$ID" not supported; exit;
esac

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

# Credit:
# https://launchpad.net/~ondrej/+archive/ubuntu/php
addRepositoryPpaOndrejPhp() {
    local notfound=
    yellow Mengecek source PPA ondrej/php
    cd /etc/apt/sources.list.d
    if grep --no-filename -R -E "/ondrej/php/" | grep -q -v -E '^\s*#';then
        __ Sudah terdapat di direktori '`'/etc/apt/sources.list.d'`'.
    else
        notfound=1
        __ Tidak terdapat di direktori '`'/etc/apt/sources.list.d'`'.
    fi
    if [ -n "$notfound" ];then
        yellow Menambahkan source PPA ondrej/php
        magenta add-apt-repository ppa:ondrej/php -y
        magenta apt update -y
        add-apt-repository ppa:ondrej/php -y
        apt update -y
        # deb http://ppa.launchpad.net/ondrej/php/ubuntu focal main
        # deb https://ppa.launchpadcontent.net/ondrej/php/ubuntu/ jammy main
        if grep --no-filename -R -E "/ondrej/php/" | grep -q -v -E '^\s*#';then
            __; green Sudah terdapat di direktori '`'/etc/apt/sources.list.d'`'.
        else
            __; red Tidak terdapat di direktori '`'/etc/apt/sources.list.d'`'.;  exit
        fi
    fi
}

installPhp() {
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
                22.04|22.10)
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

yellow Mengecek apakah PHP version "$PHP_VERSION" installed.
notfound=
string="php${PHP_VERSION}"
string_quoted=$(pregQuote "$string")
if grep -q "^${string_quoted}/" <<< "$aptinstalled";then
    __ PHP "$PHP_VERSION" installed.
else
    __ PHP "$PHP_VERSION" not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menginstall PHP "$PHP_VERSION"
    installPhp "$PHP_VERSION"
    aptinstalled=$(apt --installed list 2>/dev/null)
    if grep -q "^${string_quoted}/" <<< "$aptinstalled";then
        __; green PHP "$PHP_VERSION" installed.
    else
        __; red PHP "$PHP_VERSION" not found.; exit
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

downloadApplication php"$PHP_VERSION"-{common,gd,mysql,imap,cli,fpm,curl,intl,pspell,sqlite3,tidy,xmlrpc,xsl,zip,mbstring,soap,opcache}
validateApplication php"$PHP_VERSION"-{common,gd,mysql,imap,cli,fpm,curl,intl,pspell,sqlite3,tidy,xmlrpc,xsl,zip,mbstring,soap,opcache}
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
    yellow Menginstall Postfix
    debconf-set-selections <<< "postfix postfix/mailname string ${fqdn}"
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

# @todo, beritahu user kalo script ini hanya berlaku
# jika ISP membuka port 25 outgoing
application=
application+=' postfix-mysql postfix-doc'
application+=' dovecot-core dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve dovecot-lmtpd'
application+=' getmail6 amavisd-new postgrey spamassassin'
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

yellow Membatasi akses ke localhost.
if [ -L /etc/nginx/sites-enabled/default ];then
    __ Menghapus symlink /etc/nginx/sites-enabled/default
    rm /etc/nginx/sites-enabled/default
fi
if [ -f /etc/nginx/sites-available/default ];then
    __ Backup file /etc/nginx/sites-available/default
    backupFile move /etc/nginx/sites-available/default
    cat <<'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html;
    server_name _;
    location / {
        deny all;
    }
}
EOF
    cd /etc/nginx/sites-enabled/
    ln -sf ../sites-available/default
    if nginx -t 2> /dev/null;then
        nginx -s reload
        sleep 1
    else
        red Terjadi kesalahan konfigurasi nginx. Gagal reload nginx.; exit
    fi
fi
magenta curl http://127.0.0.1
code=$(curl -L \
    -o /dev/null -s -w "%{http_code}\n" \
    http://127.0.0.1)
[ $code -eq 403 ] && {
    __ HTTP Response code '`'$code'`' '('Required')'.
} || {
    __; red Terjadi kesalahan. HTTP Response code '`'$code'`'.; exit
}
____
