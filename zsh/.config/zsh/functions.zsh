cf_tunnel_run() {
  local env_file="${CF_TUNNEL_ENV_FILE:-$HOME/.secrets/cloudflared/op.env}"
  if ! command -v op >/dev/null 2>&1; then
    echo "op not found"
    return 1
  fi

  if ! command -v cloudflared >/dev/null 2>&1; then
    echo "cloudflared not found"
    return 1
  fi

  if [ ! -r "$env_file" ]; then
    echo "missing or unreadable: $env_file"
    return 1
  fi

  op run --env-file "$env_file" -- sh -eu -c '
    : "${TUNNEL_TOKEN:?TUNNEL_TOKEN is not set}"
    exec cloudflared tunnel run --token "$TUNNEL_TOKEN" "$@"
  ' cf_tunnel_run "$@"
}

wt() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf not found"
    return 1
  fi

  local dir
  dir=$(git worktree list | awk '{print $1}' | fzf) || return
  cd "$dir" || return
}
