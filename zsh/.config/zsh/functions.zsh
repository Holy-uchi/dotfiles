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

# Quick directory bookmarks.
# Functions are tracked in dotfiles; entries are local-only in ~/.local/state.
JUMP_DB_FILE="${JUMP_DB_FILE:-$HOME/.local/state/jump/dirs.txt}"

_jump_init_db() {
  local db_dir="${JUMP_DB_FILE:h}"
  mkdir -p -- "$db_dir" || return 1
  [ -f "$JUMP_DB_FILE" ] || : > "$JUMP_DB_FILE" || return 1
}

_jump_resolve_dir() {
  local candidate="${1:-$PWD}"
  [ -d "$candidate" ] || return 1
  (cd "$candidate" 2>/dev/null && pwd -P)
}

_jump_entries() {
  [ -f "$JUMP_DB_FILE" ] || return 0
  awk "NF > 0" "$JUMP_DB_FILE"
}

_jump_pick_entry() {
  local query="${1:-}"
  local selected=""

  if [ -n "$query" ]; then
    if [[ "$query" == <-> ]]; then
      selected="$(sed -n "${query}p" "$JUMP_DB_FILE")"
    else
      selected="$(_jump_entries | grep -Fi -- "$query" | head -n 1)"
    fi
  else
    if command -v fzf >/dev/null 2>&1; then
      selected="$(_jump_entries | fzf --height 40% --reverse --prompt "jump > ")"
    else
      local i=1
      local line
      while IFS= read -r line; do
        printf "%2d) %s\n" "$i" "$line"
        i=$((i + 1))
      done < <(_jump_entries)

      printf "Select number: "
      local idx
      read -r idx
      [[ "$idx" == <-> ]] || return 1
      selected="$(sed -n "${idx}p" "$JUMP_DB_FILE")"
    fi
  fi

  [ -n "$selected" ] || return 1
  printf "%s\n" "$selected"
}

_jump_list_numbered() {
  local i=1
  local line
  while IFS= read -r line; do
    printf "%2d) %s\n" "$i" "$line"
    i=$((i + 1))
  done < <(_jump_entries)
}

_jump_add() {
  _jump_init_db || return 1

  local target
  target="$(_jump_resolve_dir "${1:-$PWD}")" || {
    echo "directory not found: ${1:-$PWD}"
    return 1
  }

  if grep -Fxq -- "$target" "$JUMP_DB_FILE"; then
    echo "already registered: $target"
    return 0
  fi

  printf "%s\n" "$target" >> "$JUMP_DB_FILE"
  echo "registered: $target"
}

_jump_del() {
  _jump_init_db || return 1

  local target
  if [ -n "${1:-}" ]; then
    if [ -d "$1" ]; then
      target="$(_jump_resolve_dir "$1")" || return 1
    else
      target="$(_jump_pick_entry "$1")" || {
        echo "not found: $1"
        return 1
      }
    fi
  else
    target="$(_jump_pick_entry)" || return 1
  fi

  if ! grep -Fxq -- "$target" "$JUMP_DB_FILE"; then
    echo "not registered: $target"
    return 1
  fi

  local tmp="${JUMP_DB_FILE}.tmp.$$"
  awk -v p="$target" '$0 != p' "$JUMP_DB_FILE" > "$tmp" || {
    rm -f -- "$tmp"
    return 1
  }
  mv -- "$tmp" "$JUMP_DB_FILE" || return 1
  echo "deleted: $target"
}

_jump_ls() {
  _jump_init_db || return 1
  _jump_list_numbered
}

_jump_prune() {
  _jump_init_db || return 1

  local tmp="${JUMP_DB_FILE}.tmp.$$"
  awk 'NF > 0' "$JUMP_DB_FILE" > "$tmp" || {
    rm -f -- "$tmp"
    return 1
  }

  local line
  local removed=0
  local kept="${tmp}.kept"
  : > "$kept"
  while IFS= read -r line; do
    if [ -d "$line" ]; then
      printf "%s\n" "$line" >> "$kept"
    else
      echo "removed missing: $line"
      removed=$((removed + 1))
    fi
  done < "$tmp"
  mv -- "$kept" "$JUMP_DB_FILE" || return 1
  rm -f -- "$tmp"
  echo "pruned: $removed"
}

_jump_go() {
  local query="${1:-}"
  local target
  target="$(_jump_pick_entry "$query")" || return 1
  if [ ! -d "$target" ]; then
    echo "directory no longer exists: $target"
    echo "remove it with: jump del \"$target\""
    return 1
  fi
  cd "$target" || return 1
}

_jump_dispatch() {
  _jump_init_db || return 1

  local cmd="${1:-}"
  [ "$#" -gt 0 ] && shift

  case "$cmd" in
    "")
      _jump_go
      ;;
    add)
      _jump_add "$@"
      ;;
    del|rm|remove)
      _jump_del "$@"
      ;;
    ls|list)
      _jump_ls
      ;;
    prune)
      _jump_prune
      ;;
    edit)
      "${EDITOR:-vi}" "$JUMP_DB_FILE"
      ;;
    help|-h|--help)
      echo "jump usage:"
      echo "  jump [query|number]       # jump"
      echo "  jump add [dir]            # register current dir if omitted"
      echo "  jump del [path|query|num] # delete one entry"
      echo "  jump ls                   # list entries"
      echo "  jump prune                # remove missing dirs"
      echo "  jump edit                 # edit db file directly"
      ;;
    *)
      _jump_go "$cmd"
      ;;
  esac
}

jump() { _jump_dispatch "$@"; }
j() { jump "$@"; }
jadd() { jump add "$@"; }
jdel() { jump del "$@"; }
jls() { jump ls; }
