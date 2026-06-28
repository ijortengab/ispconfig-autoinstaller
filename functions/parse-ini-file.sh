#!/bin/bash

parse-ini-file() {
    php=$(cat <<'EOF'
$args = $_SERVER['argv'];
$mode = $_SERVER['argv'][1];
switch ($mode) {
    case 'is_different':
        $file = $_SERVER['argv'][2];
        $array = unserialize($_SERVER['argv'][3]);
        $autoinstall = parse_ini_file($file);
        if (!isset($autoinstall)) {
            exit(255);
        }
        $is_different = !empty(array_diff_assoc($array, $autoinstall));
        $is_different ? exit(0) : exit(1);
        break;
    case 'get' :
        $file = $_SERVER['argv'][2];
        $key = $_SERVER['argv'][3];
        $autoinstall = parse_ini_file($file);
        echo array_key_exists($key, $autoinstall) ? $autoinstall[$key] : '';
        break;
}
EOF
    )
    php -r "$php" "$@"
}
