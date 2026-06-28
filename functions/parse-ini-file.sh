#!/bin/bash

parse-ini-file() {
    php=$(cat <<'EOF'

function dump_to_ini(array $data, string $filePath): bool {
    $content = "";

    foreach ($data as $section => $values) {
        if (is_array($values) && !is_list_array($values)) {
            // Write section header
            $content .= "[$section]" . PHP_EOL;

            // Write key-value pairs for this section
            foreach ($values as $key => $value) {
                $content .= format_ini_line($key, $value);
            }
            $content .= PHP_EOL;
        } else {
            // Write top-level items
            $content .= format_ini_line($section, $values);
        }
    }
    $content .= PHP_EOL;

    return file_put_contents($filePath, trim($content)) !== false;
}

function format_ini_line($key, $value): string {
    // If the value is a list of items with the same key name
    if (is_array($value)) {
        $lines = "";
        foreach ($value as $item) {
            $lines .= "{$key}[]=" . format_ini_value($item) . PHP_EOL;
        }
        return $lines;
    }

    // Regular single key-value pair
    return "$key=" . format_ini_value($value) . PHP_EOL;
}

function format_ini_value($value): string {
    if (is_numeric($value)) {
        return $value;
    }
    if (is_bool($value)) {
        return $value ? 'true' : 'false';
    }
    if ($value === null) {
        return 'null';
    }
    // return '"' . str_replace('"', '\"', $value) . '"';
    return $value;
}

function is_list_array(array $arr): bool {
    if (empty($arr)) return true;
    return array_keys($arr) === range(0, count($arr) - 1);
}

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

    case 'merge' :
        $file = $_SERVER['argv'][2];
        $ini_string = $_SERVER['argv'][3];
        $array = parse_ini_file($file, true);
        if (!isset($array)) {
            exit(255);
        }
        $replacements = parse_ini_string($ini_string, true);
        $array = array_replace_recursive($array, $replacements);
        dump_to_ini($array, $file);
        break;
}
EOF
    )
    php -r "$php" "$@"
}
