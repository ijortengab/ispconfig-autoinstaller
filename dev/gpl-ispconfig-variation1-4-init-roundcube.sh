#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

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
$mode = $_SERVER['argv'][1];
$file = $_SERVER['argv'][2];
$array = unserialize($_SERVER['argv'][3]);
include($file);
$config = isset($config) ? $config : [];
$is_different = !empty(array_diff_assoc($array, $config));
switch ($mode) {
    case 'is_different':
        $is_different ? exit(0) : exit(1);
        break;
    case 'save':
        if ($is_different) {
            $config = array_replace_recursive($config, $array);
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

reference="$(php -r "echo serialize([
    'des_key' => '$roundcube_blowfish',
    'db_dsnw' => 'mysql://${roundcube_db_user}:${roundcube_db_user_password}@${ROUNDCUBE_DB_USER_HOST}/${ROUNDCUBE_DB_NAME}',
    'smtp_host' => 'localhost:25',
    'smtp_user' => '',
    'smtp_pass' => '',
    'identities_level' => '3',
    'username_domain' => '%t',
    'default_list_mode' => 'threads',
]);")"

is_different=
if php -r "$php" is_different \
    /usr/local/share/roundcube/${roundcube_version}/config/config.inc.php \
    "$reference";then
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
        "$reference"
    if php -r "$php" is_different \
        /usr/local/share/roundcube/${roundcube_version}/config/config.inc.php \
        "$reference";then
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
