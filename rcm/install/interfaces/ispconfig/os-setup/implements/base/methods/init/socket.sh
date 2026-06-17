#!/bin/bash

# Dependency.
require command apt-install

# Referensi:
# Git Repo: https://git.ispconfig.org/ispconfig/ispconfig-autoinstaller
# File: class.ISPConfigDebianOS.inc.php
# Commit: 249b7c2
# Line: 136
# Method: getInitialPackages().
application=
application+=' ssh'
application+=' openssh-server'
application+=' nano'
application+=' vim-nox'
application+=' lsb-release'
application+=' apt-transport-https'
application+=' ca-certificates'
application+=' wget'
application+=' git'
application+=' gnupg'
application+=' software-properties-common'
application+=' curl'
application+=' cron'
# todo, ntp
# application+=' ntp'
apt-install $application
