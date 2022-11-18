#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

yellow Mengecek akses root.
if [[ "$EUID" -ne 0 ]]; then
	red This script needs to be run with superuser privileges.; exit
else
    __ Privileges.
fi
____

yellow Mengecek '$PATH'
notfound=
if grep -q '/usr/sbin' <<< "$PATH";then
  __ '$PATH' sudah lengkap.
else
  __ '$PATH' belum lengkap.
  notfound=1
fi

if [[ -n "$notfound" ]];then
    yellow Memperbaiki '$PATH'
    PATH=/usr/local/sbin:/usr/sbin:/sbin:$PATH
    if grep -q '/usr/sbin' <<< "$PATH";then
      __; green '$PATH' sudah lengkap.
    else
      __; green '$PATH' belum lengkap.
      notfound=1
    fi
fi
____

yellow Mengecek shell default
is_dash=
if [[ $(realpath /bin/sh) == '/usr/bin/dash' ]];then
    __ '`'sh'`' command is linked to dash.
    is_dash=1
else
    __ '`'sh'`' command is linked to $(realpath /bin/sh).
fi
____

if [[ -n "$is_dash" ]];then
    yellow Disable dash
    __ '`sh` command link to dash. Disable now.'
    echo "dash dash/sh boolean false" | debconf-set-selections
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
    if [[ $(realpath /bin/sh) == '/usr/bin/dash' ]];then
        __; red '`'sh'`' command link to dash.; exit

    else
        __; green '`'sh'`' command link to $(realpath /bin/sh).
    fi
    ____
fi

yellow Mengecek timezone.
current_timezone=$(timedatectl status | grep 'Time zone:' | grep -o -P "Time zone:\s\K(\S+)")
adjust=
if [[ "$current_timezone" == "$timezone" ]];then
    __ Timezone is match: ${current_timezone}
else
    __ Timezone is different: ${current_timezone}
    adjust=1
fi
____

if [[ -n "$adjust" ]];then
    yellow Adjust timezone.
    timedatectl set-timezone "$timezone"
    current_timezone=$(timedatectl status | grep 'Time zone:' | grep -o -P "Time zone:\s\K(\S+)")
    if [[ "$current_timezone" == "$timezone" ]];then
        __; green Timezone is match: ${current_timezone}
    else
        __; red Timezone is different: ${current_timezone}; exit
    fi
    ____
fi
