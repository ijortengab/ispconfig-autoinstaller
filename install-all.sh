#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then
    echo This script needs to be run with superuser privileges
    exit
fi

# Functions.
resolve_relative_path() {
    if [ -d "$1" ];then
        cd "$1" || return 1
        pwd
    elif [ -e "$1" ];then
        if [ ! "${1%/*}" = "$1" ]; then
            cd "${1%/*}" || return 1
        fi
        echo "$(pwd)/${1##*/}"
    else
        return 1
    fi
}
__FILE__=$(resolve_relative_path "$0")
__DIR__=$(dirname "$__FILE__")
cd "$__DIR__"
echo cd /usr/local/bin
echo __DIR__='"'"$__DIR__"'"'

while read line; do
    chmod a+x "$line"
    echo ln -sf '"''$__DIR__'/"$line"'"' '"'$(basename "$line" | sed s,\.sh$,,)'"'
    ln -sf "$PWD/$line" /usr/local/bin/$(basename "$line" | sed s,\.sh$,,)
done <<< `find * -mindepth 1 -type f -name '*.sh'`
