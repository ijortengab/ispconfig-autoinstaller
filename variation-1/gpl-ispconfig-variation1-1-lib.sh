#!/bin/bash

# global used:
# global modified:
# function used: __, green, red, x
fileMustExists() {
    if [ -f "$1" ];then
        __; green File '`'$(basename "$1")'`' ditemukan.
    else
        __; red File '`'$(basename "$1")'`' tidak ditemukan.; x
    fi
}

# global used:
# global modified: found, notfound
# function used: __
isFileExists() {
    found=
    notfound=
    if [ -f "$1" ];then
        __ File '`'$(basename "$1")'`' ditemukan.
        found=1
    else
        __ File '`'$(basename "$1")'`' tidak ditemukan.
        notfound=1
    fi
}

pregQuote() {
    local string="$1"
    # karakter dot (.), menjadi slash dot (\.)
    sed "s/\./\\\./g" <<< "$string"
}

# @todo, ubah juga function ini drupal.
backupFile() {
    local mode="$1"
    local oldpath="$2" i newpath
    i=1
    newpath="${oldpath}.${i}"
    if [ -f "$newpath" ]; then
        let i++
        newpath="${oldpath}.${i}"
        while [ -f "$newpath" ] ; do
            let i++
            newpath="${oldpath}.${i}"
        done
    fi
    case $mode in
        move)
            mv "$oldpath" "$newpath" ;;
        copy)
            local user=$(stat -c "%U" "$oldpath")
            local group=$(stat -c "%G" "$oldpath")
            cp "$oldpath" "$newpath"
            chown ${user}:${group} "$newpath"
    esac
}

databaseCredentialPhpmyadmin() {
    if [ -f /usr/local/share/phpmyadmin/credential/database ];then
        local PHPMYADMIN_DB_USER PHPMYADMIN_DB_USER_PASSWORD PHPMYADMIN_BLOWFISH
        . /usr/local/share/phpmyadmin/credential/database
        phpmyadmin_db_user=$PHPMYADMIN_DB_USER
        phpmyadmin_db_user_password=$PHPMYADMIN_DB_USER_PASSWORD
        phpmyadmin_blowfish=$PHPMYADMIN_BLOWFISH
    else
        phpmyadmin_db_user=$PHPMYADMIN_DB_USER # global variable
        phpmyadmin_db_user_password=$(pwgen -s 32 -1)
        phpmyadmin_blowfish=$(pwgen -s 32 -1)
        mkdir -p /usr/local/share/phpmyadmin/credential
        cat << EOF > /usr/local/share/phpmyadmin/credential/database
PHPMYADMIN_DB_USER=$phpmyadmin_db_user
PHPMYADMIN_DB_USER_PASSWORD=$phpmyadmin_db_user_password
PHPMYADMIN_BLOWFISH=$phpmyadmin_blowfish
EOF
        chmod 0500 /usr/local/share/phpmyadmin/credential
        chmod 0400 /usr/local/share/phpmyadmin/credential/database
    fi
}

databaseCredentialRoundcube() {
    if [ -f /usr/local/share/roundcube/credential/database ];then
        local ROUNDCUBE_DB_USER ROUNDCUBE_DB_USER_PASSWORD ROUNDCUBE_BLOWFISH
        . /usr/local/share/roundcube/credential/database
        roundcube_db_user=$ROUNDCUBE_DB_USER
        roundcube_db_user_password=$ROUNDCUBE_DB_USER_PASSWORD
        roundcube_blowfish=$ROUNDCUBE_BLOWFISH
    else
        roundcube_db_user=$ROUNDCUBE_DB_USER # global variable
        roundcube_db_user_password=$(pwgen -s 32 -1)
        roundcube_blowfish=$(pwgen -s 32 -1)
        mkdir -p /usr/local/share/roundcube/credential
        cat << EOF > /usr/local/share/roundcube/credential/database
ROUNDCUBE_DB_USER=$roundcube_db_user
ROUNDCUBE_DB_USER_PASSWORD=$roundcube_db_user_password
ROUNDCUBE_BLOWFISH=$roundcube_blowfish
EOF
        chmod 0500 /usr/local/share/roundcube/credential
        chmod 0400 /usr/local/share/roundcube/credential/database
    fi
}

databaseCredentialIspconfig() {
    if [ -f /usr/local/share/ispconfig/credential/database ];then
        local ISPCONFIG_DB_NAME ISPCONFIG_DB_USER ISPCONFIG_DB_USER_PASSWORD
        . /usr/local/share/ispconfig/credential/database
        ispconfig_db_name=$ISPCONFIG_DB_NAME
        ispconfig_db_user=$ISPCONFIG_DB_USER
        ispconfig_db_user_password=$ISPCONFIG_DB_USER_PASSWORD
    else
        ispconfig_db_user_password=$(pwgen -s 32 -1)
        mkdir -p /usr/local/share/ispconfig/credential
        cat << EOF > /usr/local/share/ispconfig/credential/database
ISPCONFIG_DB_USER_PASSWORD=$ispconfig_db_user_password
EOF
        chmod 0500 /usr/local/share/ispconfig/credential
        chmod 0400 /usr/local/share/ispconfig/credential/database
    fi
}

websiteCredentialIspconfig() {
    if [ -f /usr/local/share/ispconfig/credential/website ];then
        local ISPCONFIG_WEB_USER_PASSWORD
        . /usr/local/share/ispconfig/credential/website
        ispconfig_web_user_password=$ISPCONFIG_WEB_USER_PASSWORD
    else
        ispconfig_web_user_password=$(pwgen 6 -1vA0B)
        mkdir -p /usr/local/share/ispconfig/credential
        cat << EOF > /usr/local/share/ispconfig/credential/website
ISPCONFIG_WEB_USER_PASSWORD=$ispconfig_web_user_password
EOF
        chmod 0500 /usr/local/share/ispconfig/credential
        chmod 0400 /usr/local/share/ispconfig/credential/website
    fi
}
