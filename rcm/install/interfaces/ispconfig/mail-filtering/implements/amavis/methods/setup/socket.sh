#!/bin/bash

require command systemctl

chapter Mengecek UnitFileState service SpamAssassin.
msg=$(systemctl show spamassassin.service --no-page | grep UnitFileState | grep -o -P "UnitFileState=\K(\S+)")
disable=
if [[ -z "$msg" ]];then
    __ UnitFileState service SpamAssassin not found.
elif [[ "$msg"  == 'enabled' ]];then
    __ UnitFileState service SpamAssassin enabled.
    disable=1
else
    __ UnitFileState service SpamAssassin: $msg.
fi
____

if [ -n "$disable" ];then
    chapter Mematikan service SpamAssassin.
    code systemctl disable --now spamassassin
    systemctl disable --now spamassassin
    msg=$(systemctl show spamassassin.service --no-page | grep UnitFileState | grep -o -P "UnitFileState=\K(\S+)")
    if [[ $msg == 'disabled' ]];then
        __; green Berhasil disabled.; _.
    else
        __; red Gagal disabled.; _.
        __ UnitFileState state: $msg.
        exit
    fi
    ____
fi
