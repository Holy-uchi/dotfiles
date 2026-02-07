typeset -U path

export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export VOLTA_HOME="$HOME/.volta"
export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/Library/pnpm"

if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

path=(
  "$HOME/dotfiles/.bin"
  "$HOME/.bin.local"
  "$HOME/.local/bin"
  "$HOME/.volta/bin"
  "$HOME/.bun/bin"
  "$HOME/Library/pnpm"
  "/opt/homebrew/opt/mysql-client/bin"
  "/opt/homebrew/opt/redis/bin"
  "$ANDROID_HOME/emulator"
  "$ANDROID_HOME/platform-tools"
  $path
)

export PATH
