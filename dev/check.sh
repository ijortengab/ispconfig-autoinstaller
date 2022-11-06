#!/bin/bash

source /home/ijortengab/gist/var-dump.function.sh


# yellow Dump variable from shell.
ispconfig_db_user_host="$ISPCONFIG_DB_USER_HOST"
ispconfig_db_user_host=abc
# magenta ispconfig_db_user="$ispconfig_db_user"
# magenta ispconfig_db_user_host="$ispconfig_db_user_host"
# magenta ispconfig_db_user_password="$ispconfig_db_user_password"
# magenta ispconfig_db_name="$ispconfig_db_name"
# todo dump from php
# _ispconfig_db_user=$(php -r "include '$ISPCONFIG_INSTALL_DIR/interface/lib/config.inc.php';echo DB_USER;")
# _ispconfig_db_user_password=$(php -r "include '$ISPCONFIG_INSTALL_DIR/interface/lib/config.inc.php';echo DB_PASSWORD;")
# _ispconfig_db_user_host=$(php -r "include '$ISPCONFIG_INSTALL_DIR/interface/lib/config.inc.php';echo DB_HOST;")
# _ispconfig_db_name=$(php -r "include '$ISPCONFIG_INSTALL_DIR/interface/lib/config.inc.php';echo DB_DATABASE;")
has_different=
for string in ispconfig_db_name ispconfig_db_user ispconfig_db_user_host ispconfig_db_user_password
do
    echo "$string"
    var=${!string}
    echo "$var"
    # if [[ ! "$string" == "_${string}" ]];
done

exit
VarDump '<$0>'"$0"
VarDump '<$1>'"$1"
VarDump '<$2>'"$2"
VarDump '<$$>'"$$"
VarDump '<$PPID>'"$PPID"
mengapa
# answer=$(kill -CONT "$PPID")
# kill -CONT "$PPID"
# kill -CHLD "$PPID"
# VarDump answer

# Jika dari terminal, maka ...
if [ -t 0 ]; then
    echo Cannot execute directly. >&2; exit 1
fi

command -v mengapa

# echo gpl
# sleep 100
echo ok
echo $anu
