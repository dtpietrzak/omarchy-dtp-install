#!/usr/bin/env bash
# Install omarchy-dtp features. Safe to run again: each feature installer
# leaves files that already match alone.
#
#   ./install.sh         pick the features in a checklist
#   ./install.sh --all   install every feature without asking
#
# A checkout next to this repo is used when it exists. Otherwise the optional
# git URL after the name is cloned into ~/.local/share/omarchy-dtp/<name>.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CHECKOUTS="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-dtp"

# Install order. Add a repo as "omarchy-dtp-<feature>|[git-url]|<description>".
features=(
  "omarchy-dtp-app-list|https://github.com/dtpietrzak/omarchy-dtp-app-list.git|List launcher beside the menu button"
  # After the app list. A new dock clone would turn the dock back on.
  "omarchy-dtp-no-dock|https://github.com/dtpietrzak/omarchy-dtp-no-dock.git|Turns the dock off"
  # After the app list too. It patches the list's installed copy.
  "omarchy-dtp-start-menu|https://github.com/dtpietrzak/omarchy-dtp-start-menu.git|Opens the menus in the corner by the menu button"
  "omarchy-dtp-floating-titlebar-limits|https://github.com/dtpietrzak/omarchy-dtp-floating-titlebar-limits.git|Keeps floating title bars on the screen"
  "omarchy-dtp-workspace-swipe|https://github.com/dtpietrzak/omarchy-dtp-workspace-swipe.git|Four finger workspace swipe with a fade"
  "omarchy-dtp-workspace-control|https://github.com/dtpietrzak/omarchy-dtp-workspace-control.git|Four finger swipe up for a workspace panel"
  # Personal settings last, so feature installers keep their own glue.
  "omarchy-dtp-config|https://github.com/dtpietrzak/omarchy-dtp-config.git|Personal settings: cursor, touchpad, text, bar"
)

fail() {
  echo "install: $*" >&2
  exit 1
}

install_all=0
case "${1:-}" in
  -h | --help)
    echo "Usage: install.sh [--all]"
    echo "Shows a checklist of omarchy-dtp features and installs the ones you pick."
    echo "  --all   Install every feature without showing the checklist."
    exit 0
    ;;
  --all)
    install_all=1
    shift
    ;;
esac
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

names=()
urls=()
descriptions=()
for entry in "${features[@]}"; do
  entry="$(trim "$entry")"
  [[ -n $entry && $entry != \#* ]] || continue

  IFS='|' read -r name url description <<<"$entry"
  name="$(trim "$name")"

  [[ $name =~ ^omarchy-dtp-[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "feature name must look like omarchy-dtp-<feature>: $name"
  [[ $name != omarchy-dtp-install ]] || fail "refusing to run this installer as one of its own features"

  names+=("$name")
  urls+=("$(trim "$url")")
  descriptions+=("$(trim "$description")")
done

# Prints the chosen feature names, one per line. Every feature starts ticked.
choose_features() {
  local i options=()
  for i in "${!names[@]}"; do
    options+=("$(printf '%-26s %s' "${names[i]#omarchy-dtp-}" "${descriptions[i]}")"$'\t'"${names[i]}")
  done
  gum choose --no-limit --selected='*' --label-delimiter=$'\t' \
    --header="Choose the omarchy-dtp features to install" "${options[@]}"
}

declare -A wanted=()
if ((install_all)); then
  for name in "${names[@]}"; do
    wanted[$name]=1
  done
else
  [[ -t 0 && -t 1 ]] || fail "no terminal for the checklist. Run install.sh --all to install every feature."
  command -v gum >/dev/null || fail "the checklist needs gum. Install it, or run install.sh --all to install every feature."

  chosen="$(choose_features)" || {
    echo "Nothing was installed."
    exit 0
  }
  while IFS= read -r name; do
    [[ -z $name ]] || wanted[$name]=1
  done <<<"$chosen"

  if [[ ${#wanted[@]} -eq 0 ]]; then
    echo "Nothing was installed."
    exit 0
  fi

  echo "Selected:"
  for name in "${names[@]}"; do
    [[ -z ${wanted[$name]:-} ]] || echo "  ${name#omarchy-dtp-}"
  done
  gum confirm "Install ${#wanted[@]} of ${#names[@]} features?" || {
    echo "Nothing was installed."
    exit 0
  }
fi

# Walk the full list, so the install order holds whatever was picked.
for i in "${!names[@]}"; do
  name="${names[i]}"
  [[ -n ${wanted[$name]:-} ]] || continue

  dir="$(resolve_feature "$name" "${urls[i]}")"
  [[ -f $dir/install.sh ]] || fail "$dir has no install.sh"
  echo "==> $name"
  "$dir/install.sh"
done
