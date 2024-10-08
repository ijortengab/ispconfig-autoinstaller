#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then domain="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --root-sure) root_sure=1; shift ;;
        --[^-]*) shift ;;
        *) _new_arguments+=("$1"); shift ;;
    esac
done
set -- "${_new_arguments[@]}"
unset _new_arguments

# Common Functions.
red() { echo -ne "\e[91m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
green() { echo -ne "\e[92m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
yellow() { echo -ne "\e[93m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
blue() { echo -ne "\e[94m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
magenta() { echo -ne "\e[95m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
error() { echo -n "$INDENT" >&2; red '#' "$@" >&2; echo >&2; }
success() { echo -n "$INDENT" >&2; green '#' "$@" >&2; echo >&2; }
chapter() { echo -n "$INDENT" >&2; yellow '#' "$@" >&2; echo >&2; }
title() { echo -n "$INDENT" >&2; blue '#' "$@" >&2; echo >&2; }
code() { echo -n "$INDENT" >&2; magenta "$@" >&2; echo >&2; }
x() { echo >&2; exit 1; }
e() { echo -n "$INDENT" >&2; echo "#" "$@" >&2; }
_() { echo -n "$INDENT" >&2; echo -n "#" "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "#" '    ' >&2; [ -n "$1" ] && echo "$@" >&2 || echo -n  >&2; }
____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

# Command.
command="$1"; shift
if [ -n "$command" ];then
    case "$command" in
        add|delete|isset|get_dns_record) ;;
        *) echo -e "\e[91m""Command ${command} is unknown.""\e[39m"; exit 1
    esac
fi

# Functions.
printVersion() {
    echo '0.9.3'
}
printHelp() {
    title RCM ISPConfig Control
    _ 'Variation '; yellow Manage Domain; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << 'EOF'
Usage: rcm-ispconfig-control-manage-domain [command] [options]

Available commands: add, delete, isset, get_dns_record.

Options:
   --domain
        Set the domain to control.

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.
   --root-sure
        Bypass root checking.

Environment Variables:
   DKIM_SELECTOR
        Default to default.
   MAILBOX_WEB
        Default to webmaster

Dependency:
   ispconfig.sh
   php
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { echo -e "\e[91m""Unable to proceed, "'`'"${line}"'`'" command not found." "\e[39m"; exit 1; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Functions.
fileMustExists() {
    # global used:
    # global modified:
    # function used: __, success, error, x
    if [ -f "$1" ];then
        __; green File '`'$(basename "$1")'`' ditemukan.; _.
    else
        __; red File '`'$(basename "$1")'`' tidak ditemukan.; x
    fi
}
isFileExists() {
    # global used:
    # global modified: found, notfound
    # function used: __
    found=
    notfound=
    if [ -f "$1" ];then
        __ File '`'$(basename "$1")'`' ditemukan.
        found=1
    else
        __ File '`'$(basename "$1")'`' tidak ditemukan.
        notfound=1
    fi
}
backupFile() {
    local mode="$1"
    local oldpath="$2" i newpath
    i=1
    newpath="${oldpath}.${i}"
    if [ -f "$newpath" ]; then
        let i++
        newpath="${oldpath}.${i}"
        while [ -f "$newpath" ] ; do
            let i++
            newpath="${oldpath}.${i}"
        done
    fi
    case $mode in
        move)
            mv "$oldpath" "$newpath" ;;
        copy)
            local user=$(stat -c "%U" "$oldpath")
            local group=$(stat -c "%G" "$oldpath")
            cp "$oldpath" "$newpath"
            chown ${user}:${group} "$newpath"
    esac
}
link_symbolic() {
    local source="$1"
    local target="$2"
    local sudo="$3"
    local create
    _success=
    [ -e "$source" ] || { error Source not exist: $source.; x; }
    [ -n "$target" ] || { error Target not defined.; x; }
    [[ $(type -t backupFile) == function ]] || { error Function backupFile not found.; x; }

    chapter Membuat symbolic link.
    __ source: '`'$source'`'
    __ target: '`'$target'`'
    if [ -h "$target" ];then
        __ Path target saat ini sudah merupakan symbolic link: '`'$target'`'
        __; _, Mengecek apakah link merujuk ke '`'$source'`':
        _dereference=$(stat ${stat_cached} "$target" -c %N)
        match="'$target' -> '$source'"
        if [[ "$_dereference" == "$match" ]];then
            _, ' 'Merujuk.; _.
        else
            _, ' 'Tidak merujuk.; _.
            __ Melakukan backup.
            backupFile move "$target"
            create=1
        fi
    elif [ -e "$target" ];then
        __ File/directory bukan merupakan symbolic link.
        __ Melakukan backup.
        backupFile move "$target"
        create=1
    else
        create=1
    fi
    if [ -n "$create" ];then
        __ Membuat symbolic link '`'$target'`'.
        if [ -n "$sudo" ];then
            __; magenta sudo -u '"'$sudo'"' ln -s '"'$source'"' '"'$target'"'; _.
            sudo -u "$sudo" ln -s "$source" "$target"
        else
            __; magenta ln -s '"'$source'"' '"'$target'"'; _.
            ln -s "$source" "$target"
        fi
        __ Verifikasi
        if [ -h "$target" ];then
            _dereference=$(stat ${stat_cached} "$target" -c %N)
            match="'$target' -> '$source'"
            if [[ "$_dereference" == "$match" ]];then
                __; green Symbolic link berhasil dibuat.; _.
                _success=1
            else
                __; red Symbolic link gagal dibuat.; x
            fi
        fi
    fi
    ____
}
vercomp() {
    # https://www.google.com/search?q=bash+compare+version
    # https://stackoverflow.com/a/4025065
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]];then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}

# Title.
title rcm-ispconfig-control-manage-domain
____

# Requirement, validate, and populate value.
chapter Dump variable.
DKIM_SELECTOR=${DKIM_SELECTOR:=default}
code 'DKIM_SELECTOR="'$DKIM_SELECTOR'"'
MAILBOX_WEB=${MAILBOX_WEB:=webmaster}
code 'MAILBOX_WEB="'$MAILBOX_WEB'"'
code 'command="'$command'"'
ispconfig_domain_exists_sure=
code 'ispconfig_domain_exists_sure="'$ispconfig_domain_exists_sure'"'
delay=.5; [ -n "$fast" ] && unset delay
if [ -z "$domain" ];then
    error "Argument --domain required."; x
fi
code 'domain="'$domain'"'
vercomp `stat --version | head -1 | grep -o -E '\S+$'` 8.31
if [[ $? -lt 2 ]];then
    stat_cached=' --cached=never'
else
    stat_cached=''
fi
____

if [ -z "$root_sure" ];then
    chapter Mengecek akses root.
    if [[ "$EUID" -ne 0 ]]; then
        error This script needs to be run with superuser privileges.; x
    else
        __ Privileges.
    fi
    ____
fi

chapter Mengecek domain '`'$domain'`' di Module Mail ISPConfig.
php=$(cat <<-'EOF'
$stdin = '';
while (FALSE !== ($line = fgets(STDIN))) {
   $stdin .= $line;
}
$result = @unserialize($stdin);
if ($result === false) {
    echo('Unserialize failed: '. $stdin.PHP_EOL);
    exit(1);
}
$mode = $_SERVER['argv'][1];
switch ($mode) {
    case 'get_dkim_public':
        echo $result[0]['dkim_public'];
        break;

    case 'get_dkim_selector':
        echo $result[0]['dkim_selector'];
        break;

    case 'get_dkim_private':
        echo $result[0]['dkim_private'];
        break;

    case 'isset':
        if ($result === []) { // empty array
            exit(1); // not found.
        }
        exit(0);
        break;
}
EOF
)
notfound=
__ Create PHP Script from template '`'mail_domain_get_by_domain'`'.
template=mail_domain_get_by_domain
template_temp=$(ispconfig.sh mktemp "${template}.php")
template_temp_path=$(ispconfig.sh realpath "$template_temp")
__; magenta template_temp_path="$template_temp_path"; _.
sed -i -E -e '/echo/d' -e '/^\s*$/d' -e 's,\t,    ,g' -e 's/print_r/echo serialize/' \
    -e 's/\$domain\s+=\s+[^;]+;/\$domain = "'"$domain"'";/' \
    "$template_temp_path"
contents=$(<"$template_temp_path")
__ Execute PHP Script.
magenta "$contents"; _.
stdout=$(ispconfig.sh php "$template_temp")
__ Standard Output.
magenta stdout="$stdout"; _.
php -r "$php" isset <<< "$stdout" || notfound=1
if [ -z "$notfound" ];then
    __ Domain '`'$domain'`' telah terdaftar di ISPConfig.
    ispconfig_domain_exists_sure=1
    if [[ $command == isset ]];then
        exit 0
    fi
    _dkim_selector=$(php -r "$php" get_dkim_selector <<< "$stdout")
    dkim_public=$(php -r "$php" get_dkim_public <<< "$stdout")
    if [[ ! "$DKIM_SELECTOR" == "$_dkim_selector" ]];then
        __; red Terdapat perbedaan antara dkim_selector versi database dengan user input.; _.
        __; red Menggunakan value versi database.; _.
        DKIM_SELECTOR="$_dkim_selector"
        __; magenta DKIM_SELECTOR="$DKIM_SELECTOR"; _.
    fi
    # Populate Global Variable
    dns_record=$(echo "$dkim_public" | sed -e "/-----BEGIN PUBLIC KEY-----/d" -e "/-----END PUBLIC KEY-----/d" | tr '\n' ' ' | sed 's/\ //g')
    if [[ $command == get_dns_record ]];then
        echo "$dns_record"
        exit 0
    fi
else
    __ Domain '`'$domain'`' belum terdaftar di ISPConfig.
    ispconfig_domain_exists_sure=
    if [[ $command == isset ]];then
        exit 1
    fi
fi

__ Cleaning temporary file.
__; magenta rm "$template_temp_path"; _.
rm "$template_temp_path"
____

json=
if [[ $command == add && -n "$notfound" ]];then
    chapter Generate DKIM Public and Private Key
    token=$(pwgen 6 -1)
    . ispconfig.sh export > /dev/null
    dirname="$ispconfig_install_dir/interface/web/mail"
    temp_ajax_get_json="temp_ajax_get_json_${token}.php"
    cp "${dirname}/ajax_get_json.php" "${dirname}/${temp_ajax_get_json}"
    chmod go-r "${dirname}/${temp_ajax_get_json}"
    chmod go-w "${dirname}/${temp_ajax_get_json}"
    chmod go-x "${dirname}/${temp_ajax_get_json}"
    __ Mempersiapkan file '`'${dirname}/${temp_ajax_get_json}'`'
    fileMustExists "${dirname}/${temp_ajax_get_json}"
    sed -i "/\$app->auth->check_module_permissions('mail');/d" "${dirname}/${temp_ajax_get_json}"
    sed -i "s,if (\$dkim_strength==''),if (\$dkim_strength==0),g" "${dirname}/${temp_ajax_get_json}"
    php=$(cat <<- 'EOF'
$dirname = $_SERVER['argv'][1];
$file = $_SERVER['argv'][2];
$domain = $_SERVER['argv'][3];
$dkim_selector = $_SERVER['argv'][4];
chdir($dirname);
$_GET['type'] = 'create_dkim';
$_GET['domain_id'] = $domain;
$_GET['dkim_selector'] = $dkim_selector;
$_GET['dkim_public'] = '';
include_once $file;
EOF
)
    json=$(php -r "$php" "$dirname" "${dirname}/${temp_ajax_get_json}" "$domain" "$DKIM_SELECTOR")
    __ Standard Output.
    magenta "$json"; _.
    __ Cleaning temporary file.
    __; magenta rm "$temp_ajax_get_json"; _.
    rm "${dirname}/${temp_ajax_get_json}"
    ____
fi
if [[ $command == add && -n "$json" ]];then
    dkim_private=$(php -r "echo (json_decode(fgets(STDIN)))->dkim_private;" <<< "$json")
    dkim_public=$(php -r "echo (json_decode(fgets(STDIN)))->dkim_public;" <<< "$json")
    dns_record=$(php -r "echo (json_decode(fgets(STDIN)))->dns_record;" <<< "$json")
    if [ -z "$dns_record" ];then
        __; red DNS record not found.; x
    fi
    chapter Mendaftarkan domain '`'$domain'`' di Module Mail ISPConfig.
    __ Create PHP Script from template '`'mail_domain_add'`'.
    template=mail_domain_add
    template_temp=$(ispconfig.sh mktemp "${template}.php")
    template_temp_path=$(ispconfig.sh realpath "$template_temp")
    __; magenta template_temp_path="$template_temp_path"; _.
    parameter=''
    parameter+="\t\t'server_id' => '1',\n"
    parameter+="\t\t'domain' => '${domain}',\n"
    parameter+="\t\t'active' => 'y',\n"
    parameter+="\t\t'dkim' => 'y',\n"
    parameter+="\t\t'dkim_selector' => '${DKIM_SELECTOR}',\n"
    parameter+="\t\t'dkim_private' => '"
    while IFS= read -r line; do
        parameter+="${line}\n"
    done <<< "$dkim_private"
    parameter="${parameter:0:-2}"
    parameter+="',\n"
    parameter+="\t\t'dkim_public' => '"
    while IFS= read -r line; do
        parameter+="${line}\n"
    done <<< "$dkim_public"
    parameter="${parameter:0:-2}"
    parameter+="',\n"
    sed -i -E \
        -e ':a;N;$!ba;s|\$params\s+=\s+[^;]+;|\$params = array(\n'"${parameter}"'\n\t);|g' \
        "$template_temp_path"
    sed -i -E -e '/echo/d' -e '/^\s*$/d' -e 's,\t,    ,g' \
        "$template_temp_path"
    contents=$(<"$template_temp_path")
    __ Execute PHP Script.
    magenta "$contents"; _.
    ispconfig.sh php "$template_temp"
    __ Cleaning temporary file.
    __; magenta rm "$template_temp_path"; _.
    rm "$template_temp_path"
    __ Verifikasi:
    php=$(cat <<-'EOF'
$stdin = '';
while (FALSE !== ($line = fgets(STDIN))) {
   $stdin .= $line;
}
$result = unserialize($stdin);
if ($result === []) { // empty array
    exit(1); // not found.
}
exit(0);
EOF
)
    template=mail_domain_get_by_domain
    template_temp=$(ispconfig.sh mktemp "${template}.php")
    template_temp_path=$(ispconfig.sh realpath "$template_temp")
    sed -i -E -e '/echo/d' -e '/^\s*$/d' -e 's,\t,    ,g' -e 's/print_r/echo serialize/' \
        -e 's/\$domain\s+=\s+[^;]+;/\$domain = "'"$domain"'";/' \
        "$template_temp_path"
    contents=$(<"$template_temp_path")
    magenta "$contents"; _.
    notfound=
    ispconfig.sh php "$template_temp" | php -r "$php" || notfound=1
    if [ -n "$notfound" ];then
        __; red Domain gagal terdaftar.; x
    else
        __; green Domain berhasil terdaftar.; _.
    fi
    ____

    chapter Membuat welcome mail.
    filename='/usr/local/share/ispconfig/mail/welcome_email_'$domain'.html'
    mkdir -p $(dirname "$filename")
    cat <<-EOF > "$filename"
From: Webmaster <$MAILBOX_WEB@$domain>
Subject: Welcome to your new email account.

<p>Welcome to your new email account. Your webmaster.</p>

EOF
    link_symbolic "$filename" "$ispconfig_install_dir/server/conf-custom/mail/welcome_email_${domain}.html"
    ____
fi

exit 0

# parse-options.sh \
# --without-end-options-double-dash \
# --compact \
# --clean \
# --no-hash-bang \
# --no-original-arguments \
# --no-error-invalid-options \
# --no-error-require-arguments << EOF | clip
# FLAG=(
# --fast
# --version
# --help
# --root-sure
# )
# VALUE=(
# --domain
# )
# CSV=(
# )
# EOF
# clear
