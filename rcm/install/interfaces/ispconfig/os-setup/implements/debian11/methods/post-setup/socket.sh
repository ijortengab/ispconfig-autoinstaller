#!/bin/bash

include `rcm plugin run-parent-method ispconfig/os-setup debian post-setup`

require command systemctl
require command netstat

# Functions.
RcmAmavisSetupIspconfig_startTweak() {
    __; magenta chown -R root:amavis /etc/amavis/; _.
    __; magenta chmod 644 /etc/amavis/50-user~; _.
    __; magenta chmod 644 /etc/amavis/conf.d/50-user; _.
    __; magenta service amavis restart; _.
    __; magenta chmod 750 /etc/amavis/conf.d; _.
    tweak=
    restart=
    if [ $(stat /etc/amavis -c %G) == amavis ];then
        __ Directory '`'/etc/amavis'`' bagian dari Group '`'amavis'`'.
    else
        __ Directory '`'/etc/amavis'`' bukan bagian dari Group '`'amavis'`'.
        tweak=1
    fi
    if [ -n "$tweak" ];then
        chown -R root:amavis /etc/amavis/
        restart=1
        if [ $(stat ${stat_cached} /etc/amavis -c %G) == amavis ];then
            __; green Directory '`'/etc/amavis'`' bagian dari Group '`'amavis'`'.; _.
        else
            __; red Directory '`'/etc/amavis'`' bukan bagian dari Group '`'amavis'`'.; x
        fi
    fi
    if [ -f /etc/amavis/50-user~ ];then
        tweak=
        if [[ $(stat /etc/amavis/50-user~ -c %a) == 644 ]];then
            __ File  '`'/etc/amavis/50-user~'`' memiliki permission '`'644'`'.
        else
            __ File  '`'/etc/amavis/50-user~'`' tidak memiliki permission '`'644'`'.
            tweak=1
        fi
        if [ -n "$tweak" ];then
            chmod 644 /etc/amavis/50-user~
            restart=1
            if [[ -f /etc/amavis/50-user~ && $(stat ${stat_cached} /etc/amavis/50-user~ -c %a) == 644 ]];then
                __; green File  '`'/etc/amavis/50-user~'`' memiliki permission '`'644'`'.; _.
            else
                __; red File  '`'/etc/amavis/50-user~'`' tidak memiliki permission '`'644'`'.; x
            fi
        fi
    fi
    if [ -f /etc/amavis/conf.d/50-user ];then
        tweak=
        if [[ $(stat /etc/amavis/conf.d/50-user -c %a) == 644 ]];then
            __ File  '`'/etc/amavis/conf.d/50-user'`' memiliki permission '`'644'`'.
        else
            __ File  '`'/etc/amavis/conf.d/50-user'`' tidak memiliki permission '`'644'`'.
            tweak=1
        fi
        if [ -n "$tweak" ];then
            chmod 644 /etc/amavis/conf.d/50-user
            restart=1
            if [[ -f /etc/amavis/conf.d/50-user && $(stat ${stat_cached} /etc/amavis/conf.d/50-user -c %a) == 644 ]];then
                __; green File  '`'/etc/amavis/conf.d/50-user'`' memiliki permission '`'644'`'.; _.
            else
                __; red File  '`'/etc/amavis/conf.d/50-user'`' tidak memiliki permission '`'644'`'.; x
            fi
        fi
    fi
    if [ -d /etc/amavis/conf.d ];then
        tweak=
        if [[ $(stat /etc/amavis/conf.d -c %a) == 750 ]];then
            __ Directory  '`'/etc/amavis/conf.d'`' memiliki permission '`'750'`'.
        else
            __ Directory  '`'/etc/amavis/conf.d'`' tidak memiliki permission '`'750'`'.
            tweak=1
        fi
        if [ -n "$tweak" ];then
            chmod 750 /etc/amavis/conf.d
            restart=1
            if [[ -d /etc/amavis/conf.d && $(stat ${stat_cached} /etc/amavis/conf.d -c %a) == 750 ]];then
                __; green Directory  '`'/etc/amavis/conf.d'`' memiliki permission '`'750'`'.; _.
            else
                __; red Directory  '`'/etc/amavis/conf.d'`' tidak memiliki permission '`'750'`'.; x
            fi
        fi
    fi
    msg=$(systemctl show amavis.service --no-page | grep ActiveState | grep -o -P "ActiveState=\K(\S+)")
    if [ ! "$msg" == 'active' ];then
        restart=1
    fi
    if [ -n "$restart" ];then
        __; magenta restart="$restart"; _.
        __ Merestart amavis.
        code systemctl restart amavis.service
        systemctl restart amavis.service
        countdown=5
        while [ "$countdown" -ge 0 ]; do
            printf "\r\033[K" >&2
            printf %"$countdown"s | tr " " "." >&2
            printf "\r"
            countdown=$((countdown - 1))
            sleep .8
        done
    fi
    stdout=$(netstat -tpn --listening | grep 10026 | grep amavisd)
    if [ -z "$stdout" ];then
        __; red Port 10026 tidak ditemukan.; x
    else
        __; green Port 10026 ditemukan.; _.
    fi
    ____
}

vercomp() {
    # https://www.google.com/search?q=bash+compare+version
    # https://stackoverflow.com/a/4025065
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]];then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}

# Requirement, validate, and populate value.
chapter Variable dump.
declare -i countdown
vercomp `stat --version | head -1 | grep -o -E '\S+$'` 8.31
if [[ $? -lt 2 ]];then
    stat_cached=' --cached=never'
else
    stat_cached=''
fi
____

chapter Memastikan amavis terinstall dan running.
stdout=$(systemctl show amavis.service --no-page | grep MainPID | grep -o -P "^MainPID=\K(\S+)")
if [ -n "$stdout" ];then
    __ Amavis Service berjalan dengan Main PID=$stdout
else
    __ Amavis Service tidak berjalan.
fi
____

chapter Memastikan amavis port 10026 listening.
stdout=$(netstat -tpn --listening | grep 10026 | grep amavisd)
if [ -n "$stdout" ];then
    skip=1
    __ Port 10026 ditemukan.
else
    __ Port 10026 tidak ditemukan.
    RcmAmavisSetupIspconfig_startTweak
fi
____
