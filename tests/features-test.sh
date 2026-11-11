#!/usr/bin/env bash
# Every feature named in install.sh can be installed: a wrapper in this repo,
# or an install.sh in the feature repo beside this one.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() {
  echo "not ok - $*" >&2
  exit 1
}

found=0
while IFS= read -r name; do
  [[ -n $name ]] || continue
  found=$((found + 1))
  if [[ -f $ROOT/installers/$name.sh ]]; then
    bash -n "$ROOT/installers/$name.sh"
    echo "ok - $name wrapper"
    continue
  fi
  if [[ -f $ROOT/../$name/install.sh ]]; then
    bash -n "$ROOT/../$name/install.sh"
    echo "ok - $name install.sh"
    continue
  fi
  fail "$name is listed but has no installer"
done < <(awk -F'|' '/^  "omarchy-dtp-/{gsub(/[ "]/,"",$1); print $1}' "$ROOT/install.sh")

[[ $found -gt 0 ]] || fail "no features listed"
echo "ok - $found features"
