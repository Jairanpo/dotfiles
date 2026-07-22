alias tmux="TERM=screen-256color-bce tmux"
alias python=python3


# This is so TMUX sessions share history
shopt -s histappend
shopt -s histreedit
shopt -s histverify
HISCONTROL="ignoreboth"
PROMPT_COMMAND="history -a;history -c;history -r; $PROMPT_COMMAND"

# ------------------------------------------------------------------
# STARSHIP (with one-time, non-fatal auto-install; fish as fallback)
#
# Safety: every step below is guarded so a missing binary, a failed
# install, or no network can never break or hang this shell.
#   - only runs in interactive shells, and only if starship is missing
#   - a stamp file stops retries after one attempt (rm it to retry)
#   - curl has a timeout; the fish fallback uses `sudo -n` so it can
#     never block on a password prompt
__prompt_stamp="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/prompt-install.done"
if [[ $- == *i* ]] && ! command -v starship >/dev/null 2>&1 && [ ! -e "$__prompt_stamp" ]; then
    mkdir -p "${__prompt_stamp%/*}" 2>/dev/null

    # 1) Try starship — userspace install to ~/.local/bin, no sudo needed.
    if command -v curl >/dev/null 2>&1; then
        printf '%s\n' "starship not found — one-time install attempt..." >&2
        curl --max-time 30 -fsSL https://starship.rs/install.sh 2>/dev/null \
            | sh -s -- --yes --bin-dir "$HOME/.local/bin" >/dev/null 2>&1 || true
    fi

    # 2) Fallback: if starship still isn't available, try installing fish.
    #    Fish has no curl installer, so apt is the only automated route here;
    #    `sudo -n` keeps it non-interactive so it can never hang the shell.
    if ! command -v starship >/dev/null 2>&1 && ! command -v fish >/dev/null 2>&1 \
        && command -v apt-get >/dev/null 2>&1; then
        sudo -n apt-get install -y fish >/dev/null 2>&1 || true
    fi

    # Mark attempted regardless of outcome so we don't retry every startup.
    : > "$__prompt_stamp" 2>/dev/null || true
fi
unset __prompt_stamp

# Activate starship if present; otherwise the plain bash prompt stays.
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# ------------------------------------------------------------------
# ALIASES

# Alias python to python3
alias python=python3

# ------------------------------------------------------------------

export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ------------------------------------------------------------------

[ -f .venv/bin/activate ] && source .venv/bin/activate

# ------------------------------------------------------------------
# SOURCE FILES

FILES_TO_SOURCE=(
  "$HOME/.sdkman/bin/sdkman-init.sh"
)

for file in "${FILES_TO_SOURCE[@]}"; do
    if [ -f "$file" ]; then
        source "$file"
        # Optional: Confirm it loaded
        # echo "Loaded: $file"
    else
        echo "Warning: Could not find '$file'. Skipping."
    fi
done

# ------------------------------------------------------------------
#

# ADD_TO_PATH
PATH_LIST=(
  "$HOME/.local/bin"
)
for dir in "${PATH_LIST[@]}"; do
    if [ -d "$dir" ]; then
        case ":$PATH:" in
            *":$dir:"*) ;;                 # already in PATH, skip
            *) PATH="$dir:$PATH" ;;        # prepend it
        esac
    else
        echo "Warning: '$dir' not found. Skipping."
    fi
done
export PATH
