# Purpose

Get up and going in Linux with some nice bash aliases, neovim configuration + plugins, and tmux.

# Prerequisites

    - tmux
    - npm or nvm
    - neovim 0.8+

# Installation

Symlink the config files to `~/.config/nvim` and `~`, respectively, OR just run `./install.sh` which will do that for you.

    > ln -s $HOME/repos/dotfiles/init.lua $HOME/.config/nvim/init.lua
    > ln -s $HOME/repos/dotfiles/vimrc.vim $HOME/.config/nvim/vimrc.vim
    > ln -s $HOME/repos/dotfiles/bash_aliases $HOME/.bash_aliases
    > ln -s $HOME/repos/dotfiles/tmux.conf $HOME/.tmux.conf

After Coc is installed, install coc-pyright and pyright:

    # terminal:
    > npm install -g pyright
    > sudo apt install ripgrep   # or brew install
    # inside nvim:
    :CocInstall coc-pyright
