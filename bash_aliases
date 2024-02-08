alias nvim=~/nvim-linux64/bin/nvim
alias vi=nvim
alias ss='source ~/.bashrc'
alias bb='vi ~/.bashrc'
alias ba='vi ~/.bash_aliases'
alias bs='vi ~/.git_secret'
alias r='cd ~/repos && pwd'
alias vl='vi ~/.config/nvim/init.lua'
alias vv='vi ~/.config/nvim/vimrc.vim'
alias gb='git branch'
alias gl='git log'
alias pp='vi ~/.profile'
alias pg='git pull origin $(git branch --show-current)'
alias gp='git push origin $(git branch --show-current)'
alias gs='git status'
alias gd='git diff'
alias ga='git add --all'
alias l='ls -l'
alias i='ipython'
alias python=python3

function gc() {
    git commit -m "$1"
}
