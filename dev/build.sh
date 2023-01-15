#!/bin/bash

if [[ "$0" =~ build\.sh$ ]];then
    echo 'Cara penggunaan yang benar adalah `. build.sh`'
    exit
fi

dev_d="$PWD"
root_d=$(realpath "$dev_d"/../)
variaton_1_d="${root_d}/variation-1"
mktemp=$(mktemp)
rm "$mktemp"
temp_d=${mktemp}.d
echo "Direktori Temporary dibuat: $temp_d"
mkdir -p "$temp_d"

cd "$dev_d"
cp gpl-ispconfig-variation1.sh -t "$temp_d"
files_required=$(cat <<EOF
${dev_d}/gpl-ispconfig-variation1-1-lib.sh
${dev_d}/gpl-ispconfig-variation1-2-init.sh
${dev_d}/gpl-ispconfig-variation1-3-init-phpmyadmin.sh
${dev_d}/gpl-ispconfig-variation1-4-init-roundcube.sh
${dev_d}/gpl-ispconfig-variation1-5-init-ispconfig.sh
${dev_d}/gpl-ispconfig-variation1-6-soap-remote-user.sh
${dev_d}/gpl-ispconfig-variation1-7-roundcube-plugin-ispconfig-integration.sh
${dev_d}/gpl-ispconfig-variation1-8-domain-nginx-config.sh
${dev_d}/gpl-ispconfig-variation1-9-domain-register-with-dkim.sh
${dev_d}/gpl-ispconfig-variation1-10-mailbox.sh
${dev_d}/gpl-ispconfig-variation1-11-digitalocean.sh
${dev_d}/gpl-ispconfig-variation1-12-letsencrypt.sh
${dev_d}/gpl-ispconfig-variation1-13-report.sh
EOF
)
while IFS= read -r line; do
    [ -f "${line}" ] && {
        cp "${line}" -t "$temp_d"
    }
done <<< "$files_required"

cd "$root_d"
git switch master
if [[ $? -eq 0 ]];then
    mkdir -p "$variaton_1_d"
    cp -f "$temp_d"/* -t "$variaton_1_d"
else
    cd -
fi
echo "Direktori Temporary dihapus: $temp_d"
rm -rf "$temp_d"
