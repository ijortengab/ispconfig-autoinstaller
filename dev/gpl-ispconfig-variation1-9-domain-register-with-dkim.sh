#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

# Dependencies of this script only.
[ -n "$domain" ] || { red "Value of variable \$domain required."; x; }

yellow Mengecek domain '`'$domain'`' di Module Mail ISPConfig.
php=$(cat <<-'EOF'
$stdin = '';
while (FALSE !== ($line = fgets(STDIN))) {
   $stdin .= $line;
}
$result = unserialize($stdin);
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
__; magenta template_temp_path="$template_temp_path"
sed -i -E -e '/echo/d' -e '/^\s*$/d' -e 's,\t,    ,g' -e 's/print_r/echo serialize/' \
    -e 's/\$domain\s+=\s+[^;]+;/\$domain = "'"$domain"'";/' \
    "$template_temp_path"
contents=$(<"$template_temp_path")
__ Execute PHP Script.
magenta "$contents"
stdout=$(ispconfig.sh php "$template_temp")
php -r "$php" isset <<< "$stdout" || notfound=1
if [ -z "$notfound" ];then
    _dkim_selector=$(php -r "$php" get_dkim_selector <<< "$stdout")
    dkim_public=$(php -r "$php" get_dkim_public <<< "$stdout")
    if [[ ! "$dkim_selector" == "$_dkim_selector" ]];then
        __; red Terdapat perbedaan antara dkim_selector versi database dengan user input.
        __; red Menggunakan value versi database.
        __; magenta dkim_selector="$_dkim_selector"
        dkim_selector="$_dkim_selector"
    fi
    dns_record=$(echo "$dkim_public" | sed -e "/-----BEGIN PUBLIC KEY-----/d" -e "/-----END PUBLIC KEY-----/d" | tr '\n' ' ' | sed 's/\ //g')
fi

__ Cleaning temporary file.
__; magenta rm "$template_temp_path"
rm "$template_temp_path"
____

json=
if [ -n "$notfound" ];then
    yellow Generate DKIM Public and Private Key
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
    json=$(php -r "$php" "$dirname" "${dirname}/${temp_ajax_get_json}" "$domain" "$dkim_selector")
    __ Cleaning temporary file.
    __; magenta rm "$temp_ajax_get_json"
    rm "${dirname}/${temp_ajax_get_json}"
    ____
fi
if [ -n "$json" ];then
    dkim_private=$(php -r "echo (json_decode(fgets(STDIN)))->dkim_private;" <<< "$json")
    dkim_public=$(php -r "echo (json_decode(fgets(STDIN)))->dkim_public;" <<< "$json")
    dns_record=$(php -r "echo (json_decode(fgets(STDIN)))->dns_record;" <<< "$json")
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
    parameter+="\t\t'dkim' => 'y',\n"
    parameter+="\t\t'dkim_selector' => '${dkim_selector}',\n"
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
    magenta "$contents"
    ispconfig.sh php "$template_temp"
    __ Cleaning temporary file.
    __; magenta rm "$template_temp_path"
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
    magenta "$contents"
    notfound=
    ispconfig.sh php "$template_temp" | php -r "$php" || notfound=1
    if [ -n "$notfound" ];then
        __; red Domain gagal terdaftar.; x
    else
        __; green Domain berhasil terdaftar.
    fi
    ____
fi
