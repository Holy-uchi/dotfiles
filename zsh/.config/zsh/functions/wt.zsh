wt() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf not found"
    return 1
  fi

  local dir
  dir=$(git worktree list | awk '{print $1}' | fzf) || return
  cd "$dir" || return
}
