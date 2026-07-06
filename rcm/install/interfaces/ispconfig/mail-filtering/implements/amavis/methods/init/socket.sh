#!/bin/bash

# Execute Parent
include `rcm plugin run-parent-method mail-filtering amavis init`

INDENT+="$RCM_INDENT" \
rcm spamassassin init \
    ; [ ! $? -eq 0 ] && x
