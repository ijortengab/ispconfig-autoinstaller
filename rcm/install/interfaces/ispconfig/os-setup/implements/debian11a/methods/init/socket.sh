#!/bin/bash

# Dependency.
[ -n "$RCM_PHP_VERSION" ] || { red "Unable to proceed, variable \$RCM_PHP_VERSION is empty."; x; }

include `rcm plugin run-parent-method ispconfig/os-setup debian11 init`

# Dependency.
require command apt-install

INDENT+="$RCM_INDENT" \
rcm php init \
    --php-version=$RCM_PHP_VERSION \
    --extension=common \
    --extension=gd \
    --extension=mysql \
    --extension=imap \
    --extension=cli \
    --extension=fpm \
    --extension=curl \
    --extension=intl \
    --extension=pspell \
    --extension=sqlite3 \
    --extension=tidy \
    --extension=xmlrpc \
    --extension=xsl \
    --extension=zip \
    --extension=mbstring \
    --extension=soap \
    --extension=opcache \
    && INDENT+="$RCM_INDENT" \
rcm php switch \
    --php-version=$RCM_PHP_VERSION \
    ; [ ! $? -eq 0 ] && x

# Section base.
application=()

# Referensi:
# Git Repo: https://git.ispconfig.org/ispconfig/ispconfig-autoinstaller
# File: class.ISPConfigDebianOS.inc.php
# Commit: 249b7c2
# Line: 230.
# Method: runPerfectSetup(), getPackagesToInstall().
# + php-pear
# + php-memcache
# + php-imagick
# + php-gettext
# + mcrypt
# + imagemagick
# + libruby
# + memcached
# + php-apcu

# Referensi:
# Git Repo: https://git.ispconfig.org/ispconfig/ispconfig-autoinstaller
# File: class.ISPConfigDebian11OS.inc.php
# Commit: 249b7c2
# Line: 27.
# Method: getPackagesToInstall().
# - php-gettext

application+=('php-pear')
application+=('php-memcache')
application+=('php-imagick')
application+=('mcrypt')
application+=('imagemagick')
application+=('libruby')
application+=('memcached')
application+=('php-apcu')

apt-install "${application[@]}"
