#!/bin/bash
# How to Use:
[ -z "$1" ] && { echo Argument Directory required; exit; }
[ -d "$1" ] || { echo Directory not exists; exit; }
wait_before_execute="$2"
[ -n "$wait_before_execute" ] || { wait_before_execute=1; }
dir=$(realpath "$1")
this_file=$(realpath "$0")

while true; do
    n=3
    until [[ $n == 0 ]]; do
        printf "\r\033[K"  >&2
        echo -n Waiting $n...  >&2
        let n--
        sleep 1
    done
    printf "\r\033[K" >&2
    echo "Watching Directory: $dir"
    inotifywait -q -e modify --format "%f" "$dir" | while read -r LINE
    do
        echo "The modify of file ${LINE} is detected."
        if [[ "$this_file" == "$dir/$LINE" ]];then
            sleep .5
            echo This file
        else
            [[ -x "$dir/$LINE" ]] &&  {
                echo Execute
                if [ $wait_before_execute -gt 1 ];then
                    n="$wait_before_execute"
                    until [[ $n == 0 ]]; do
                        printf "\r\033[K"  >&2
                        echo -n Waiting $n...  >&2
                        let n--
                        sleep 1
                    done
                else
                    sleep $wait_before_execute
                fi
                "$dir"/"$LINE"
            }
        fi
    done
done
