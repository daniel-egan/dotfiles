# Setting up keybinds
bindkey '^[[1;5D' backward-word  # Ctrl + Left Arrow
bindkey '^[[1;5C' forward-word   # Ctrl + Right Arrow

# Terminal History
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt SHARE_HISTORY

# Source custom aliases
source ~/.config/zsh/aliases.zsh

# Antidote Plugin Manager
source ${ZDOTDIR:-$HOME}/.antidote/antidote.zsh
antidote load ~/.config/zsh/.zsh_plugins.txt

# Add Homebrew to shell
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"