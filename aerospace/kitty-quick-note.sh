kitten quick-access-terminal --instance-group quick-note \
  --config ~/.config/kitty/quick-note.conf \
  zsh -lc 'nvim ~/.local/quick-notes/$(date "+%Y-%m-%d-%H-%M").md'
  
