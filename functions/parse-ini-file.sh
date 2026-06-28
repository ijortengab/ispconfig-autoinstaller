#!/bin/bash

parse-ini-file() {
    php=$(cat <<'EOF'

$args = $_SERVER['argv'];
$mode = $_SERVER['argv'][1];
switch ($mode) {
    case 'is_different':
        $file = $_SERVER['argv'][2];
        $ini_string = $_SERVER['argv'][3];
        $arrays_1 = parse_ini_file($file, true);
        if (!isset($arrays_1)) {
            exit(255);
        }
        $array = parse_ini_string($ini_string, true);
        $is_different = false;
        foreach ($array as $key => $value) {
            if (array_key_exists($key, $arrays_1)) {
                 $is_different = !empty(array_diff_assoc($array[$key], $arrays_1[$key]));
                 if ($is_different) {
                     break;
                 }
            }
            else {
                $is_different = true;
                break;
            }
        }
        $is_different ? exit(0) : exit(1);
        break;

    case 'get' :
        $file = $_SERVER['argv'][2];
        $section = null;
        $key = $_SERVER['argv'][3];
        if (isset($_SERVER['argv'][4])) {
            $section = $_SERVER['argv'][3];
            $key = $_SERVER['argv'][4];
        }
        $autoinstall = isset($section) ? parse_ini_file($file, true): parse_ini_file($file);
        if (isset($section)) {
            echo isset($autoinstall[$section][$key]) ? $autoinstall[$section][$key] : '';
        }
        else {
            echo isset($autoinstall[$key]) ? $autoinstall[$key] : '';
        }
        break;
}
EOF
    )
    php -r "$php" "$@"
}
