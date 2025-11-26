#!/bin/sh
# Apply XDG MIME type patches to desktop files

set -e

if [ $# -ne 1 ] || [ ! -f "$1" ]; then
  echo "Usage: $0 <desktop-file>" >&2
  exit 1
fi

desktop_file="$1"

# Add text/plain MIME type if not already present
if ! grep -q "text/plain" "$desktop_file"; then
  sed -i -E 's/^(MimeType=.*);$/\1;text\/plain;/' "$desktop_file"
fi

# Add inode/directory MIME type if not already present
if ! grep -q "inode/directory" "$desktop_file"; then
  sed -i -E 's/^(MimeType=.*);$/\1;inode\/directory;/' "$desktop_file"
fi

echo "Applied XDG MIME patches to $desktop_file"
