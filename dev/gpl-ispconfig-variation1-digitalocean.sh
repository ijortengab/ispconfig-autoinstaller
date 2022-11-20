#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

# Dependencies of this script only.
[ -n "$domain" ] || { red "Value of variable \$domain required."; x; }
[ -n "$ip_address" ] || { red "Value of variable \$ip_address required."; x; }

# populate variable
fqdn_phpmyadmin="${subdomain_phpmyadmin}.${domain}"
fqdn_roundcube="${subdomain_roundcube}.${domain}"
fqdn_ispconfig="${subdomain_ispconfig}.${domain}"
mail_provider="$fqdn"

if [[ ! $(hostname -f) == $fqdn ]];then
    ____

    yellow Attention.
    __ Your current hostname is different with your input.
    __; magenta hostname -f ' # '$(hostname -f)
    __; magenta \$fqdn'        # '$fqdn
    ____

    yellow Suggestion.
    __ Execute command below then reboot server.
    if [[ ! $(hostname) == $hostname ]];then
        __; magenta echo $hostname' > /etc/hostname'
    fi
    _fqdn=$(hostname -f | sed 's/\./\\./g')
    _hostname=$(hostname)
    __; magenta sed -i -E \\
    __; __; magenta \"s/^\\s*'(.*)'$_fqdn\\s+$_hostname/$ip_address $fqdn $hostname/\" \\
    __; __; magenta /etc/hosts
    ____
fi

isDomainExists() {
    local domain=$1 code
    local dumpfile=$2
    [ -z "$dumpfile" ] && dumpfile=$(mktemp -t digitalocean.XXXXXX)
    magenta "curl https://api.digitalocean.com/v2/domains/$domain"
    code=$(curl -X GET \
        -H "Authorization: Bearer $digitalocean_token" \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        "https://api.digitalocean.com/v2/domains/$domain")
    sleep .5 # Delay
    json=$(<"$dumpfile")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    magenta "$json_pretty"
    if [[ $code == 200 ]];then
        return 0
    elif [[ $code == 404 ]];then
        return 1
    fi
    red Unexpected result with response code: $code.; x
}

insertDomain() {
    local domain="$1" ip="$2" reference code
    local dumpfile="$3"
    [ -z "$dumpfile" ] && dumpfile=$(mktemp -t digitalocean.XXXXXX)
    reference="$(php -r "echo json_encode([
        'name' => '$domain',
        'ip_address' => '$ip',
    ]);")"
    magenta "curl -X POST -d '$reference' https://api.digitalocean.com/v2/domains/"
    code=$(curl -X POST \
        -H "Authorization: Bearer $digitalocean_token" \
        -H "Content-Type: application/json" \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        -d "$reference" \
        "https://api.digitalocean.com/v2/domains")
    sleep .5 # Delay
    json=$(<"$dumpfile")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    magenta "$json_pretty"
    if [[ $code == 201 ]];then
        return 0
    fi
    red Unexpected result with response code: $code.; x
}

