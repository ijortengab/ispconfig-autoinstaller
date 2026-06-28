#!/bin/bash


# @todo, hapus ini.


modify-file-debian11() {
    local file=/tmp/ispconfig3_install/install/dist/conf/debian110.conf.php
    isFileExists "$file"
    [ -n "$notfound" ] && fileMustExists "$file"
    if [[ ! "$php_version" == 7.4 ]];then
        sed -i \
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
