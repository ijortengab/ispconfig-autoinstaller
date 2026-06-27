#!/bin/bash

# Dependency.
require command apt-install

include `rcm plugin run-static-method os-setup debian12 init`
include `rcm plugin run-parent-method ispconfig/os-setup debian init`

# Section first.
application=()

# Referensi:
# Git Repo: https://git.ispconfig.org/ispconfig/ispconfig-autoinstaller
# File: class.ISPConfigDebianOS.inc.php
# Commit: 249b7c2
# Line: 1067, 1068, 158, 159.
# Method: runPerfectSetup(), getPackagesToInstall().
# + dbconfig-common
# + postfix
# + postfix-mysql
# + mariadb-client
# + mariadb-server
# + openssl
# + getmail4
# + rkhunter
# + binutils
# + sudo

# Referensi:
# Git Repo: https://git.ispconfig.org/ispconfig/ispconfig-autoinstaller
# File: class.ISPConfigDebian10OS.inc.php
# Commit: 249b7c2
# Line: 32, 35.
# Method: getPackagesToInstall().
# - getmail4
# + getmail

# Referensi:
# Git Repo: https://git.ispconfig.org/ispconfig/ispconfig-autoinstaller
# File: class.ISPConfigDebian12OS.inc.php
# Commit: 249b7c2
# Line: 24, 27.
# Method: getPackagesToInstall().
# - getmail
# + getmail6
# + rsyslog

application+=('dbconfig-common')
# application+=('postfix') # Diambil alih oleh: `rcm plugin get-socket mail-server postfix init`.
# application+=('postfix-mysql') # Diambil alih oleh: `rcm plugin get-socket postfix/dbms mysql init`.
# application+=('mariadb-client') # Diambil alih oleh: `rcm plugin get-socket dbms mariadb init`.
# application+=('mariadb-server') # Diambil alih oleh: `rcm plugin get-socket dbms mariadb init`.
application+=('openssl')
application+=('rkhunter')
application+=('binutils')
application+=('sudo')
application+=('getmail6')
application+=('rsyslog')

apt-install "${application[@]}"

# Section mail.
application=()

# Referensi:
# Git Repo: https://git.ispconfig.org/ispconfig/ispconfig-autoinstaller
# File: class.ISPConfigDebianOS.inc.php
# Commit: 249b7c2
# Line: 1200, 1201, 158, 172.
# Method: runPerfectSetup(), getPackagesToInstall('mail').
# + software-properties-common
# + update-inetd
# + dnsutils
# + resolvconf
# + clamav
# + clamav-daemon
# + zip
# + unzip
# + bzip2
# + xz-utils
# + lzip
# + borgbackup
# + arj
# + nomarch
# + lzop
# + cabextract
# + apt-listchanges
# + libnet-ldap-perl
# + libauthen-sasl-perl
# + daemon
# + libio-string-perl
# + libio-socket-ssl-perl
# + libnet-ident-perl
# + libnet-dns-perl
# + libdbd-mysql-perl

# Referensi:
# Git Repo: https://git.ispconfig.org/ispconfig/ispconfig-autoinstaller
# File: class.ISPConfigDebian10OS.inc.php
# Commit: 249b7c2
# Line: 32, 41.
# Method: getPackagesToInstall().
# + p7zip
# + p7zip-full
# + unrar-free
# + lrzip

application+=('software-properties-common')
application+=('update-inetd')
application+=('dnsutils')
# application+=('resolvconf') # Terdapat trouble, error resolve dns.
application+=('clamav')
application+=('clamav-daemon')
application+=('zip')
application+=('unzip')
application+=('bzip2')
application+=('xz-utils')
application+=('lzip')
application+=('borgbackup')
application+=('arj')
application+=('nomarch')
application+=('lzop')
application+=('cabextract')
application+=('apt-listchanges')
application+=('libnet-ldap-perl')
application+=('libauthen-sasl-perl')
application+=('daemon')
application+=('libio-string-perl')
application+=('libio-socket-ssl-perl')
application+=('libnet-ident-perl')
application+=('libnet-dns-perl')
application+=('libdbd-mysql-perl')
application+=('p7zip')
application+=('p7zip-full')
application+=('unrar-free')
application+=('lrzip')

apt-install "${application[@]}"
