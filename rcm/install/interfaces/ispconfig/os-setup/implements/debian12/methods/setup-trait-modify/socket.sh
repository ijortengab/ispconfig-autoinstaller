#!/bin/bash

modify-file-debian12() {
    local file=/tmp/ispconfig3_install/install/dist/conf/debian120.conf.php
    [ -f "$file" ] || { error File must exists: "$file".; x; }
    sed -i \
        -e 's,"8\.2","'$php_version'",g' \
        -e 's,/8\.2/,/'$php_version'/,g' \
        -e 's,php8\.2,php'$php_version',g' \
        "$file"
    # Edit informasi cron dan ufw yang terlewat.
    string="//* cron"
    number_1=$(grep -n -F "$string" "$file" | head -1 | cut -d: -f1)
    number_1plus=$((number_1 - 1))
    number_1plus2=$((number_1 + 1))
    part1=$(sed -n '1,'$number_1plus'p' "$file")
    part2=$(sed -n $number_1plus2',$p' "$file")
    additional=$(cat << 'EOF'

//* ufw
$conf['ufw']['installed'] = false;

//* cron
$conf['cron']['installed'] = false;
EOF
        )
    echo "$part1"$'\n'"$additional"$'\n'"$part2" > "$file"
}
createFileDebian12() {
    local source=/tmp/ispconfig3_install/install/dist/conf/debian110.conf.php
    local file=/tmp/ispconfig3_install/install/dist/conf/debian120.conf.php
    if [ ! -f "$file" ];then
        fileMustExists "$source"
        __ Membuat file '`'debian120.conf.php'`'.
        cp "$source" "$file"
        fileMustExists "$file"
        sed -i \
            -e 's,Debian 11,Debian 12,g' \
            -e 's,debian110,debian120,g' \
            -e 's,"7\.4","'$php_version'",g' \
            -e 's,/7\.4/,/'$php_version'/,g' \
            -e 's,php7\.4,php'$php_version',g' \
            "$file"
    fi
    # Edit informasi cron dan ufw yang terlewat.
    string="//* cron"
    number_1=$(grep -n -F "$string" "$file" | head -1 | cut -d: -f1)
    number_1plus=$((number_1 - 1))
    number_1plus2=$((number_1 + 1))
    part1=$(sed -n '1,'$number_1plus'p' "$file")
    part2=$(sed -n $number_1plus2',$p' "$file")
    additional=$(cat << 'EOF'

//* ufw
$conf['ufw']['installed'] = false;

//* cron
$conf['cron']['installed'] = false;
EOF
        )
    echo "$part1"$'\n'"$additional"$'\n'"$part2" > "$file"
}
editInstallLibDebian12() {
    file=/tmp/ispconfig3_install/install/lib/install.lib.php
    string="elseif(substr(trim(file_get_contents('/etc/debian_version')),0,2) == '12')"
    edit=1
    if grep -q -F "$string" "$file";then
        __ File sudah diedit agar terdapat informasi Debian 12: $(basename "$file").
        edit=
    fi
    if [ -n "$edit" ];then
        __ Mengedit file: $(basename "$file").
        string="elseif(substr(trim(file_get_contents('/etc/debian_version')),0,2) == '11')"
        number_1=$(grep -n -F "$string" "$file" | head -1 | cut -d: -f1)
        number_1plus=$((number_1 + 6))
        number_1plus2=$((number_1 + 7))
        part1=$(sed -n '1,'$number_1plus'p' "$file")
        part2=$(sed -n $number_1plus2',$p' "$file")
        additional=$(cat << 'EOF'
            } elseif(substr(trim(file_get_contents('/etc/debian_version')),0,2) == '12') {
                $distname = 'Debian';
                $distver = 'Bookworm';
                $distconfid = 'debian120';
                $distid = 'debian60';
                $distbaseid = 'debian';
                swriteln("Operating System: Debian 12.0 (Bookworm) or compatible\n");
EOF
        )
        echo "$part1"$'\n'"$additional"$'\n'"$part2" > "$file"
        __ Verifikasi.
        if grep -q -F "$string" "$file";then
            __; green File berhasil diedit agar terdapat informasi Debian 12: $(basename "$file").; _.
        else
            __; red File gagal diedit: $(basename "$file"); _.
        fi
    fi
}
