# Common zsh config — loaded on all platforms

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000000            # commands kept in memory per session
SAVEHIST=1000000            # commands persisted to $HISTFILE

setopt EXTENDED_HISTORY     # record timestamp + duration for each command
setopt SHARE_HISTORY        # live-share history across all running shells
setopt HIST_IGNORE_DUPS     # don't store a command identical to the previous
setopt HIST_IGNORE_SPACE    # don't store commands prefixed with a space
setopt HIST_REDUCE_BLANKS   # collapse superfluous whitespace before storing
setopt HIST_FIND_NO_DUPS    # skip earlier duplicates when searching (fzf, ↑)
setopt HIST_SAVE_NO_DUPS    # don't write duplicate entries to the file
setopt HIST_FCNTL_LOCK      # safe concurrent writes from multiple shells

# Aliases
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases

# Keybindings (fixes home/end in JetBrains terminals and some others)
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

# FZF
[[ -x "$(command -v fzf)" ]] && source <(fzf --zsh)

# Colors
export CLICOLOR=1

# Prompt
autoload -U colors && colors
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '(%b)'
setopt PROMPT_SUBST
PROMPT='%{%B%K{green}%}%?%k %{%B%F{green}%}%n@%m:%{%F{blue}%}%4~ %{$reset_color%}${vcs_info_msg_0_} $ '

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/go/bin"
export PATH="$PATH:$HOME/.cargo/bin"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
[[ -x "$(command -v pyenv)" ]] && eval "$(pyenv init -)"

# nvm
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]]          && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# n (node version manager)
export N_PREFIX="$HOME/.n"
export PATH="$PATH:$N_PREFIX/bin"

# sdkman
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
