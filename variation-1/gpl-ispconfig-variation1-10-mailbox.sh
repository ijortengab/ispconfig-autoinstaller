#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

# Dependencies of this script only.
[ -n "$domain" ] || { red "Value of variable \$domain required."; x; }

blue Setup Email
____

yellow Mengecek credentials ISPConfig.
ispconfig_db_user_host="$ISPCONFIG_DB_USER_HOST"
magenta ispconfig_db_user_host="$ispconfig_db_user_host"
databaseCredentialIspconfig
if [[ -z "$ispconfig_db_name" || -z "$ispconfig_db_user" || -z "$ispconfig_db_user_password" ]];then
    __; red Informasi credentials tidak lengkap: '`'/usr/local/share/ispconfig/credential/database'`'.; exit
else
    magenta ispconfig_db_name="$ispconfig_db_name"
    magenta ispconfig_db_user="$ispconfig_db_user"
    magenta ispconfig_db_user_password="$ispconfig_db_user_password"
fi
____

yellow Mengecek database credentials RoundCube.
roundcube_db_name="$ROUNDCUBE_DB_NAME"
magenta roundcube_db_name="$roundcube_db_name"
roundcube_db_user_host="$ROUNDCUBE_DB_USER_HOST"
magenta roundcube_db_user_host="$roundcube_db_user_host"
databaseCredentialRoundcube
if [[ -z "$roundcube_db_user" || -z "$roundcube_db_user_password" ]];then
    __; red Informasi credentials tidak lengkap: '`'/usr/local/share/roundcube/credential/database'`'.; exit
else
    magenta roundcube_db_user="$roundcube_db_user"
    magenta roundcube_db_user_password="$roundcube_db_user_password"
fi
____

# Get the mailuser_id from table mail_user in ispconfig database.
#
# Globals:
#   ispconfig_db_user, ispconfig_db_user_password,
#   ispconfig_db_user_host, ispconfig_db_name
#
# Arguments:
#   $1: user mail
#   $2: host mail
#
# Output:
#   Write mailuser_id to stdout.
getMailUserIdIspconfigByEmail() {
    local email="$1"@"$2"
    local sql="SELECT mailuser_id FROM mail_user WHERE email = '$email';"
    local u="$ispconfig_db_user"
    local p="$ispconfig_db_user_password"
    local mailuser_id=$(mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        -h "$ispconfig_db_user_host" "$ispconfig_db_name" -r -N -s -e "$sql"
    )
    echo "$mailuser_id"
}

# Check if the mailuser_id from table mail_user exists in ispconfig database.
#
# Globals:
#   Used: roundcube_db_user, roundcube_db_user_password,
#         roundcube_db_user_host, roundcube_db_name
#   Modified: mailuser_id
#
# Arguments:
#   $1: user mail
#   $2: host mail
#
# Return:
#   0 if exists.
#   1 if not exists.
isEmailIspconfigExist() {
    mailuser_id=$(getMailUserIdIspconfigByEmail "$1" "$2")
    if [ -n "$mailuser_id" ];then
        return 0
    fi
    return 1
}

mailboxCredential() {
    local host="$1"
    local user="$2"
    if [ -f /usr/local/share/credential/mailbox/$host/$user ];then
        local MAILBOX_USER_PASSWORD
        . /usr/local/share/credential/mailbox/$host/$user
        mailbox_user_password=$MAILBOX_USER_PASSWORD
    else
        mailbox_user_password=$(pwgen 9 -1vA0B)
        mkdir -p /usr/local/share/credential/mailbox/$host/
        cat << EOF > /usr/local/share/credential/mailbox/$host/$user
MAILBOX_USER_PASSWORD=$mailbox_user_password
EOF
        chmod 0500 /usr/local/share/credential
        chmod 0500 /usr/local/share/credential/mailbox
        chmod 0500 /usr/local/share/credential/mailbox/$host
        chmod 0400 /usr/local/share/credential/mailbox/$host/$user
    fi
}

