
alias tmux="TERM=screen-256color-bce tmux"
alias python=python3


# This is so TMUX sessions share history
shopt -s histappend
shopt -s histreddit
shopt -s hisverify
HISCONTROL="ignoreboth"
PROMPT_COMMAND="history -a;history -c;history -r; $PROMPT_COMMAND"


# Alias python to python3
alias python=python3

