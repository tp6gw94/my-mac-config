eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(mise activate zsh)"

export BUN_INSTALL="$HOME/.bun"
export ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
export BEORG="$HOME/Library/Mobile Documents/iCloud~com~appsonthemove~beorg"

path=($BUN_INSTALL/bin $path)
path=($HOME/.local/bin $path)
path=($HOME/.kiro/bin $path)
path=($HOME/.pi/bin $path)
path=($HOME/.config/agent-safehouse $path)
path=($XDG_CONFIG_HOME/bin $path)

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
