#!/usr/bin/env bash
# PreToolUse(Bash): block `git add` while makepkg build output is present.
set -uo pipefail
cmd=$(jq -r '.tool_input.command // empty')
[[ "$cmd" =~ git[[:space:]]+(add|commit[[:space:]]+-a) ]] || exit 0
junk=$(git ls-files --others --exclude-standard | grep -E '(^|/)(src|pkg)/|\.pkg\.tar\.|\.(tar\.(gz|xz|zst|bz2)|zip)$' | head -5)
if [[ -n "$junk" ]]; then
  echo "Untracked build output present; delete it before staging:" >&2
  echo "$junk" >&2
  exit 2
fi
exit 0
