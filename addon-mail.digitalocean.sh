# !/bin/bash
# http://ijortengab.id
# https://github.com/ijortengab/ispconfig-autoinstaller

# Dependencies.
command -v "isp" >/dev/null || { echo "isp command not found."; exit 1; }
command -v "php" >/dev/null || { echo "php command not found."; exit 1; }
command -v "curl" >/dev/null || { echo "curl command not found."; exit 1; }
command -v "mysql" >/dev/null || { echo "mysql command not found."; exit 1; }

ispconfig_install_dir=$(isp export | grep ^ispconfig_install_dir | sed 's/^ispconfig_install_dir=//')
roundcube_install_dir=$(isp export | grep ^roundcube_install_dir | sed 's/^roundcube_install_dir=//')
roundcube_config_dir="${roundcube_install_dir}/config"
CONTENT=$(cat <<- EOF
if (file_exists('$ispconfig_install_dir/interface/lib/config.inc.php')) {
    include_once '$ispconfig_install_dir/interface/lib/config.inc.php';
    echo DB_USER."\t".DB_PASSWORD."\t".DB_HOST."\t".DB_DATABASE;
}
EOF
)
output=$(php -r "$CONTENT")
ispconfig_db_user=$(php -r "echo explode(\"\t\", '$output')[0];")
ispconfig_db_pass=$(php -r "echo explode(\"\t\", '$output')[1];")
ispconfig_db_host=$(php -r "echo explode(\"\t\", '$output')[2];")
ispconfig_db_name=$(php -r "echo explode(\"\t\", '$output')[3];")
CONTENT=$(cat <<- EOF
if (file_exists('$roundcube_config_dir/config.inc.php')) {
    include_once '$roundcube_config_dir/config.inc.php';
    echo isset(\$config['db_dsnw']) ? \$config['db_dsnw'] : '';
}
EOF
)
db_dsnw=$(php -r "$CONTENT")
roundcube_db_user=$(php -r "echo parse_url('$db_dsnw', PHP_URL_USER);")
roundcube_db_pass=$(php -r "echo parse_url('$db_dsnw', PHP_URL_PASS);")
roundcube_db_host=$(php -r "echo parse_url('$db_dsnw', PHP_URL_HOST);")
roundcube_db_name=$(php -r "echo ltrim(parse_url('$db_dsnw', PHP_URL_PATH), '/');")
[ -n "$ispconfig_install_dir" ] || { echo "Variable ispconfig_install_dir unknown."; exit 1; }
[ -n "$roundcube_config_dir" ] || { echo "Variable roundcube_config_dir unknown."; exit 1; }
[ -n "$ispconfig_db_user" ] || { echo "Variable ispconfig_db_user unknown."; exit 1; }
[ -n "$ispconfig_db_pass" ] || { echo "Variable ispconfig_db_pass unknown."; exit 1; }
[ -n "$ispconfig_db_host" ] || { echo "Variable ispconfig_db_host unknown."; exit 1; }
[ -n "$ispconfig_db_name" ] || { echo "Variable ispconfig_db_name unknown."; exit 1; }
[ -n "$roundcube_db_user" ] || { echo "Variable roundcube_db_user unknown."; exit 1; }
[ -n "$roundcube_db_pass" ] || { echo "Variable roundcube_db_pass unknown."; exit 1; }
[ -n "$roundcube_db_host" ] || { echo "Variable roundcube_db_host unknown."; exit 1; }
[ -n "$roundcube_db_name" ] || { echo "Variable roundcube_db_name unknown."; exit 1; }

# Input Value.
DOMAIN="$1"
FQCDN_MX="$2"
DIGITALOCEAN_TOKEN="$3"

# Default Value.
SUBDOMAIN_ROUNDCUBE=mail
EMAIL_HOST=hostmaster
VERSION_ROUNDCUBE='1.4.11'
DKIM_SELECTOR=default
EMAIL_ADMIN=admin
EMAIL_ADMIN_IDENTITIES=Admin
EMAIL_HOST=hostmaster
EMAIL_WEB=webmaster
EMAIL_POST=postmaster
[ -n "$DIGITALOCEAN_TOKEN" ] || \
[ -f ~/.digitalocean-token-ispconfig.txt ] && \
DIGITALOCEAN_TOKEN=$(<~/.digitalocean-token-ispconfig.txt)

# Validate Required Value.
until [[ ! -z "$DOMAIN" ]]; do
    read -p "Domain: " DOMAIN
done
until [[ ! -z "$FQCDN_MX" ]]; do
    read -p "MX Hostname: " FQCDN_MX
done
until [[ ! -z "$DIGITALOCEAN_TOKEN" ]]; do
    read -p "DigitalOcean Token API: " DIGITALOCEAN_TOKEN
done
echo "Domain is: ${DOMAIN}"
echo "MX Hostname is: ${FQCDN_MX}"
echo "DigitalOcean token is: $DIGITALOCEAN_TOKEN"

# Additional Value.
FQCDN_ROUNDCUBE="${SUBDOMAIN_ROUNDCUBE}.${DOMAIN}"

