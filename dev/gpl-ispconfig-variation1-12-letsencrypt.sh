#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

# Dependencies of this script only.
[ -n "$domain" ] || { red "Value of variable \$domain required."; x; }

# populate variable
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

yellow Mengecek '$PATH'
magenta PATH="$PATH"
notfound=
if grep -q '/snap/bin' <<< "$PATH";then
  __ '$PATH' sudah lengkap.
else
  __ '$PATH' belum lengkap.
  notfound=1
fi

if [[ -n "$notfound" ]];then
    yellow Memperbaiki '$PATH'
    PATH=/snap/bin:$PATH
    if grep -q '/snap/bin' <<< "$PATH";then
      __; green '$PATH' sudah lengkap.
      __; magenta PATH="$PATH"

    else
      __; red '$PATH' belum lengkap.; x
    fi
fi
____

yellow Certbot Request for '`'$fqdn_ispconfig'`'
if [ -d /etc/letsencrypt/live/"$fqdn_ispconfig" ];then
    __ Certificate berada pada direktori '`'/etc/letsencrypt/live/$fqdn_ispconfig/'`'
else
    __ Save DigitalOcean Token as File
    mktemp=$(mktemp -t digitalocean.XXXXXX.ini)
    chmod 0700 "$mktemp"
    cat << EOF > "$mktemp"
dns_digitalocean_token = $digitalocean_token
EOF
    __; fileMustExists "$mktemp"
    __; magenta certbot -i nginx -d "$fqdn_ispconfig" -d "$fqdn_phpmyadmin" -d "$fqdn_roundcube"
    certbot -i nginx \
       -n --agree-tos --email "${mailbox_host}@${domain}" \
       --dns-digitalocean \
       --dns-digitalocean-credentials "$mktemp" \
       -d "$fqdn_ispconfig" \
       -d "$fqdn_phpmyadmin" \
       -d "$fqdn_roundcube"
    __ Cleaning File Temporary
    __; magenta rm "$mktemp"
    rm "$mktemp"
fi
____
