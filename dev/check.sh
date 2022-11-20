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



# ------------------------------------------------------------------------------
 
exit 0

source /home/ijortengab/gist/var-dump.function.sh
# @todo: devel

# arguments=( 
    # '--dev'
    # '--file=/etc/nginx/nginx.conf'
# )
# set -- "${arguments[@]}"

VarDump '<$1>'"$1"
VarDump '<$2>'"$2"
VarDump '<$3>'"$3"
VarDump '<$4>'"$4"
VarDump '<$$>'"$$"

# parse-options.sh \
# --without-end-options-double-dash \
# --compact \
# --clean \
# --no-hash-bang \
# --no-error-invalid-options \
# --no-error-require-arguments << EOF | clip
# VALUE=(
# --file
# )
# FLAG=(
# --dev
# )
# EOF

ORIGINAL_ARGUMENTS=("$@")

_new_arguments=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dev) dev=1; shift ;;
        --file=*) file="${1#*=}"; shift ;;
        --file) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then file="$2"; shift; fi; shift ;;
        --[^-]*) shift ;;
        *) _new_arguments+=("$1"); shift ;;
    esac
done

set -- "${_new_arguments[@]}"

unset _new_arguments

VarDump '<$1>'"$1"
VarDump '<$2>'"$2"
VarDump '<$$>'"$$"

this_file=$(realpath "$0")
directory_this_file=$(dirname "$this_file")

VarDump this_file directory_this_file

mengapa() {
echo mengapa
}
# Jika ada module, maka
if [ -n "$1" ];then
    module_name="$1"
    if [ -f "$directory_this_file/$module_name" ];then
        echo -n
        echo mantab
        . "$directory_this_file/$module_name" "${ORIGINAL_ARGUMENTS[@]}"

    fi
    exit
fi

$this_file 'check.sh' "$@"

exit

cleaning() {
    echo mantab
    echo mantab jiwa
    echo \$\$ "$$"
    echo \$PPID "$PPID"
    anu=kitabisa
    exit
}
trap cleaning SIGCHLD

echo "$directory"
[[ -e "$directory/check.sh" && -x "$directory/check.sh" ]] && {
    "$directory/check.sh" "$@"
    echo \$\? "$?"
}
echo wrapper sleep
# echo sleep
# sleep 500

