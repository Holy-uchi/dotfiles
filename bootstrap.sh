#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${1:-}" = "--with-brew" ]; then
  if command -v brew >/dev/null 2>&1; then
    brew bundle --file "$DOTFILES_DIR/Brewfile"
  else
    printf 'brew is not installed. skip brew bundle.\n' >&2
  fi
fi

"$DOTFILES_DIR/install.sh"
