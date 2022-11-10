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

FQDN=server1.systemix.id
ip_public=152.118.38.22

SUBDOMAIN_FQDN=server1

if [[ ! $(hostname -f) == $FQDN ]];then
    ____

    yellow Attention.
    __ Your current hostname is different with your input.
    __; magenta hostname -f ' # '$(hostname -f)
    __; magenta \$FQDN'        # '$FQDN
    ____

    yellow Suggestion.
    __ Execute command below then reboot server.
    if [[ ! $(hostname) == $SUBDOMAIN_FQDN ]];then
        __; magenta echo $SUBDOMAIN_FQDN' > /etc/hostname'
    fi
    _fqcdn=$(hostname -f | sed 's/\./\\./g')
    _hostname=$(hostname)
    __; magenta sed -i -E \\
    __; __; magenta \"s/^\\s*'(.*)'$_fqcdn\\s+$_hostname/$ip_public $FQDN $SUBDOMAIN_FQDN/\" \\
    __; __; magenta /etc/hosts
    ____
fi

domain=systemix.id
domain=devel.web.id
ip_public=206.189.94.130

isDomainExists() {
    local domain=$1 code
    code=$(curl -X GET \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -o /dev/null -s -w "%{http_code}\n" \
        "https://api.digitalocean.com/v2/domains/$domain")
    if [[ $code == 200 ]];then
        return 0
    elif [[ $code == 404 ]];then
        return 1
    fi
    red Unexpected result with response code: $code.;
    json=$(curl -X GET \
            -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
            -s \
            "https://api.digitalocean.com/v2/domains/$domain")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    magenta "$json_pretty"; x
}

insertDomain() {
    local domain="$1" ip="$2" code
    code=$(curl -X POST \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -o /dev/null -s -w "%{http_code}\n" \
        -d '{"name":"'""$domain""'","ip_address":"'"$ip"'"}' \
        "https://api.digitalocean.com/v2/domains")
    if [[ $code == 201 ]];then
        return 0
    fi
    red Unexpected result with response code: $code.;
    json=$(curl -X POST \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        -H "Content-Type: application/json" \
        -s \
        -d '{"name":"'""$domain""'","ip_address":"'"$ip"'"}' \
        "https://api.digitalocean.com/v2/domains")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    magenta "$json_pretty"; x
}

yellow Modify DNS Record for Domain "'"${domain}"'"
# if isDomainExists $domain;then
    # __ Domain "'""$domain""'" found in DNS Digital Ocean.
# elif insertDomain $domain $ip_public;then
    # __; green Domain "'""$domain""'" created in DNS Digital Ocean.
# fi
____ 

isARecordExist() {
    local type="A" php json json_pretty
    local domain="$2"
    local name="$3"
    json=$(curl -X GET \
        -s \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
        "https://api.digitalocean.com/v2/domains/$domain/records?type=$type&name=$name")
    json_pretty=$(php -r "echo json_encode(json_decode(fgets(STDIN)), JSON_PRETTY_PRINT).PHP_EOL;" <<< "$json")
    # magenta "$json_pretty"; x
    php=$(cat <<-'EOF'
$object = json_decode(fgets(STDIN));
var_dump($object);
EOF
)
    php -r "$php" <<< "$json"
}

yellow Modify A DNS Record for Domain "'"${domain}"'"
if isARecordExist $domain $domain;then
    echo -n
fi