# Insert to table mail_user a new record via SOAP.
#
# Globals:
#   Used: roundcube_db_user, roundcube_db_user_password,
#         roundcube_db_user_host, roundcube_db_name
#   Modified: mailuser_id
#
# Arguments:
#   $1: user mail
#   $2: host mail
#
# Return:
#   0 if exists.
#   1 if not exists.
insertEmailIspconfig() {
    local user="$1"
    local host="$2"
    __ Mengecek credentials Mailbox.
    mailboxCredential $host $user
    if [[ -z "$mailbox_user_password" ]];then
        __; red Informasi credentials tidak lengkap: '`'/usr/local/share/credential/mailbox/$host/$user'`'.; x
    else
        __; magenta mailbox_user_password="$mailbox_user_password"
    fi
    __ Create PHP Script from template '`'mail_user_add'`'.
    template=mail_user_add
    template_temp=$(ispconfig.sh mktemp "${template}.php")
    template_temp_path=$(ispconfig.sh realpath "$template_temp")
    __; magenta template_temp_path="$template_temp_path"
    parameter=''
    parameter+="\t\t'server_id' => '1',\n"
    parameter+="\t\t'email' => '$user@$host',\n"
    parameter+="\t\t'login' => '$user@$host',\n"
    parameter+="\t\t'password' => '$mailbox_user_password',\n"
    parameter+="\t\t'name' => '$user',\n"
    parameter+="\t\t'uid' => '5000',\n"
    parameter+="\t\t'gid' => '5000',\n"
    parameter+="\t\t'maildir' => '/var/vmail/$host/$user',\n"
    parameter+="\t\t'maildir_format' => 'maildir',\n"
    parameter+="\t\t'quota' => '0',\n"
    parameter+="\t\t'cc' => '',\n"
    parameter+="\t\t'forward_in_lda' => 'y',\n"
    parameter+="\t\t'sender_cc' => '',\n"
    parameter+="\t\t'homedir' => '/var/vmail',\n"
    parameter+="\t\t'autoresponder' => 'n',\n"
    parameter+="\t\t'autoresponder_start_date' => NULL,\n"
    parameter+="\t\t'autoresponder_end_date' => NULL,\n"
    parameter+="\t\t'autoresponder_subject' => '',\n"
    parameter+="\t\t'autoresponder_text' => '',\n"
    parameter+="\t\t'move_junk' => 'Y',\n"
    parameter+="\t\t'purge_trash_days' => 0,\n"
    parameter+="\t\t'purge_junk_days' => 0,\n"
    parameter+="\t\t'custom_mailfilter' => NULL,\n"
    parameter+="\t\t'postfix' => 'y',\n"
    parameter+="\t\t'greylisting' => 'n',\n"
    parameter+="\t\t'access' => 'y',\n"
    parameter+="\t\t'disableimap' => 'n',\n"
    parameter+="\t\t'disablepop3' => 'n',\n"
    parameter+="\t\t'disabledeliver' => 'n',\n"
    parameter+="\t\t'disablesmtp' => 'n',\n"
    parameter+="\t\t'disablesieve' => 'n',\n"
    parameter+="\t\t'disablesieve-filter' => 'n',\n"
    parameter+="\t\t'disablelda' => 'n',\n"
    parameter+="\t\t'disablelmtp' => 'n',\n"
    parameter+="\t\t'disabledoveadm' => 'n',\n"
    parameter+="\t\t'disablequota-status' => 'n',\n"
    parameter+="\t\t'disableindexer-worker' => 'n',\n"
    parameter+="\t\t'last_quota_notification' => NULL,\n"
    parameter+="\t\t'backup_interval' => 'none',\n"
    parameter+="\t\t'backup_copies' => '1',\n"
    sed -i -E \
        -e ':a;N;$!ba;s|\$params\s+=\s+[^;]+;|\$params = array(\n'"${parameter}"'\n\t);|g' \
        "$template_temp_path"
    sed -i -E -e '/echo/d' -e '/^\s*$/d' -e 's,\t,    ,g' \
        "$template_temp_path"
    contents=$(<"$template_temp_path")
    __ Execute PHP Script.
    magenta "$contents"
    ispconfig.sh php "$template_temp"
    __ Cleaning Temporary File.
    __; magenta rm "$template_temp_path"
    rm "$template_temp_path"
    mailuser_id=$(getMailUserIdIspconfigByEmail "$1" "$2")
    if [ -n "$mailuser_id" ];then
        return 0
    fi
    return 1
}

