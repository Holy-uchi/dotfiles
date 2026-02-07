#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
BACKUP_USED=0

log() {
  printf '%s\n' "$*"
}

backup_path() {
  local target="$1"
  local rel="${target#$HOME/}"
  mkdir -p "$BACKUP_ROOT/$(dirname "$rel")"
  mv "$target" "$BACKUP_ROOT/$rel"
  BACKUP_USED=1
  log "backed up: $target -> $BACKUP_ROOT/$rel"
}

link_path() {
  local source_path="$1"
  local target_path="$2"

  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
    log "skip: $target_path already linked"
    return
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    backup_path "$target_path"
  fi

  mkdir -p "$(dirname "$target_path")"
  ln -s "$source_path" "$target_path"
  log "linked: $target_path -> $source_path"
}

ensure_local_zsh() {
  local local_zsh="$HOME/.config/zsh/local.zsh"
  local example_zsh="$DOTFILES_DIR/zsh/.config/zsh/local.zsh.example"

  if [ -f "$local_zsh" ]; then
    log "skip: $local_zsh already exists"
    return
  fi

  mkdir -p "$HOME/.config/zsh"

  if [ -f "$example_zsh" ]; then
    cp "$example_zsh" "$local_zsh"
    log "created: $local_zsh from template"
    return
  fi

  : > "$local_zsh"
  log "created: $local_zsh"
}

ensure_local_gitconfig() {
  local local_cfg="$HOME/.gitconfig.local"
  local example_cfg="$DOTFILES_DIR/git/.gitconfig.local.example"

  if [ -f "$local_cfg" ]; then
    log "skip: $local_cfg already exists"
    return
  fi

  if [ -f "$example_cfg" ]; then
    cp "$example_cfg" "$local_cfg"
    chmod 600 "$local_cfg" 2>/dev/null || true
    log "created: $local_cfg from template (edit name/email)"
    return
  fi

  cat > "$local_cfg" <<'EOF'
[user]
  name = Your Name
  email = you@example.com
EOF
  chmod 600 "$local_cfg" 2>/dev/null || true
  log "created: $local_cfg (edit name/email)"
}

ensure_local_bin() {
  mkdir -p "$HOME/.bin.local"
}

link_path "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
link_path "$DOTFILES_DIR/zsh/.config/zsh/path.zsh" "$HOME/.config/zsh/path.zsh"
link_path "$DOTFILES_DIR/zsh/.config/zsh/tools.zsh" "$HOME/.config/zsh/tools.zsh"
link_path "$DOTFILES_DIR/zsh/.config/zsh/aliases.zsh" "$HOME/.config/zsh/aliases.zsh"
link_path "$DOTFILES_DIR/zsh/.config/zsh/functions.zsh" "$HOME/.config/zsh/functions.zsh"
link_path "$DOTFILES_DIR/zsh/.config/zsh/banner.zsh" "$HOME/.config/zsh/banner.zsh"
link_path "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
link_path "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
link_path "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
link_path "$DOTFILES_DIR/tmux/.tmux-cheatsheet" "$HOME/.tmux-cheatsheet"
link_path "$DOTFILES_DIR/nvim/.config/nvim" "$HOME/.config/nvim"
link_path "$DOTFILES_DIR/ghostty/.config/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
link_path "$DOTFILES_DIR/karabiner/.config/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
link_path "$DOTFILES_DIR/skhd/.config/skhd/skhdrc" "$HOME/.config/skhd/skhdrc"
ensure_local_zsh
ensure_local_gitconfig
ensure_local_bin

if [ "$BACKUP_USED" -eq 1 ]; then
  log "backup directory: $BACKUP_ROOT"
else
  rmdir "$BACKUP_ROOT" 2>/dev/null || true
fi

log "dotfiles install complete"
