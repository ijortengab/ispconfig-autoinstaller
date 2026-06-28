#!/bin/bash

# Dependency.
[ -n "$RCM_ISPCONFIG_VERSION" ] || { red "Unable to proceed, variable \$RCM_ISPCONFIG_VERSION is empty."; x; }

# Define variables and constants.
ispconfig_version="$RCM_ISPCONFIG_VERSION"

chapter Get ISPConfig
code cd /tmp
cd /tmp
filename="ISPConfig-${ispconfig_version}.tar.gz"
rcm-file "$filename" isExists
if [ -n "$notfound" ];then
    __ Downloading ISPConfig
    wget https://www.ispconfig.org/downloads/ISPConfig-$ispconfig_version.tar.gz
    rcm-file "$filename" mustExists
else
    __ Use downloaded ISPConfig.
fi
rcm-file "$filename" terminateIfNotExists
path=/tmp/ispconfig3_install/install/install.php
code 'path="'$path'"'
rcm-file "$path" isExists
if [ -n "$notfound" ];then
    __ Extracting downloaded ISPConfig
    tar xfz ISPConfig-$ispconfig_version.tar.gz
    rcm-file "$path" mustExists
fi
rcm-file "$path" terminateIfNotExists
cd - >/dev/null
____
