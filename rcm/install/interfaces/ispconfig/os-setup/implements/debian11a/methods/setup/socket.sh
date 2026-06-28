#!/bin/bash

include `rcm plugin run-parent-method ispconfig/os-setup debian11 setup`

# Source: ISPConfigDebianOS::runPerfectSetup()
chapter Mengecek existing ISPConfig.
path=/usr/local/ispconfig/server/lib/config.inc.php
code 'path="'$path'"'
do_install=
if [ -f "$path" ]; then
    __ File '`'$path'`' found.
    __ The server already has ISPConfig installed.;
else
    __ File '`'$path'`' not found.;
    __ Installation is continue.
    do_install=1
fi
____

if [ -n "$do_install" ];then

    # use-trait utamanya digunakan untuk me-load function-function yang
    # digunakan bersama-sama.
    include `rcm plugin use-trait ispconfig/os-setup base setup-downloading-trait`

    include `rcm plugin use-trait ispconfig/os-setup base setup-trait`

fi

include `rcm plugin use-trait ispconfig/os-setup base setup-finishing-trait`
