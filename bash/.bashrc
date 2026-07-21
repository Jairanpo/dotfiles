
alias tmux="TERM=screen-256color-bce tmux"
alias python=python3


# This is so TMUX sessions share history
shopt -s histappend
shopt -s histreedit
shopt -s histverify
HISCONTROL="ignoreboth"
PROMPT_COMMAND="history -a;history -c;history -r; $PROMPT_COMMAND"

# ------------------------------------------------------------------
# ALIASES

# Alias python to python3
alias python=python3

# ------------------------------------------------------------------
#
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ------------------------------------------------------------------

# UI

eval "$(oh-my-posh init bash --config ~/.ohmyposh/config.json)" || { printf "%b" "FAILED.\n"; exit 1; }

[ -f .venv/bin/activate ] && source .venv/bin/activate

# ------------------------------------------------------------------
# SOURCE FILES

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
