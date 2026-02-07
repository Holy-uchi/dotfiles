export PYENV_ROOT="$HOME/.pyenv"
if command -v pyenv >/dev/null 2>&1; then
  pyenv() {
    unset -f pyenv
    eval "$(command pyenv init -)"
    command pyenv "$@"
  }
else
  path=("$PYENV_ROOT/bin" $path)
fi

if command -v rbenv >/dev/null 2>&1; then
  rbenv() {
    unset -f rbenv
    eval "$(command rbenv init -)"
    command rbenv "$@"
  }
fi

[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