# Get the forwarding_id from table mail_forwarding in ispconfig database.
#
# Globals:
#   ispconfig_db_user, ispconfig_db_user_password,
#   ispconfig_db_user_host, ispconfig_db_name
#
# Arguments:
#   $1: Filter by email source.
#   $2: Filter by email destination.
#
# Output:
#   Write forwarding_id to stdout.
getForwardingIdIspconfigByEmailAlias() {
    local source="$1"
    local destination="$2"
    local sql="SELECT forwarding_id FROM mail_forwarding WHERE source = '$source' and destination = '$destination' and type = 'alias';"
    local u="$ispconfig_db_user"
    local p="$ispconfig_db_user_password"
    # echo '---'
    # mysql \
        # --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        # -h "$ispconfig_db_user_host" "$ispconfig_db_name" -r -N -s -e "$sql"

    # echo '---'
    local forwarding_id=$(mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        -h "$ispconfig_db_user_host" "$ispconfig_db_name" -r -N -s -e "$sql"
    )
    echo "$forwarding_id"
}

# Check if the email alias (source and destination)
# from table mail_forwarding exists in ispconfig database.
#
# Globals:
#   Used: ispconfig_db_user, ispconfig_db_user_password,
#         ispconfig_db_user_host, ispconfig_db_name
#   Modified: forwarding_id
#
# Arguments:
#   $1: Filter by email source.
#   $2: Filter by email destination.
#
# Return:
#   0 if exists.
#   1 if not exists.
isEmailAliasIspconfigExist() {
    local source="$1"
    local destination="$2"
    forwarding_id=$(getForwardingIdIspconfigByEmailAlias "$source" "$destination")
    if [ -n "$forwarding_id" ];then
        return 0
    fi
    return 1
}

# Insert to table mail_forwarding a new record via SOAP.
#
# Globals:
#   Used: roundcube_db_user, roundcube_db_user_password,
#         roundcube_db_user_host, roundcube_db_name
#   Modified: forwarding_id
#
# Arguments:
#   $1: email destination
#   $2: email alias
#
# Return:
#   0 if exists.
#   1 if not exists.
insertEmailAliasIspconfig() {
    local source="$1"
    local destination="$2"
    __ Create PHP Script from template '`'mail_alias_add'`'.
    template=mail_alias_add
    template_temp=$(ispconfig.sh mktemp "${template}.php")
    template_temp_path=$(ispconfig.sh realpath "$template_temp")
    __; magenta template_temp_path="$template_temp_path"
    parameter=''
    parameter+="\t\t'server_id' => '1',\n"
    parameter+="\t\t'source' => '${source}',\n"
    parameter+="\t\t'destination' => '${destination}',\n"
    parameter+="\t\t'type' => 'alias',\n"
    parameter+="\t\t'active' => 'y',\n"
    sed -i -E \
        -e ':a;N;$!ba;s|\$params\s+=\s+[^;]+;|\$params = array(\n'"${parameter}"'\n\t);|g' \
        "$template_temp_path"
    sed -i -E -e '/echo/d' -e '/^\s*$/d' -e 's,\t,    ,g' \
        "$template_temp_path"
    contents=$(<"$template_temp_path")
    __ Execute PHP Script.
    magenta "$contents"
    ispconfig.sh php "$template_temp"
    __ Cleaning temporary file.
    __; magenta rm "$template_temp_path"
    rm "$template_temp_path"
    forwarding_id=$(getForwardingIdIspconfigByEmailAlias "$source" "$destination")
    if [ -n "$forwarding_id" ];then
        return 0
    fi
    return 1
}

