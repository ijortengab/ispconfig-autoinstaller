#!/bin/bash

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

[ -z $1 ] && {
    echo 'Operand <version> is required. Example: 1.0.0.'; exit 1
}
version=$1
old_version=$(./rcm.sh --version)
case "$version" in
    major|minor|patch)
        major=$(sed -E 's,^([0-9]+)\.([0-9]+)\.([0-9]+)$,\1,' <<< "$old_version")
        minor=$(sed -E 's,^([0-9]+)\.([0-9]+)\.([0-9]+)$,\2,' <<< "$old_version")
        patch=$(sed -E 's,^([0-9]+)\.([0-9]+)\.([0-9]+)$,\3,' <<< "$old_version")
    ;;
    *)
        if grep -q -E '^[0-9]+\.[0-9]+\.[0-9]+$' <<< "$version";then
            echo Format version valid.
        else
            echo Format version invalid: '`'$version'`'.; exit 1
        fi
esac
case "$version" in
    major)
        major=$((major + 1))
        version="${major}.0.0"
        ;;
    minor)
        minor=$((minor + 1))
        version="${major}.${minor}.0"
        ;;
    patch)
        patch=$((patch + 1))
        version="${major}.${minor}.${patch}"
esac
echo "$old_version" '->' "$version"

# https://stackoverflow.com/questions/11145270/how-to-replace-an-entire-line-in-a-text-file-by-line-number
# https://stackoverflow.com/a/11145362
string='printVersion()'
while read file; do
    number=$(grep -n -F "$string" "$file" | head -1 | cut -d: -f1)
    number_below=$((number + 1))
    sed -i "$number_below"'s/.*/'"    echo '$version'"'/' "$file"
done <<< `find * -mindepth 1 -type f -name '*.sh'`
while read file; do
    case "$file" in
        rcm\.sh)
            number=$(grep -n -F "$string" "$file" | head -1 | cut -d: -f1)
            number_below=$((number + 1))
            sed -i "$number_below"'s/.*/'"    echo '$version'"'/' "$file"
            ;;
    esac
done <<< `find * -mindepth 0 -maxdepth 0 -type f -name '*.sh'`
