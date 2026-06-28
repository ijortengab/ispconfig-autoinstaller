#!/bin/bash

# Dependency.
[ -v RCM_PUBLIC_DOMAIN ] || { red "Unable to proceed, variable \$RCM_PUBLIC_DOMAIN does not exist."; x; }

# Define variables and constants.
public_domain="$RCM_PUBLIC_DOMAIN"

if [ -n "$public_domain" ];then

    include `rcm plugin use-trait ispconfig/os-setup base setup-smtpd-trait`

fi
