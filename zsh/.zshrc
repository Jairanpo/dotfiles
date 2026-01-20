
plugins=(
  git 
  zsh-autosuggestions
)

export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"


FILES_TO_SOURCE=(
  "$HOME/.sdkman/bin/sdkman-init.sh"
)
echo "${FILES_TO_SOURCE}"

for file in "${FILES_TO_SOURCE[@]}"; do
    if [ -f "$file" ]; then
        source "$file"
        # Optional: Confirm it loaded
        # echo "Loaded: $file"
    else
        echo "Warning: Could not find '$file'. Skipping."
    fi
done

eval "$(oh-my-posh init zsh --config ~/.ohmyposh/config.json)"
