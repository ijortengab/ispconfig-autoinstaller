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