echo -n $'\n''########################################'
echo         '########################################'
echo $'\n''#' CHAPTER 1. SETUP WEB SERVER
echo -n $'\n''########################################'
echo         '########################################'

echo $'\n''#' Validate Roundcube.
if [ ! -d /usr/local/share/roundcube/${VERSION_ROUNDCUBE} ];then
    echo 'Roundcube not found.'
    echo -e '\033[0;31m'Script terminated.'\033[0m'
    exit 1
fi
[ -L /usr/local/roundcube ] || ln -sf /usr/local/share/roundcube/${VERSION_ROUNDCUBE} /usr/local/roundcube

echo $'\n''#' Save DigitalOcean Token as File
[ -f ~/.digitalocean-token-ispconfig.ini ] || {
touch      ~/.digitalocean-token-ispconfig.ini
chmod 0700 ~/.digitalocean-token-ispconfig.ini
CONTENT=$(cat <<- EOF
dns_digitalocean_token = $DIGITALOCEAN_TOKEN
EOF
)
echo "$CONTENT" > ~/.digitalocean-token-ispconfig.ini
echo "$DIGITALOCEAN_TOKEN" > ~/.digitalocean-token-ispconfig.txt
}

echo $'\n''#' Modify DNS Record for Domain "'"${DOMAIN}"'"
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
        # @todo, beritahu untuk eksekusi gpl-add-domain.sh
        echo -e '\033[0;31m'Script terminated.'\033[0m'
        exit 1
        ;;
    *)
        echo Domain "'""$DOMAIN""'" failed to query in DNS Digital Ocean.
        echo Unexpected result with response code: $_code.
        echo -e '\033[0;31m'Script terminated.'\033[0m'
        exit 1
esac

echo $'\n''#' Modify CNAME DNS Record for Roundcube
type="CNAME"
name="$FQCDN_ROUNDCUBE"
_total=$(curl -X GET \
    -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    "https://api.digitalocean.com/v2/domains/$DOMAIN/records?type=$type&name=$name" | \
    grep -o '"meta":{"total":.*}}' | \
    sed -E 's/"meta":\{"total":(.*)\}\}/\1/')
if [ $_total -gt 0 ];then
    echo DNS CNAME Record of FQCDN "'"${FQCDN_ROUNDCUBE}"'" found in DNS Digital Ocean.
else
    echo DNS CNAME Record of FQCDN "'"${FQCDN_ROUNDCUBE}"'" NOT found in DNS Digital Ocean.
    echo -n Trying to create...
    type="CNAME"
    name="$SUBDOMAIN_ROUNDCUBE"
    _code=$(curl -X POST \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -o /dev/null -s -w "%{http_code}\n" \
        -d '{"type":"'"$type"'","name":"'"$name"'","data":"@","priority":null,"port":null,"ttl":1800,"weight":null,"flags":null,"tag":null}' \
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

echo $'\n''#' Setup Roundcube Virtual Host
[[ -f /etc/nginx/sites-available/"$FQCDN_ROUNDCUBE" && -L /etc/nginx/sites-enabled/"$FQCDN_ROUNDCUBE" ]] || {
cd      /etc/nginx/sites-available
touch   "$FQCDN_ROUNDCUBE"
cd      /etc/nginx/sites-enabled
ln -sf  ../sites-available/"$FQCDN_ROUNDCUBE" "$FQCDN_ROUNDCUBE"
cd      /etc/nginx/sites-available
echo   "$CONTENT" > "$FQCDN_ROUNDCUBE"
sed -i 's/|SERVER_NAME|/'"$FQCDN_ROUNDCUBE"'/' "$FQCDN_ROUNDCUBE"

echo $'\n''#' Roundcube Adjust Web Root
sed -i  "s,/var/www/${FQCDN_ROUNDCUBE},/usr/local/roundcube," \
        "${FQCDN_ROUNDCUBE}"
nginx -s reload
sleep 1
}

echo $'\n''#' Certbot Request
[ -d /etc/letsencrypt/live/"$FQCDN_ROUNDCUBE" ] || {
certbot -i nginx \
   -n --agree-tos --email "${EMAIL_HOST}@${DOMAIN}" \
   --dns-digitalocean \
   --dns-digitalocean-credentials ~/.digitalocean-token-ispconfig.ini \
   -d "$FQCDN_ROUNDCUBE"
}

echo $'\n''#' HTTPS Request Verification
_code=$(curl -L \
    -o /dev/null -s -w "%{http_code}\n" \
    https://"$FQCDN_ROUNDCUBE")
if [[ "$_code" == 200 ]];then
    echo Success to request https://"$FQCDN_ROUNDCUBE"
else
    echo Failed to request https://"$FQCDN_ROUNDCUBE"
    echo -e '\033[0;31m'Script terminated.'\033[0m'
    exit 1
fi

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
echo Roundcube: "https://$FQCDN_ROUNDCUBE"
user="$EMAIL_ADMIN"
host="$DOMAIN"
echo '   - 'username: $EMAIL_ADMIN
[ -f ~/roundcube-passwd-user-"$user"-host-"$host".txt ] && \
    echo '     'password: $(<~/roundcube-passwd-user-"$user"-host-"$host".txt)
