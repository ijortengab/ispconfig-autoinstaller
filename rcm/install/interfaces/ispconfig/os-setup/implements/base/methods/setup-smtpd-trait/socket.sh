#!/bin/bash

# Dependency.
[ -n "$RCM_TLS_CERTIFICATE" ] || { red "Unable to proceed, variable \$RCM_TLS_CERTIFICATE is empty."; x; }
[ -n "$RCM_TLS_CERTIFICATE_KEY" ] || { red "Unable to proceed, variable \$RCM_TLS_CERTIFICATE_KEY is empty."; x; }
require command postconf

# Define variables and constants.
POSTFIX_CONFIG_DIR=${POSTFIX_CONFIG_DIR:=/etc/postfix}

verifyKey() {
    local key=$1
    local output=$2
    case "$key" in
        smtpd_tls_cert_file)
            prefer_parameter="prefer_${key}"
            if [[ "$output" == "${key} = ${!prefer_parameter}" ]];then
                return 0
            fi
            ;;
        smtpd_tls_key_file)
            prefer_parameter="prefer_${key}"
            if [[ "$output" == "${key} = ${!prefer_parameter}" ]];then
                return 0
            fi
            ;;
    esac
    return 1
}

# Require, validate, and populate value.
chapter Variable dump.
tls_certificate="$RCM_TLS_CERTIFICATE"
tls_certificate_key="$RCM_TLS_CERTIFICATE_KEY"
rcm-file "$tls_certificate" terminateIfNotExists
rcm-file "$tls_certificate_key" terminateIfNotExists

smtpd_tls_cert_file=$(postconf -n smtpd_tls_cert_file | grep -o -P '^smtpd_tls_cert_file\s+=\s+\K([^;]+)')
smtpd_tls_key_file=$(postconf -n smtpd_tls_key_file | grep -o -P '^smtpd_tls_key_file\s+=\s+\K([^;]+)')
code smtpd_tls_cert_file="$smtpd_tls_cert_file"
code smtpd_tls_key_file="$smtpd_tls_key_file"
prefer_smtpd_tls_cert_file="${POSTFIX_CONFIG_DIR}/smtpd.cert"
prefer_smtpd_tls_key_file="${POSTFIX_CONFIG_DIR}/smtpd.key"
code prefer_smtpd_tls_cert_file="$prefer_smtpd_tls_cert_file"
code prefer_smtpd_tls_key_file="$prefer_smtpd_tls_key_file"
____

link-symbolic "$tls_certificate" "$prefer_smtpd_tls_cert_file" - absolute
link-symbolic "$tls_certificate_key" "$prefer_smtpd_tls_key_file" - absolute

tempfile_error=$(mktemp -p /dev/shm -t rcm-ispconfig-setup-smtpd-certificate.XXXXXX)
tempfile_output=$(mktemp -p /dev/shm -t rcm-ispconfig-setup-smtpd-certificate.XXXXXX)

for key in smtpd_tls_cert_file smtpd_tls_key_file; do
    chapter Memastikan key '`'$key'`' enabled.
    postconf -n $key 2> $tempfile_error > $tempfile_output
    error="$(<"$tempfile_error")"
    if [ -n "$error" ];then
        error "$error"; rm $tempfile_error; rm $tempfile_output; x
    fi
    output="$(<"$tempfile_output")"
    found=
    if [ -n "$output" ];then
        __ Key ditemukan.
        e "$output"; _.
        __ Verifikasi.
        if verifyKey "$key" "$output";then
            found=1
            __ Key ditemukan, dan value cocok.
        else
            __ Key ditemukan, namun value tidak cocok.
            __ Disable and create new one.
            code "postconf -# ${key}"
            postconf -# $key
        fi
    fi
    if [ -z "$found" ];then
        __ Set value of key '`'$key'`'
        prefer_parameter="prefer_${key}"
        postconf "${key}=${!prefer_parameter}"
        __ Verifikasi.
        if verifyKey "$key" "$(postconf -n $key)";then
            __ Verifikasi berhasil.
            restart=1
        else
            error Verifikasi gagal.; rm $tempfile_error; rm $tempfile_output; x
        fi
    fi
    ____
done

if [ -n "$restart" ];then
    chapter Restart Postfix
    code systemctl restart postfix
    systemctl restart postfix
    ____
fi

rm $tempfile_error
rm $tempfile_output
