#
# ~/.bashrc
#

alias ls='ls --color=auto'
alias ll='ls -la'

# red blue green color scheme
PS1='\[\e[0;31m\]\u\[\e[m\]\[\e[1;34m\]\w\[\e[m\]\[\e[0;31m\]\[\e[m\]\[\e[0;32m\]$(__git_ps1)\[\033[01;34m\] \$\[\033[00m\] '

# prevent fork bombs
ulimit -u 256

alias gs='git status'
alias gsu='git status -uno'
alias ga='git add'
alias gc='git commit -m'
alias glog='git log --graph --pretty=oneline --abbrev-commit'
alias gpush='git push origin master'
alias gpull='git pull origin master'
alias gconfig='git config --list'
