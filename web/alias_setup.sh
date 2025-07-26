#!/bin/bash

# One-liner alias setup script
# Usage: curl -s https://lebit.sh/alias | bash

# Predefined aliases
declare -A ALIASES=(
    ["apt-up"]="apt update && apt upgrade -y"
    ["dfh"]="df -h"
    ["duh"]="du -h --max-depth=1"
    ["psa"]="ps aux"
    ["ll"]="ls -alF"
    ["la"]="ls -A"
    ["l"]="ls -CF"
    ["grep"]="grep --color=auto"
    ["fgrep"]="fgrep --color=auto"
    ["egrep"]="egrep --color=auto"
    [".."]="cd .."
    ["..."]="cd ../.."
    ["...."]="cd ../../.."
    ["h"]="history"
    ["j"]="jobs -l"
)

# Detect shell config file
shell_config="$HOME/.bashrc"
if [ -n "$ZSH_VERSION" ]; then
    shell_config="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ] && [ "$shell_config" != "$HOME/.bashrc" ] && [ -f "$HOME/.bashrc" ]; then
    shell_config="$HOME/.bashrc"
fi

echo "Setting up useful aliases in $shell_config..."

# Ensure config file exists
if [ ! -f "$shell_config" ]; then
    touch "$shell_config"
fi

# Add aliases
for alias_name in "${!ALIASES[@]}"; do
    # Check if alias already exists
    if grep -q "^alias ${alias_name}=" "$shell_config" 2>/dev/null; then
        # Update existing alias
        sed -i "s/^alias ${alias_name}=.*/alias ${alias_name}='${ALIASES[$alias_name]}'/" "$shell_config"
        echo "  Updated: $alias_name"
    else
        # Add new alias
        echo "alias ${alias_name}='${ALIASES[$alias_name]}'" >> "$shell_config"
        echo "  Added: $alias_name"
    fi
done

# Apply aliases to current session
source "$shell_config" 2>/dev/null || echo "Note: Please restart your terminal or run 'source $shell_config' to use the new aliases."

echo "Alias setup complete! Enjoy your more efficient terminal experience."