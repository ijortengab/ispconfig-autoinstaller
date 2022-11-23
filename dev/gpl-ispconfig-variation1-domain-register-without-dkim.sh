#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

# Dependencies of this script only.
[ -n "$domain" ] || { red "Value of variable \$domain required."; x; }

# Dependencies.
command -v "ispconfig.sh" >/dev/null || { __; red Command "ispconfig.sh" not found.; x; }

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
