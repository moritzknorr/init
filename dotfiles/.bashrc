# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# append to the history file, don't overwrite it
# (history size / control / format are configured together further below)
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    #alias grep='grep --color=auto'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
# if ! shopt -oq posix; then
#   if [ -f /usr/share/bash-completion/bash_completion ]; then
#     . /usr/share/bash-completion/bash_completion
#   elif [ -f /etc/bash_completion ]; then
#     . /etc/bash_completion
#   fi
# fi

export PS1="\t \[$(tput sgr0)\]\[\033[38;5;11m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]@\h > \[$(tput sgr0)\]\[\033[38;5;14m\][\w]\[$(tput sgr0)\]\[\033[38;5;15m\]: \[$(tput sgr0)\]"

export environ="$HOME/.ssh/environment"

# Uncomment for machine with private key
# if [ -f "$environ" ]; then
#   . "$environ" >/dev/null
# fi
# if [ -z "$SSH_AUTH_SOCK" ] || ! ps -p "$SSH_AGENT_PID" | grep -q ssh-agent; then (umask 077; ssh-agent > "$environ")
#   . "$environ" >/dev/null
#   ssh-add $HOME/.ssh/$USER &> /dev/null
#   ssh-add $HOME/moritzknorr.pk &> /dev/null
# fi

shopt -s no_empty_cmd_completion

## Nicer shell experience
# export GREP_OPTIONS="--color=auto"; # make grep colorful, NOT SUPPORTED
export LSCOLORS=gxfxbEaEBxxEhEhBaDaCaD; # make ls more colorful as well
export HISTSIZE=32768; # Larger bash history (allow 32³ entries; default is 500)
export HISTFILESIZE=$HISTSIZE;
export HISTCONTROL=ignoredups; # Remove duplicates from history. I use `git status` a lot.
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"; # Make some commands not show up in history
export LANG="en_GB.UTF-8"; # Language formatting is still important
export LC_ALL="en_GB.UTF-8"; # byte-wise sorting and force language for those pesky apps

# Add timestamps to history for better context
export HISTTIMEFORMAT="%F %T " # Format: YYYY-MM-DD HH:MM:SS

# A safer 'rm'
alias rm='rm -i'

# A better 'ls' (your 'll' is good, this one is an alternative)
alias l='ls -lhtr' # List all files, human-readable sizes

# Clear
alias c='clear'

# Auto-start tmux, if not called from vscode or in Hyprland
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ "$TERM_PROGRAM" != "vscode" ] && [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    # If a session named "main" exists, attach to it.
    # Otherwise, create a new session named "main".
    (tmux has-session -t main 2>/dev/null && tmux attach -t main) || tmux new-session -s main
fi

export EDITOR="vim"
export VISUAL="vim"

# Add .local/bin to PATH for claude-code
export PATH="$HOME/.local/bin:$PATH"

# Add opencode to PATH
export PATH="$HOME/.opencode/bin:$PATH"

# nvm (Node Version Manager) — lazy-loaded to keep shell startup fast.
# Sourcing nvm.sh eagerly costs ~140ms per shell (it runs `node --version`
# etc.). Instead we register lightweight stubs; the first call to node/npm/nvm
# sources the real nvm and then re-runs the command. Interactive shells that
# never touch node pay nothing.
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

# Disable xdg-open over SSH (for ranger)
if [ -n "$SSH_CONNECTION" ]; then
    export OpenXDG=false
    alias xdg-open="false"
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
        git -C "$repo" fetch --quiet 2>/dev/null &
    fi
    local behind
    behind=$(git -C "$repo" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
    if [ "${behind:-0}" -gt 0 ]; then
        echo -e "\033[33minit: ${behind} new commit(s) available\033[0m — cd ~/init && git pull && dotfiles/install.sh"
    fi
}
_check_init_updates
unset -f _check_init_updates
