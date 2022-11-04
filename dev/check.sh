#!/bin/bash

source /home/ijortengab/gist/var-dump.function.sh
 
VarDump '<$1>'"$1"
VarDump '<$2>'"$2"
VarDump '<$$>'"$$"
VarDump '<$PPID>'"$PPID"
# answer=$(kill -CONT "$PPID")
# kill -CONT "$PPID"
kill -CHLD "$PPID"
# VarDump answer

# Jika dari terminal, maka
if [ -t 0 ]; then
    VarDump 'Ini dari terminal'
else
    VarDump 'Ini bukan dari terminal'
fi

echo gpl
# sleep 100
echo ok
