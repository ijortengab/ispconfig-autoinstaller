#!/bin/bash
# How to Use:
[ -z "$1" ] && { echo Argument Directory required; exit; }
[ -d "$1" ] || { echo Directory not exists; exit; }
dir=$(realpath "$1")
this_file=$(realpath "$0")

echo "Watching Directory: $dir"
while true; do
    n=3
    until [[ $n == 0 ]]; do
        printf "\r\033[K"  >&2
        echo -n Waiting $n...  >&2
        let n--
        sleep 1
    done
    printf "\r\033[K" >&2
    inotifywait -q -e modify --format "%f" "$dir" | while read -r LINE
    do
        echo "The modify of file ${LINE} is detected."
        if [[ "$this_file" == "$dir/$LINE" ]];then
            sleep 1
            echo This file
        else
            [[ -x "$LINE" ]] &&  {
                echo Executing....
                sleep 1
                cd "$dir"
                . "$LINE"
            }
        fi
    done
done
