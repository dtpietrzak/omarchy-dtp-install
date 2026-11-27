#!/usr/bin/env bash
# Install better-trackpad from a checkout. Its own installer asks which
# modules to install; with install.sh --all (OMARCHY_DTP_INSTALL_ALL=1), or
# without a terminal to ask in, it installs every module.
#
#   omarchy-dtp-better-trackpad.sh <checkout>

set -euo pipefail

fail() {
  echo "install: $*" >&2
  exit 1
}

[[ $# -eq 1 && -f $1/install.sh ]] || fail "usage: $(basename "$0") <checkout>"

if [[ ${OMARCHY_DTP_INSTALL_ALL:-0} == 1 || ! -t 0 ]]; then
  exec "$1/install.sh" --all
fi
exec "$1/install.sh"
