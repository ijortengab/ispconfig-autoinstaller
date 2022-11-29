#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

blue Report
____

[ -n "$domain" ] && {
    fqdn_phpmyadmin="${subdomain_phpmyadmin}.${domain}"
    fqdn_roundcube="${subdomain_roundcube}.${domain}"
    fqdn_ispconfig="${subdomain_ispconfig}.${domain}"
} || {
    fqdn_phpmyadmin=$PHPMYADMIN_SUBDOMAIN_LOCALHOST
    fqdn_roundcube=$ROUNDCUBE_SUBDOMAIN_LOCALHOST
    fqdn_ispconfig=$ISPCONFIG_SUBDOMAIN_LOCALHOST
}
if [[ "$letsencrypt" == 'digitalocean' && -n "$digitalocean_token" ]];then
    http=https
else
    http=http
fi

yellow PHPMyAdmin: "${http}://${fqdn_phpmyadmin}"
databaseCredentialPhpmyadmin
e ' - 'username: $phpmyadmin_db_user
e '   'password: $phpmyadmin_db_user_password
databaseCredentialRoundcube
e ' - 'username: $roundcube_db_user
e '   'password: $roundcube_db_user_password
databaseCredentialIspconfig
e ' - 'username: $ispconfig_db_user
e '   'password: $ispconfig_db_user_password
____

yellow Roundcube: "${http}://${fqdn_roundcube}"
e ' - 'username: $mailbox_admin
if [ -n "$domain" ];then
    user="$mailbox_admin"
    host="$domain"
    . /usr/local/share/credential/mailbox/$host/$user
    e '   'password: $MAILBOX_USER_PASSWORD
else
    e '   'password: ...
fi
____

yellow ISPConfig: "${http}://${fqdn_ispconfig}"
websiteCredentialIspconfig
e ' - 'username: admin
e '   'password: $ispconfig_web_user_password
____

yellow Manual Action
e Command to make sure remote user working properly:
__; magenta ispconfig.sh php login.php
e Command to implement '`'ispconfig.sh'`' command autocompletion immediately:
__; magenta source /etc/profile.d/ispconfig-completion.sh
e Command to check PTR Record:
if [ -n "$ip_address" ];then
    __; magenta dig -x "$ip_address" +short
else
    __; magenta dig -x "\$ip_address" +short
fi
____

if [ -n "$ip_address" ];then
    if [[ ! $(dig -x $ip_address +short) == ${fqdn}. ]];then
        red Attention
        e Your PTR Record is different with your FQDN.
        __; magenta dig -x $ip_address +short' # ' $(dig -x $ip_address +short)
        __; magenta fqdn="$fqdn"
        ____
        yellow Suggestion.
        e If you user of DigitalOcean, change your droplet name with FQDN.
        e More info: https://www.digitalocean.com/community/questions/how-do-i-setup-a-ptr-record
        ____
    fi
fi

if [[ ! $(hostname -f) == $fqdn ]];then
    red Attention.
    __ Your current hostname is different with your FQDN.
    __; magenta hostname -f' # '$(hostname -f)
    __; magenta fqdn="$fqdn"
    ____

    yellow Suggestion.
    __ Execute command below to change hostname immediately.
    if [[ ! $(hostname) == $hostname ]];then
        __; magenta hostnamectl set-hostname $hostname
    fi
    _fqdn=$(hostname -f | sed 's/\./\\./g')
    _hostname=$(hostname)
    __; magenta sed -i -E \\
    __; __; magenta \"s/^\\s*'(.*)'$_fqdn\\s+$_hostname/$ip_address $fqdn $hostname/\" \\
    __; __; magenta /etc/hosts
    ____
fi
