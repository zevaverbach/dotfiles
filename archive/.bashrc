function gc {
  _wrap_command "git commit -m \"$1\""
}

function m {
  _wrap_command "cd '/Users/zev/repos/main'"
}

function _wrap_command {
  # echo then run the command
  command=$1
  echo $command
  eval "$command"
}

function gac {
  _wrap_command "git add --all && git commit -m \"$1\""
}

alias gb="git branch --show-current"

function pg {
  _wrap_command "git pull origin $(git branch --show-current)"
}

function gp {
  _wrap_command "git push origin $(git branch --show-current)"
}

export BASH_SILENCE_DEPRECATION_WARNING=1
export PS1="∫ "
export PKG_CONFIG_PATH="/usr/local/opt/python@3.11/lib/pkgconfig"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
. "$HOME/.cargo/env"

# if this is present, source it
test -f ~/.git-completion.bash && . $_
export EDITOR=nvim
export FLASK_SECRET='\x8f\xf5\x8b\xbe\xedg\xa7\x8d\x02u\xabTq\x11[7'
export PROMPT_COMMAND='echo -ne "\033]0; \007"'
export LD_LIBRARY_PATH="/Library/Developer/CommandLineTools/usr/lib/:$LD_LIBRARY_PATH"
PYTHON3_HOST_PROG=/usr/bin/python3
export NETLIFY_DOMAINS=helpers.fun
export AI_GETTER_S3_BUCKET="ai-generated-assets"
export AI_GETTER_SAVE_PATH="/Users/zev/images"
export OPENAI_ORG=org-CDraHWcETUPMydQlRFMIS7ge
if [ -f $HOME/.bash_secret ]; then
    . $HOME/.bash_secret
fi
export LDFLAGS="-L/usr/local/opt/llvm/lib"
export CPPFLAGS="-I/usr/local/opt/llvm/include"

export PATH=$PATH:/Users/zev/.local/bin

# Added by Radicle.
export PATH="$PATH:/Users/zev/.radicle/bin"
export PATH="$PATH:/Applications/Docker.app/Contents/Resources/bin"
export ANTHROPIC_MODEL='claude-sonnet-4-20250514'
export ANTHROPIC_SMALL_FAST_MODEL='claude-3-5-haiku-20241022'
export PATH="/usr/local/Cellar/node/24.4.1/bin:$PATH"
