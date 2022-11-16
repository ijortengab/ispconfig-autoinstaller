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

aptinstalled=$(apt --installed list 2>/dev/null)

yellow Mengecek apakah snap installed.
notfound=
if grep -q "^snapd/" <<< "$aptinstalled";then
    __ Snap installed.
else
    __ Snap not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menginstall snap
    magenta apt install snapd -y
    apt install snapd -y
    aptinstalled=$(apt --installed list 2>/dev/null)
    if grep -q "^snapd/" <<< "$aptinstalled";then
        __; green Snap installed.
    else
        __; red Snap not found.; exit
    fi
    ____
fi

command -v "snap" >/dev/null || {
    [ -f /etc/profile.d/apps-bin-path.sh ] && . /etc/profile.d/apps-bin-path.sh
}

yellow Mengecek apakah snap core installed.
notfound=
if grep '^core\s' <<< $(snap list core);then
    __ Snap core installed.
else
    __ Snap core not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menginstall snap core
    magenta snap install core
    magenta snap refresh core
    snap install core
    snap refresh core
    if grep '^core\s' <<< $(snap list core);then
        __; green Snap core installed.
    else
        __; red Snap core not found.; x
    fi
    ____
fi

yellow Mengecek apakah snap certbot installed.
notfound=
if grep '^certbot\s' <<< $(snap list certbot);then
    __ Snap certbot installed.
else
    __ Snap certbot not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menginstall snap certbot
    magenta snap install --classic certbot
    snap install --classic certbot
    snap set certbot trust-plugin-with-root=ok
    if grep '^certbot\s' <<< $(snap list certbot);then
        __; green Snap certbot installed.
    else
        __; red Snap certbot not found.; x
    fi
    ____
fi

# @todo, jika tidak dengan dns gimana?

yellow Mengecek apakah snap certbot-dns-digitalocean installed.
notfound=
if grep '^certbot-dns-digitalocean\s' <<< $(snap list certbot-dns-digitalocean);then
    __ Snap certbot-dns-digitalocean installed.
else
    __ Snap certbot-dns-digitalocean not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menginstall snap certbot-dns-digitalocean
    magenta snap install certbot-dns-digitalocean
    magenta snap refresh certbot
    snap install certbot-dns-digitalocean
    snap refresh certbot
    if grep '^certbot-dns-digitalocean\s' <<< $(snap list certbot-dns-digitalocean);then
        __; green Snap certbot-dns-digitalocean installed.
    else
        __; red Snap certbot-dns-digitalocean not found.; x
    fi
    ____
fi

# printf "[client]\nuser = %s\npassword = %s\n" "root" "$mysql_root_passwd" > "$MYSQL_ROOT_PASSWD_INI"

# cetak() {
    # local file=$1
    # echo '----'
    # cat $file
    # echo '0000'
# }
# echo cetak <(printf "dns_digitalocean_token = %s\n" "$DIGITALOCEAN_TOKEN") 
# cetak <(printf "dns_digitalocean_token = %s\n" "$DIGITALOCEAN_TOKEN")
