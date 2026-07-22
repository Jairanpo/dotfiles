# ------------------------------------------------------------------
# PATH  (fish_add_path is idempotent — no need to guard for duplicates)
fish_add_path $HOME/.local/bin

# ------------------------------------------------------------------
# ENV VARS  (set -gx == exported global; the bash `export FOO=bar`)
set -gx EDITOR nvim

# ------------------------------------------------------------------
# ALIASES / ABBREVIATIONS
#   alias  -> runs as a wrapper function
#   abbr   -> expands inline as you type (great for things you want to see)
alias python="python3"
abbr -a tmux "TERM=screen-256color-bce tmux"

# ------------------------------------------------------------------
# PROMPT
# (fish shares history across sessions natively — no PROMPT_COMMAND hack needed)
if type -q starship
    starship init fish | source
end

# ------------------------------------------------------------------
# TOOLING
# Auto-activate a project venv if present
test -f .venv/bin/activate.fish; and source .venv/bin/activate.fish
