#!/bin/bash


# Usage Functions.
usage() {
    cat << EOF
Usage: rcm-ispconfig [options]

Available subcommands from command: rcm-ispconfig(helper mode-available).

Global Options.
   --version
        Print version of this script.
   --help
        Show this help.
   --non-interactive
        Skip prompt for every options.
   --
        Every arguments after double dash will pass to rcm-ispconfig-setup-variation-* command.

Dependency:
   rcm:0.18.0-alpha.6
   rcm-dig-apt
   rcm-dig-is-record-exists

Download:
   [rcm-ispconfig-setup-mode-init](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-mode-init.sh)
   [rcm-ispconfig-setup-mode-mail-domain](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-mode-mail-domain.sh)
   [rcm-ispconfig-setup-mode-website-ispconfig](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-mode-website-ispconfig.sh)
   [rcm-ispconfig-setup-mode-website-roundcube](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-mode-website-roundcube.sh)
   [rcm-ispconfig-setup-mode-website-phpmyadmin](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-mode-website-phpmyadmin.sh)
   [rcm-ispconfig-setup-mode-bundle](https://github.com/ijortengab/ispconfig-autoinstaller/raw/master/rcm/ispconfig/rcm-ispconfig-setup-mode-bundle.sh)

Subcommand Substitute:
   init: rcm-ispconfig-setup-mode-init
   mail-domain: rcm-ispconfig-setup-mode-mail-domain
   website-ispconfig: rcm-ispconfig-setup-mode-website-ispconfig
   website-roundcube: rcm-ispconfig-setup-mode-website-roundcube
   website-phpmyadmin: rcm-ispconfig-setup-mode-website-phpmyadmin
   bundle: rcm-ispconfig-setup-mode-bundle

RCM Config:
   --no-timer
   --no-confirmation
EOF
}

# Functions.
helper-generate-key() {
    title rcm-ispconfig::helper::generate-key
    ____

    chapter Variable dump.
    domain="$1"
    if [ -z "$domain" ];then
        error "Operand <domain> required."; x
    fi
    code 'domain="'$domain'"'
    php_fpm_user=ispconfig
    code 'php_fpm_user="'$php_fpm_user'"'
    prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
    code 'prefix="'$prefix'"'
    tempfile=$(mktemp -p "$prefix/interface/web/mail" -t rcm-ispconfig-ajax-get-json.XXXXXX)
    code 'tempfile="'$tempfile'"'
    cp "${prefix}/interface/web/mail/ajax_get_json.php" "$tempfile"
    chmod go-r "$tempfile"
    chmod go-w "$tempfile"
    chmod go-x "$tempfile"
    sed -i "/\$app->auth->check_module_permissions('mail');/d" "$tempfile"
    sed -i "s,if (\$dkim_strength==''),if (\$dkim_strength==0),g" "$tempfile"
    dirname="${prefix}/interface/web/mail"
    php=$(cat <<'EOF'
$mode = $_SERVER['argv'][1];
switch ($mode) {
    case 'ajax_get_json':
        $dirname = $_SERVER['argv'][2];
        $file = $_SERVER['argv'][3];
        $domain = $_SERVER['argv'][4];
        $dkim_selector = $_SERVER['argv'][5];
        chdir($dirname);
        $_GET['type'] = 'create_dkim';
        $_GET['domain_id'] = $domain;
        $_GET['dkim_selector'] = $dkim_selector;
        $_GET['dkim_public'] = '';
        include_once $file;
        break;
    default:
        fwrite(STDERR, 'Unknown mode.'.PHP_EOL);
        exit(1);
        break;
}
EOF
    )
    ____

    php -r "$php" ajax_get_json "$dirname" "$tempfile" "$domain" "$DKIM_SELECTOR"
    # @todo: serialize_array
    [ -n "$tempfile" ] && rm "$tempfile"
}
command-helper() {
    local helper=$1; shift
    if [ "$helper" == do-nothing ];then
        return
    fi
    if [ -n "$helper" ];then
        if [[ $(type -t "helper-${helper}") == function ]];then
            helper-${helper} "$@"
            exit 0
        else
            error Helper unknown: '`'"$helper"'`'.; x
        fi
    fi
}
mode-available() {
    # global mode_available
    mode_available=()
    # Source: ISPConfigDebianOS::runPerfectSetup()
    path=/usr/local/ispconfig/server/lib/config.inc.php
    if [ -f "$path" ]; then
        mode_available+=(mail-domain website-ispconfig website-roundcube website-phpmyadmin bundle)
    else
        mode_available+=(init)
    fi
}
helper-mode-available() {
    local wrap
    local lines=()
    local each
    mode-available
    _; _.
    longest_text='#     Mode website-phpmyadmin.    Add Interface of PHPMyAdmin (Database Client).'
    if [[ $(tput cols) -gt "${#longest_text}" ]];then
        wrap=
    else
        wrap=1
    fi
    a=init b='Install ISPConfig + LEMP Stack Setup.' c='LEMP Stack (Linux, Nginx, MySQL, PHP).'
    if ArraySearch $a mode_available[@] ]];then color=green; else color=red; fi
    [ -n "$wrap" ] && lines+=("Mode <${color}>$a</${color}>. -->$b")
    [ -n "$wrap" ] && lines+=("-->$c")
    [ -z "$wrap" ] && { ___; _, 'Mode '; $color $a; _, '.'; _, '               '; _, "$b" ; _.; }
    [ -z "$wrap" ] && { ___; _, '                         '; _, "$c"; _.; }

    a=mail-domain b='Add Mail Domain (Mailbox).'
    if ArraySearch mail-domain mode_available[@] ]];then color=green; else color=red; fi
    [ -n "$wrap" ] && lines+=("Mode <${color}>$a</${color}>. -->$b")
    [ -z "$wrap" ] && { ___; _, 'Mode '; $color $a; _, '.'; _, '        '; _, "$b" ; _.; }

    a=website-ispconfig b='Add Interface of ISPConfig.'
    if ArraySearch website-ispconfig mode_available[@] ]];then color=green; else color=red; fi
    [ -n "$wrap" ] && lines+=("Mode <${color}>$a</${color}>. -->$b")
    [ -z "$wrap" ] && { ___; _, 'Mode '; $color $a; _, '.'; _, '  '; _, "$b" ; _.; }

    a=website-roundcube b='Add Interface of Roundcube (Webmail Client).'
    if ArraySearch website-roundcube mode_available[@] ]];then color=green; else color=red; fi
    [ -n "$wrap" ] && lines+=("Mode <${color}>$a</${color}>. -->$b")
    [ -z "$wrap" ] && { ___; _, 'Mode '; $color $a; _, '.'; _, '  '; _, "$b" ; _.; }

    a=website-phpmyadmin b='Add Interface of PHPMyAdmin (Database Client).'
    if ArraySearch website-phpmyadmin mode_available[@] ]];then color=green; else color=red; fi
    [ -n "$wrap" ] && lines+=("Mode <${color}>$a</${color}>. -->$b")
    [ -z "$wrap" ] && { ___; _, 'Mode '; $color $a; _, '.'; _, ' '; _, "$b" ; _.; }

    a=bundle b='All in one by Domain Name (Mailbox + Website).'
    if ArraySearch bundle mode_available[@] ]];then color=green; else color=red; fi
    [ -n "$wrap" ] && lines+=("Mode <${color}>$a</${color}>. -->$b")
    [ -z "$wrap" ] && { ___; _, 'Mode '; $color $a; _, '.'; _, '             '; _, "$b" ; _.; }

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
        # rcm-paragraph printed-per-line -- --indent=2 --indent-hanging=1 <<< "$plain"
        TAB_STOP_POSITION='25' rcm-paragraph printed-per-2-lines --indent=2 --indent-hanging=1 <<< "$plain"
        # TAB_STOP_POSITION='21 14 9 19 18' rcm-paragraph printed-per-n-lines 3 -- --indent=2 --indent-hanging=1 <<< "$plain"
    fi

    for each in "${mode_available[@]}";do
        echo $each
    done
}
command-plugin() {
    local interface=$1 name=$2 method=$3
    local function="plugin-${interface}-${name}-$method"
    if [[ $(type -t "${function}") == function ]];then
        title "rcm-ispconfig::plugin-${interface}-${name}-${method}()"
        ____

        ${function}
        exit 0
    else
        error The function of method '`'"$function"'`' has not yet defined.; x
    fi
}
plugin-dns-manual-prompt() {
    return 0
}
plugin-dns-manual-server_setup_pre() {
    INDENT+='    ' \
    rcm-dig-apt $isfast \
        ; [ ! $? -eq 0 ] && x
}
plugin-dns-manual-is_a_record_exists_not_cname() {
    [ -n "$RCM_DOMAIN" ] || { error Environment Variable RCM_DOMAIN required; x; }
    [ -n "$RCM_HOSTNAME" ] || { error Environment Variable RCM_HOSTNAME required; x; }
    local domain="$RCM_DOMAIN"
    local hostname="$RCM_HOSTNAME"
    [ $hostname == - ] && hostname=
    local fqdn="$domain"
    [ -n "$hostname" ] && fqdn="${hostname}.${domain}"

    INDENT+='    ' \
    rcm-dig-is-record-exists $isfast --name-exists-sure \
        --reverse \
        --domain="$fqdn" \
        --type=cname \
        --hostname="@" \
        --alias-of="*" \
        && INDENT+='    ' \
    rcm-dig-is-record-exists $isfast --name-exists-sure \
        --domain="$fqdn" \
        --type=a \
        --ip-address="*" \
        ; [ ! $? -eq 0 ] && x
}
plugin-dns-manual-server_setup_post() {
    return 0
}
plugin-dns-manual-is_domain_exists() {
    [ -n "$RCM_DOMAIN" ] || { error Environment Variable RCM_DOMAIN required; x; }
    local domain="$RCM_DOMAIN"
    INDENT+="    " \
    rcm-dig-watch-domain-exists $isfast \
        --domain="$domain" \
        --waiting-time="60"
}
plugin-tls-manual-prompt() {
    INDENT+='    ' \
    rcm nginx-variables-export tls-certificate \
        ; [ ! $? -eq 0 ] && x
}
plugin-tls-manual-server_setup_post() {
    return 0
}
plugin-tls-manual-obtain_certificate() {
    return 0
}

# ------------------------------------------------------------------------------

# Title.
title rcm-ispconfig
____
