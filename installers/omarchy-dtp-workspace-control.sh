#!/usr/bin/env bash
# Install workspace control from a checkout. It lives here rather than in the
# plugin's repo, which only needs what `omarchy plugin add` uses. Safe to run
# again: files that already match are left alone.
#
#   omarchy-dtp-workspace-control.sh <plugin-checkout>

set -euo pipefail

PLUGIN_ID="io.github.dtpietrzak.workspace-control"
DEST="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

fail() {
  echo "install: $*" >&2
  exit 1
}

[[ $# -eq 1 && -f $1/manifest.json ]] || fail "usage: $(basename "$0") <plugin-checkout>"
ROOT="$(cd "$1" && pwd)"
command -v jq >/dev/null || fail "jq is required"
command -v rsync >/dev/null || fail "rsync is required"

updating=0
[[ -f $DEST/manifest.json ]] && updating=1
mkdir -p "$DEST"
copied="$(rsync -a --checksum --delete --exclude .git --itemize-changes "$ROOT/" "$DEST/")"
if [[ -n $copied ]]; then
  echo "Synced plugin files to $DEST"
  if [[ $updating -eq 1 ]]; then
    # An always-loaded panel survives the shell's plugin hot-reload, so only a
    # restart picks up new code.
    echo "Restarting the shell so the panel picks up the new files"
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

# Omarchy calls a bar widget enabled only while it is on the bar, and enabling
# puts it there. Listed anywhere in shell.json, the panel already runs, and
# whether the button is on the bar is the user's choice.
if jq -e --arg id "$PLUGIN_ID" 'any(.. | objects; .id? == $id)' "$HOME/.config/omarchy/shell.json" >/dev/null 2>&1 ||
  omarchy plugin list --json | jq -e --arg id "$PLUGIN_ID" 'any(.[]; .id == $id and .enabled)' >/dev/null; then
  echo "Plugin $PLUGIN_ID is already enabled"
else
  omarchy plugin enable "$PLUGIN_ID"
fi
