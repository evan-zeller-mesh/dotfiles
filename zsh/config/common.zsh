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

# Prompt — single line; directory right-aligned, auto-hides on long commands.
# Pastel foregrounds from the Rosé Pine "rose" palette (tmux), neutral bg kept.
_p_red='#ff7979'    # exit code on failure
_p_green='#93c795'  # user@host (remote) + prompt char (active-window green)
_p_yellow='#f0e68c' # git branch
_p_blue='#81c0ff'   # python virtualenv
_p_muted='242'      # directory (subtle grey)

_g_branch=$'' #  powerline git-branch glyph
_g_python=$'' #  nerd-font python glyph

# Render the virtualenv ourselves (see DISABLE_PROMPT vars below), so disable
# venv's own "(name)" prefix to avoid it colliding with the git branch styling.
export VIRTUAL_ENV_DISABLE_PROMPT=1
export PYENV_VIRTUALENV_DISABLE_PROMPT=1

autoload -Uz vcs_info
# Show the exit code only when a real command ran (not on empty Enter spam).
preexec() { _cmd_ran=1 }
precmd() {
  local exit=$?
  vcs_info
  if (( ${_cmd_ran:-0} && exit )); then
    _exit_prompt="%F{$_p_red}${exit} %f"
  else
    _exit_prompt=""
  fi
  if [[ -n "$VIRTUAL_ENV" ]]; then
    _py_prompt="%F{$_p_blue}${_g_python} ${${VIRTUAL_ENV:t}//\%/%%}%f "
  else
    _py_prompt=""
  fi
  _cmd_ran=0
}
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats "%F{$_p_yellow}${_g_branch} %b%f"
setopt PROMPT_SUBST

# fish-style abbreviation: parent dirs shortened to first letter (~/p/mind)
_prompt_pwd() {
  setopt localoptions extendedglob
  local p="${PWD/#$HOME/~}"
  if [[ "$p" == (#m)[/~] ]]; then
    print -rn -- "$MATCH"
  else
    print -rn -- "${${${${(@j:/:M)${(@s:/:)p}##.#?}:h}%/}//\%/%%}/${${p:t}//\%/%%}"
  fi
}

# bold-green user@host only when remote
_prompt_host=''
[[ -n "$SSH_CONNECTION" || -n "$SSH_TTY" ]] && _prompt_host="%B%F{$_p_green}%n@%m%f%b "

# left: [exit] [user@host if ssh] [ venv] [ branch] $   right: path
PROMPT='${_exit_prompt}${_prompt_host}${_py_prompt}${vcs_info_msg_0_:+${vcs_info_msg_0_} }%B%F{'$_p_green'}$%f%b '
RPROMPT='%F{'$_p_muted'}$(_prompt_pwd)%f'

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
