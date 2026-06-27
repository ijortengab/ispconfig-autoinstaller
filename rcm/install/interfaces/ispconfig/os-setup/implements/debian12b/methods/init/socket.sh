#!/bin/bash

include `rcm plugin run-parent-method ispconfig/os-setup debian12 init`

# Dependency.
require command apt-install

RCM_PHP_VERSION=8.3

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
    --extension=memcache \
    --extension=imagick \
    --extension=apcu \
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
# application+=('php-memcache') # Diambil alih oleh: `rcm php init`.
# application+=('php-imagick') # Diambil alih oleh: `rcm php init`.
application+=('mcrypt')
application+=('imagemagick')
application+=('libruby')
application+=('memcached')
# application+=('php-apcu') # Diambil alih oleh: `rcm php init`.

apt-install "${application[@]}"
