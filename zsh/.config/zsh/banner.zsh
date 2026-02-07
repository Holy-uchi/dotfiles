if [[ $- == *i* ]]; then
  figlet_bin="${commands[figlet]:-/opt/homebrew/bin/figlet}"
  cowsay_bin="${commands[cowsay]:-/opt/homebrew/bin/cowsay}"
  lolcat_bin="${commands[lolcat]:-/opt/homebrew/bin/lolcat}"

  echo ""
  if [ -x "$figlet_bin" ] && [ -x "$cowsay_bin" ]; then
    if [ -x "$lolcat_bin" ]; then
      "$figlet_bin" -f slant "git push -f origin main" | "$cowsay_bin" -n -f dragon-and-cow | "$lolcat_bin"
    else
      "$figlet_bin" -f slant "git push -f origin main" | "$cowsay_bin" -n -f dragon-and-cow
    fi
  else
    echo "[dotfiles] git push -f origin main"
  fi
  echo ""
fi
