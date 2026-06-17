#!/bin/bash

# Dependency.
require rcm ispconfig create remote-user root

INDENT+="$RCM_INDENT" \
rcm ispconfig create remote-user root \
    ; [ ! $? -eq 0 ] && x
