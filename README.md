# Purpose

Get up and going in Linux with some nice bash aliases, neovim configuration + plugins, and tmux.

# Prerequisites

    - tmux
    - modern node and npm
    - neovim 0.9+
    - git

# Installation

## Symlink config files

    > ln -s $HOME/repos/dotfiles/init.lua $HOME/.config/nvim/init.lua
    > ln -s $HOME/repos/dotfiles/bash_funcs $HOME/.bash_aliases
    > ln -s $HOME/repos/dotfiles/bashrc $HOME/.bashrc
    > ln -s $HOME/repos/dotfiles/tmux.conf $HOME/.tmux.conf
    > ln -s $HOME/repos/dotfiles/fzf-tmux /usr/local/bin/fzf-tmux

## Install TPM (Tmux Plugin Manager)

    > git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

After symlinking tmux.conf, launch tmux and install plugins with `Ctrl-a + Shift-i`.

## Set up Neovim plugins

After Coc is installed, install coc-pyright and pyright:

    # terminal:
    > npm install -g pyright
    > sudo apt install ripgrep
    # inside nvim:
    :CocInstall coc-pyright

When you launch neovim, Lazy should automatically install all the plugins.
