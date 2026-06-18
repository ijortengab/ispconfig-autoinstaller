#!/bin/bash

INDENT+="$RCM_INDENT" \
rcm nginx add vhost php-default \
    --url="$RCM_WEB_SERVER_URL" \
    --root="$RCM_WEB_SERVER_ROOT" \
    --fastcgi-pass="unix:${RCM_WEB_SERVER_PHP_FPM_SOCKET}" \
    ; [ ! $? -eq 0 ] && x
