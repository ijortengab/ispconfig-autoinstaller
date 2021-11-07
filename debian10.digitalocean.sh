# !/bin/bash
# http://ijortengab.id
# https://github.com/ijortengab/ispconfig-autoinstaller

# Required Value.
DOMAIN="$1"
DIGITALOCEAN_TOKEN="$2"
IP_PUBLIC="$3"

# Optional Value.
SUBDOMAIN_FQCDN=server
TIMEZONE='Asia/Jakarta'
VERSION_ROUNDCUBE='1.4.11'
VERSION_PHPMYADMIN='5.1.1'
SUBDOMAIN_PHPMYADMIN=db
SUBDOMAIN_ROUNDCUBE=mail
SUBDOMAIN_ISPCONFIG=cp
REMOTE_USER_ROUNDCUBE=roundcube
REMOTE_USER_ROOT=root
DEBIAN_CONF='debian100.conf.php'
DKIM_SELECTOR=default
EMAIL_ADMIN=admin
EMAIL_HOST=hostmaster
EMAIL_WEB=webmaster
EMAIL_POST=postmaster

# Validate Required Value.
until [[ ! -z "$DOMAIN" ]]; do
    read -p "Domain: " DOMAIN
done
until [[ ! -z "$DIGITALOCEAN_TOKEN" ]]; do
    read -p "DigitalOcean Token API: " DIGITALOCEAN_TOKEN
done
until [[ ! -z "$IP_PUBLIC" ]]; do
    IP_PUBLIC=$(wget -T 3 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/")
    echo IP Address Public is "'"$IP_PUBLIC"'".
done

# Additional Value.
FQCDN="${SUBDOMAIN_FQCDN}.${DOMAIN}"
FQCDN_PHPMYADMIN="${SUBDOMAIN_PHPMYADMIN}.${DOMAIN}"
FQCDN_ROUNDCUBE="${SUBDOMAIN_ROUNDCUBE}.${DOMAIN}"
FQCDN_ISPCONFIG="${SUBDOMAIN_ISPCONFIG}.${DOMAIN}"
FQCDN_MX="$FQCDN"

# Validate Variables.
if [[ -z $(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$'  <<< $IP_PUBLIC ) ]];then
    echo IP Address Invalid: "'""$IP_PUBLIC""'".
    echo -e '\033[0;31m'Script terminated.'\033[0m'
    exit 1
fi

if [[ ! $(hostname -f) == $FQCDN ]];then
    echo
    echo -e '\033[0;33m'Attention'\033[0m':
    echo '   'Your current hostname is different with your request.
    echo '   hostname -f    #' $(hostname -f)
    echo '   'echo \$FQCDN'    #' $FQCDN
    echo
    echo -e '\033[0;31m'Script terminated.'\033[0m'
    echo
    echo -e '\033[0;32m'Suggestion'\033[0m':
    echo '   'Execute command below then reboot server.
    echo
    if [[ ! $(hostname) == $SUBDOMAIN_FQCDN ]];then
        echo echo $SUBDOMAIN_FQCDN' > /etc/hostname'
    fi
    _fqcdn=$(hostname -f | sed 's/\./\\./g')
    _hostname=$(hostname)
    echo sed -i -E \\
    echo \"s/^\\s*'(.*)'$_fqcdn\\s+$_hostname/$IP_PUBLIC $FQCDN $SUBDOMAIN_FQCDN/\" \\
    echo /etc/hosts
    echo
    exit
fi

echo -n $'\n''########################################'
echo         '########################################'
echo $'\n''#' CHAPTER 1. SETUP SERVER
echo -n $'\n''########################################'
echo         '########################################'

echo $'\n''#' Disable dash
if [[ $(realpath /bin/sh) == '/usr/bin/dash' ]];then
    echo '`sh` command link to dash. Disable now.'
    echo "dash dash/sh boolean false" | debconf-set-selections
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
else
    echo '`sh` command link to '$(realpath /bin/sh)
fi

echo $'\n''#' Set Timezone
if [[ ! $(timedatectl status | grep 'Time zone:' | grep -o "$TIMEZONE") == "$TIMEZONE" ]];then
    echo 'Timezone is not '"$TIMEZONE". Adjust now.
    timedatectl set-timezone "$TIMEZONE"
else
    timedatectl status | grep 'Time zone:' | grep -o "$TIMEZONE"
fi

echo $'\n''#' Update Repository
sed -i 's/^deb/# deb/g' /etc/apt/sources.list
echo >> /etc/apt/sources.list
NOW=$(date +%Y%m%d-%H%M%S)
echo "# Customize. ${NOW}" >> /etc/apt/sources.list
CONTENT=$(cat <<- 'EOF'
deb http://deb.debian.org/debian/ buster main contrib non-free
deb http://security.debian.org/debian-security buster/updates main contrib non-free
deb http://deb.debian.org/debian/ buster-updates main
deb-src http://deb.debian.org/debian/ buster main contrib non-free
deb-src http://deb.debian.org/debian/ buster-updates main
deb-src http://security.debian.org/debian-security buster/updates main contrib non-free
EOF
)
echo "$CONTENT" >> /etc/apt/sources.list
apt update
apt -y upgrade

echo $'\n''#' Install Basic Apps
apt -y install \
    lsb-release apt-transport-https ca-certificates \
    sudo patch curl net-tools apache2-utils openssl rkhunter \
    binutils dnsutils pwgen daemon apt-listchanges\
    lrzip p7zip p7zip-full unrar zip unzip bzip2 lzop arj nomarch cabextract\
    libnet-ldap-perl libnet-ident-perl libnet-dns-perl libdbd-mysql-perl \
    libauthen-sasl-perl libio-string-perl libio-socket-ssl-perl

echo $'\n''#' Disable Sendmail '(if any)'
service sendmail stop; update-rc.d -f sendmail remove

echo $'\n''#' Install Snapd and Certbot
apt -y install snapd
sudo snap install core; sudo snap refresh core
export PATH=$PATH:/snap/bin
snap install --classic certbot
snap set certbot trust-plugin-with-root=ok
snap install certbot-dns-digitalocean

echo $'\n''#' Save DigitalOcean Token as File
touch      ~/digitalocean-token-ispconfig.ini
chmod 0700 ~/digitalocean-token-ispconfig.ini
CONTENT=$(cat <<- EOF
dns_digitalocean_token = $DIGITALOCEAN_TOKEN
EOF
)
echo "$CONTENT" > ~/digitalocean-token-ispconfig.ini

echo $'\n''#' Update Repository for PHP 7.4
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
apt update

echo $'\n''#' Search PHP 7.4 in Cache
if [ $(apt-cache search php7.4 | wc -l ) == 0 ];then
    echo PHP-7.4 not found.
    echo -e '\033[0;31m'Script terminated.'\033[0m'
    exit 1
fi

echo $'\n''#' Disable Apache '(if any)'
systemctl stop apache2
systemctl disable apache2
apt-get remove apache2

echo $'\n''#' Modify Domain DNS Record
_code=$(curl -X GET \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    -o /dev/null -s -w "%{http_code}\n" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN")
case $_code in
    200)
        echo Domain "'""$DOMAIN""'" found in DNS Digital Ocean.
        ;;
    404)
        echo Domain "'""$DOMAIN""'" NOT found in DNS Digital Ocean.
        echo -n  Trying to create...
        _code_2=$(curl -X POST \
            -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
            -H "Content-Type: application/json" \
            -o /dev/null -s -w "%{http_code}\n" \
            -d '{"name":"'""$DOMAIN""'","ip_address":"'"$IP_PUBLIC"'"}' \
            "https://api.digitalocean.com/v2/domains")
        case $_code_2 in
            201)
                echo ' 'Created.
                ;;
            *)
                echo ' 'Failed.
                echo Unexpected result with response code: $_code.
                echo -e '\033[0;31m'Script terminated.'\033[0m'
                exit 1
        esac
        ;;
    *)
        echo Domain "'""$DOMAIN""'" failed to query in DNS Digital Ocean.
        echo Unexpected result with response code: $_code.
        echo -e '\033[0;31m'Script terminated.'\033[0m'
        exit 1
esac

echo $'\n''#' Modify FQCDN DNS Record
_total=$(curl -X GET \
    -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN/records?type=A&name=$FQCDN" | \
    grep -o '"meta":{"total":.*}}' | \
    sed -E 's/"meta":\{"total":(.*)\}\}/\1/')
if [ $_total -gt 0 ];then
    echo DNS A Record of FQCDN "'"${FQCDN}"'" found in DNS Digital Ocean.
else
    echo DNS A Record of FQCDN "'"${FQCDN}"'" NOT found in DNS Digital Ocean.
    echo -n  Trying to create...
    _code=$(curl -X POST \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -o /dev/null -s -w "%{http_code}\n" \
        -d '{"type":"A","name":"'"$SUBDOMAIN_FQCDN"'","data":"'"$IP_PUBLIC"'","priority":null,"port":null,"ttl":1800,"weight":null,"flags":null,"tag":null}' \
        "https://api.digitalocean.com/v2/domains/$DOMAIN/records")
    case $_code in
        201)
            echo ' 'Created.
            ;;
        *)
            echo ' 'Failed.
            echo Unexpected result with response code: $_code.
            echo -e '\033[0;31m'Script terminated.'\033[0m'
            exit 1
    esac
fi

