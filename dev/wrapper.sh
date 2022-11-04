#!/bin/bash
source /home/ijortengab/gist/var-dump.function.sh
# @todo: devel
arguments=( 
    '--dev'     
    '--fi le'  
)
set -- "${arguments[@]}"
 
VarDump '<$1>'"$1"
VarDump '<$2>'"$2"
VarDump '<$$>'"$$"  

this_file=$(realpath "$0")
directory=$(dirname "$this_file") 

cleaning() {
echo mantab   
echo mantab jiwa    
echo \$\$ "$$"
echo \$PPID "$PPID"
# exit 
}
trap cleaning SIGCHLD  



echo "$directory"
[[ -e "$directory/check.sh" && -x "$directory/check.sh" ]] && {
    "$directory/check.sh" "$@"
    echo \$\? "$?"
}
# echo wrapper sleep
# echo sleep
# sleep 500