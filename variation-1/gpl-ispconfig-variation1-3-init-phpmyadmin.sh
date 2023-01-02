#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

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
$mode = $_SERVER['argv'][1];
$file = $_SERVER['argv'][2];
$array = unserialize($_SERVER['argv'][3]);
include($file);
$cfg = isset($cfg) ? $cfg : [];
$cfg['blowfish_secret'] = isset($cfg['blowfish_secret']) ? $cfg['blowfish_secret'] : NULL;
$cfg['Servers']['1'] = isset($cfg['Servers']['1']) ? $cfg['Servers']['1'] : [];
$is_different = false;
if ($cfg['blowfish_secret'] != $array['blowfish_secret']) {
    $is_different = true;
}
$result = array_diff_assoc($array['Servers']['1'], $cfg['Servers']['1']);
if (!empty($result)) {
    $is_different = true;
}
switch ($mode) {
    case 'is_different':
        $is_different ? exit(0) : exit(1);
        break;
    case 'save':
        if ($is_different) {
            $cfg = array_replace_recursive($cfg, $array);
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
reference="$(php -r "echo serialize([
    'blowfish_secret' => '$phpmyadmin_blowfish',
    'Servers' => [
        '1' => [
            'controlhost' => '$PHPMYADMIN_DB_USER_HOST',
            'controluser' => '$phpmyadmin_db_user',
            'controlpass' => '$phpmyadmin_db_user_password',
        ],
    ],
]);")"
is_different=
if php -r "$php" is_different \
    /usr/local/share/phpmyadmin/${phpmyadmin_version}/config.inc.php \
    "$reference";then
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
        "$reference"
    if php -r "$php" is_different \
        /usr/local/share/phpmyadmin/${phpmyadmin_version}/config.inc.php \
        "$reference";then
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
        sleep 1
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
