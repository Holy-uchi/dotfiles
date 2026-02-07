for _fn_file in "${${(%):-%x}:A:h}"/functions/*.zsh(N); do
  source "$_fn_file"
done
unset _fn_file
