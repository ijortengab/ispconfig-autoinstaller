#!/bin/bash
_message=$(printf " %s" "$@")
message=${_message:1}
[ -z "$message" ] && message="Update $(date +%Y%m%d-%H%M%S) at $(hostname)."
echo Git commit.
git commit -m "$message"
