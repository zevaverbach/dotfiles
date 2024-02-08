# Purpose

Get up and going in Linux with some nice bash aliases, neovim configuration + plugins, and tmux.

# Prerequisites

    - tmux
    - npm or nvm
    - neovim 0.8+

# Installation

Symlink the config files to `~/.config/nvim` and `~`, respectively. 

    > ln -s $HOME/repos/dotfiles/init.lua $HOME/.config/nvim/init.lua
    > ln -s $HOME/repos/dotfiles/vimrc.vim $HOME/.config/nvim/vimrc.vim
    > ln -s $HOME/repos/dotfiles/bash_aliases $HOME/.bash_aliases
    > ln -s $HOME/repos/dotfiles/tmux.conf $HOME/.tmux.conf

After Coc is installed, install coc-pyright and pyright:

    # terminal:
    > npm install -g pyright
    > sudo apt install ripgrep
    # inside nvim:
    :CocInstall coc-pyright
