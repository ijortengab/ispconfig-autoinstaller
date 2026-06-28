#!/bin/bash

# Dependency.
[ -n "$RCM_FQDN" ] || { red "Unable to proceed, variable \$RCM_FQDN is empty."; x; }

# Todo. Gunakan certbot certificates.

# Temporary.
certificate_name="$RCM_FQDN"
RCM_TLS_CERTIFICATE="/etc/letsencrypt/live/${certificate_name}/fullchain.pem"
RCM_TLS_CERTIFICATE_KEY="/etc/letsencrypt/live/${certificate_name}/privkey.pem"
