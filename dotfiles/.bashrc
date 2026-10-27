# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Shell options
shopt -s histappend checkwinsize no_empty_cmd_completion

# Prompt
export PS1='\t \[\033[0;38;5;11m\]\u\[\033[0;38;5;15m\]@\h > \[\033[0;38;5;14m\][\w]\[\033[0;38;5;15m\]: \[\033[0m\]'

# History
export HISTSIZE=32768
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoredups
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"
export HISTTIMEFORMAT="%F %T "

# Locale & Editor
if [ -n "$TERMUX_VERSION" ]; then
    export LANG="en_US.UTF-8"
else
    export LANG="en_GB.UTF-8"
fi
export EDITOR="vim"
export VISUAL="vim"

# PATH
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

# Colors & Aliases
if command -v dircolors >/dev/null 2>&1; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi
alias rm='rm -i'
alias l='ls -lhtr'
alias c='clear'

# Disable xdg-open over SSH (for ranger)
if [ -n "$SSH_CONNECTION" ]; then
    export OpenXDG=false
    alias xdg-open="false"
fi

# SSH Agent: use forwarded socket on remote servers, start local agent on endpoints
export environ="$HOME/.ssh/environment"
if [ -n "$SSH_CONNECTION" ] && [ -S "$HOME/.ssh/ssh_auth_sock" ]; then
    export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
elif [ -z "$SSH_CONNECTION" ]; then
    [ -f "$environ" ] && . "$environ" >/dev/null
    if [ ! -S "$SSH_AUTH_SOCK" ] || ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
        mkdir -p "$HOME/.ssh"
        (umask 077; ssh-agent > "$environ")
        . "$environ" >/dev/null
        ssh-add 2>/dev/null
        [ -n "$USER" ] && [ -f "$HOME/.ssh/$USER" ] && ssh-add "$HOME/.ssh/$USER"
        [ -f "$HOME/moritzknorr.pk" ] && ssh-add "$HOME/moritzknorr.pk"
    fi
fi

# nvm (Node Version Manager) — lazy-loaded on first node/npm/npx/nvm call
export NVM_DIR="$HOME/.nvm"
_load_nvm() {
    unset -f node npm npx nvm _load_nvm 2>/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
if [ -s "$NVM_DIR/nvm.sh" ]; then
    nvm() { _load_nvm; nvm "$@"; }
    node() { _load_nvm; node "$@"; }
    npm() { _load_nvm; npm "$@"; }
    npx() { _load_nvm; npx "$@"; }
fi

# Auto-start tmux, if not called from vscode or in Hyprland
if command -v tmux >/dev/null 2>&1 && [ -z "$TMUX" ] && [ "$TERM_PROGRAM" != "vscode" ] && [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    tmux new-session -A -s main
fi

# Check for updates to ~/init config repo
_check_init_updates() {
    local repo="$HOME/init"
    local stamp="${XDG_CACHE_HOME:-$HOME/.cache}/init_update_stamp"
    [ -d "$repo/.git" ] || return
    mkdir -p "$(dirname "$stamp")"
    local now last
    now=$(date +%s)
    last=$(cat "$stamp" 2>/dev/null || echo 0)
    if [ "$(( now - last ))" -gt 3600 ]; then
        echo "$now" > "$stamp"
        (git -C "$repo" fetch --quiet 2>/dev/null &)
    fi
    local behind
    behind=$(git -C "$repo" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
    if [ "${behind:-0}" -gt 0 ]; then
        echo -e "\033[33minit: ${behind} new commit(s) available\033[0m — cd ~/init && git pull && dotfiles/install.sh"
    fi
}
_check_init_updates
unset -f _check_init_updates
