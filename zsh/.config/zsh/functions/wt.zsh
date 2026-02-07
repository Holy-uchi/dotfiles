_wt_usage() {
  cat <<'USAGE'
wt usage:
  wt                          # same as: wt switch
  wt ls                       # list worktrees
  wt add <branch> [base]      # add worktree for branch and switch
  wt rm [-f] [branch|path]    # remove worktree
  wt switch [branch|path]     # switch current shell directory
  wt open [branch|path]       # open worktree in Cursor/VS Code
  wt current                  # show current worktree
  wt status                   # list with dirty/ahead/behind
  wt prune [--dry-run]        # prune stale worktree info

options:
  -o, --open                  # open editor after add/switch
  --no-open                   # disable auto-open for this run
  -h, --help

env:
  WT_ROOT                     # root directory for new worktrees
  WT_AUTO_OPEN=1              # auto open editor when switching/adding
USAGE
}

_wt_require_repo() {
  if ! command -v git >/dev/null 2>&1; then
    echo "git not found"
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not a git repo"
    return 1
  fi
}

_wt_require_fzf() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf not found"
    return 1
  fi
}

_wt_entries() {
  git worktree list --porcelain | awk '
    function flush() {
      if (dir == "") return
      b = branch
      sub(/^refs\/heads\//, "", b)
      if (b == "") {
        if (head != "") b = "(detached:" substr(head, 1, 7) ")"
        else b = "(detached)"
      }
      printf "%s\t%s\n", b, dir
    }
    $0 ~ /^worktree / { dir = substr($0, 10); next }
    $0 ~ /^branch /   { branch = substr($0, 8); next }
    $0 ~ /^HEAD /     { head = substr($0, 6); next }
    $0 == "" {
      flush()
      dir = ""
      branch = ""
      head = ""
      next
    }
    END { flush() }
  '
}

_wt_list_pretty() {
  _wt_entries | awk -F '\t' '{ printf "%-28s %s\n", $1, $2 }'
}

_wt_pick_worktree() {
  _wt_require_fzf || return 1
  _wt_entries | fzf \
    --prompt="${1:-wt> }" \
    --delimiter="$(printf '\t')" \
    --with-nth=1,2
}

_wt_open_editor() {
  local target="${1:-.}"
  if command -v cursor >/dev/null 2>&1; then
    cursor -n "$target"
  elif command -v code >/dev/null 2>&1; then
    code -n "$target"
  else
    return 1
  fi
}

_wt_repo_root() {
  local top common common_abs
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  common="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1

  if [[ "$common" != /* ]]; then
    common="$top/$common"
  fi

  common_abs="$(cd "$common" >/dev/null 2>&1 && pwd -P)" || return 1
  if [ "${common_abs##*/}" = ".git" ]; then
    (cd "$common_abs/.." >/dev/null 2>&1 && pwd -P)
    return $?
  fi

  (cd "$top" >/dev/null 2>&1 && pwd -P)
}

_wt_resolve_root() {
  local repo_root root
  repo_root="$(_wt_repo_root)" || return 1

  root="${WT_ROOT:-$repo_root/../wt}"
  if [[ "$root" != /* ]]; then
    root="$repo_root/$root"
  fi

  mkdir -p -- "$root" || return 1
  (cd "$root" >/dev/null 2>&1 && pwd -P)
}

_wt_sanitize_dir_name() {
  local name="$1"
  name="${name//\//__}"
  name="${name// /_}"
  name="${name//:/_}"
  printf "%s\n" "$name"
}

_wt_find_dir() {
  local query="${1:-}"
  [ -n "$query" ] || return 1

  if [ -d "$query" ]; then
    (cd "$query" >/dev/null 2>&1 && pwd -P)
    return 0
  fi

  _wt_entries | awk -F '\t' -v q="$query" '$1 == q { print $2; exit }'
}

_wt_add() {
  local branch="${1:-}" base="${2:-}"
  local wt_root dir_safe new_dir base_ref existing_dir

  if [ -z "$branch" ]; then
    printf "New branch name (e.g. feat/login-fix): "
    IFS= read -r branch
  fi

  [ -n "$branch" ] || {
    echo "Canceled"
    return 1
  }

  if ! git check-ref-format --branch "$branch" >/dev/null 2>&1; then
    echo "invalid branch name: $branch"
    return 1
  fi

  existing_dir="$(_wt_find_dir "$branch")"
  if [ -n "$existing_dir" ] && [ -d "$existing_dir" ]; then
    printf "%s\n" "$existing_dir"
    return 0
  fi

  wt_root="$(_wt_resolve_root)" || return 1
  dir_safe="$(_wt_sanitize_dir_name "$branch")"
  new_dir="$wt_root/$dir_safe"

  if [ -d "$new_dir" ]; then
    if [ -d "$new_dir/.git" ] || [ -f "$new_dir/.git" ]; then
      printf "%s\n" "$new_dir"
      return 0
    fi
    echo "directory already exists: $new_dir"
    return 1
  fi

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$new_dir" "$branch" >&2 || return 1
  else
    base_ref="${base:-$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --verify --short HEAD)}"
    git worktree add -b "$branch" "$new_dir" "$base_ref" >&2 || return 1
  fi

  printf "%s\n" "$new_dir"
}

_wt_rm() {
  local target="${1:-}" force="${2:-0}"
  local pick branch dir answer current

  if [ -z "$target" ]; then
    pick="$(_wt_pick_worktree "wt rm> ")" || return 1
    branch="${pick%%$'\t'*}"
    dir="${pick#*$'\t'}"
  else
    dir="$(_wt_find_dir "$target")"
    branch="$(_wt_entries | awk -F '\t' -v d="$dir" '$2 == d { print $1; exit }')"
  fi

  if [ -z "$dir" ]; then
    echo "worktree not found: ${target:-<interactive>}"
    return 1
  fi

  current="$(git rev-parse --show-toplevel 2>/dev/null)"
  if [ "$dir" = "$current" ]; then
    echo "cannot remove current worktree: $dir"
    return 1
  fi

  if [ "$force" -ne 1 ]; then
    printf "Remove worktree %s (%s)? [y/N]: " "${branch:-unknown}" "$dir"
    IFS= read -r answer
    case "$answer" in
      y|Y|yes|YES)
        ;;
      *)
        echo "Canceled"
        return 0
        ;;
    esac
  fi

  if [ "$force" -eq 1 ]; then
    git worktree remove --force "$dir" || return 1
  else
    git worktree remove "$dir" || return 1
  fi

  echo "removed: $dir"
}

_wt_current() {
  local top branch
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  branch="$(git branch --show-current 2>/dev/null)"
  if [ -z "$branch" ]; then
    branch="(detached:$(git rev-parse --short HEAD 2>/dev/null))"
  fi
  printf "%s\t%s\n" "$branch" "$top"
}

_wt_status() {
  _wt_entries | while IFS=$'\t' read -r branch dir; do
    dirty_flag="-"
    dirty_count="$(git -C "$dir" status --porcelain --ignore-submodules=dirty 2>/dev/null | awk 'END{print NR+0}')"
    if [ "$dirty_count" -gt 0 ]; then
      dirty_flag="*"
    fi

    ahead="-"
    behind="-"
    upstream="$(git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)"
    if [ -n "$upstream" ]; then
      counts="$(git -C "$dir" rev-list --left-right --count "$upstream...HEAD" 2>/dev/null)"
      behind="${counts%% *}"
      ahead="${counts##* }"
    fi

    printf "%-1s %-22s ahead:%-4s behind:%-4s %s\n" "$dirty_flag" "$branch" "$ahead" "$behind" "$dir"
  done
}

wt() {
  emulate -L zsh
  setopt localoptions pipefail typesetsilent

  _wt_require_repo || return 1

  local auto_open=0
  [ "${WT_AUTO_OPEN:-0}" = "1" ] && auto_open=1

  while [ "$#" -gt 0 ]; do
    case "$1" in
      -o|--open)
        auto_open=1
        shift
        ;;
      --no-open)
        auto_open=0
        shift
        ;;
      -h|--help)
        _wt_usage
        return 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "unknown option: $1"
        _wt_usage
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  local cmd="${1:-switch}"
  [ "$#" -gt 0 ] && shift

  local pick dir target force
  target=""
  force=0

  case "$cmd" in
    ls)
      _wt_list_pretty
      return $?
      ;;
    add)
      target="$(_wt_add "${1:-}" "${2:-}")" || return 1
      ;;
    rm)
      if [ "${1:-}" = "-f" ] || [ "${1:-}" = "--force" ]; then
        force=1
        shift
      fi
      _wt_rm "${1:-}" "$force"
      return $?
      ;;
    switch)
      if [ -n "${1:-}" ]; then
        dir="$(_wt_find_dir "$1")"
      else
        pick="$(_wt_pick_worktree "wt switch> ")" || return 1
        dir="${pick#*$'\t'}"
      fi
      [ -n "$dir" ] || {
        echo "worktree not found"
        return 1
      }
      target="$dir"
      ;;
    open)
      if [ -n "${1:-}" ]; then
        dir="$(_wt_find_dir "$1")"
      else
        pick="$(_wt_pick_worktree "wt open> ")" || return 1
        dir="${pick#*$'\t'}"
      fi
      [ -n "$dir" ] || {
        echo "worktree not found"
        return 1
      }
      _wt_open_editor "$dir" || {
        echo "Cursor / VS Code not found"
        return 1
      }
      return 0
      ;;
    current)
      _wt_current
      return $?
      ;;
    status)
      _wt_status
      return $?
      ;;
    prune)
      git worktree prune "$@"
      return $?
      ;;
    *)
      echo "unknown subcommand: $cmd"
      _wt_usage
      return 1
      ;;
  esac

  [ -n "$target" ] || return 0
  cd "$target" || return 1

  if [ "$auto_open" -eq 1 ]; then
    _wt_open_editor "." >/dev/null 2>&1 || true
  fi
}