# Get the user_id from table users in roundcube database.
#
# Globals:
#   roundcube_db_user, roundcube_db_user_password,
#   roundcube_db_user_host, roundcube_db_name
#
# Arguments:
#   $1: Filter by username.
#
# Output:
#   Write user_id to stdout.
getUserIdRoundcubeByUsername() {
    local username="$1"
    local sql="SELECT user_id FROM users WHERE username = '$username';"
    local u="$roundcube_db_user"
    local p="$roundcube_db_user_password"
    local user_id=$(mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        -h "$roundcube_db_user_host" "$roundcube_db_name" -r -N -s -e "$sql"
    )
    echo "$user_id"
}

# Check if the username from table users exists in roundcube database.
#
# Globals:
#   Used: roundcube_db_user, roundcube_db_user_password,
#         roundcube_db_user_host, roundcube_db_name
#   Modified: user_id
#
# Arguments:
#   $1: username to be checked.
#
# Return:
#   0 if exists.
#   1 if not exists.
isUsernameRoundcubeExist() {
    local username="$1"
    user_id=$(getUserIdRoundcubeByUsername "$username")
    if [ -n "$user_id" ];then
        return 0
    fi
    return 1
}

# Insert the username to table users in roundcube database.
#
# Globals:
#   Used: roundcube_db_user, roundcube_db_user_password,
#         roundcube_db_user_host, roundcube_db_name
#   Modified: user_id
#
# Arguments:
#   $1: username to be checked.
#   $2: mail host (if omit, default to localhost)
#   $3: language (if omit, default to en_US)
#
# Return:
#   0 if exists.
#   1 if not exists.
insertUsernameRoundcube() {
    local username="$1"
    local mail_host="$2"; [ -n "$mail_host" ] || mail_host=localhost
    local language="$3"; [ -n "$language" ] || language=en_US
    local now=$(date +%Y-%m-%d\ %H:%M:%S)
    local sql="INSERT INTO users
        (created, last_login, username, mail_host, language)
        VALUES
        ('$now', '$now', '$username', '$mail_host', '$language');"
    local u="$roundcube_db_user"
    local p="$roundcube_db_user_password"
    mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        -h "$roundcube_db_user_host" "$roundcube_db_name" -e "$sql"
    user_id=$(getUserIdRoundcubeByUsername "$username")
    if [ -n "$user_id" ];then
        return 0
    fi
    return 1
}

# Get the user_id from table users in roundcube database.
#
# Globals:
#   roundcube_db_user, roundcube_db_user_password,
#   roundcube_db_user_host, roundcube_db_name
#
# Arguments:
#   $1: Filter by standard.
#   $2: Filter by email.
#   $3: Filter by user_id.
#
# Output:
#   Write identity_id to stdout.
getIdentityIdRoundcubeByEmail() {
    local standard="$1"
    local email="$2"
    local user_id="$3"
    local sql="SELECT identity_id FROM identities WHERE standard = '$standard' and email = '$email' and user_id = '$user_id';"
    local u="$roundcube_db_user"
    local p="$roundcube_db_user_password"
    local identity_id=$(mysql \
        --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        -h "$roundcube_db_user_host" "$roundcube_db_name" -r -N -s -e "$sql"
    )
    echo "$identity_id"
}

# Check if the username from table users exists in roundcube database.
#
# Globals:
#   Used: roundcube_db_user, roundcube_db_user_password,
#         roundcube_db_user_host, roundcube_db_name
#   Modified: identity_id
#
# Arguments:
#   $1: username to be checked.
#
# Return:
#   0 if exists.
#   1 if not exists.
isIdentitiesRoundcubeExist() {
    local standard="$1"
    local email="$2"
    local user_id="$3"
    identity_id=$(getIdentityIdRoundcubeByEmail "$standard" "$email" "$user_id")
    if [ -n "$identity_id" ];then
        return 0
    fi
    return 1
}

