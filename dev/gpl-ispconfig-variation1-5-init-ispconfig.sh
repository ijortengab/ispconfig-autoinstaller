#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

blue ISPConfig
sleep .5
____

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
$mode = $_SERVER['argv'][1];
$file = $_SERVER['argv'][2];
$array = unserialize($_SERVER['argv'][3]);
$autoinstall = parse_ini_file($file);
if (!isset($autoinstall)) {
    exit(255);
}
$is_different = !empty(array_diff_assoc($array, $autoinstall));
switch ($mode) {
    case 'is_different':
        $is_different ? exit(0) : exit(1);
        break;
}
EOF
)

filename_path=/usr/local/ispconfig/interface/web/index.php
filename=$(basename "$filename_path")
yellow Mengecek existing '`'$filename'`'
magenta filename_path=$filename_path
isFileExists "$filename_path"
# VarDump notfound found
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
        cd /tmp
        if [ ! -f /tmp/ISPConfig-3-stable.tar.gz ];then
            wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
        fi
        __ Mengextract ISPConfig
        tar xfz ISPConfig-3-stable.tar.gz
    fi
    if [ ! -f /tmp/ispconfig3_install/install/autoinstall.ini ];then
        __ Membuat file '`'autoinstall.ini'`'.
        cp /tmp/ispconfig3_install/docs/autoinstall_samples/autoinstall.ini.sample \
           /tmp/ispconfig3_install/install/autoinstall.ini
        sed -i -E \
            -e ':a;N;$!ba;s|\[expert\]|[expert]\nconfigure_webserver=n|g' \
            /tmp/ispconfig3_install/install/autoinstall.ini
    fi
    __ Verifikasi file '`'autoinstall.ini'`'.
    mysql_root_passwd="$(<$MYSQL_ROOT_PASSWD)"
    reference="$(php -r "echo serialize([
        'install_mode' => 'expert',
        'configure_webserver' => 'n',
        'hostname' => '$fqdn',
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
        sed -e "s,^install_mode=.*$,install_mode=expert," \
            -e "s,^configure_webserver=.*$,configure_webserver=n," \
            -e "s,^hostname=.*$,hostname=${fqdn}," \
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

    __ Mengecek existing '`'$filename'`'
    fileMustExists "$filename_path" #@todo, apakah ini bisa?

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

    __ Mengubah kepemilikan directory '`'ISPConfig'`'.
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

yellow Menghapus port 8080 buatan ISPConfig
if [ -L /etc/nginx/sites-enabled/000-ispconfig.vhost ];then
    __ Menghapus symlink /etc/nginx/sites-enabled/000-ispconfig.vhost
    rm /etc/nginx/sites-enabled/000-ispconfig.vhost
    if nginx -t 2> /dev/null;then
        nginx -s reload
    else
        red Terjadi kesalahan konfigurasi nginx. Gagal reload nginx.; exit
    fi
fi
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
