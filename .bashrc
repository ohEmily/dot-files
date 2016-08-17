#
# ~/.bashrc
#

alias ll='ls -la'

# On Mac or Ubuntu, set up __git_ps1 before changing PS1 (from http://stackoverflow.com/questions/12870928)
if [[ ! -f ~/.git-prompt.sh ]]; then
  curl -o ~/.git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
fi
source ~/.git-prompt.sh

# autocompletion for git (not available by default on OSX)
if [ ! -f ~/.git-completion.bash ]; then
  curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash
fi
source ~/.git-completion.bash

export CLICOLOR=1
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

# red blue green color scheme
PS1='\[\e[0;31m\]\u \[\e[m\]\[\e[1;34m\]\w\[\e[m\]\[\e[0;31m\]\[\e[m\]\[\e[0;32m\]$(__git_ps1)\[\033[01;34m\] \$\[\033[00m\] '

alias gs='git status'
alias gsu='git status -uno'
alias ga='git add'
alias gc='git commit -m'
alias glog='git log --decorate --graph --oneline'
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

# colorized man pages
# (http://boredzo.org/blog/archives/2016-08-15/colorized-man-pages-understood-and-customized)
man() {
	env \
		LESS_TERMCAP_mb=$(printf "\e[1;31m") \
		LESS_TERMCAP_md=$(printf "\e[1;31m") \
		LESS_TERMCAP_me=$(printf "\e[0m") \
		LESS_TERMCAP_se=$(printf "\e[0m") \
		LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
		LESS_TERMCAP_ue=$(printf "\e[0m") \
		LESS_TERMCAP_us=$(printf "\e[1;32m") \
			man "$@"
}