echo $'\n''#' Modify CNAME DNS Record for PHPMyAdmin
_total=$(curl -X GET \
    -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN/records?type=CNAME&name=$FQCDN_PHPMYADMIN" | \
    grep -o '"meta":{"total":.*}}' | \
    sed -E 's/"meta":\{"total":(.*)\}\}/\1/')
if [ $_total -gt 0 ];then
    echo DNS CNAME Record of FQCDN "'"${FQCDN_PHPMYADMIN}"'" found in DNS Digital Ocean.
else
    echo DNS CNAME Record of FQCDN "'"${FQCDN_PHPMYADMIN}"'" NOT found in DNS Digital Ocean.
    echo -n  Trying to create...
    _code=$(curl -X POST \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -o /dev/null -s -w "%{http_code}\n" \
        -d '{"type":"CNAME","name":"'"$SUBDOMAIN_PHPMYADMIN"'","data":"@","priority":null,"port":null,"ttl":1800,"weight":null,"flags":null,"tag":null}' \
        "https://api.digitalocean.com/v2/domains/$DOMAIN/records")
    case $_code in
        201)
            echo ' 'Created.
            ;;
        *)
            echo ' 'Failed.
            echo Unexpected result with response code: $_code.
            echo -e '\033[0;31m'Script terminated.'\033[0m'
            exit 1
    esac
fi

echo $'\n''#' Modify CNAME DNS Record for Roundcube
_total=$(curl -X GET \
    -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN/records?type=CNAME&name=$FQCDN_ROUNDCUBE" | \
    grep -o '"meta":{"total":.*}}' | \
    sed -E 's/"meta":\{"total":(.*)\}\}/\1/')
if [ $_total -gt 0 ];then
    echo DNS CNAME Record of FQCDN "'"${FQCDN_ROUNDCUBE}"'" found in DNS Digital Ocean.
else
    echo DNS CNAME Record of FQCDN "'"${FQCDN_ROUNDCUBE}"'" NOT found in DNS Digital Ocean.
    echo -n  Trying to create...
    _code=$(curl -X POST \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -o /dev/null -s -w "%{http_code}\n" \
        -d '{"type":"CNAME","name":"'"$SUBDOMAIN_ROUNDCUBE"'","data":"@","priority":null,"port":null,"ttl":1800,"weight":null,"flags":null,"tag":null}' \
        "https://api.digitalocean.com/v2/domains/$DOMAIN/records")
    case $_code in
        201)
            echo ' 'Created.
            ;;
        *)
            echo ' 'Failed.
            echo Unexpected result with response code: $_code.
            echo -e '\033[0;31m'Script terminated.'\033[0m'
            exit 1
    esac
fi

echo $'\n''#' Modify CNAME DNS Record for ISPConfig
_total=$(curl -X GET \
    -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN/records?type=CNAME&name=$FQCDN_ISPCONFIG" | \
    grep -o '"meta":{"total":.*}}' | \
    sed -E 's/"meta":\{"total":(.*)\}\}/\1/')
if [ $_total -gt 0 ];then
    echo DNS CNAME Record of FQCDN "'"${FQCDN_ISPCONFIG}"'" found in DNS Digital Ocean.
else
    echo DNS CNAME Record of FQCDN "'"${FQCDN_ISPCONFIG}"'" NOT found in DNS Digital Ocean.
    echo -n  Trying to create...
    _code=$(curl -X POST \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -o /dev/null -s -w "%{http_code}\n" \
        -d '{"type":"CNAME","name":"'"$SUBDOMAIN_ISPCONFIG"'","data":"@","priority":null,"port":null,"ttl":1800,"weight":null,"flags":null,"tag":null}' \
        "https://api.digitalocean.com/v2/domains/$DOMAIN/records")
    case $_code in
        201)
            echo ' 'Created.
            ;;
        *)
            echo ' 'Failed.
            echo Unexpected result with response code: $_code.
            echo -e '\033[0;31m'Script terminated.'\033[0m'
            exit 1
    esac
fi

echo $'\n''#' Install Web Server Application
apt -y install nginx php7.4 \
php7.4-{common,gd,mysql,imap,cli,fpm,curl,intl,pspell,sqlite3,tidy,xmlrpc,xsl,zip,mbstring,soap,opcache}

cd      /etc/php/7.4/fpm/
sed -i  's|^;date\.timezone =$|date.timezone = '"$TIMEZONE"'|' php.ini
/etc/init.d/php7.4-fpm restart

CONTENT=$(cat <<- 'EOF'
server {
    listen 80;
    listen [::]:80;
    root /var/www/|SERVER_NAME|;
    server_name |SERVER_NAME|;
    index index.php index.html index.htm;
    location / {
        try_files $uri $uri/ =404;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }
}
EOF
)

echo $'\n''#' Setup ISPConfig Virtual Host
cd      /etc/nginx/sites-available
touch   "$FQCDN_ISPCONFIG"
cd      /etc/nginx/sites-enabled
ln -sf  ../sites-available/"$FQCDN_ISPCONFIG" "$FQCDN_ISPCONFIG"
cd      /etc/nginx/sites-available
echo   "$CONTENT" > "$FQCDN_ISPCONFIG"
sed -i 's/|SERVER_NAME|/'"$FQCDN_ISPCONFIG"'/' "$FQCDN_ISPCONFIG"
mkdir -p    /var/www/"$FQCDN_ISPCONFIG"
cd          /var/www/"$FQCDN_ISPCONFIG"
echo        "<?php echo '$FQCDN_ISPCONFIG'.PHP_EOL;?>" > index.php

echo $'\n''#' Setup PHPMyAdmin Virtual Host
cd      /etc/nginx/sites-available
touch   "$FQCDN_PHPMYADMIN"
cd      /etc/nginx/sites-enabled
ln -sf  ../sites-available/"$FQCDN_PHPMYADMIN" "$FQCDN_PHPMYADMIN"
cd      /etc/nginx/sites-available
echo   "$CONTENT" > "$FQCDN_PHPMYADMIN"
sed -i 's/|SERVER_NAME|/'"$FQCDN_PHPMYADMIN"'/' "$FQCDN_PHPMYADMIN"
mkdir -p    /var/www/"$FQCDN_PHPMYADMIN"
cd          /var/www/"$FQCDN_PHPMYADMIN"
echo        "<?php echo '$FQCDN_PHPMYADMIN'.PHP_EOL;?>" > index.php

echo $'\n''#' Setup Roundcube Virtual Host
cd      /etc/nginx/sites-available
touch   "$FQCDN_ROUNDCUBE"
cd      /etc/nginx/sites-enabled
ln -sf  ../sites-available/"$FQCDN_ROUNDCUBE" "$FQCDN_ROUNDCUBE"
cd      /etc/nginx/sites-available
echo   "$CONTENT" > "$FQCDN_ROUNDCUBE"
sed -i 's/|SERVER_NAME|/'"$FQCDN_ROUNDCUBE"'/' "$FQCDN_ROUNDCUBE"
mkdir -p    /var/www/"$FQCDN_ROUNDCUBE"
cd          /var/www/"$FQCDN_ROUNDCUBE"
echo        "<?php echo '$FQCDN_ROUNDCUBE'.PHP_EOL;?>" > index.php

