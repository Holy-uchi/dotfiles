alias dstopall='docker stop $(docker ps -q)'
alias dcup='docker-compose up -d'
alias gpu='git push -u origin HEAD'

if command -v nodenv >/dev/null 2>&1; then
  alias claude-global='PATH="$(nodenv prefix 20.15.1)/bin:$PATH" claude'
fi
