#
# ~/.bashrc
#

alias ll='ls -la'

# On Mac or Ubuntu, set up __git_ps1 before changing PS1 (from http://stackoverflow.com/questions/12870928)
if [[ ! -f ~/.git-prompt.sh ]]; then
  curl -o ~/.git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
fi
source ~/.git-prompt.sh

# autocompletion for git
if [ ! -f ~/.git-completion.bash ]; then
  curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash
  . ~/.git-completion.bash
fi

export CLICOLOR=1
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

# red blue green color scheme
PS1='\[\e[0;31m\]\u \[\e[m\]\[\e[1;34m\]\w\[\e[m\]\[\e[0;31m\]\[\e[m\]\[\e[0;32m\]$(__git_ps1)\[\033[01;34m\] \$\[\033[00m\] '

alias gs='git status'
alias gsu='git status -uno'
alias ga='git add'
alias gc='git commit -m'
alias glog='git log --graph --pretty=oneline --abbrev-commit'
alias gpush='git push origin master'
alias gpull='git pull origin master'
alias gconfig='git config --list'

# connect to wifi from command line (Ubuntu only)
wificonn() {
        if [ $# -lt 1 ]; then
                echo "Usage: $0 <access point name>"
        fi
        nmcli dev wifi connect $1
} 
alias wifiscan='sudo iwlist wlan0 s' # (Ubuntu only)
