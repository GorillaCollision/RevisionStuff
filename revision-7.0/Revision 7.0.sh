#!/bin/sh
printf '\033c\033]0;%s\a' Revision 7.0
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Revision 7.0.x86_64" "$@"
