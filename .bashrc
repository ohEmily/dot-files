#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'

# red blue green color scheme
PS1='\[\e[0;31m\]\u\[\e[m\] \[\e[1;34m\]\w\[\e[m\] \[\e[0;31m\]\$ \[\e[m\]\[\e[0;32m\]'

# prevent fork bombs
ulimit -u 256

alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias glog='git log --graph --pretty=oneline --abbrev-commit'
alias gpm='git push origin master'