isRecordExist() {
    local type="$1" php json json_pretty
    local domain="$2"
    local name="$3"
    local data="$4"
    local dumpfile="$5"
    [ -z "$dumpfile" ] && dumpfile=$(mktemp -t digitalocean.XXXXXX)
    magenta "curl https://api.digitalocean.com/v2/domains/$domain/records?type=$type&name=$name"
    code=$(curl -X GET \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $digitalocean_token" \
        "https://api.digitalocean.com/v2/domains/$domain/records?type=$type&name=$name")
    sleep .5 # Delay
    json=$(<"$dumpfile")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    magenta "$json_pretty"
    if [[ ! $code == 200 ]];then
        red Unexpected result with response code: $code.; x
    fi
    php=$(cat <<-'EOF'
$object = json_decode(fgets(STDIN));
$data = $_SERVER['argv'][1];
if (is_object($object) && isset($object->domain_records)) {
    foreach ($object->domain_records as $domain_record) {
        if ($domain_record->data == $data) {
            exit(0);
        }
    }
}
exit(1);
EOF
)
    php -r "$php" "$data" <<< "$json"
    return $?
}

isARecordExist() {
    local type="A" php json json_pretty
    local domain="$1"
    local name="$2"
    local ip_address="$3"
    local dumpfile="$4"
    [ -z "$dumpfile" ] && dumpfile=$(mktemp -t digitalocean.XXXXXX)
    magenta "curl https://api.digitalocean.com/v2/domains/$domain/records?type=$type&name=$name"
    code=$(curl -X GET \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $digitalocean_token" \
        "https://api.digitalocean.com/v2/domains/$domain/records?type=$type&name=$name")
    sleep .5 # Delay
    json=$(<"$dumpfile")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    magenta "$json_pretty"
    if [[ ! $code == 200 ]];then
        red Unexpected result with response code: $code.; x
    fi
    php=$(cat <<-'EOF'
$object = json_decode(fgets(STDIN));
$ip_address = $_SERVER['argv'][1];
if (is_object($object) && isset($object->domain_records)) {
    foreach ($object->domain_records as $domain_record) {
        if ($domain_record->data == $ip_address) {
            exit(0);
        }
    }
}
exit(1);
EOF
)
    php -r "$php" "$ip_address" <<< "$json"
    return $?
}

# global used: digitalocean_token
insertARecord() {
    local domain="$1" name="$2" reference code
    local ip_address="$3"
    local dumpfile="$4"
    [ -z "$dumpfile" ] && dumpfile=$(mktemp -t digitalocean.XXXXXX)
    reference="$(php -r "echo json_encode([
        'type' => 'A',
        'name' => '$name',
        'data' => '$ip_address',
        'priority' => NULL,
        'port' => NULL,
        'ttl' => 1800,
        'weight' => NULL,
        'flags' => NULL,
        'tag' => NULL,
    ]);")"
    magenta "curl -X POST -d '$reference' https://api.digitalocean.com/v2/domains/records"
    code=$(curl -X POST \
        -H "Authorization: Bearer $digitalocean_token" \
        -H "Content-Type: application/json" \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        -d "$reference" \
        "https://api.digitalocean.com/v2/domains/$domain/records")
    sleep .5 # Delay
    json=$(<"$dumpfile")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    magenta "$json_pretty"
    if [[ $code == 201 ]];then
        return 0
    fi
    red Unexpected result with response code: $code.; x
}

insertRecord() {
    local type="$1" domain="$2" name="$3" reference code
    local data="$4"
    local dumpfile="$5"
    [ -z "$dumpfile" ] && dumpfile=$(mktemp -t digitalocean.XXXXXX)
    local priority=NULL
    [[ $type == 'MX' ]] && priority=10
    reference="$(php -r "echo json_encode([
        'type' => '$type',
        'name' => '$name',
        'data' => '$data',
        'priority' => $priority,
        'port' => NULL,
        'ttl' => 1800,
        'weight' => NULL,
        'flags' => NULL,
        'tag' => NULL,
    ]);")"
    magenta "curl -X POST -d '$reference' https://api.digitalocean.com/v2/domains/records"
    code=$(curl -X POST \
        -H "Authorization: Bearer $digitalocean_token" \
        -H "Content-Type: application/json" \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        -d "$reference" \
        "https://api.digitalocean.com/v2/domains/$domain/records")
    sleep .5 # Delay
    json=$(<"$dumpfile")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    magenta "$json_pretty"
    if [[ $code == 201 ]];then
        return 0
    fi
    red Unexpected result with response code: $code.; x
}

# global used: digitalocean_token
isCnameRecordExist() {
    local type="CNAME" php json json_pretty total
    local domain="$1"
    local name="$2"
    local dumpfile="$3"
    [ -z "$dumpfile" ] && dumpfile=$(mktemp -t digitalocean.XXXXXX)
    magenta "curl https://api.digitalocean.com/v2/domains/$domain/records?type=$type&name=$name"
    code=$(curl -X GET \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $digitalocean_token" \
        "https://api.digitalocean.com/v2/domains/$domain/records?type=$type&name=$name")
    sleep .5 # Delay
    json=$(<"$dumpfile")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    magenta "$json_pretty"
    if [[ ! $code == 200 ]];then
        red Unexpected result with response code: $code.; x
    fi
    php=$(cat <<-'EOF'
$object = json_decode(fgets(STDIN));
if (isset($object->meta->total) && $object->meta->total > 0) {
    exit(0);
}
exit(1);
EOF
)
    php -r "$php" <<< "$json"
    return $?
}

# global used: digitalocean_token
insertCnameRecord() {
    local domain="$1" reference code
    local name="$2"
    local dumpfile="$3"
    [ -z "$dumpfile" ] && dumpfile=$(mktemp -t digitalocean.XXXXXX)
    reference="$(php -r "echo json_encode([
        'type' => 'CNAME',
        'name' => '$name',
        'data' => '@',
        'priority' => NULL,
        'port' => NULL,
        'ttl' => 1800,
        'weight' => NULL,
        'flags' => NULL,
        'tag' => NULL,
    ]);")"
    magenta "curl -X POST -d '$reference' https://api.digitalocean.com/v2/domains/records"
    code=$(curl -X POST \
        -H "Authorization: Bearer $digitalocean_token" \
        -H "Content-Type: application/json" \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        -d "$reference" \
        "https://api.digitalocean.com/v2/domains/$domain/records")
    sleep .5 # Delay
    json=$(<"$dumpfile")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    magenta "$json_pretty"
    if [[ $code == 201 ]];then
        return 0
    fi
    red Unexpected result with response code: $code.; x
}

deleteRecord() {
    local domain="$1" id="$2"
    local dumpfile="$3"
    [ -z "$dumpfile" ] && dumpfile=$(mktemp -t digitalocean.XXXXXX)
    magenta "curl -X DELETE https://api.digitalocean.com/v2/domains/$domain/records/$id"
    code=$(curl -X DELETE \
        -H "Authorization: Bearer $digitalocean_token" \
        -H "Content-Type: application/json" \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        "https://api.digitalocean.com/v2/domains/$domain/records/$id")
    sleep .5 # Delay
    json=$(<"$dumpfile")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    magenta "$json_pretty"
    if [[ $code == 204 ]];then
        return 0
    fi
    red Unexpected result with response code: $code.; x
}

getIdRecords() {
    local mktemp="$1"
    json=$(<"$mktemp")
    php=$(cat <<-'EOF'
$object = json_decode(fgets(STDIN));
if (isset($object->meta->total) && $object->meta->total > 0) {
    foreach ($object->domain_records as $each) {
        echo $each->id."\n";
    }
}
EOF
)
    php -r "$php" <<< "$json"
}

yellow Modify DNS Record for Domain '`'${domain}'`'
if isDomainExists $domain;then
    __ Domain '`'"$domain"'`' found in DNS Digital Ocean.
elif insertDomain $domain $ip_address;then
    __; green Domain '`'"$domain"'`' created in DNS Digital Ocean.
fi
____

yellow Modify A DNS Record for Domain '`'${domain}'`'
if isRecordExist A $domain $domain $ip_address;then
    __ DNS A Record of '`'${domain}'`' point to IP '`'${ip_address}'`' found in DNS Digital Ocean.
elif insertARecord $domain '@' $ip_address;then
    __; green DNS A Record of '`'${domain}'`' point to IP '`'${ip_address}'`' created in DNS Digital Ocean.
fi
____

yellow Modify CNAME DNS Record for Domain '`'${domain}'`'
found=
mktemp=$(mktemp -t digitalocean.XXXXXX)
if isCnameRecordExist $domain $fqdn $mktemp;then
    __ DNS CNAME Record of '`'$hostname'`' alias to '`'${domain}'`' found in DNS Digital Ocean.
    found=1
else
    __ DNS CNAME Record of '`'$hostname'`' alias to '`'${domain}'`' NOT found in DNS Digital Ocean.
fi
____

if [ -n "$found" ];then
    while IFS= read -r line; do
        __ Delete record id "$line" of domain "$domain"
        if deleteRecord $domain $line;then
            __; green DNS CNAME Record of '`'$hostname'`' alias to '`'${domain}'`' deleted in DNS Digital Ocean.
        fi
    done <<< $(getIdRecords "$mktemp")
    ____
fi

yellow Modify A DNS Record for FQDN '`'$fqdn'`'
if isARecordExist $domain $fqdn $ip_address;then
    __ DNS A Record of '`'$fqdn'`' point to IP '`'$ip_address'`' found in DNS Digital Ocean.
elif insertARecord $domain $hostname $ip_address;then
    __; green DNS A Record of '`'$fqdn'`' point to IP '`'$ip_address'`' created in DNS Digital Ocean.
fi
____

yellow Modify CNAME DNS Record for FQDN '`'$fqdn_ispconfig'`'
if isCnameRecordExist $domain $fqdn_ispconfig;then
    __ DNS CNAME Record of '`'$fqdn_ispconfig'`' alias to '`'$domain'`' found in DNS Digital Ocean.
elif insertCnameRecord $domain $subdomain_ispconfig;then
    __; green DNS CNAME Record of '`'$fqdn_ispconfig'`' alias to '`'$domain'`' created in DNS Digital Ocean.
fi
____

yellow Modify CNAME DNS Record for FQDN '`'$fqdn_phpmyadmin'`'
if isCnameRecordExist $domain $fqdn_phpmyadmin;then
    __ DNS CNAME Record of '`'$fqdn_phpmyadmin'`' alias to '`'$domain'`' found in DNS Digital Ocean.
elif insertCnameRecord $domain $subdomain_phpmyadmin;then
    __; green DNS CNAME Record of '`'$fqdn_phpmyadmin'`' alias to '`'$domain'`' created in DNS Digital Ocean.
fi
____

yellow Modify CNAME DNS Record for FQDN '`'$fqdn_roundcube'`'
if isCnameRecordExist $domain $fqdn_roundcube;then
    __ DNS CNAME Record of '`'$fqdn_roundcube'`' alias to '`'$domain'`' found in DNS Digital Ocean.
elif insertCnameRecord $domain $subdomain_roundcube;then
    __; green DNS CNAME Record of '`'$fqdn_roundcube'`' alias to '`'$domain'`' created in DNS Digital Ocean.
fi
____

yellow Modify MX DNS Record for Domain '`'$domain'`'
if isRecordExist MX $domain $domain $mail_provider;then
    __ DNS MX Record of '`'$domain'`' handled by '`'$mail_provider'`' found in DNS Digital Ocean.
elif insertRecord MX $domain '@' "${mail_provider}.";then
    __; green DNS MX Record of '`'$domain'`' handled by '`'$mail_provider'`' created in DNS Digital Ocean.
fi


data="v=spf1 a:${mail_provider} ~all"
php=$(cat <<-'EOF'
$data = $_SERVER['argv'][1];
echo '"'.implode('""', str_split($data, 200)).'"';
EOF
)
data=$(php -r "$php" "$data" )
if isRecordExist TXT $domain $domain "$data";then
    __ DNS TXT Record of '`'$domain'`' for SPF found in DNS Digital Ocean.
elif insertRecord TXT $domain '@' "$data";then
    __; green DNS TXT Record of '`'$domain'`' for SPF created in DNS Digital Ocean.
fi

yellow Mengecek domain '`'$domain'`' di Module Mail ISPConfig.
php=$(cat <<-'EOF'
$stdin = '';
while (FALSE !== ($line = fgets(STDIN))) {
   $stdin .= $line;
}
$result = unserialize($stdin);
$mode = $_SERVER['argv'][1];
switch ($mode) {
    case 'get_dkim_public':
        echo $result[0]['dkim_public'];
        break;

    case 'get_dkim_selector':
        echo $result[0]['dkim_selector'];
        break;

    case 'get_dkim_private':
        echo $result[0]['dkim_private'];
        break;

    case 'isset':
        if ($result === []) { // empty array
            exit(1); // not found.
        }
        exit(0);
        break;
}
EOF
)
notfound=
__ Create PHP Script from template '`'mail_domain_get_by_domain'`'.
template=mail_domain_get_by_domain
template_temp=$(ispconfig.sh mktemp "${template}.php")
template_temp_path=$(ispconfig.sh realpath "$template_temp")
__; magenta template_temp_path="$template_temp_path"
sed -i -E -e '/echo/d' -e '/^\s*$/d' -e 's,\t,    ,g' -e 's/print_r/echo serialize/' \
    -e 's/\$domain\s+=\s+[^;]+;/\$domain = "'"$domain"'";/' \
    "$template_temp_path"
contents=$(<"$template_temp_path")
__ Execute PHP Script.
magenta "$contents"
stdout=$(ispconfig.sh php "$template_temp")
php -r "$php" isset <<< "$stdout" || notfound=1
if [ -z "$notfound" ];then
    _dkim_selector=$(php -r "$php" get_dkim_selector <<< "$stdout")
    dkim_public=$(php -r "$php" get_dkim_public <<< "$stdout")
    if [[ ! "$dkim_selector" == "$_dkim_selector" ]];then
        __; red Terdapat perbedaan antara dkim_selector versi database dengan user input.
        __; red Menggunakan value versi database.
        __; magenta dkim_selector="$_dkim_selector"
        dkim_selector="$_dkim_selector"
    fi
    dns_record=$(echo "$dkim_public" | sed -e "/-----BEGIN PUBLIC KEY-----/d" -e "/-----END PUBLIC KEY-----/d" | tr '\n' ' ' | sed 's/\ //g')
fi

__ Cleaning temporary file.
__; magenta rm "$template_temp_path"
rm "$template_temp_path"
____

# @todo: jika false,maka nggak ada, maka generate pair code.
json=
if [ -n "$notfound" ];then
    yellow Generate DKIM Public and Private Key
    token=$(pwgen 6 -1)
    . ispconfig.sh export > /dev/null
    dirname="$ispconfig_install_dir/interface/web/mail"
    temp_ajax_get_json="temp_ajax_get_json_${token}.php"
    cp "${dirname}/ajax_get_json.php" "${dirname}/${temp_ajax_get_json}"
    chmod go-r "${dirname}/${temp_ajax_get_json}"
    chmod go-w "${dirname}/${temp_ajax_get_json}"
    chmod go-x "${dirname}/${temp_ajax_get_json}"
    __ Mempersiapkan file '`'${dirname}/${temp_ajax_get_json}'`'
    fileMustExists "${dirname}/${temp_ajax_get_json}"
    sed -i "/\$app->auth->check_module_permissions('mail');/d" "${dirname}/${temp_ajax_get_json}"
    php=$(cat <<- 'EOF'
$dirname = $_SERVER['argv'][1];
$file = $_SERVER['argv'][2];
$domain = $_SERVER['argv'][3];
$dkim_selector = $_SERVER['argv'][4];
chdir($dirname);
$_GET['type'] = 'create_dkim';
$_GET['domain_id'] = $domain;
$_GET['dkim_selector'] = $dkim_selector;
$_GET['dkim_public'] = '';
include_once $file;
EOF
)
    json=$(php -r "$php" "$dirname" "${dirname}/${temp_ajax_get_json}" "$domain" "$dkim_selector")
    __ Cleaning temporary file.
    __; magenta rm "$temp_ajax_get_json"
    rm "${dirname}/${temp_ajax_get_json}"
    ____
fi
if [ -n "$json" ];then
    dkim_private=$(php -r "echo (json_decode(fgets(STDIN)))->dkim_private;" <<< "$json")
    dkim_public=$(php -r "echo (json_decode(fgets(STDIN)))->dkim_public;" <<< "$json")
    dns_record=$(php -r "echo (json_decode(fgets(STDIN)))->dns_record;" <<< "$json")
    yellow Mendaftarkan domain '`'$domain'`' di Module Mail ISPConfig.
    __ Create PHP Script from template '`'mail_domain_add'`'.
    template=mail_domain_add
    template_temp=$(ispconfig.sh mktemp "${template}.php")
    template_temp_path=$(ispconfig.sh realpath "$template_temp")
    __; magenta template_temp_path="$template_temp_path"
    parameter=''
    parameter+="\t\t'server_id' => '1',\n"
    parameter+="\t\t'domain' => '${domain}',\n"
    parameter+="\t\t'active' => 'y',\n"
    parameter+="\t\t'dkim' => 'y',\n"
    parameter+="\t\t'dkim_selector' => '${dkim_selector}',\n"
    parameter+="\t\t'dkim_private' => '"
    while IFS= read -r line; do
        parameter+="${line}\n"
    done <<< "$dkim_private"
    parameter="${parameter:0:-2}"
    parameter+="',\n"
    parameter+="\t\t'dkim_public' => '"
    while IFS= read -r line; do
        parameter+="${line}\n"
    done <<< "$dkim_public"
    parameter="${parameter:0:-2}"
    parameter+="',\n"
    sed -i -E \
        -e ':a;N;$!ba;s|\$params\s+=\s+[^;]+;|\$params = array(\n'"${parameter}"'\n\t);|g' \
        "$template_temp_path"
    sed -i -E -e '/echo/d' -e '/^\s*$/d' -e 's,\t,    ,g' \
        "$template_temp_path"
    contents=$(<"$template_temp_path")
    __ Execute PHP Script.
    magenta "$contents"
    ispconfig.sh php "$template_temp"
    __ Cleaning temporary file.
    __; magenta rm "$template_temp_path"
    rm "$template_temp_path"
    __ Verifikasi:
    php=$(cat <<-'EOF'
$stdin = '';
while (FALSE !== ($line = fgets(STDIN))) {
   $stdin .= $line;
}
$result = unserialize($stdin);
if ($result === []) { // empty array
    exit(1); // not found.
}
exit(0);
EOF
)
    template=mail_domain_get_by_domain
    template_temp=$(ispconfig.sh mktemp "${template}.php")
    template_temp_path=$(ispconfig.sh realpath "$template_temp")
    sed -i -E -e '/echo/d' -e '/^\s*$/d' -e 's,\t,    ,g' -e 's/print_r/echo serialize/' \
        -e 's/\$domain\s+=\s+[^;]+;/\$domain = "'"$domain"'";/' \
        "$template_temp_path"
    contents=$(<"$template_temp_path")
    magenta "$contents"
    notfound=
    ispconfig.sh php "$template_temp" | php -r "$php" || notfound=1
    if [ -n "$notfound" ];then
        __; red Domain gagal terdaftar.; x
    else
        __; green Domain berhasil terdaftar.
    fi
    ____
fi

data="v=DKIM1; t=s; p=${dns_record}"
php=$(cat <<-'EOF'
$data = $_SERVER['argv'][1];
echo '"'.implode('""', str_split($data, 200)).'"';
EOF
)
data=$(php -r "$php" "$data" )

# name_find=$dkim_selector._domainkey.$domain
# name_insert=$dkim_selector._domainkey
# if isRecordExist TXT $domain $name_find "$data";then
    # __ DNS TXT Record of '`'$domain'`' for DKIM found in DNS Digital Ocean.
# elif insertRecord TXT $domain $name_insert "$data";then
    # __; green DNS TXT Record of '`'$domain'`' for DKIM created in DNS Digital Ocean.
# fi

data="v=DMARC1; p=none; rua=${email_post}@${domain}"
php=$(cat <<-'EOF'
$data = $_SERVER['argv'][1];
echo '"'.implode('""', str_split($data, 200)).'"';
EOF
)
data=$(php -r "$php" "$data" )

name_find=_dmarc.$domain
name_insert=_dmarc
if isRecordExist TXT $domain $name_find "$data";then
    __ DNS TXT Record of '`'$domain'`' for DMARC found in DNS Digital Ocean.
elif insertRecord TXT $domain $name_insert "$data";then
    __; green DNS TXT Record of '`'$domain'`' for DMARC created in DNS Digital Ocean.
fi

yellow Script Finished

blue PHPMyAdmin
