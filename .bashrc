fortune | cowsay -f tux
#
#If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
alias ..="cd .."
alias ...="cd ../..".
alias ....="cd ../.."
alias reload="source .bashrc"
alias nv="nvim"
alias ll="ls"
alias create_tmux="~/scripts/create_tmux.sh"
alias tent="tmux a -t"
alias gb="git branch"
alias gs="git status"
alias run="npm run dev"
# Make an alias for invoking commands you use constantly
# alias p='python'
alias config='/usr/bin/git --git-dir=/home/janis/.cfg/ --work-tree=/home/janis'
alias config='/usr/bin/git --git-dir=/home/janis/.cfg/ --work-tree=/home/janis'

. "$HOME/.local/share/../bin/env"

eval "$(starship init bash)"

