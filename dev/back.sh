#!/bin/bash

if [[ "$0" =~ back\.sh$ ]];then
    echo 'Cara penggunaan yang benar adalah `. back.sh`'
else
    cd $PWD/../
    git switch master
    if [ $? -eq 1 ];then
        cd -
    fi
fi
