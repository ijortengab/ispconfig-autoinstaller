#!/bin/bash
# How to Use:
[ -z "$1" ] && { echo Argument Directory required; exit; }
[ -d "$1" ] || { echo Directory not exists; exit; }
delay_before_start="$2"
[ -n "$delay_before_start" ] || { delay_before_start=0; }
dir=$(realpath "$1")
this_file=$(realpath "$0")
n="$delay_before_start"
echo Welcome to inotify.sh
until [[ $n == 0 ]]; do
    printf "\r\033[K"  >&2
    echo -n Waiting $n...  >&2
    let n--
    sleep 1
done
printf "\r\033[K" >&2
while true; do
    echo "Watching Directory: $dir"
    inotifywait -q -e modify --format "%f" "$dir" | while read -r LINE
    do
        echo "The modify of file ${LINE} is detected. Process:"
        lsof -t "$dir/$LINE"
        if [[ "$this_file" == "$dir/$LINE" ]];then
            sleep .5
            echo This file
        else
            [[ -x "$dir/$LINE" ]] &&  {
                echo Execute.
                is_busy=$(lsof -t "$dir/$LINE" | wc -w)
                n=0
                until [[ $is_busy == 0 ]];do
                    printf "\r\033[K"  >&2
                    echo -n File is busy. Waiting $n...  >&2
                    let n++
                    sleep 1
                    is_busy=$(lsof -t "$dir/$LINE" | wc -w)
                done
                printf "\r\033[K"  >&2
                # "$dir"/"$LINE"
                "$dir"/gpl-ispconfig-variation1.sh
            }
        fi
    done
done
