#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

check_bash() {
  local failed=0
  while IFS= read -r file; do
    if ! bash -n "$file"; then
      failed=1
    fi
  done < <(find "$DOTFILES_DIR" -type f -name '*.sh' \
    ! -path "$DOTFILES_DIR/.git/*")
  return "$failed"
}

check_zsh() {
  local failed=0
  while IFS= read -r file; do
    if ! zsh -n "$file"; then
      failed=1
    fi
  done < <(find "$DOTFILES_DIR/zsh" -type f -name '*.zsh')
  if ! zsh -n "$DOTFILES_DIR/zsh/.zshrc"; then
    failed=1
  fi
  return "$failed"
}

check_bash
check_zsh
echo "dotfiles checks: ok"
