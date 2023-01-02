#!/bin/bash

this_file=$(realpath "$0")
directory_this_file=$(dirname "$this_file")

parent_dir=$(realpath "$directory_this_file"/../)
variaton_1_dir="${parent_dir}/variation-1"
mkdir -p "$variaton_1_dir"

cd "$directory_this_file"
cp gpl-ispconfig-variation1.sh -t "$variaton_1_dir"
files_required=$(cat <<EOF
${directory_this_file}/gpl-ispconfig-variation1-1-lib.sh
${directory_this_file}/gpl-ispconfig-variation1-2-init.sh
${directory_this_file}/gpl-ispconfig-variation1-3-init-phpmyadmin.sh
${directory_this_file}/gpl-ispconfig-variation1-4-init-roundcube.sh
${directory_this_file}/gpl-ispconfig-variation1-5-init-ispconfig.sh
${directory_this_file}/gpl-ispconfig-variation1-6-soap-remote-user.sh
${directory_this_file}/gpl-ispconfig-variation1-7-roundcube-plugin-ispconfig-integration.sh
${directory_this_file}/gpl-ispconfig-variation1-8-domain-nginx-config.sh
${directory_this_file}/gpl-ispconfig-variation1-9-domain-register-with-dkim.sh
${directory_this_file}/gpl-ispconfig-variation1-10-mailbox.sh
${directory_this_file}/gpl-ispconfig-variation1-11-digitalocean.sh
${directory_this_file}/gpl-ispconfig-variation1-12-letsencrypt.sh
${directory_this_file}/gpl-ispconfig-variation1-13-report.sh
EOF
)
while IFS= read -r line; do
    [ -f "${line}" ] && {
        # Trim Trailing Space
        sed -i -e 's/[ ]*$//'  "$line"
        git diff "$line"
        cp "${line}" -t "$variaton_1_dir"
    }
done <<< "$files_required"
