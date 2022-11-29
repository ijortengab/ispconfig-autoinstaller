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

# Mencari root
yellow Mengecek nginx configuration apakah terdapat web root dari PHPMyAdmin
notfound=
root=/usr/local/share/phpmyadmin/${phpmyadmin_version}
string_quoted=$(pregQuote "$root")
file_config=$(grep -R -l -E "^\s*root\s+${string_quoted}\s*;" /etc/nginx/sites-enabled | head -1)
# File config sebelumnya sudah digunakan oleh subdomain localhost.
[ -n "$file_config" ] || {
    __; red File config not found.; exit
} && {
    __ File config found.
}
file_config=$(realpath $file_config)
____

yellow Mengecek domain '`'$fqdn_phpmyadmin'`' di nginx config.
string="$fqdn_phpmyadmin"
string_quoted=$(pregQuote "$string")
if grep -q -E "^\s*server_name\s+.*$string_quoted.*;\s*$" "$file_config";then
    __ Domain "$string" sudah terdapat pada file config.
else
    __ Domain "$string" belum terdapat pada file config.
    notfound=1
fi
if [ -n "$notfound" ];then
    sed -i -E "s/server_name([^;]+);/server_name\1 "${string}";/" "$file_config"
    if grep -q -E "^\s*server_name\s+.*$string_quoted.*;\s*$" "$file_config";then
        __; green Domain "$string" sudah terdapat pada file config.
        reload=1
    else
        __; red Domain "$string" belum terdapat pada file config.; exit
    fi
fi
____

# Mencari root
yellow Mengecek nginx configuration apakah terdapat web root dari RoundCube
notfound=
root=/usr/local/share/roundcube/${roundcube_version}
string_quoted=$(pregQuote "$root")
file_config=$(grep -R -l -E "^\s*root\s+${string_quoted}\s*;" /etc/nginx/sites-enabled | head -1)
# File config sebelumnya sudah digunakan oleh subdomain localhost.
[ -n "$file_config" ] || {
    __; red File config not found.; exit
} && {
    __ File config found.
}
file_config=$(realpath $file_config)
____

yellow Mengecek domain '`'$fqdn_roundcube'`' di nginx config.
string="$fqdn_roundcube"
string_quoted=$(pregQuote "$string")
if grep -q -E "^\s*server_name\s+.*$string_quoted.*;\s*$" "$file_config";then
    __ Domain "$string" sudah terdapat pada file config.
else
    __ Domain "$string" belum terdapat pada file config.
    notfound=1
fi
if [ -n "$notfound" ];then
    sed -i -E "s/server_name([^;]+);/server_name\1 "${string}";/" "$file_config"
    if grep -q -E "^\s*server_name\s+.*$string_quoted.*;\s*$" "$file_config";then
        __; green Domain "$string" sudah terdapat pada file config.
        reload=1
    else
        __; red Domain "$string" belum terdapat pada file config.; exit
    fi
fi
____

# Mencari root
yellow Mengecek nginx configuration apakah terdapat web root dari ISPConfig
notfound=
root=/usr/local/ispconfig/interface/web
string_quoted=$(pregQuote "$root")
file_config=$(grep -R -l -E "^\s*root\s+${string_quoted}\s*;" /etc/nginx/sites-enabled | head -1)
# File config sebelumnya sudah digunakan oleh subdomain localhost.
[ -n "$file_config" ] || {
    __; red File config not found.; exit
} && {
    __ File config found.
}
file_config=$(realpath $file_config)
____

yellow Mengecek domain '`'$fqdn_ispconfig'`' di nginx config.
string="$fqdn_ispconfig"
string_quoted=$(pregQuote "$string")
if grep -q -E "^\s*server_name\s+.*$string_quoted.*;\s*$" "$file_config";then
    __ Domain "$string" sudah terdapat pada file config.
else
    __ Domain "$string" belum terdapat pada file config.
    notfound=1
fi
if [ -n "$notfound" ];then
    sed -i -E "s/server_name([^;]+);/server_name\1 "${string}";/" "$file_config"
    if grep -q -E "^\s*server_name\s+.*$string_quoted.*;\s*$" "$file_config";then
        __; green Domain "$string" sudah terdapat pada file config.
        reload=1
    else
        __; red Domain "$string" belum terdapat pada file config.; exit
    fi
fi
____

yellow Save DigitalOcean Token as File
mktemp=$(mktemp -t digitalocean.XXXXXX.ini)
chmod 0700 "$mktemp"
cat << EOF > "$mktemp"
dns_digitalocean_token = $digitalocean_token
EOF
____

yellow Certbot Request
[ -d /etc/letsencrypt/live/"$fqdn_ispconfig" ] || {
certbot -i nginx \
   -n --agree-tos --email "${mailbox_host}@${domain}" \
   --dns-digitalocean \
   --dns-digitalocean-credentials "$mktemp" \
   -d "$fqdn_ispconfig" \
   -d "$fqdn_phpmyadmin" \
   -d "$fqdn_roundcube"
}
