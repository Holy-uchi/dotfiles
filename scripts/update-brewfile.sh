#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v brew >/dev/null 2>&1; then
  printf 'brew is not installed\n' >&2
  exit 1
fi

brew bundle dump --force --file "$DOTFILES_DIR/Brewfile"
printf 'updated %s/Brewfile\n' "$DOTFILES_DIR"
