#!/bin/bash

if [[ $(uname | cut -c1-6) == "CYGWIN" ]];then
    if [[ "$0" =~ back\.sh$ ]];then
        echo 'Cara penggunaan yang benar adalah `. back.sh`'
    else
        cd $PWD/../
        git switch master
    fi
fi
