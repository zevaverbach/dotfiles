# Purpose

Get up and going in Linux with some nice bash aliases, neovim configuration + plugins, and tmux.

# Prerequisites

    - tmux
    - modern node and npm
    - neovim 0.9+
    - git

# Installation

## Symlink config files

    # core configs
    > ln -s $HOME/repos/dotfiles/init.lua $HOME/.config/nvim/init.lua
    > ln -s $HOME/repos/dotfiles/bash-funcs $HOME/.bash_functions
    > ln -s $HOME/repos/dotfiles/bashrc $HOME/.bashrc
    > ln -s $HOME/repos/dotfiles/tmux.conf $HOME/.tmux.conf
    > ln -s $HOME/repos/dotfiles/.prettierrc.json $HOME/.prettierrc.json

    # helper scripts on PATH
    > ln -s $HOME/repos/dotfiles/fzf-tmux /usr/local/bin/fzf-tmux
    > ln -s $HOME/repos/dotfiles/get_git_branch.sh /usr/local/bin/get_git_branch.sh
    > ln -s $HOME/repos/dotfiles/tok /usr/local/bin/tok

## Symlink layout (what I actually use)

    ~/.bashrc -> ~/repos/dotfiles/bashrc
    ~/.bash_functions -> ~/repos/dotfiles/bash-funcs
    ~/.tmux.conf -> ~/repos/dotfiles/tmux.conf
    ~/.config/nvim/init.lua -> ~/repos/dotfiles/init.lua
    ~/.prettierrc.json -> ~/repos/dotfiles/.prettierrc.json
    /usr/local/bin/fzf-tmux -> ~/repos/dotfiles/fzf-tmux
    /usr/local/bin/get_git_branch.sh -> ~/repos/dotfiles/get_git_branch.sh
    /usr/local/bin/tok -> ~/repos/dotfiles/tok

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