echo $'\n''#' HTTP Request Verification
nginx -s reload
sleep 1
if [[ ! $(curl -s http://"$FQCDN_PHPMYADMIN") == "$FQCDN_PHPMYADMIN" ]];then
    echo Failed to request http://"$FQCDN_PHPMYADMIN"
    echo -e '\033[0;31m'Script terminated.'\033[0m'
    exit 1
fi
if [[ ! $(curl -s http://"$FQCDN_ROUNDCUBE") == "$FQCDN_ROUNDCUBE" ]];then
    echo Failed to request http://"$FQCDN_ROUNDCUBE"
    echo -e '\033[0;31m'Script terminated.'\033[0m'
    exit 1
fi
if [[ ! $(curl -s http://"$FQCDN_ISPCONFIG") == "$FQCDN_ISPCONFIG" ]];then
    echo Failed to request http://"$FQCDN_ISPCONFIG"
    echo -e '\033[0;31m'Script terminated.'\033[0m'
    exit 1
fi

echo $'\n''#' Certbot Request
certbot -i nginx \
   -n --agree-tos --email "${EMAIL_HOST}@${DOMAIN}" \
   --dns-digitalocean \
   --dns-digitalocean-credentials ~/digitalocean-token-ispconfig.ini \
   -d "$FQCDN_PHPMYADMIN" \
   -d "$FQCDN_ROUNDCUBE" \
   -d "$FQCDN_ISPCONFIG"

echo $'\n''#' HTTPS Request Verification
if [[ ! $(curl -s https://"$FQCDN_PHPMYADMIN") == "$FQCDN_PHPMYADMIN" ]];then
    echo Failed to request https://"$FQCDN_PHPMYADMIN"
    echo -e '\033[0;31m'Script terminated.'\033[0m'
    exit 1
fi
if [[ ! $(curl -s https://"$FQCDN_ROUNDCUBE") == "$FQCDN_ROUNDCUBE" ]];then
    echo Failed to request https://"$FQCDN_ROUNDCUBE"
    echo -e '\033[0;31m'Script terminated.'\033[0m'
    exit 1
fi
if [[ ! $(curl -s https://"$FQCDN_ISPCONFIG") == "$FQCDN_ISPCONFIG" ]];then
    echo Failed to request https://"$FQCDN_ISPCONFIG"
    echo -e '\033[0;31m'Script terminated.'\033[0m'
    exit 1
fi

echo $'\n''#' MariaDB
apt -y install mariadb-client mariadb-server
cd      /etc/mysql/mariadb.conf.d/
sed -i  "s/bind-address/# bind-address/" 50-server.cnf
echo    "update mysql.user set plugin = 'mysql_native_password' where user='root';" | mysql -u root
echo    "" >> /etc/security/limits.conf
echo    "# Custom" >> /etc/security/limits.conf
echo    "mysql soft nofile 65535" >> /etc/security/limits.conf
echo    "mysql hard nofile 65535" >> /etc/security/limits.conf
mkdir -p /etc/systemd/system/mysql.service.d/
CONTENT=$(cat <<- 'EOF'
[Service]
LimitNOFILE=infinity
EOF
)
echo "$CONTENT" >> /etc/systemd/system/mysql.service.d/limits.conf
systemctl daemon-reload
systemctl restart mariadb

echo $'\n''#' PHPMyAdmin Download
cd          /tmp
wget        https://files.phpmyadmin.net/phpMyAdmin/${VERSION_PHPMYADMIN}/phpMyAdmin-${VERSION_PHPMYADMIN}-all-languages.tar.gz
tar xfz     phpMyAdmin-${VERSION_PHPMYADMIN}-all-languages.tar.gz
mkdir -p    /usr/local/share/phpmyadmin/${VERSION_PHPMYADMIN}
mv          phpMyAdmin-${VERSION_PHPMYADMIN}-all-languages/* -t /usr/local/share/phpmyadmin/${VERSION_PHPMYADMIN}
mv          phpMyAdmin-${VERSION_PHPMYADMIN}-all-languages/.[!.]* -t /usr/local/share/phpmyadmin/${VERSION_PHPMYADMIN}
rmdir       phpMyAdmin-${VERSION_PHPMYADMIN}-all-languages

echo $'\n''#' PHPMyAdmin Credential
password=$(pwgen -s 32 -1)
blowfish=$(pwgen -s 32 -1)
phpmyadmin_db_user=pma
phpmyadmin_db_pass="$password"
phpmyadmin_db_host=localhost
phpmyadmin_db_name=phpmyadmin
echo "CREATE USER 'pma'@'localhost' IDENTIFIED BY '${password}';" | mysql -u root
echo "GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'pma'@'localhost';" | mysql -u root
echo "FLUSH PRIVILEGES;" | mysql -u root

echo $'\n''#' PHPMyAdmin Import Table
cd          /usr/local/share/phpmyadmin/${VERSION_PHPMYADMIN}
mysql <     sql/create_tables.sql

echo $'\n''#' PHPMyAdmin Configuration
cd          /usr/local/share/phpmyadmin/${VERSION_PHPMYADMIN}
mkdir -p    tmp
chmod 0777  tmp
cp          config.sample.inc.php config.inc.php
sed -i "s|^// \$cfg\['Servers'\]\[\$i\]\['controlpass'\] = 'pmapass';|\$cfg['Servers'][\$i]['controlpass'] = '${password}';|" config.inc.php
sed -i "s|^// \$cfg\['Servers'\]\[\$i\]\['controlhost'\] = '';|\$cfg['Servers'][\$i]['controlhost'] = 'localhost';|" config.inc.php
sed -i "s|^\$cfg\['blowfish_secret'\] = '';|\$cfg['blowfish_secret'] = '${blowfish}';|" config.inc.php
sed -i "s|^// \$cfg\['Servers'\]\[\$i\]|\$cfg['Servers'][\$i]|" config.inc.php

echo $'\n''#' PHPMyAdmin Adjust Web Root
ln -sf  /usr/local/share/phpmyadmin/${VERSION_PHPMYADMIN} /usr/local/phpmyadmin
cd      /etc/nginx/sites-available
sed -i  "s,/var/www/${FQCDN_PHPMYADMIN},/usr/local/phpmyadmin," \
        "${FQCDN_PHPMYADMIN}"

echo $'\n''#' Install Mail Server Application
debconf-set-selections <<< "postfix postfix/mailname string ${FQCDN}"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt -y install postfix postfix-mysql postfix-doc
apt -y install \
    dovecot-core dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve dovecot-lmtpd \
    getmail4 amavisd-new postgrey spamassassin

echo $'\n''#' Disable SpamAssassin service
systemctl stop spamassassin
systemctl disable spamassassin

echo $'\n''#' Postfix Configuration
sed -i 's|^#submission|submission|' /etc/postfix/master.cf
sed -i 's|^#smtps|smtps|' /etc/postfix/master.cf
sed -i 's|^#  -o syslog_name=postfix/submission|  -o syslog_name=postfix/submission|' /etc/postfix/master.cf
sed -i 's|^#  -o syslog_name=postfix/smtps|  -o syslog_name=postfix/smtps|' /etc/postfix/master.cf
sed -i 's|^#  -o smtpd_tls_security_level=encrypt|  -o smtpd_tls_security_level=encrypt|' /etc/postfix/master.cf
sed -i 's|^#  -o smtpd_tls_auth_only=yes|  -o smtpd_tls_auth_only=yes|' /etc/postfix/master.cf
sed -i 's|^#  -o smtpd_tls_wrappermode=yes|  -o smtpd_tls_wrappermode=yes|' /etc/postfix/master.cf
sed -i 's|^#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|^#  -o smtpd_client_restrictions=|  -o smtpd_client_restrictions=permit_sasl_authenticated,reject # |' /etc/postfix/master.cf

echo $'\n''#' Postfix Reload
/etc/init.d/postfix restart

echo $'\n''#' Roundcube Download
cd          /tmp
wget        https://github.com/roundcube/roundcubemail/releases/download/${VERSION_ROUNDCUBE}/roundcubemail-${VERSION_ROUNDCUBE}-complete.tar.gz
tar xfz     roundcubemail-${VERSION_ROUNDCUBE}-complete.tar.gz
mkdir -p    /usr/local/share/roundcube/${VERSION_ROUNDCUBE}
mv          roundcubemail-${VERSION_ROUNDCUBE}/* -t /usr/local/share/roundcube/${VERSION_ROUNDCUBE}/
mv          roundcubemail-${VERSION_ROUNDCUBE}/.[!.]* -t /usr/local/share/roundcube/${VERSION_ROUNDCUBE}/
rmdir       roundcubemail-${VERSION_ROUNDCUBE}

echo $'\n''#' Roundcube Credential
password=$(pwgen -s 32 -1)
blowfish=$(pwgen -s 32 -1)
roundcube_db_user=roundcube
roundcube_db_pass="$password"
roundcube_db_host=localhost
roundcube_db_name=roundcubemail
echo "CREATE DATABASE roundcubemail CHARACTER SET utf8 COLLATE utf8_general_ci;" | mysql -u root
echo "CREATE USER 'roundcube'@'localhost' IDENTIFIED BY '${password}';" | mysql -u root
echo "GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'localhost';" | mysql -u root
echo "FLUSH PRIVILEGES;" | mysql -u root

echo $'\n''#' Roundcube Import Table
cd /usr/local/share/roundcube/${VERSION_ROUNDCUBE}
mysql roundcubemail < SQL/mysql.initial.sql

echo $'\n''#' Roundcube Configuration
cd          /usr/local/share/roundcube/${VERSION_ROUNDCUBE}
chmod 0777  temp/
chmod 0777  logs/
cp          config/config.inc.php.sample config/config.inc.php
CONTENT=$(cat <<- EOF
\$config['des_key'] = '$blowfish';
\$config['db_dsnw'] = 'mysql://roundcube:$password@localhost/roundcubemail';
\$config['smtp_port'] = 25;
\$config['smtp_user'] = '';
\$config['smtp_pass'] = '';
\$config['identities_level'] = 3;
\$config['username_domain'] = '%t';
\$config['default_list_mode'] = 'threads';
EOF
)
echo "" >> config/config.inc.php
echo "$CONTENT" >> config/config.inc.php

echo $'\n''#' Roundcube Adjust Web Root
ln -sf  /usr/local/share/roundcube/${VERSION_ROUNDCUBE} /usr/local/roundcube
cd      /etc/nginx/sites-available
sed -i  "s,/var/www/${FQCDN_ROUNDCUBE},/usr/local/roundcube," \
        "${FQCDN_ROUNDCUBE}"

echo $'\n''#' ISPConfig Download
cd      /tmp
wget    http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar xfz ISPConfig-3-stable.tar.gz
cd      ispconfig3_install/install/

echo $'\n''#' ISPConfig Modification PHP 7.3 to 7.4
cd      /tmp/ispconfig3_install/install/dist/conf
sed -i  's|php7.3|php7.4|g' debian100.conf.php
sed -i  's|php/7.3/|php/7.4/|g' debian100.conf.php

echo $'\n''#' MySQL Setup Root Password
echo $(pwgen -s 32 -1) > ~/mysql-root-passwd.txt
chmod 0700 ~/mysql-root-passwd.txt
mysql -e "UPDATE mysql.user SET Password = PASSWORD('"$(<~/mysql-root-passwd.txt)"') WHERE User = 'root'"
mysql -e "FLUSH PRIVILEGES"

echo $'\n''#' ISPConfig Credential
password=$(pwgen -s 32 -1)
ispconfig_db_user=ispconfig
ispconfig_db_pass="$password"
ispconfig_db_host=localhost
ispconfig_db_name=dbispconfig

echo $'\n''#' ISPConfig Install
cd      /tmp/ispconfig3_install/install/
cp      ../docs/autoinstall_samples/autoinstall.ini.sample ./autoinstall.ini
sed -i "s,hostname=server1.example.com,hostname=${FQCDN}," autoinstall.ini
sed -i "s,mysql_root_password=ispconfig,mysql_root_password="$(<~/mysql-root-passwd.txt)"," autoinstall.ini
sed -i "s,http_server=apache,http_server=nginx," autoinstall.ini
sed -i "s,ispconfig_use_ssl=y,ispconfig_use_ssl=n," autoinstall.ini
echo $(pwgen 6 -1vA0B) > ~/ispconfig-admin-passwd.txt
chmod 0700 ~/ispconfig-admin-passwd.txt
sed -i "s,ispconfig_admin_password=admin,ispconfig_admin_password="$(<~/ispconfig-admin-passwd.txt)"," autoinstall.ini
sed -i "s,mysql_ispconfig_password=.*,mysql_ispconfig_password="$password"," autoinstall.ini
php install.php --autoinstall=autoinstall.ini

echo $'\n''#' ISPConfig Adjust Web Root
cd      /etc/nginx/sites-available
sed -i  "s,/var/www/${FQCDN_ISPCONFIG},/usr/local/ispconfig/interface/web," \
        "${FQCDN_ISPCONFIG}"
sed -i  "s,/var/run/php/php7.4-fpm.sock,/var/lib/php7.4-fpm/ispconfig.sock," \
        "${FQCDN_ISPCONFIG}"

echo $'\n''#' Nginx Cleaning
cd  /etc/nginx/sites-enabled
rm  000-ispconfig.vhost
rm  000-apps.vhost
rm  999-acme.vhost
rm -rf /var/www/"$FQCDN_PHPMYADMIN"
rm -rf /var/www/"$FQCDN_ROUNDCUBE"
rm -rf /var/www/"$FQCDN_ISPCONFIG"
nginx -s reload
sleep 1
echo $'\n''#' Retrieve ISP Config Directory
CONTENT=$(cat <<- EOF
include "/tmp/ispconfig3_install/install/dist/conf/$DEBIAN_CONF";
echo \$conf['ispconfig_install_dir'];
EOF
)
ispconfig_install_dir=$(php -r "$CONTENT")
phpmyadmin_install_dir=/usr/local/share/phpmyadmin/"$VERSION_PHPMYADMIN"
roundcube_install_dir=/usr/local/share/roundcube/"$VERSION_ROUNDCUBE"

echo $'\n''#' Copy ISPConfig PHP Scripts
mkdir -p "$ispconfig_install_dir"/scripts
cp /tmp/ispconfig3_install/remoting_client/examples/* "$ispconfig_install_dir/scripts"
scripts_dir="$ispconfig_install_dir"/scripts

echo $'\n''#' Modify PHP Scripts
cd "$ispconfig_install_dir"/scripts
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

echo $'\n''#' Create ISPConfig Command '`'isp'`'.
CONTENT=$(cat <<- 'EOF'
#!/bin/bash
s=|scripts_dir|
Usage() {
    echo -e "Usage: isp \e[33m<command>\e[0m [<args>]" >&2
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
esac
EOF
)
: > /usr/local/bin/isp
echo "$CONTENT" >> /usr/local/bin/isp
chmod a+x /usr/local/bin/isp
sed -i 's,|phpmyadmin_install_dir|,'"${phpmyadmin_install_dir}"',' /usr/local/bin/isp
sed -i 's,|roundcube_install_dir|,'"${roundcube_install_dir}"',' /usr/local/bin/isp
sed -i 's,|ispconfig_install_dir|,'"${ispconfig_install_dir}"',' /usr/local/bin/isp
sed -i 's,|scripts_dir|,'"${scripts_dir}"',' /usr/local/bin/isp

echo $'\n''#' Create Autocompletion for '`'isp'`' Command.
CONTENT=$(cat <<- 'EOF'
#!/bin/bash
_isp() {
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
complete -F _isp isp
EOF
)
: > /etc/profile.d/isp-completion.sh
echo "$CONTENT" >> /etc/profile.d/isp-completion.sh
chmod a+x /etc/profile.d/isp-completion.sh
sed -i 's,|scripts_dir|,'"${scripts_dir}"',' /etc/profile.d/isp-completion.sh

echo $'\n''#' Implement Autocompletion for '`'isp'`' Command.
echo 'Execute: `source /etc/profile.d/isp-completion.sh`'
source /etc/profile.d/isp-completion.sh

echo $'\n''#' Insert Remote User to ISPConfig Database - Username: root
root_password=$(pwgen -s 32 -1)
CONTENT=$(cat <<- EOF
require '${ispconfig_install_dir}/interface/lib/classes/auth.inc.php';
echo (new auth)->crypt_password('$root_password');
EOF
)
root_password_hash=$(php -r "$CONTENT")
root_access='server_get,server_config_set,get_function_list,client_templates_get_all,server_get_serverid_by_ip,server_ip_get,server_ip_add,server_ip_update,server_ip_delete,system_config_set,system_config_get,config_value_get,config_value_add,config_value_update,config_value_replace,config_value_delete
admin_record_permissions
client_get_id,login,logout,mail_alias_get,mail_fetchmail_add,mail_fetchmail_delete,mail_fetchmail_get,mail_fetchmail_update,mail_policy_get,mail_spamfilter_blacklist_add,mail_spamfilter_blacklist_delete,mail_spamfilter_blacklist_get,mail_spamfilter_blacklist_update,mail_spamfilter_user_add,mail_spamfilter_user_get,mail_spamfilter_user_update,mail_spamfilter_whitelist_add,mail_spamfilter_whitelist_delete,mail_spamfilter_whitelist_get,mail_spamfilter_whitelist_update,mail_user_filter_add,mail_user_filter_delete,mail_user_filter_get,mail_user_filter_update,mail_user_get,mail_user_update,server_get,server_get_app_version
client_get_all,client_get,client_add,client_update,client_delete,client_get_sites_by_user,client_get_by_username,client_get_by_customer_no,client_change_password,client_get_id,client_delete_everything,client_get_emailcontact
domains_domain_get,domains_domain_add,domains_domain_update,domains_domain_delete,domains_get_all_by_user
quota_get_by_user,trafficquota_get_by_user,mailquota_get_by_user,databasequota_get_by_user
mail_domain_get,mail_domain_add,mail_domain_update,mail_domain_delete,mail_domain_set_status,mail_domain_get_by_domain
mail_aliasdomain_get,mail_aliasdomain_add,mail_aliasdomain_update,mail_aliasdomain_delete
mail_mailinglist_get,mail_mailinglist_add,mail_mailinglist_update,mail_mailinglist_delete
mail_user_get,mail_user_add,mail_user_update,mail_user_delete
mail_alias_get,mail_alias_add,mail_alias_update,mail_alias_delete
mail_forward_get,mail_forward_add,mail_forward_update,mail_forward_delete
mail_catchall_get,mail_catchall_add,mail_catchall_update,mail_catchall_delete
mail_transport_get,mail_transport_add,mail_transport_update,mail_transport_delete
mail_relay_get,mail_relay_add,mail_relay_update,mail_relay_delete
mail_whitelist_get,mail_whitelist_add,mail_whitelist_update,mail_whitelist_delete
mail_blacklist_get,mail_blacklist_add,mail_blacklist_update,mail_blacklist_delete
mail_spamfilter_user_get,mail_spamfilter_user_add,mail_spamfilter_user_update,mail_spamfilter_user_delete
mail_policy_get,mail_policy_add,mail_policy_update,mail_policy_delete
mail_fetchmail_get,mail_fetchmail_add,mail_fetchmail_update,mail_fetchmail_delete
mail_spamfilter_whitelist_get,mail_spamfilter_whitelist_add,mail_spamfilter_whitelist_update,mail_spamfilter_whitelist_delete
mail_spamfilter_blacklist_get,mail_spamfilter_blacklist_add,mail_spamfilter_blacklist_update,mail_spamfilter_blacklist_delete
mail_user_filter_get,mail_user_filter_add,mail_user_filter_update,mail_user_filter_delete
mail_user_backup
mail_filter_get,mail_filter_add,mail_filter_update,mail_filter_delete
monitor_jobqueue_count
sites_cron_get,sites_cron_add,sites_cron_update,sites_cron_delete
sites_database_get,sites_database_add,sites_database_update,sites_database_delete, sites_database_get_all_by_user,sites_database_user_get,sites_database_user_add,sites_database_user_update,sites_database_user_delete, sites_database_user_get_all_by_user
sites_web_folder_get,sites_web_folder_add,sites_web_folder_update,sites_web_folder_delete,sites_web_folder_user_get,sites_web_folder_user_add,sites_web_folder_user_update,sites_web_folder_user_delete
sites_ftp_user_get,sites_ftp_user_server_get,sites_ftp_user_add,sites_ftp_user_update,sites_ftp_user_delete
sites_shell_user_get,sites_shell_user_add,sites_shell_user_update,sites_shell_user_delete
sites_web_domain_get,sites_web_domain_add,sites_web_domain_update,sites_web_domain_delete,sites_web_domain_set_status
sites_web_domain_backup
sites_web_aliasdomain_get,sites_web_aliasdomain_add,sites_web_aliasdomain_update,sites_web_aliasdomain_delete
sites_web_subdomain_get,sites_web_subdomain_add,sites_web_subdomain_update,sites_web_subdomain_delete
sites_aps_update_package_list,sites_aps_available_packages_list,sites_aps_change_package_status,sites_aps_install_package,sites_aps_get_package_details,sites_aps_get_package_file,sites_aps_get_package_settings,sites_aps_instance_get,sites_aps_instance_delete
sites_webdav_user_get,sites_webdav_user_add,sites_webdav_user_update,sites_webdav_user_delete
dns_zone_get,dns_zone_get_id,dns_zone_add,dns_zone_update,dns_zone_delete,dns_zone_set_status,dns_templatezone_add
dns_a_get,dns_a_add,dns_a_update,dns_a_delete
dns_aaaa_get,dns_aaaa_add,dns_aaaa_update,dns_aaaa_delete
dns_alias_get,dns_alias_add,dns_alias_update,dns_alias_delete
dns_caa_get,dns_caa_add,dns_caa_update,dns_caa_delete
dns_cname_get,dns_cname_add,dns_cname_update,dns_cname_delete
dns_dname_get,dns_dname_add,dns_dname_update,dns_dname_delete
dns_ds_get,dns_ds_add,dns_ds_update,dns_ds_delete
dns_hinfo_get,dns_hinfo_add,dns_hinfo_update,dns_hinfo_delete
dns_loc_get,dns_loc_add,dns_loc_update,dns_loc_delete
dns_mx_get,dns_mx_add,dns_mx_update,dns_mx_delete
dns_naptr_get,dns_naptr_add,dns_naptr_update,dns_naptr_delete
dns_ns_get,dns_ns_add,dns_ns_update,dns_ns_delete
dns_ptr_get,dns_ptr_add,dns_ptr_update,dns_ptr_delete
dns_rp_get,dns_rp_add,dns_rp_update,dns_rp_delete
dns_srv_get,dns_srv_add,dns_srv_update,dns_srv_delete
dns_sshfp_get,dns_sshfp_add,dns_sshfp_update,dns_sshfp_delete
dns_tlsa_get,dns_tlsa_add,dns_tlsa_update,dns_tlsa_delete
dns_txt_get,dns_txt_add,dns_txt_update,dns_txt_delete
vm_openvz'
root_access_joined=$(tr '\n' ';' <<< "$root_access")
sql="INSERT INTO remote_user
(sys_userid, sys_groupid, sys_perm_user, sys_perm_group, sys_perm_other, remote_username, remote_password, remote_access, remote_ips, remote_functions)
VALUES
(1, 1, 'riud', 'riud', '', '$REMOTE_USER_ROOT', '$root_password_hash', 'y', '$IP_PUBLIC','$root_access_joined');"
u=root
p=$(<~/mysql-root-passwd.txt)
mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
    dbispconfig -e "$sql"

echo $'\n''#' Configure SOAP Config for root remote user
CONTENT=$(cat <<- EOF
<?php

\$username = 'root';
\$password = '$root_password';
\$soap_location = 'https://$FQCDN_ISPCONFIG/remote/index.php';
\$soap_uri = 'https://$FQCDN_ISPCONFIG/remote/';
EOF
)
echo "$CONTENT" > "$ispconfig_install_dir"/scripts/soap_config.php

echo $'\n''#' Insert Remote User to ISPConfig Database - Username: roundcube
roundcube_password=$(pwgen -s 32 -1)
CONTENT=$(cat <<- EOF
require '${ispconfig_install_dir}/interface/lib/classes/auth.inc.php';
echo (new auth)->crypt_password('$roundcube_password');
EOF
)
roundcube_password_hash=$(php -r "$CONTENT")
roundcube_access='server_get,server_config_set,get_function_list,client_templates_get_all,server_get_serverid_by_ip,server_ip_get,server_ip_add,server_ip_update,server_ip_delete,system_config_set,system_config_get,config_value_get,config_value_add,config_value_update,config_value_replace,config_value_delete
client_get_all,client_get,client_add,client_update,client_delete,client_get_sites_by_user,client_get_by_username,client_get_by_customer_no,client_change_password,client_get_id,client_delete_everything,client_get_emailcontact
mail_user_get,mail_user_add,mail_user_update,mail_user_delete
mail_alias_get,mail_alias_add,mail_alias_update,mail_alias_delete
mail_forward_get,mail_forward_add,mail_forward_update,mail_forward_delete
mail_spamfilter_user_get,mail_spamfilter_user_add,mail_spamfilter_user_update,mail_spamfilter_user_delete
mail_policy_get,mail_policy_add,mail_policy_update,mail_policy_delete
mail_fetchmail_get,mail_fetchmail_add,mail_fetchmail_update,mail_fetchmail_delete
mail_spamfilter_whitelist_get,mail_spamfilter_whitelist_add,mail_spamfilter_whitelist_update,mail_spamfilter_whitelist_delete
mail_spamfilter_blacklist_get,mail_spamfilter_blacklist_add,mail_spamfilter_blacklist_update,mail_spamfilter_blacklist_delete
mail_user_filter_get,mail_user_filter_add,mail_user_filter_update,mail_user_filter_delete'
roundcube_access_joined=$(tr '\n' ';' <<< "$roundcube_access")
sql="INSERT INTO remote_user
(sys_userid, sys_groupid, sys_perm_user, sys_perm_group, sys_perm_other, remote_username, remote_password, remote_access, remote_ips, remote_functions)
VALUES
(1, 1, 'riud', 'riud', '', '$REMOTE_USER_ROUNDCUBE', '$roundcube_password_hash', 'y', '$IP_PUBLIC', '$roundcube_access_joined');"
u=root
p=$(<~/mysql-root-passwd.txt)
mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
    dbispconfig -e "$sql"

echo $'\n''#' Download Plugin ISP Config Roundcube Integration
cd /tmp
wget https://github.com/w2c/ispconfig3_roundcube/archive/master.zip
unzip -qq master.zip
cd ./ispconfig3_roundcube-master
cp -r ./ispconfig3_* /usr/local/share/roundcube/$VERSION_ROUNDCUBE/plugins/

echo $'\n''#' Configure Plugin Credential
cd  /usr/local/share/roundcube/$VERSION_ROUNDCUBE/plugins/ispconfig3_account/config
cp  config.inc.php.dist config.inc.php
sed -i "s/\$config\['remote_soap_user'\] = '.*';/\$config['remote_soap_user'] = '$REMOTE_USER_ROUNDCUBE';/" config.inc.php
sed -i "s/\$config\['remote_soap_pass'\] = '.*';/\$config['remote_soap_pass'] = '$roundcube_password';/" config.inc.php
sed -i "s|\$config\['soap_url'\] = '.*';|\$config['soap_url'] = 'https://$FQCDN_ISPCONFIG/remote/';|" config.inc.php

echo $'\n''#' Enables Plugins
cd /usr/local/share/roundcube/${VERSION_ROUNDCUBE}
CONTENT=$(cat <<- 'EOF'
$config['plugins'][] = 'ispconfig3_account';
$config['plugins'][] = 'ispconfig3_autoreply';
$config['plugins'][] = 'ispconfig3_pass';
$config['plugins'][] = 'ispconfig3_filter';
$config['plugins'][] = 'ispconfig3_forward';
$config['plugins'][] = 'ispconfig3_wblist';
$config['plugins'][] = 'identity_select';
$config['identity_select_headers'] = array('To');
EOF
)
echo "" >> config/config.inc.php
echo "$CONTENT" >> config/config.inc.php

echo -n $'\n''########################################'
echo         '########################################'
echo $'\n''#' CHAPTER 2. SETUP DOMAIN
echo -n $'\n''########################################'
echo         '########################################'

echo $'\n''#' Modify MX DNS Record
_fqcdn=$DOMAIN
_output=$(curl -X GET \
    -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN/records?type=MX&name=$_fqcdn")
CONTENT=$(cat <<- EOF
\$object = (json_decode('$_output'));
if (is_object(\$object)) {
    foreach (\$object->domain_records as \$domain_record) {
        if (\$domain_record->data == '$FQCDN_MX') {
            exit(1);
        }
    }
}
EOF
)
php -r "$CONTENT"
if [[ "$?" == "1" ]];then
    echo DNS MX Record of FQCDN "'"${DOMAIN}"'" target to "'"${FQCDN_MX}"'" found in DNS Digital Ocean.
else
    echo DNS MX Record of FQCDN "'"${DOMAIN}"'" target to "'"${FQCDN_MX}"'" NOT found in DNS Digital Ocean.
    echo -n  Trying to create...
    _data=$FQCDN_MX"."
    _priority=10
    _code=$(curl -X POST \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -o /dev/null -s -w "%{http_code}\n" \
        -d '{"type":"MX","name":"@","data":"'"$_data"'","priority":"'"$_priority"'","port":null,"ttl":1800,"weight":null,"flags":null,"tag":null}' \
        "https://api.digitalocean.com/v2/domains/$DOMAIN/records")
    case "$_code" in
        201)
            echo ' 'Created.
            ;;
        *)
            echo ' 'Failed.
            echo Unexpected result with response code: $_code.
            echo -e '\033[0;31m'Script terminated.'\033[0m'
            exit 1
    esac
fi

echo $'\n''#' Modify TXT DNS Record for SPF
spf_txt='v=spf1 a:'"$FQCDN_MX"' ~all'
spf_txt=$(php -r 'echo "\"".implode("\"\"", str_split("'"$spf_txt"'", 200))."\"";')
_fqcdn=$DOMAIN
_output=$(curl -X GET \
    -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN/records?type=TXT&name=$_fqcdn")
CONTENT=$(cat <<- EOF
\$object = (json_decode('$_output'));
if (is_object(\$object)) {
    foreach (\$object->domain_records as \$domain_record) {
        if (\$domain_record->data == '$spf_txt') {
            exit(1);
        }
    }
}
EOF
)
php -r "$CONTENT"
if [[ "$?" == "1" ]];then
    echo DNS TXT Record of FQCDN "'"${DOMAIN}"'" for SPF found in DNS Digital Ocean.
else
    echo DNS TXT Record of FQCDN "'"${DOMAIN}"'" for SPF NOT found in DNS Digital Ocean.
    echo -n  Trying to create...
    spf_txt_json=$(echo "$spf_txt" | sed 's,",\\",g')
    _code=$(curl -X POST \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -o /dev/null -s -w "%{http_code}\n" \
        -d '{"type":"TXT","name":"@","data":"'"$spf_txt_json"'","priority":null,"port":null,"ttl":1800,"weight":null,"flags":null,"tag":null}' \
        "https://api.digitalocean.com/v2/domains/$DOMAIN/records")
    case "$_code" in
        201)
            echo ' 'Created.
            ;;
        *)
            echo ' 'Failed.
            echo Unexpected result with response code: $_code.
            echo -e '\033[0;31m'Script terminated.'\033[0m'
            exit 1
    esac
fi

echo $'\n''#' Execute SOAP mail_domain_get_by_domain
echo Create a temporary file:
template=mail_domain_get_by_domain
template_temp=$(isp mktemp "${template}.php")
template_temp_path=$(isp realpath "$template_temp")
echo "$template_temp_path"
sed -i -E -e '/echo/d' \
    -e 's/print_r/var_export/' \
    -e 's/\$domain\s+=\s+[^;]+;/\$domain = "'"$DOMAIN"'";/' \
    "$template_temp_path"
cat "$template_temp_path"
echo Execute command: isp php "$template_temp"
VALUE=$(isp php "$template_temp")
echo Cleaning Temporary File.
echo rm '"'"$template_temp_path"'"'
rm "$template_temp_path"
CONTENT=$(cat <<- EOF
\$value=$VALUE;
// Karena domain pasti hanya bisa satu, maka tidak perlu looping.
if (\$each = array_shift(\$value)) {
    // Gunakan selector yang ada pada database.
    echo isset(\$each['dkim_selector']) ? \$each['dkim_selector'] : '';
}
EOF
)
dkim_selector=$(php -r "$CONTENT")
CONTENT=$(cat <<- EOF
\$value=$VALUE;
// Karena domain pasti hanya bisa satu, maka tidak perlu looping.
if (\$each = array_shift(\$value)) {
    echo isset(\$each['dkim_public']) ? \$each['dkim_public'] : '';
}
EOF
)
dkim_public=$(php -r "$CONTENT")
if [ -n "$dkim_public" ];then
    dns_record=$(echo "$dkim_public" | sed -e "/-----BEGIN PUBLIC KEY-----/d" -e "/-----END PUBLIC KEY-----/d" | tr '\n' ' ' | sed 's/\ //g')
    dkim_txt='v=DKIM1; t=s; p='"$dns_record"
    dkim_txt=$(php -r 'echo "\"".implode("\"\"", str_split("'"$dkim_txt"'", 200))."\"";')
    if [[ ! "$dkim_selector" == "$DKIM_SELECTOR" ]];then
        DKIM_SELECTOR="$dkim_selector"
    fi
else
    echo $'\n''#' Generate DKIM Public and Private Key
    token=$(pwgen 32 -1)
    dirname="$ispconfig_install_dir/interface/web/mail"
    temp_ajax_get_json="temp_ajax_get_json_$token.php"
    cd "$ispconfig_install_dir/interface/web/mail"
    echo Create a temporary file:
    echo "$ispconfig_install_dir/interface/web/mail/$temp_ajax_get_json"
    cp "ajax_get_json.php" "$temp_ajax_get_json"
    echo Remove security access inside temporary file.
    sed -i "/\$app->auth->check_module_permissions('mail');/d" "$temp_ajax_get_json"
    CONTENT=$(cat <<- EOF
chdir("${ispconfig_install_dir}/interface/web/mail");
\$_GET['type'] = 'create_dkim';
\$_GET['domain_id'] = '$DOMAIN';
\$_GET['dkim_selector'] = '$DKIM_SELECTOR';
\$_GET['dkim_public'] = '';
include_once '$ispconfig_install_dir/interface/web/mail/$temp_ajax_get_json';
EOF
    )
    echo Execute temporary file and get pair of keys.
    json=$(php -r "$CONTENT")
    dkim_private=$(php -r "echo (json_decode('$json'))->dkim_private;")
    dkim_public=$(php -r "echo (json_decode('$json'))->dkim_public;")
    dns_record=$(php -r "echo (json_decode('$json'))->dns_record;")
    dkim_txt='v=DKIM1; t=s; p='"$dns_record"
    dkim_txt=$(php -r 'echo "\"".implode("\"\"", str_split("'"$dkim_txt"'", 200))."\"";')
    echo Private Key:
    echo "$dkim_private"
    echo Public Key:
    echo "$dkim_public"
    echo Public Key for DNS Record:
    echo "$dkim_txt"
    echo Cleaning Temporary File.
    echo rm '"'"$ispconfig_install_dir/interface/web/mail/$temp_ajax_get_json"'"'
    rm "$ispconfig_install_dir/interface/web/mail/$temp_ajax_get_json"
    echo $'\n''#' Execute SOAP mail_domain_add
    echo Create a temporary file:
    template=mail_domain_add
    template_temp=$(isp mktemp "${template}.php")
    template_temp_path=$(isp realpath "$template_temp")
    echo "$template_temp_path"
    sed -i -E ':a;N;$!ba;s/\$params\s+=\s+[^;]+;/\$params = array(\n|PLACEHOLDER|\t);/g' \
        "$template_temp_path"
    CONTENT=$(cat <<- EOF
\$replace = '';
\$replace .= "\t\t"."'server_id' => '1',"                                 ."\n";
\$replace .= "\t\t"."'domain' => '$DOMAIN',"                              ."\n";
\$replace .= "\t\t"."'active' => 'y',"                                    ."\n";
\$replace .= "\t\t"."'dkim' => 'y',"                                      ."\n";
\$replace .= "\t\t"."'dkim_selector' => '$DKIM_SELECTOR',"                ."\n";
\$replace .= "\t\t"."'dkim_private' => '$dkim_private',"                  ."\n";
\$replace .= "\t\t"."'dkim_public' => '$dkim_public',"                    ."\n";
\$string=file_get_contents('$template_temp_path');
\$string = str_replace('|PLACEHOLDER|', \$replace, \$string);
file_put_contents('$template_temp_path', \$string);
echo \$string;
EOF
    )
    php -r "$CONTENT"
    echo Execute command: isp php "$template_temp"
    isp php "$template_temp"
    echo Cleaning Temporary File.
    echo rm '"'"$template_temp_path"'"'
    rm "$template_temp_path"
fi

echo $'\n''#' Modify TXT DNS Record for DKIM
dkim_fqcdn=$DKIM_SELECTOR._domainkey.$DOMAIN
_output=$(curl -X GET \
    -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN/records?type=TXT&name=$dkim_fqcdn")

CONTENT=$(cat <<- EOF
\$object = (json_decode('$_output'));
if (is_object(\$object)) {
    foreach (\$object->domain_records as \$domain_record) {
        if (\$domain_record->name == '$DKIM_SELECTOR._domainkey' && \$domain_record->data == '$dkim_txt') {
            exit(1);
        }
    }
}
EOF
)
php -r "$CONTENT"
if [[ "$?" == "1" ]];then
    echo DNS TXT Record of FQCDN "'"${dkim_fqcdn}"'" for DKIM found in DNS Digital Ocean.
else
    echo DNS TXT Record of FQCDN "'"${dkim_fqcdn}"'" for DKIM NOT found in DNS Digital Ocean.
    echo -n  Trying to create...
    dkim_txt_json=$(echo "$dkim_txt" | sed 's,",\\",g')
    _code=$(curl -X POST \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -o /dev/null -s -w "%{http_code}\n" \
        -d '{"type":"TXT","name":"'"$DKIM_SELECTOR._domainkey"'","data":"'"$dkim_txt_json"'","priority":null,"port":null,"ttl":1800,"weight":null,"flags":null,"tag":null}' \
        "https://api.digitalocean.com/v2/domains/$DOMAIN/records")
    case "$_code" in
        201)
            echo ' 'Created.
            ;;
        *)
            echo ' 'Failed.
            echo Unexpected result with response code: $_code.
            echo -e '\033[0;31m'Script terminated.'\033[0m'
            exit 1
    esac
fi

echo $'\n''#' Modify TXT DNS Record for DMARC
dmarc_txt='v=DMARC1; p=none; rua='"${EMAIL_POST}@${DOMAIN}"
dmarc_txt=$(php -r 'echo "\"".implode("\"\"", str_split("'"$dmarc_txt"'", 200))."\"";')
dmarc_fqcdn=_dmarc.$DOMAIN
_output=$(curl -X GET \
    -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN/records?type=TXT&name=$dmarc_fqcdn")
CONTENT=$(cat <<- EOF
\$object = (json_decode('$_output'));
if (is_object(\$object)) {
    foreach (\$object->domain_records as \$domain_record) {
        if (\$domain_record->data == '$dmarc_txt') {
            exit(1);
        }
    }
}
EOF
)
php -r "$CONTENT"
if [[ "$?" == "1" ]];then
    echo DNS TXT Record of FQCDN "'"${DOMAIN}"'" for DMARC found in DNS Digital Ocean.
else
    echo DNS TXT Record of FQCDN "'"${DOMAIN}"'" for DMARC NOT found in DNS Digital Ocean.
    echo -n  Trying to create...
    dmarc_txt_json=$(echo "$dmarc_txt" | sed 's,",\\",g')
    _code=$(curl -X POST \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -o /dev/null -s -w "%{http_code}\n" \
        -d '{"type":"TXT","name":"_dmarc","data":"'"$dmarc_txt_json"'","priority":null,"port":null,"ttl":1800,"weight":null,"flags":null,"tag":null}' \
        "https://api.digitalocean.com/v2/domains/$DOMAIN/records")
    case "$_code" in
        201)
            echo ' 'Created.
            ;;
        *)
            echo ' 'Failed.
            echo Unexpected result with response code: $_code.
            echo -e '\033[0;31m'Script terminated.'\033[0m'
            exit 1
    esac
fi

echo -n $'\n''########################################'
echo         '########################################'
echo $'\n''#' CHAPTER 3. SETUP EMAIL
echo -n $'\n''########################################'
echo         '########################################'

# Get the mailuser_id from table mail_user in ispconfig database.
#
# Globals:
#   ispconfig_db_user, ispconfig_db_pass,
#   ispconfig_db_host, ispconfig_db_name
#
# Arguments:
#   $1: user mail
#   $2: host mail
#
# Output:
#   Write mailuser_id to stdout.
getMailUserIdIspconfigByEmail() {
    local email="$1"@"$2"
    local sql="SELECT mailuser_id FROM mail_user WHERE email = '$email';"
    local u="$ispconfig_db_user"
    local p="$ispconfig_db_pass"
    local mailuser_id=$(mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        -h "$ispconfig_db_host" "$ispconfig_db_name" -r -N -s -e "$sql"
    )
    echo "$mailuser_id"
}

# Check if the mailuser_id from table mail_user exists in ispconfig database.
#
# Globals:
#   Used: roundcube_db_user, roundcube_db_pass,
#         roundcube_db_host, roundcube_db_name
#   Modified: mailuser_id
#
# Arguments:
#   $1: user mail
#   $2: host mail
#
# Return:
#   0 if exists.
#   1 if not exists.
isEmailIspconfigExist() {
    mailuser_id=$(getMailUserIdIspconfigByEmail "$1" "$2")
    if [ -n "$mailuser_id" ];then
        return 0
    fi
    return 1
}

# Insert to table mail_user a new record via SOAP.
#
# Globals:
#   Used: roundcube_db_user, roundcube_db_pass,
#         roundcube_db_host, roundcube_db_name
#   Modified: mailuser_id
#
# Arguments:
#   $1: user mail
#   $2: host mail
#
# Return:
#   0 if exists.
#   1 if not exists.
insertEmailIspconfig() {
    local user="$1"
    local host="$2"
    echo $'\n''#' Execute SOAP mail_user_add
    echo Create a temporary file:
    template=mail_user_add
    template_temp=$(isp mktemp "${template}.php")
    template_temp_path=$(isp realpath "$template_temp")
    echo "$template_temp_path"
    sed -i -E ':a;N;$!ba;s/\$params\s+=\s+[^;]+;/\$params = array(\n|PLACEHOLDER|\t);/g' \
        "$template_temp_path"
    password=$(pwgen 9 -1vA0B)
    echo "$password"
    echo "$password" > ~/"roundcube-passwd-user-${user}-host-${host}.txt"
    CONTENT=$(cat <<- EOF
\$replace = '';
\$replace .= "\t\t"."'server_id' => '1',"                                 ."\n";
\$replace .= "\t\t"."'email' => '$user@$host',"                           ."\n";
\$replace .= "\t\t"."'login' => '$user@$host',"                           ."\n";
\$replace .= "\t\t"."'password' => '$password',"                          ."\n";
\$replace .= "\t\t"."'name' => 'Admin',"                                  ."\n";
\$replace .= "\t\t"."'uid' => '5000',"                                    ."\n";
\$replace .= "\t\t"."'gid' => '5000',"                                    ."\n";
\$replace .= "\t\t"."'maildir' => '/var/vmail/$host/$user',"              ."\n";
\$replace .= "\t\t"."'maildir_format' => 'maildir',"                      ."\n";
\$replace .= "\t\t"."'quota' => '0',"                                     ."\n";
\$replace .= "\t\t"."'cc' => '',"                                         ."\n";
\$replace .= "\t\t"."'forward_in_lda' => 'y',"                            ."\n";
\$replace .= "\t\t"."'sender_cc' => '',"                                  ."\n";
\$replace .= "\t\t"."'homedir' => '/var/vmail',"                          ."\n";
\$replace .= "\t\t"."'autoresponder' => 'n',"                             ."\n";
\$replace .= "\t\t"."'autoresponder_start_date' => NULL,"                 ."\n";
\$replace .= "\t\t"."'autoresponder_end_date' => NULL,"                   ."\n";
\$replace .= "\t\t"."'autoresponder_subject' => '',"                      ."\n";
\$replace .= "\t\t"."'autoresponder_text' => '',"                         ."\n";
\$replace .= "\t\t"."'move_junk' => 'Y',"                                 ."\n";
\$replace .= "\t\t"."'purge_trash_days' => 0,"                            ."\n";
\$replace .= "\t\t"."'purge_junk_days' => 0,"                             ."\n";
\$replace .= "\t\t"."'custom_mailfilter' => NULL,"                        ."\n";
\$replace .= "\t\t"."'postfix' => 'y',"                                   ."\n";
\$replace .= "\t\t"."'greylisting' => 'n',"                               ."\n";
\$replace .= "\t\t"."'access' => 'y',"                                    ."\n";
\$replace .= "\t\t"."'disableimap' => 'n',"                               ."\n";
\$replace .= "\t\t"."'disablepop3' => 'n',"                               ."\n";
\$replace .= "\t\t"."'disabledeliver' => 'n',"                            ."\n";
\$replace .= "\t\t"."'disablesmtp' => 'n',"                               ."\n";
\$replace .= "\t\t"."'disablesieve' => 'n',"                              ."\n";
\$replace .= "\t\t"."'disablesieve-filter' => 'n',"                       ."\n";
\$replace .= "\t\t"."'disablelda' => 'n',"                                ."\n";
\$replace .= "\t\t"."'disablelmtp' => 'n',"                               ."\n";
\$replace .= "\t\t"."'disabledoveadm' => 'n',"                            ."\n";
\$replace .= "\t\t"."'disablequota-status' => 'n',"                       ."\n";
\$replace .= "\t\t"."'disableindexer-worker' => 'n',"                     ."\n";
\$replace .= "\t\t"."'last_quota_notification' => NULL,"                  ."\n";
\$replace .= "\t\t"."'backup_interval' => 'none',"                        ."\n";
\$replace .= "\t\t"."'backup_copies' => '1',"                             ."\n";
\$string=file_get_contents('$template_temp_path');
\$string = str_replace('|PLACEHOLDER|', \$replace, \$string);
file_put_contents('$template_temp_path', \$string);
echo \$string;
EOF
    )
    php -r "$CONTENT"
    echo Execute command: isp php "$template_temp"
    isp php "$template_temp"
    echo Cleaning Temporary File.
    echo rm '"'"$template_temp_path"'"'
    rm "$template_temp_path"
    mailuser_id=$(getMailUserIdIspconfigByEmail "$1" "$2")
    if [ -n "$mailuser_id" ];then
        return 0
    fi
    return 1
}

# Get the forwarding_id from table mail_forwarding in ispconfig database.
#
# Globals:
#   ispconfig_db_user, ispconfig_db_pass,
#   ispconfig_db_host, ispconfig_db_name
#
# Arguments:
#   $1: Filter by email source.
#   $2: Filter by email destination.
#
# Output:
#   Write forwarding_id to stdout.
getForwardingIdIspconfigByEmailAlias() {
    local source="$1"
    local destination="$2"
    local sql="SELECT forwarding_id FROM mail_forwarding WHERE source = '$source' and destination = '$destination' and type = 'alias';"
    local u="$ispconfig_db_user"
    local p="$ispconfig_db_pass"
    local forwarding_id=$(mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        -h "$ispconfig_db_host" "$ispconfig_db_name" -r -N -s -e "$sql"
    )
    echo "$forwarding_id"
}

# Check if the email alias (source and destination)
# from table mail_forwarding exists in ispconfig database.
#
# Globals:
#   Used: ispconfig_db_user, ispconfig_db_pass,
#         ispconfig_db_host, ispconfig_db_name
#   Modified: forwarding_id
#
# Arguments:
#   $1: Filter by email source.
#   $2: Filter by email destination.
#
# Return:
#   0 if exists.
#   1 if not exists.
isEmailAliasIspconfigExist() {
    local source="$1"
    local destination="$2"
    forwarding_id=$(getForwardingIdIspconfigByEmailAlias "$source" "$destination")
    if [ -n "$forwarding_id" ];then
        return 0
    fi
    return 1
}

# Insert to table mail_forwarding a new record via SOAP.
#
# Globals:
#   Used: roundcube_db_user, roundcube_db_pass,
#         roundcube_db_host, roundcube_db_name
#   Modified: forwarding_id
#
# Arguments:
#   $1: email destination
#   $2: email alias
#
# Return:
#   0 if exists.
#   1 if not exists.
insertEmailAliasIspconfig() {
    local source="$1"
    local destination="$2"
    echo $'\n''#' Execute SOAP mail_alias_add
    echo Create a temporary file:
    template=mail_alias_add
    template_temp=$(isp mktemp "${template}.php")
    template_temp_path=$(isp realpath "$template_temp")
    echo "$template_temp_path"
    sed -i -E ':a;N;$!ba;s/\$params\s+=\s+[^;]+;/\$params = array(\n|PLACEHOLDER|\t);/g' \
        "$template_temp_path"
    CONTENT=$(cat <<- EOF
\$replace = '';
\$replace .= "\t\t"."'server_id' => '1',"                                 ."\n";
\$replace .= "\t\t"."'source' => '$source',"                              ."\n";
\$replace .= "\t\t"."'destination' => '$destination',"                    ."\n";
\$replace .= "\t\t"."'type' => 'alias',"                                  ."\n";
\$replace .= "\t\t"."'active' => 'y',"                                    ."\n";
\$string=file_get_contents('$template_temp_path');
\$string = str_replace('|PLACEHOLDER|', \$replace, \$string);
file_put_contents('$template_temp_path', \$string);
echo \$string;
EOF
    )
    php -r "$CONTENT"
    echo Execute command: isp php "$template_temp"
    isp php "$template_temp"
    echo Cleaning Temporary File.
    echo rm '"'"$template_temp_path"'"'
    rm "$template_temp_path"
    forwarding_id=$(getForwardingIdIspconfigByEmailAlias "$source" "$destination")
    if [ -n "$forwarding_id" ];then
        return 0
    fi
    return 1
}

# Get the user_id from table users in roundcube database.
#
# Globals:
#   roundcube_db_user, roundcube_db_pass,
#   roundcube_db_host, roundcube_db_name
#
# Arguments:
#   $1: Filter by username.
#
# Output:
#   Write user_id to stdout.
getUserIdRoundcubeByUsername() {
    local username="$1"
    local sql="SELECT user_id FROM users WHERE username = '$username';"
    local u="$roundcube_db_user"
    local p="$roundcube_db_pass"
    local user_id=$(mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        -h "$roundcube_db_host" "$roundcube_db_name" -r -N -s -e "$sql"
    )
    echo "$user_id"
}

# Check if the username from table users exists in roundcube database.
#
# Globals:
#   Used: roundcube_db_user, roundcube_db_pass,
#         roundcube_db_host, roundcube_db_name
#   Modified: user_id
#
# Arguments:
#   $1: username to be checked.
#
# Return:
#   0 if exists.
#   1 if not exists.
isUsernameRoundcubeExist() {
    local username="$1"
    user_id=$(getUserIdRoundcubeByUsername "$username")
    if [ -n "$user_id" ];then
        return 0
    fi
    return 1
}

# Insert the username to table users in roundcube database.
#
# Globals:
#   Used: roundcube_db_user, roundcube_db_pass,
#         roundcube_db_host, roundcube_db_name
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
insertUsernameRoundcube() {
    local username="$1"
    local mail_host="$2"; [ -n "$mail_host" ] || mail_host=localhost
    local language="$3"; [ -n "$language" ] || language=en_US
    local now=$(date +%Y-%m-%d\ %H:%M:%S)
    local sql="INSERT INTO users
        (created, last_login, username, mail_host, language)
        VALUES
        ('$now', '$now', '$username', '$mail_host', '$language');"
    local u="$roundcube_db_user"
    local p="$roundcube_db_pass"
    mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        -h "$roundcube_db_host" "$roundcube_db_name" -e "$sql"
    user_id=$(getUserIdRoundcubeByUsername "$username")
    if [ -n "$user_id" ];then
        return 0
    fi
    return 1
}

# Get the user_id from table users in roundcube database.
#
# Globals:
#   roundcube_db_user, roundcube_db_pass,
#   roundcube_db_host, roundcube_db_name
#
# Arguments:
#   $1: Filter by standard.
#   $2: Filter by email.
#   $3: Filter by user_id.
#
# Output:
#   Write identity_id to stdout.
getIdentityIdRoundcubeByEmail() {
    local standard="$1"
    local email="$2"
    local user_id="$3"
    local sql="SELECT identity_id FROM identities WHERE standard = '$standard' and email = '$email' and user_id = '$user_id';"
    local u="$roundcube_db_user"
    local p="$roundcube_db_pass"
    local identity_id=$(mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        -h "$roundcube_db_host" "$roundcube_db_name" -r -N -s -e "$sql"
    )
    echo "$identity_id"
}

# Check if the username from table users exists in roundcube database.
#
# Globals:
#   Used: roundcube_db_user, roundcube_db_pass,
#         roundcube_db_host, roundcube_db_name
#   Modified: identity_id
#
# Arguments:
#   $1: username to be checked.
#
# Return:
#   0 if exists.
#   1 if not exists.
isIdentitiesRoundcubeExist() {
    local standard="$1"
    local email="$2"
    local user_id="$3"
    identity_id=$(getIdentityIdRoundcubeByEmail "$standard" "$email" "$user_id")
    if [ -n "$identity_id" ];then
        return 0
    fi
    return 1
}

# Insert the username to table users in roundcube database.
#
# Globals:
#   Used: roundcube_db_user, roundcube_db_pass,
#         roundcube_db_host, roundcube_db_name
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
insertIdentitiesRoundcube() {
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
    local u="$roundcube_db_user"
    local p="$roundcube_db_pass"
    mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        -h "$roundcube_db_host" "$roundcube_db_name" -e "$sql"
    identity_id=$(getIdentityIdRoundcubeByEmail "$standard" "$email" "$user_id")
    if [ -n "$identity_id" ];then
        return 0
    fi
    return 1
}

user="$EMAIL_ADMIN"
host="$DOMAIN"
if isEmailIspconfigExist "$user" "$host";then
    echo Email "$user"@"$host" already exists.
    echo \$mailuser_id $mailuser_id
elif insertEmailIspconfig "$user" "$host";then
    echo Email "$user"@"$host" created.
    echo \$mailuser_id $mailuser_id
else
    echo Email "$user"@"$host" failed to create.
    echo -e '\033[0;31m'Script terminated.'\033[0m'
    exit 1
fi
destination="$user"@"$host"
for user in $EMAIL_HOST $EMAIL_WEB $EMAIL_POST
do
    source="$user"@"$host"
    if isEmailAliasIspconfigExist "$source" "$destination";then
        echo Email "$source" alias of "$destination" already exists.
        echo \$forwarding_id $forwarding_id
    elif insertEmailAliasIspconfig "$source" "$destination";then
        echo Email "$source" alias of "$destination" created.
        echo \$forwarding_id $forwarding_id
    else
        echo Email "$source" alias of "$destination" failed to create.
        echo -e '\033[0;31m'Script terminated.'\033[0m'
        exit 1
    fi
done
username=$EMAIL_ADMIN@$DOMAIN
if isUsernameRoundcubeExist "$username";then
    echo Username "$username" already exists.
    echo \$user_id $user_id
elif insertUsernameRoundcube "$username";then
    echo Username "$username" created.
    echo \$user_id $user_id
else
    echo Username "$username" failed to create.
    echo -e '\033[0;31m'Script terminated.'\033[0m'
    exit 1
fi
if isIdentitiesRoundcubeExist 1 "$username" "$user_id";then
    echo Identities "$username" already exists.
    echo \$identity_id $identity_id
elif insertIdentitiesRoundcube 1 "$username" "$user_id" "$EMAIL_ADMIN_IDENTITIES";then
    echo Identities "$username" created.
    echo \$identity_id $identity_id
else
    echo Identities "$username" failed to create.
    echo -e '\033[0;31m'Script terminated.'\033[0m'
    exit 1
fi
for user in $EMAIL_HOST $EMAIL_WEB $EMAIL_POST
do
    source="$user"@"$host"
    echo \$source $source
    if isIdentitiesRoundcubeExist 0 "$source" "$user_id";then
        echo Identities "$source" alias of "$destination" already exists.
        echo \$identity_id $identity_id
    elif insertIdentitiesRoundcube 0 "$source" "$user_id";then
        echo Identities "$source" alias of "$destination" created.
        echo \$identity_id $identity_id
    else
        echo Identities "$source" alias of "$user_id" failed to create.
        echo -e '\033[0;31m'Script terminated.'\033[0m'
        exit 1
    fi
done

echo -n $'\n''########################################'
echo         '########################################'
echo $'\n''#' Script Finished
echo -n $'\n''########################################'
echo         '########################################'
echo $'\n''#' Credentials
echo PHPMyAdmin: "https://$FQCDN_PHPMYADMIN"
echo '   - 'username: $ispconfig_db_user
echo '     'password: $ispconfig_db_pass
echo '   - 'username: $phpmyadmin_db_user
echo '     'password: $phpmyadmin_db_pass
echo '   - 'username: $roundcube_db_user
echo '     'password: $roundcube_db_pass
echo Roundcube: "https://$FQCDN_ROUNDCUBE"
echo '   - 'username: $EMAIL_ADMIN
echo '     'password: $(<~/roundcube-admin-passwd.txt)
echo ISP Config: "https://$FQCDN_ISPCONFIG"
echo '   - 'username: admin
echo '     'password: $(<~/ispconfig-admin-passwd.txt)
echo $'\n''#' Manual Action
echo Command to make sure remote user working properly:
echo -e '   '"\033[36m"isp"\033[m" "\033[33m"php"\033[m" "\033[35m"login.php"\033[m"
echo Command to implement '`isp`' command autocompletion immediately:
echo -e '   '"\033[36m"source"\033[m" "\033[35m"/etc/profile.d/isp-completion.sh"\033[m"
echo Command to check PTR Record:
echo -e '   '"\033[36m"dig"\033[m" "\033[35m"-x"\033[m" "\033[33m""$IP_PUBLIC""\033[m" "\033[35m"+short"\033[m"
if [[ ! $(dig -x $IP_PUBLIC +short) == ${FQCDN}. ]];then
    echo -e $'\n''#' '\033[0;33m'Attention'\033[0m'
    echo Your PTR Record is different with your FQCDN.
    echo '   dig -x '"$IP_PUBLIC"' +short  #' $(dig -x $IP_PUBLIC +short)
    echo '   'echo \$FQCDN'                    #' $FQCDN
    echo Change your droplet name with FQCDN.
    echo More info: https://www.digitalocean.com/community/questions/how-do-i-setup-a-ptr-record
fi
echo
