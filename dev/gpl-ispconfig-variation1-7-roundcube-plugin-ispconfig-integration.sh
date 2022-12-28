#!/bin/bash

if [[ ! $parent_pid == $$ ]];then
    echo This script cannot execute directly. >&2; exit 1
fi

blue Roundcube Plugin: ISPConfig Integration
____

# @todo, semua diginiin aja, kasih filename dan filename_path
filename_path=/usr/local/share/roundcube/$roundcube_version/plugins/ispconfig3_account/config/config.inc.php
filename=$(basename "$filename_path")
yellow Mengecek existing '`'$filename'`'
magenta filename_path=$filename_path
isFileExists "$filename_path"
____

if [ -n "$notfound" ];then
    yellow Menginstall Plugin Integrasi Roundcube dan ISPConfig
    __ Mendownload Plugin
    cd /tmp
    if [ ! -f /tmp/ispconfig3_roundcube-master.zip ];then
        wget https://github.com/w2c/ispconfig3_roundcube/archive/master.zip -O ispconfig3_roundcube-master.zip
    fi
    __ Mengextract Plugin
    unzip -u -qq ispconfig3_roundcube-master.zip
    cd ./ispconfig3_roundcube-master
    cp -r ./ispconfig3_* /usr/local/share/roundcube/$roundcube_version/plugins/
    cd /usr/local/share/roundcube/$roundcube_version/plugins/ispconfig3_account/config
    cp config.inc.php.dist config.inc.php
    fileMustExists "$filename_path"
    ____
fi

php=$(cat <<'EOF'
$args = $_SERVER['argv'];
$mode = $args[1];
$file = $args[2];
// die('op');
$array = unserialize($args[3]);
include($file);
$config = isset($config) ? $config : [];
//$result = array_diff_assoc($array, $config);
//var_dump($config);
//var_dump($result);
$is_different = !empty(array_diff_assoc($array, $config));
//$config = array_replace_recursive($config, $array);
//var_dump($config);
//var_export($config);
switch ($mode) {
    case 'is_different':
        $is_different ? exit(0) : exit(1);
        break;
    case 'replace':
        if ($is_different) {
            $config = array_replace_recursive($config, $array);
            $content = '$config = '.var_export($config, true).';'.PHP_EOL;
            $content = <<< EOF
<?php
$content
EOF;
            file_put_contents($file, $content);
        }
        break;
}
EOF
)

# @todo, pake istilah ini aja.
yellow Mengecek variable pada script '`'$filename'`'
__ Mendapatkan informasi credential
remoteUserCredentialIspconfig $remote_user_roundcube
if [[ -z "$ispconfig_remote_user_password" ]];then
    __; red Informasi credentials tidak lengkap: '`'/usr/local/share/ispconfig/credential/remote/$remote_user_roundcube'`'.; x
else
    __; magenta ispconfig_remote_user_password="$ispconfig_remote_user_password"
fi
reference="$(php -r "echo serialize([
    'identity_limit' => false,
    'remote_soap_user' => '$remote_user_roundcube',
    'remote_soap_pass' => '$ispconfig_remote_user_password',
    'soap_url' => 'http://${ISPCONFIG_SUBDOMAIN_LOCALHOST}/remote/',
    'soap_validate_cert' => false,
]);")"
is_different=
if php -r "$php" is_different \
    "$filename_path" \
    "$reference";then
    is_different=1
    __ Diperlukan modifikasi file '`'$filename'`'.
else
    __ File '`'$filename'`' tidak ada perubahan.
fi
____

if [ -n "$is_different" ];then
    yellow Memodifikasi file '`'$filename'`'.
    __ Backup file "$filename_path"
    backupFile copy "$filename_path"
    php -r "$php" replace \
        "$filename_path" \
        "$reference"
    if php -r "$php" is_different \
    "$filename_path" \
    "$reference";then
        __; red Modifikasi file '`'$filename'`' gagal.; exit
    else
        __; green Modifikasi file '`'$filename'`' berhasil.
    fi
    ____
fi

# filename=$(basename "$filename_path")
# yellow Mengecek variable pada script '`'$filename'`'

filename_path=/usr/local/share/roundcube/${roundcube_version}/config/config.inc.php
filename=$(basename "$filename_path")
yellow Mengecek existing '`'$filename'`'
magenta filename_path=$filename_path
isFileExists "$filename_path"
____

#@todo, ganti semua replace menjadi save.
php=$(cat <<'EOF'
$args = $_SERVER['argv'];
$mode = $args[1];
$file = $args[2];
// die('op');
$array = unserialize($args[3]);
//var_dump($array);
// die('op');
include($file);
$config = isset($config) ? $config : [];
$is_different = false;
$merge=[];
$replace=[];
// Compare plugins.
$plugins = isset($config['plugins']) ? $config['plugins'] : [];
$arg_plugins = isset($array['plugins']) ? $array['plugins'] : [];
$result = array_diff($arg_plugins, $plugins);
if (!empty($result)) {
    $is_different = true;
    $merge['plugins'] = $result;
}
// Compare identity_select_headers.
$identity_select_headers = isset($config['identity_select_headers']) ? $config['identity_select_headers'] : [];
$arg_identity_select_headers = isset($array['identity_select_headers']) ? $array['identity_select_headers'] : [];
$result = array_diff($arg_identity_select_headers, $identity_select_headers);
if (!empty($result)) {
    $is_different = true;
    $merge['identity_select_headers'] = $result;
}
switch ($mode) {
    case 'is_different':
        $is_different ? exit(0) : exit(1);
        break;
    case 'save':
        if ($is_different && $merge) {
            $config = array_merge_recursive($config, $merge);
            $content = '$config = '.var_export($config, true).';'.PHP_EOL;
            $content = <<< EOF
<?php
$content
EOF;
            file_put_contents($file, $content);
        }
        break;
}
EOF
)

yellow Mengecek variable pada script '`'$filename'`'
reference="$(php -r "echo serialize([
    'plugins' => [
        'ispconfig3_account',
        'ispconfig3_autoreply',
        'ispconfig3_pass',
        'ispconfig3_filter',
        'ispconfig3_forward',
        'ispconfig3_wblist',
        'identity_select',
    ],
    'identity_select_headers' => ['To'],
]);")"
is_different=
if php -r "$php" is_different \
    "$filename_path" \
    "$reference";then
    is_different=1
    __ Diperlukan modifikasi file '`'$filename'`'.
else
    __ File '`'$filename'`' tidak ada perubahan.
fi
____

if [ -n "$is_different" ];then
    yellow Memodifikasi file '`'$filename'`'.
    __ Backup file "$filename_path"
    backupFile copy "$filename_path"
    php -r "$php" save \
        "$filename_path" \
        "$reference"
    if php -r "$php" is_different \
    "$filename_path" \
    "$reference";then
        __; red Modifikasi file '`'$filename'`' gagal.; exit
    else
        __; green Modifikasi file '`'$filename'`' berhasil.
    fi
    ____
fi
