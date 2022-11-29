#!/bin/bash

this_file=$(realpath "$0")
directory_this_file=$(dirname "$this_file")

# "${directory_this_file}/gpl-ispconfig-variation1.sh" \
    # --help

# "${directory_this_file}/gpl-ispconfig-variation1.sh" \
    # bta.my.id 206.189.94.130 \

# "${directory_this_file}/gpl-ispconfig-variation1.sh" \
    # bta.my.id 206.189.94.130 \
    # --digitalocean-token=c29d24b8c05aa65759f243639f8d868ba4635b3d524a2eb4f5412bae6b6be906 \
    # --letsencrypt=digitalocean

"${directory_this_file}/gpl-ispconfig-variation1.sh" \
    bta.my.id \
    --autopopulate-ip-address \
    --digitalocean-token=c29d24b8c05aa65759f243639f8d868ba4635b3d524a2eb4f5412bae6b6be906 \
    --letsencrypt=digitalocean
