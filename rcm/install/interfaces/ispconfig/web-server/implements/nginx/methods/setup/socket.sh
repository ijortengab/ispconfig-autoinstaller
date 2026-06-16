#!/bin/bash

# Dependency.
require command systemctl
require command link-symbolic
require rcm nginx reload

# Define variables and constants.
rcm_nginx_reload=

# Require, validate, and populate value.
# -

chapter Mengecek UnitFileState service Apache2. # Menginstall PHP di Debian, biasanya auto install juga Apache2.
msg=$(systemctl show apache2.service --no-page | grep UnitFileState | grep -o -P "UnitFileState=\K(\S+)")
disable=
if [[ -z "$msg" ]];then
    __ UnitFileState service Apache2 not found.
elif [[ "$msg"  == 'enabled' ]];then
    __ UnitFileState service Apache2 enabled.
    disable=1
else
    __ UnitFileState service Apache2: $msg.
fi
____

if [ -n "$disable" ];then
    chapter Mematikan service Apache2.
    code systemctl disable --now apache2
    systemctl disable --now apache2
    msg=$(systemctl show apache2.service --no-page | grep UnitFileState | grep -o -P "UnitFileState=\K(\S+)")
    if [[ $msg == 'disabled' ]];then
        __; green Berhasil disabled.; _.
    else
        __; red Gagal disabled.; _.
        __ UnitFileState state: $msg.
        exit
    fi
    ____
fi

chapter Mengecek ActiveState service Nginx. # Kadang bentrok dengan Apache2.
msg=$(systemctl show nginx.service --no-page | grep ActiveState | grep -o -P "^ActiveState=\K(\S+)")
restart=
if [[ -z "$msg" ]];then
    __; red Service nginx tidak ditemukan.; x
elif [[ "$msg"  == 'active' ]];then
    __ Service nginx active.
else
    __ Service ActiveState nginx: $msg.
    restart=1
fi
____

if [ -n "$restart" ];then
    chapter Menjalankan service nginx.
    code systemctl enable --now nginx
    systemctl enable --now nginx
    msg=$(systemctl show nginx.service --no-page | grep ActiveState | grep -o -P "ActiveState=\K(\S+)")
    if [[ $msg == 'active' ]];then
        __; green Berhasil activated.; _.
    else
        __; red Gagal activated.; _.
        __ ActiveState state: $msg.
        exit
    fi
    ____
fi

chapter Membatasi akses ke localhost.

if [ -f /etc/nginx/sites-available/default ];then
    __ Backup file /etc/nginx/sites-available/default
    backup-file move /etc/nginx/sites-available/default
    rcm_nginx_reload=1
fi
if [ ! -f /etc/nginx/sites-available/default_deny ];then
    cat <<'EOF' > /etc/nginx/sites-available/default_deny
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html;
    server_name _;
    location / {
        deny all;
    }
}
EOF
    rcm_nginx_reload=1
fi
____

source=/etc/nginx/sites-available/default_deny
target=/etc/nginx/sites-enabled/default_deny
link-symbolic "$source" "$target"

if [ -n "$rcm_nginx_reload" ];then
    INDENT+="    " \
    rcm nginx reload \
        ; [ ! $? -eq 0 ] && x
fi

chapter Mengecek HTTP Response Code.
i=0
code=
if [ -z "$tempfile" ];then
    tempfile=$(mktemp -p /dev/shm -t rcm-nginx-setup-ispconfig.XXXXXX)
fi
until [ $i -eq 10 ];do
    __; magenta curl -o /dev/null -s -w '"'%{http_code}\\n'"' '"'http://127.0.0.1'"'; _.
    curl -o /dev/null -s -w "%{http_code}\n" "http://127.0.0.1" > $tempfile
    while read line; do e "$line"; _.; done < $tempfile
    code=$(head -1 $tempfile)
    if [ "$code" -eq 403 ];then
        break
    else
        __ Retry.
        __; magenta sleep .5; _.
        sleep .5
    fi
    let i++
done
if [ "$code" -eq 403 ];then
    __ HTTP Response code '`'$code'`' '('Required')'.
else
    __; red Terjadi kesalahan. HTTP Response code '`'$code'`'.; x
fi
____

if [ -n "$tempfile" ];then
    rm "$tempfile"
fi
