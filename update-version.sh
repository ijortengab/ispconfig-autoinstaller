#!/bin/bash

[ -z $1 ] && {
    echo Version Required as argument 1. Example: 1.0.0
    exit
}
version=$1

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
# https://stackoverflow.com/questions/11145270/how-to-replace-an-entire-line-in-a-text-file-by-line-number
# https://stackoverflow.com/a/11145362
string='printVersion()'
while read file; do
    number=$(grep -n -F "$string" "$file" | head -1 | cut -d: -f1)
    number_below=$((number + 1))
    sed -i "$number_below"'s/.*/'"    echo '$version'"'/' "$file"
done <<< `find * -mindepth 1 -type f -name '*.sh'`
