#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

# Dependencies of this script only.
[ -n "$domain" ] || { red "Value of variable \$domain required."; x; }
[ -n "$ip_address" ] || { red "Value of variable \$ip_address required."; x; }
[ -n "$dns_record" ] || { red "Value of variable \$dns_record required."; x; }

# populate variable
fqdn_phpmyadmin="${subdomain_phpmyadmin}.${domain}"
fqdn_roundcube="${subdomain_roundcube}.${domain}"
fqdn_ispconfig="${subdomain_ispconfig}.${domain}"
mail_provider="$fqdn"

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
____

yellow Modify TXT DNS Record for SPF
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
____

yellow Modify TXT DNS Record for DKIM
data="v=DKIM1; t=s; p=${dns_record}"
php=$(cat <<-'EOF'
$data = $_SERVER['argv'][1];
echo '"'.implode('""', str_split($data, 200)).'"';
EOF
)
data=$(php -r "$php" "$data" )
name_find=$dkim_selector._domainkey.$domain
name_insert=$dkim_selector._domainkey
if isRecordExist TXT $domain $name_find "$data";then
    __ DNS TXT Record of '`'$domain'`' for DKIM found in DNS Digital Ocean.
elif insertRecord TXT $domain $name_insert "$data";then
    __; green DNS TXT Record of '`'$domain'`' for DKIM created in DNS Digital Ocean.
fi
____

yellow Modify TXT DNS Record for DMARC
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
____
