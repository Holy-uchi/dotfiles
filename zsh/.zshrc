export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi

for zsh_file in \
  "$HOME/.config/zsh/path.zsh" \
  "$HOME/.config/zsh/tools.zsh" \
  "$HOME/.config/zsh/aliases.zsh" \
  "$HOME/.config/zsh/functions.zsh" \
  "$HOME/.config/zsh/banner.zsh"; do
  [ -f "$zsh_file" ] && source "$zsh_file"
done

[ -f "$HOME/.config/zsh/local.zsh" ] && source "$HOME/.config/zsh/local.zsh"
