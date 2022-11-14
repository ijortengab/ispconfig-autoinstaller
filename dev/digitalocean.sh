#!/bin/bash

source /home/ijortengab/gist/var-dump.function.sh

red() { echo -ne "\e[91m"; echo -n "$@"; echo -e "\e[39m"; }
green() { echo -ne "\e[92m"; echo -n "$@"; echo -e "\e[39m"; }
yellow() { echo -ne "\e[93m"; echo -n "$@"; echo -e "\e[39m"; }
blue() { echo -ne "\e[94m"; echo -n "$@"; echo -e "\e[39m"; }
magenta() { echo -ne "\e[95m"; echo -n "$@"; echo -e "\e[39m"; }
x() { exit 1; }
e() { echo "$@"; }
__() { echo -n '    '; [ -n "$1" ] && echo "$@" || echo -n ; }
____() { echo; }

DIGITALOCEAN_TOKEN=c29d24b8c05aa65759f243639f8d868ba4635b3d524a2eb4f5412bae6b6be906

# user input
domain=devel.web.id
subdomain_fqdn=server1
ip_public=206.189.94.130

subdomain_ispconfig=cp
subdomain_phpmyadmin=db
subdomain_roundcube=mail

# populate variable
fqdn="${subdomain_fqdn}.${domain}"
fqdn_phpmyadmin="${subdomain_phpmyadmin}.${domain}"
fqdn_roundcube="${subdomain_roundcube}.${domain}"
fqdn_ispconfig="${subdomain_ispconfig}.${domain}"

if [[ ! $(hostname -f) == $fqdn ]];then
    ____

    yellow Attention.
    __ Your current hostname is different with your input.
    __; magenta hostname -f ' # '$(hostname -f)
    __; magenta \$fqdn'        # '$fqdn
    ____

    yellow Suggestion.
    __ Execute command below then reboot server.
    if [[ ! $(hostname) == $subdomain_fqdn ]];then
        __; magenta echo $subdomain_fqdn' > /etc/hostname'
    fi
    _fqdn=$(hostname -f | sed 's/\./\\./g')
    _hostname=$(hostname)
    __; magenta sed -i -E \\
    __; __; magenta \"s/^\\s*'(.*)'$_fqdn\\s+$_hostname/$ip_public $fqdn $subdomain_fqdn/\" \\
    __; __; magenta /etc/hosts
    ____
fi

isDomainExists() {
    local domain=$1 code
    local dumpfile=$2
    [ -z "$dumpfile" ] && dumpfile=$(mktemp -t digitalocean.XXXXXX)
    magenta "curl https://api.digitalocean.com/v2/domains/$domain"
    code=$(curl -X GET \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        "https://api.digitalocean.com/v2/domains/$domain")
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
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        -d "$reference" \
        "https://api.digitalocean.com/v2/domains")
    json=$(<"$dumpfile")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    magenta "$json_pretty"
    if [[ $code == 201 ]];then
        return 0
    fi
    red Unexpected result with response code: $code.; x
}

isARecordExist() {
    local type="A" php json json_pretty
    local domain="$1"
    local name="$2"
    local ip_public="$3"
    local dumpfile="$4"
    [ -z "$dumpfile" ] && dumpfile=$(mktemp -t digitalocean.XXXXXX)
    magenta "curl https://api.digitalocean.com/v2/domains/$domain/records?type=$type&name=$name"
    code=$(curl -X GET \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        "https://api.digitalocean.com/v2/domains/$domain/records?type=$type&name=$name")
    json=$(<"$dumpfile")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    magenta "$json_pretty"
    if [[ ! $code == 200 ]];then
        red Unexpected result with response code: $code.; x
    fi
    php=$(cat <<-'EOF'
$object = json_decode(fgets(STDIN));
$ip_public = $_SERVER['argv'][1];
if (is_object($object) && isset($object->domain_records)) {
    foreach ($object->domain_records as $domain_record) {
        if ($domain_record->data == $ip_public) {
            exit(0);
        }
    }
}
exit(1);
EOF
)
    php -r "$php" "$ip_public" <<< "$json"
    return $?
}

# global used: DIGITALOCEAN_TOKEN
insertARecord() {
    local domain="$1" name="$2" reference code
    local ip_public="$3"
    local dumpfile="$4"
    [ -z "$dumpfile" ] && dumpfile=$(mktemp -t digitalocean.XXXXXX)
    reference="$(php -r "echo json_encode([
        'type' => 'A',
        'name' => '$name',
        'data' => '$ip_public',
        'priority' => NULL,
        'port' => NULL,
        'ttl' => 1800,
        'weight' => NULL,
        'flags' => NULL,
        'tag' => NULL,
    ]);")"
    magenta "curl -X POST -d '$reference' https://api.digitalocean.com/v2/domains/records"
    code=$(curl -X POST \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        -d "$reference" \
        "https://api.digitalocean.com/v2/domains/$domain/records")
    json=$(<"$dumpfile")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    magenta "$json_pretty"
    if [[ $code == 201 ]];then
        return 0
    fi
    red Unexpected result with response code: $code.; x
}

