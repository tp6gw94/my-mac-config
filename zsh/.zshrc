
eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

source ~/.config/zsh/functions/brew-auto-dump.sh

alias pn="pnpm"
alias lg="lazygit"
alias ld="lazydocker"
alias so="source ~/.config/zsh/.zshrc"
alias n="nvim"
alias svim="sudo -E nvim"

export EDITOR="nvim"
export VISUAL="nvim"
export SUDO_EDITOR="nvim"
export BAT_THEME="base16-256"
export FZF_DEFAULT_OPTS='--color=bg+:#ffffff,fg+:#000000,hl+:#0066cc'
export CARGO_TARGET_DIR="$HOME/cargo-global-target"
export ZK_NOTEBOOK_DIR="$(realpath ~/vaults/personal)"

path=(/opt/homebrew/bin $path)
path=($HOME/.local/bin $path)

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

function zj() {
  local ZELLIJ_OUTPUT
  ZELLIJ_OUTPUT=$(zellij list-sessions 2>/dev/null)

  local ALL_SESSIONS_LINES
  ALL_SESSIONS_LINES=$(echo "$ZELLIJ_OUTPUT" | \
    sed 's/\x1b\[[0-9;]*m//g' | \
    grep -vE '^(NAME|STATUS)')

  if [[ -n "$ALL_SESSIONS_LINES" ]]; then
    local ALL_SESSIONS_NAMES
    ALL_SESSIONS_NAMES=$(echo "$ALL_SESSIONS_LINES" | awk '{print $1}')

    local SELECTED_SESSION
    SELECTED_SESSION=$(echo "$ALL_SESSIONS_NAMES" | fzf --prompt="Attach to Zellij Session: ")

    if [[ -n "$SELECTED_SESSION" ]]; then
      zellij attach "$SELECTED_SESSION"
    fi
  else
    echo "No sessions found. Starting a new one."
    zellij attach -c
  fi
}

if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

zinit light zsh-users/zsh-completions
zinit light rupa/z
zinit light zsh-users/zsh-history-substring-search

zinit ice wait"1"
zinit light zsh-users/zsh-autosuggestions

zinit ice wait"2"
zinit light zsh-users/zsh-syntax-highlighting
