# only login shell load it.
eval "$(/opt/homebrew/bin/brew shellenv)"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Environment variables
export CARGO_TARGET_DIR="$HOME/cargo-global-target"
export BUN_INSTALL="$HOME/.bun"
export ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
export BEORG="$HOME/Library/Mobile Documents/iCloud~com~appsonthemove~beorg"
export OBSIDIAN="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/obsidian"

# PATH
path=(
  "$BUN_INSTALL/bin"
  "$HOME/.local/bin"
  "$HOME/.kiro/bin"
  "$HOME/.pi/bin"
  "$HOME/.config/agent-safehouse"
  "$XDG_CONFIG_HOME/bin"
  $path
)

export PATH