# global used: DIGITALOCEAN_TOKEN
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
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        "https://api.digitalocean.com/v2/domains/$domain/records?type=$type&name=$name")
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

# global used: DIGITALOCEAN_TOKEN
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
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        -d "$reference" \
        "https://api.digitalocean.com/v2/domains/$domain/records")
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
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -o "$dumpfile" -s -w "%{http_code}\n" \
        "https://api.digitalocean.com/v2/domains/$domain/records/$id")
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

# yellow Modify DNS Record for Domain '`'${domain}'`'
# if isDomainExists $domain;then
    # __ Domain '`'"$domain"'`' found in DNS Digital Ocean.
# elif insertDomain $domain $ip_public;then
    # __; green Domain '`'"$domain"'`' created in DNS Digital Ocean.
# fi
# ____

# yellow Modify A DNS Record for Domain '`'${domain}'`'
# if isARecordExist $domain $domain $ip_public;then
    # __ DNS A Record of '`'${domain}'`' point to IP '`'${ip_public}'`' found in DNS Digital Ocean.
# elif insertARecord $domain '@' $ip_public;then
    # __; green DNS A Record of '`'${domain}'`' point to IP '`'${ip_public}'`' created in DNS Digital Ocean.
# fi
# ____

yellow Modify CNAME DNS Record for Domain '`'${domain}'`'
found=
mktemp=$(mktemp -t digitalocean.XXXXXX)
if isCnameRecordExist $domain $fqdn $mktemp;then
    __ DNS CNAME Record of '`'${subdomain_fqdn}'`' alias to '`'${domain}'`' found in DNS Digital Ocean.
    found=1
else
    __ DNS CNAME Record of '`'${subdomain_fqdn}'`' alias to '`'${domain}'`' NOT found in DNS Digital Ocean.
fi
____

if [ -n "$found" ];then
    while IFS= read -r line; do
        __ Delete record id "$line" of domain "$domain"
        if deleteRecord $domain $line;then
            __; green DNS CNAME Record of '`'${subdomain_fqdn}'`' alias to '`'${domain}'`' deleted in DNS Digital Ocean.
        fi
    done <<< $(getIdRecords "$mktemp")
    ____
fi

# yellow Modify A DNS Record for FQDN '`'$fqdn'`'
# if isARecordExist $domain $fqdn $ip_public;then
    # __ DNS A Record of '`'$fqdn'`' point to IP '`'$ip_public'`' found in DNS Digital Ocean.
# elif insertARecord $domain $subdomain_fqdn $ip_public;then
    # __; green DNS A Record of '`'$fqdn'`' point to IP '`'$ip_public'`' created in DNS Digital Ocean.
# fi
# ____

# yellow Modify CNAME DNS Record for FQDN '`'$fqdn_ispconfig'`'
# if isCnameRecordExist $domain $fqdn_ispconfig;then
    # __ DNS CNAME Record of '`'$fqdn_ispconfig'`' alias to '`'$domain'`' found in DNS Digital Ocean.
# elif insertCnameRecord $domain $subdomain_ispconfig;then
    # __; green DNS CNAME Record of '`'$fqdn_ispconfig'`' alias to '`'$domain'`' created in DNS Digital Ocean.
# fi
# ____

# yellow Modify CNAME DNS Record for FQDN '`'$fqdn_phpmyadmin'`'
# if isCnameRecordExist $domain $fqdn_phpmyadmin;then
    # __ DNS CNAME Record of '`'$fqdn_phpmyadmin'`' alias to '`'$domain'`' found in DNS Digital Ocean.
# elif insertCnameRecord $domain $subdomain_phpmyadmin;then
    # __; green DNS CNAME Record of '`'$fqdn_phpmyadmin'`' alias to '`'$domain'`' created in DNS Digital Ocean.
# fi
# ____

# yellow Modify CNAME DNS Record for FQDN '`'$fqdn_roundcube'`'
# if isCnameRecordExist $domain $fqdn_roundcube;then
    # __ DNS CNAME Record of '`'$fqdn_roundcube'`' alias to '`'$domain'`' found in DNS Digital Ocean.
# elif insertCnameRecord $domain $subdomain_roundcube;then
    # __; green DNS CNAME Record of '`'$fqdn_roundcube'`' alias to '`'$domain'`' created in DNS Digital Ocean.
# fi
# ____
