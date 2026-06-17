#!/bin/bash

# Kembalikan INDENT ke semula.
INDENT="$OLD_INDENT"

require vendor/ijortengab/rcm/functions/classes/rcm-paragraph.sh

green2() {
    local word=$1
    hN "$word" green
}
hN() {
    # hightlightNumber
    local other=$2
    [ -z "$other" ] && other=_,
    local number=yellow
    local word=$1 segment
    local current last
    for ((i = 0 ; i < ${#word} ; i++)); do
        if [[ ${word:$i:1} =~ ^[0-9]+$ ]];then
            current=number
        else
            current=other
        fi
        if [[ -n "$last" && ! "$last" == "$current" ]];then
            ${!last} $segment
            segment=
        fi
        last="$current"
        segment+=${word:$i:1}
    done
    ${!last} $segment
}
bundle-available() {
    bundle_available=()
    bundle_available+=("debian11a;debian;11")
    bundle_available+=("ubuntu22a;ubuntu;22.04")
    bundle_available+=("debian11b;debian;11")
    bundle_available+=("debian12a;debian;12")
    bundle_available+=("debian12b;debian;12")
    bundle_available+=("ubuntu24a;ubuntu;24.04")
}
variation-eligible() {
    local variation _id _version_id
    bundle-available
    variation_eligible=()
    if [ -f /etc/os-release ];then
        . /etc/os-release
    fi
    for each in "${bundle_available[@]}"; do
        variation=$(cut -d';' -f1 <<< "$each")
        _id=$(cut -d';' -f2 <<< "$each")
        _version_id=$(cut -d';' -f3 <<< "$each")
        if [[ "$_id" == "$ID" && "$_version_id" == "$VERSION_ID" ]];then
            variation_eligible+=("$variation")
        fi
    done
}
helper-bundle-available() {
    local wrap
    local lines=()
    if [ -f /etc/os-release ];then
        . /etc/os-release
    fi
    _; _.
    longest_text='        #         Variation ubuntu24a. Ubuntu 24.04, PHP 8.3, ISPConfig 3.2.12p1, PHPMyAdmin 5.2.2, Roundcube 1.6.10.'
    if [[ $(tput cols) -gt "${#longest_text}" ]];then
        wrap=
    else
        wrap=1
    fi
    a=debian11a b=Debian; c=11; d=7.4; e=3.2.7; f=5.2.0; g=1.6.0
    [[ "$ID" == debian && "$VERSION_ID" == 11 ]] && color=green2 || color=red;
    [ -n "$wrap" ] && lines+=("Variation <${color}>$a</${color}>. -->$b <hN>$c</hN>, -->PHP <hN>$d</hN>, -->ISPConfig <hN>$e</hN>,-->PHPMyAdmin <hN>$f</hN>, -->Roundcube <hN>$g</hN>.")
    [ -z "$wrap" ] && { ___; _, 'Variation '; $color $a; _, ". $b "; hN $c; _, ',    PHP '; hN $d; _, ', ISPConfig '; hN $e; _, ',    PHPMyAdmin '; hN $f; _, ', Roundcube '; hN $g; _, '.'; _.; }

    a=debian11b b=Debian; c=11; d=8.1; e=3.2.11p2; f=5.2.1; g=1.6.6
    [[ "$ID" == debian && "$VERSION_ID" == 11 ]] && color=green2 || color=red;
    [ -n "$wrap" ] && lines+=("Variation <${color}>$a</${color}>. -->$b <hN>$c</hN>, -->PHP <hN>$d</hN>, -->ISPConfig <hN>$e</hN>,-->PHPMyAdmin <hN>$f</hN>, -->Roundcube <hN>$g</hN>.")
    [ -z "$wrap" ] && { ___; _, 'Variation '; $color $a; _, ". $b "; hN $c; _, ',    PHP '; hN $d; _, ', ISPConfig '; hN $e; _, ', PHPMyAdmin '; hN $f; _, ', Roundcube '; hN $g; _, '.'; _.; }

    a=ubuntu22a b=Ubuntu; c=22.04; d=7.4; e=3.2.7; f=5.2.0; g=1.6.0
    [[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 ]] && color=green2 || color=red;
    [ -n "$wrap" ] && lines+=("Variation <${color}>$a</${color}>. -->$b <hN>$c</hN>, -->PHP <hN>$d</hN>, -->ISPConfig <hN>$e</hN>,-->PHPMyAdmin <hN>$f</hN>, -->Roundcube <hN>$g</hN>.")
    [ -z "$wrap" ] && { ___; _, 'Variation '; $color $a; _, ". $b "; hN $c; _, ', PHP '; hN $d; _, ', ISPConfig '; hN $e; _, ',    PHPMyAdmin '; hN $f; _, ', Roundcube '; hN $g; _, '.'; _.; }

    a=debian12a b=Debian; c=12; d=8.1; e=3.2.10; f=5.2.1; g=1.6.2
    [[ "$ID" == debian && "$VERSION_ID" == 12 ]] && color=green2 || color=red;
    [ -n "$wrap" ] && lines+=("Variation <${color}>$a</${color}>. -->$b <hN>$c</hN>, -->PHP <hN>$d</hN>, -->ISPConfig <hN>$e</hN>,-->PHPMyAdmin <hN>$f</hN>, -->Roundcube <hN>$g</hN>.")
    [ -z "$wrap" ] && { ___; _, 'Variation '; $color $a; _, ". $b "; hN $c; _, ',    PHP '; hN $d; _, ', ISPConfig '; hN $e; _, ',   PHPMyAdmin '; hN $f; _, ', Roundcube '; hN $g; _, '.'; _.; }

    a=debian12b b=Debian; c=12; d=8.3 e=3.2.11p2; f=5.2.1; g=1.6.6
    [[ "$ID" == debian && "$VERSION_ID" == 12 ]] && color=green2 || color=red;
    [ -n "$wrap" ] && lines+=("Variation <${color}>$a</${color}>. -->$b <hN>$c</hN>, -->PHP <hN>$d</hN>, -->ISPConfig <hN>$e</hN>,-->PHPMyAdmin <hN>$f</hN>, -->Roundcube <hN>$g</hN>.")
    [ -z "$wrap" ] && { ___; _, 'Variation '; $color $a; _, ". $b "; hN $c; _, ',    PHP '; hN $d; _, ', ISPConfig '; hN $e; _, ', PHPMyAdmin '; hN $f; _, ', Roundcube '; hN $g; _, '.'; _.; }

    a=ubuntu24a b=Ubuntu; c=24.04; d=8.3; e=3.2.12p1; f=5.2.2; g=1.6.10
    [[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 ]] && color=green2 || color=red;
    [ -n "$wrap" ] && lines+=("Variation <${color}>$a</${color}>. -->$b <hN>$c</hN>, -->PHP <hN>$d</hN>, -->ISPConfig <hN>$e</hN>,-->PHPMyAdmin <hN>$f</hN>, -->Roundcube <hN>$g</hN>.")
    [ -z "$wrap" ] && { ___; _, 'Variation '; $color $a; _, ". $b "; hN $c; _, ', PHP '; hN $d; _, ', ISPConfig '; hN $e; _, ', PHPMyAdmin '; hN $f; _, ', Roundcube '; hN $g; _, '.'; _.; }

    if [ -n "$wrap" ];then
        lines_cloned=("${lines[@]}")
        lines=()
        for line in "${lines_cloned[@]}"; do
            lines+=("$(echo "$line" | sed -E s,-+\>,$'\t',g)")
        done
        unset lines_cloned
        plain=
        for each in "${lines[@]}"; do
            plain+="$each"$'\n'
        done
        # 4 Variasi.
        # rcm-paragraph printed-all-at-once -- --indent=2 --indent-hanging=1 <<< "$plain"
        rcm-paragraph printed-per-line -- --indent=2 --indent-hanging=1 <<< "$plain"
        # TAB_STOP_POSITION='21 14 9 19 18' rcm-paragraph printed-per-2-lines --indent=2 --indent-hanging=1 <<< "$plain"
        # TAB_STOP_POSITION='21 14 9 19 18' rcm-paragraph printed-per-n-lines 3 -- --indent=2 --indent-hanging=1 <<< "$plain"
    fi

    variation-eligible
    for each in "${variation_eligible[@]}";do
        echo $each
    done
}

# Execute.
helper-bundle-available
