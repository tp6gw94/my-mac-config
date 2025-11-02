brew() {
    command brew "$@"
    local brew_command="$1"
    
    if [[ "$brew_command" == "install" ]] || \
       [[ "$brew_command" == "uninstall" ]] || \
       [[ "$brew_command" == "upgrade" ]] || \
       [[ "$brew_command" == "remove" ]]; then
        echo "📝 更新 Homebrew 套件列表..."
        brew bundle dump --force --file=~/.config/Brewfile
    fi
}
