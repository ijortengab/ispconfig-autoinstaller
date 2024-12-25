#!/bin/bash

# Common Functions.
red() { echo -ne "\e[91m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
green() { echo -ne "\e[92m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
yellow() { echo -ne "\e[93m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
blue() { echo -ne "\e[94m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
magenta() { echo -ne "\e[95m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
x() { echo >&2; exit 1; }

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

yellow 'Set chmod a+x'; _.
magenta "find * -mindepth 1 -type f \( ! -perm -g+x -or  ! -perm -u+x -or ! -perm -o+x \) -and \( -name '*.sh' -or  -name '*.php' \)"; _.
find * -mindepth 1 -type f \( ! -perm -g+x -or  ! -perm -u+x -or ! -perm -o+x \) -and \( -name '*.sh' -or  -name '*.php' \)
if [[ $( find * -mindepth 1 -type f \( ! -perm -g+x -or  ! -perm -u+x -or ! -perm -o+x \) -and \( -name '*.sh' -or  -name '*.php' \)|wc -l) -eq 0 ]];then
    green There no changes.; _.
else
    red Need update;_.
fi