# Insert the username to table users in roundcube database.
#
# Globals:
#   Used: roundcube_db_user, roundcube_db_user_password,
#         roundcube_db_user_host, roundcube_db_name
#   Modified: identity_id
#
# Arguments:
#   $1: standard
#   $2: email
#   $3: user_id
#   $4: name
#   $5: organization
#   $6: reply_to
#   $7: bcc
#   $8: html_signature (if omit, default to 0)
#
# Return:
#   0 if exists.
#   1 if not exists.
insertIdentitiesRoundcube() {
    local standard="$1"
    local email="$2"
    local user_id="$3"
    local name="$4"
    local organization="$5"
    local reply_to="$6"
    local bcc="$7"
    local html_signature="$8"; [ -n "$html_signature" ] || html_signature=0
    local now=$(date +%Y-%m-%d\ %H:%M:%S)
    local sql="INSERT INTO identities
        (user_id, changed, del, standard, name, organization, email, \`reply-to\`, bcc, html_signature)
        VALUES
        ('$user_id', '$now', 0, $standard, '$name', '$organization', '$email', '$reply_to', '$reply_to', $html_signature);"
    local u="$roundcube_db_user"
    local p="$roundcube_db_user_password"
    mysql --defaults-extra-file=<(printf "[client]\nuser = %s\npassword = %s" "$u" "$p") \
        -h "$roundcube_db_user_host" "$roundcube_db_name" -e "$sql"
    identity_id=$(getIdentityIdRoundcubeByEmail "$standard" "$email" "$user_id")
    if [ -n "$identity_id" ];then
        return 0
    fi
    return 1
}

# ini code untuk domain localhost.
# bagaimana untuk domain beneran.
yellow Mengecek domain '`'$domain'`' apakah terdaftar di Module Mail ISPConfig.
__ Create PHP Script from template '`'mail_domain_get_by_domain'`'.
template=mail_domain_get_by_domain
template_temp=$(ispconfig.sh mktemp "${template}.php")
template_temp_path=$(ispconfig.sh realpath "$template_temp")
__; magenta template_temp_path="$template_temp_path"
sed -i -E -e '/echo/d' -e '/^\s*$/d' -e 's,\t,    ,g' -e 's/print_r/var_export/' \
    -e 's/\$domain\s+=\s+[^;]+;/\$domain = "'"$domain"'";/' \
    "$template_temp_path"
contents=$(<"$template_temp_path")
__ Execute PHP Script.
magenta "$contents"
string=$(ispconfig.sh php "$template_temp")
# VarDump string
string=$(php -r "echo serialize($string);")
# VarDump string
__ Cleaning temporary file.
__; magenta rm "$template_temp_path"
rm "$template_temp_path"
php=$(cat <<'EOF'
$args = $_SERVER['argv'];
$mode = $args[1];
$array = unserialize($args[2]);
//var_dump($array);
$each = array_shift($array);
switch ($mode) {
    case 'is_exists':
        isset($each['domain_id']) ? exit(0) : exit(1);
        break;

    case '':
        // Do something.
        break;

    default:
        // Do something.
        break;
}
EOF
)
notfound=
if php -r "$php" is_exists "$string";then
    __ Domain terdaftar
else
    __ Domain tidak terdaftar
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Mendaftarkan domain '`'$domain'`' di Module Mail ISPConfig.
    __ Create PHP Script from template '`'mail_domain_add'`'.
    template=mail_domain_add
    template_temp=$(ispconfig.sh mktemp "${template}.php")
    template_temp_path=$(ispconfig.sh realpath "$template_temp")
    __; magenta template_temp_path="$template_temp_path"
    parameter=''
    parameter+="\t\t'server_id' => '1',\n"
    parameter+="\t\t'domain' => '${domain}',\n"
    parameter+="\t\t'active' => 'y',\n"
    parameter+="\t\t'dkim' => 'n',\n"
    sed -i -E \
        -e ':a;N;$!ba;s|\$params\s+=\s+[^;]+;|\$params = array(\n'"${parameter}"'\n\t);|g' \
        "$template_temp_path"
    sed -i -E -e '/echo/d' -e '/^\s*$/d' -e 's,\t,    ,g' \
        "$template_temp_path"
    contents=$(<"$template_temp_path")
    __ Execute PHP Script.
    magenta "$contents"
    ispconfig.sh php "$template_temp"
    __ Cleaning temporary file.
    __; magenta rm "$template_temp_path"
    rm "$template_temp_path"
    __ Verifikasi:
    template=mail_domain_get_by_domain
    template_temp=$(ispconfig.sh mktemp "${template}.php")
    template_temp_path=$(ispconfig.sh realpath "$template_temp")
    sed -i -E -e '/echo/d' -e '/^\s*$/d' -e 's,\t,    ,g' -e 's/print_r/var_export/' \
        -e 's/\$domain\s+=\s+[^;]+;/\$domain = "'"$domain"'";/' \
        "$template_temp_path"
    contents=$(<"$template_temp_path")
    magenta "$contents"
    string=$(ispconfig.sh php "$template_temp")
    string=$(php -r "echo serialize($string);")
    rm "$template_temp_path"
    if php -r "$php" is_exists "$string";then
        __; green Domain berhasil terdaftar.
    else
        __; red Domain gagal terdaftar.; x
    fi
fi

# @todo, jika domain bukan localhost, maka perlu dkim.
blue Mailbox
____

user="$mailbox_admin"
host="$domain"

yellow Mengecek mailbox "$user"@"$host"
if isEmailIspconfigExist "$user" "$host";then
    __ Email "$user"@"$host" already exists.
    __; magenta mailuser_id=$mailuser_id
elif insertEmailIspconfig "$user" "$host";then
    __; green "$user"@"$host" created.
    __; magenta mailuser_id=$mailuser_id
else
    __; red Email "$user"@"$host" failed to create.; x
fi
____

destination="$user"@"$host"

for user in $mailbox_host $mailbox_web $mailbox_post
do
    source="$user"@"$host"
    # VarDump source
    yellow Mengecek alias of "$source"
    if isEmailAliasIspconfigExist "$source" "$destination";then
        __ Email "$source" alias of "$destination" already exists.
        __; magenta forwarding_id=$forwarding_id
    elif insertEmailAliasIspconfig "$source" "$destination";then
        __; green Email "$source" alias of "$destination" created.
        __; magenta forwarding_id=$forwarding_id
    else
        __; red Email "$source" alias of "$destination" failed to create.; x
    fi
    ____
done

username=$mailbox_admin@$domain
yellow Mengecek username "$username" di Roundcube.
if isUsernameRoundcubeExist "$username";then
    __ Username "$username" already exists.
    __; magenta user_id=$user_id
elif insertUsernameRoundcube "$username";then
    __; green Username "$username" created.
    __; magenta user_id=$user_id
else
    __; red Username "$username" failed to create.; x
fi
____

yellow Mengecek Identities "$username" di Roundcube.
if isIdentitiesRoundcubeExist 1 "$username" "$user_id";then
    __ Identities "$username" already exists.
    __; magenta identity_id=$identity_id
elif insertIdentitiesRoundcube 1 "$username" "$user_id" "$mailbox_admin";then
    __; green Identities "$username" created.
    __; magenta identity_id=$identity_id
else
    __; red Identities "$username" failed to create.; x
fi
____

for user in $mailbox_host $mailbox_web $mailbox_post
do
    source="$user"@"$host"
    yellow Mengecek Identities "$source" di Roundcube.
    __; magenta source $source
    if isIdentitiesRoundcubeExist 0 "$source" "$user_id";then
        __ Identities "$source" alias of "$destination" already exists.
        __; magenta identity_id=$identity_id
    elif insertIdentitiesRoundcube 0 "$source" "$user_id";then
        __; green Identities "$source" alias of "$destination" created.
        __; magenta identity_id=$identity_id
    else
        __; red Identities "$source" alias of "$user_id" failed to create.; x
    fi
    ____
done
