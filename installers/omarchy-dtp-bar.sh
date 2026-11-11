#!/usr/bin/env bash
# Install the bar from a checkout. It lives here rather than in the
# plugin's repo, which only needs what `omarchy plugin add` uses. Safe to run
# again: files that already match are left alone.
#
#   omarchy-dtp-bar.sh <plugin-checkout>

set -euo pipefail

PLUGIN_ID="io.github.dtpietrzak.bar"
DEST="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

fail() {
  echo "install: $*" >&2
  exit 1
}

[[ $# -eq 1 && -f $1/manifest.json ]] || fail "usage: $(basename "$0") <plugin-checkout>"
ROOT="$(cd "$1" && pwd)"
command -v jq >/dev/null || fail "jq is required"
command -v rsync >/dev/null || fail "rsync is required"

# An older clone of the stock bar would compete with this plugin. Remove it
# first. The remove command keeps a backup.
if [[ ! -f $DEST/manifest.json ]]; then
  old="$(omarchy plugin list --json | jq -r --arg id "$PLUGIN_ID" '[.[] | select(.clonedFrom == "omarchy.bar" and .id != $id)][0].id // empty')"
  if [[ -n $old ]]; then
    echo "Removing the old bar clone $old"
    omarchy plugin remove "$old" --yes
  fi
fi

updating=0
[[ -f $DEST/manifest.json ]] && updating=1
mkdir -p "$DEST"
copied="$(rsync -a --checksum --delete --exclude .git --itemize-changes "$ROOT/" "$DEST/")"
if [[ -n $copied ]]; then
  echo "Synced plugin files to $DEST"
  if [[ $updating -eq 1 ]]; then
    echo "Restarting the shell so the bar picks up the new files"
    omarchy restart shell
  else
    omarchy-shell shell rescanPlugins >/dev/null
  fi
else
  echo "Plugin files already match $DEST"
fi

known=0
for attempt in $(seq 1 40); do
  if omarchy plugin list --json | jq -e --arg id "$PLUGIN_ID" 'any(.[]; .id == $id)' >/dev/null; then
    known=1
    break
  fi
  if [[ $attempt -eq 1 ]]; then
    omarchy-shell shell rescanPlugins >/dev/null
  fi
  sleep 0.05
done
[[ $known -eq 1 ]] || fail "plugin $PLUGIN_ID was not discovered"

# Enabling a bar plugin switches the bar in use. shell.json names the one
# that is already on screen.
if jq -e --arg id "$PLUGIN_ID" '.bar.id == $id' "$HOME/.config/omarchy/shell.json" >/dev/null 2>&1; then
  echo "Plugin $PLUGIN_ID is already the bar"
else
  omarchy plugin enable "$PLUGIN_ID"
fi

# Glassy is the look this bar is built for. The command also turns on the
# Hyprland blur behind it, and leaves a matching background alone.
if [[ $(omarchy bar background) == glassy ]]; then
  echo "Bar background is already glassy"
else
  omarchy bar background glassy
fi
