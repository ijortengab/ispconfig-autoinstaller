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
IP_PUBLIC=152.118.38.22

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
    __; __; magenta \"s/^\\s*'(.*)'$_fqcdn\\s+$_hostname/$IP_PUBLIC $FQDN $SUBDOMAIN_FQDN/\" \\
    __; __; magenta /etc/hosts
    ____
fi

DOMAIN=systemix.id

# phpJsonDecode() {

# }

getData() {
    local domain=$1
    # cek cache.
    cache_file=/tmp/.cache/api.digitalocean.com/v2/domains/$domain
    if [ -f "$cache_file" ];then
        # json=$(<"$cache_file")
        php -r 'echo json_encode(json_decode(file_get_contents($_SERVER["argv"][1])), JSON_PRETTY_PRINT);' "$cache_file"
    else
        mkdir -p $(dirname "$cache_file")
        curl -X GET \
            -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" -s \
            "https://api.digitalocean.com/v2/domains/$domain" | tee "$cache_file"
    fi
}

getData $DOMAIN
____

# curl -X GET \
    # -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    # -o /dev/null -s -w "%{http_code}\n" \
    # "https://api.digitalocean.com/v2/domains/$DOMAIN"
# __ kita
# curl -X GET \
    # -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    # "https://api.digitalocean.com/v2/domains/$DOMAIN"
# __ kita

# @todo, disable sendmail.
