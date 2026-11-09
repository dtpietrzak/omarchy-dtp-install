#!/usr/bin/env bash
# Install every omarchy-dtp feature. Safe to run again: each feature installer
# leaves files that already match alone.
#
#   ./install.sh
#
# A checkout next to this repo is used when it exists. Otherwise the optional
# git URL after the name is cloned into ~/.local/share/omarchy-dtp/<name>.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CHECKOUTS="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-dtp"

# Install order. Add a repo as "omarchy-dtp-<feature> [git-url]".
features=(
  "omarchy-dtp-app-list https://github.com/dtpietrzak/omarchy-dtp-app-list.git"
  # After the app list. A new dock clone would turn the dock back on.
  "omarchy-dtp-no-dock https://github.com/dtpietrzak/omarchy-dtp-no-dock.git"
  # After the app list too. It patches the list's installed copy.
  "omarchy-dtp-start-menu https://github.com/dtpietrzak/omarchy-dtp-start-menu.git"
  "omarchy-dtp-floating-titlebar-limits https://github.com/dtpietrzak/omarchy-dtp-floating-titlebar-limits.git"
  "omarchy-dtp-workspace-swipe https://github.com/dtpietrzak/omarchy-dtp-workspace-swipe.git"
  "omarchy-dtp-workspace-control https://github.com/dtpietrzak/omarchy-dtp-workspace-control.git"
  # Personal settings last, so feature installers keep their own glue.
  "omarchy-dtp-config https://github.com/dtpietrzak/omarchy-dtp-config.git"
)

fail() {
  echo "install: $*" >&2
  exit 1
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  echo "Usage: install.sh"
  echo "Installs every omarchy-dtp feature listed in this script."
  exit 0
fi
[[ $# -eq 0 ]] || fail "unknown argument: $1"

trim() {
  local value=$1
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

resolve_feature() {
  local name=$1 url=$2
  local sibling="$ROOT/../$name"
  local cached="$CHECKOUTS/$name"

  if [[ -f $sibling/install.sh ]]; then
    realpath "$sibling"
    return
  fi

  if [[ -n $url ]]; then
    if [[ -d $cached/.git ]]; then
      git -C "$cached" pull --ff-only >&2
    elif [[ -e $cached ]]; then
      fail "$cached exists but is not a git checkout"
    else
      mkdir -p "$CHECKOUTS"
      git clone "$url" "$cached" >&2
    fi
  fi

  if [[ -f $cached/install.sh ]]; then
    realpath "$cached"
    return
  fi

  fail "$name was not found next to $(basename "$ROOT") and has no git URL. Check the repo out beside this one, or add its URL in install.sh."
}

[[ ${#features[@]} -gt 0 ]] || fail "no features are listed"

for entry in "${features[@]}"; do
  entry="$(trim "$entry")"
  [[ -n $entry && $entry != \#* ]] || continue

  name="${entry%%[[:space:]]*}"
  url=""
  if [[ $entry != "$name" ]]; then
    url="$(trim "${entry#"$name"}")"
  fi

  [[ $name =~ ^omarchy-dtp-[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "feature name must look like omarchy-dtp-<feature>: $name"
  [[ $name != omarchy-dtp-install ]] || fail "refusing to run this installer as one of its own features"

  dir="$(resolve_feature "$name" "$url")"
  [[ -f $dir/install.sh ]] || fail "$dir has no install.sh"
  echo "==> $name"
  "$dir/install.sh"
done
