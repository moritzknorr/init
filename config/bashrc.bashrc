# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# set term, this should work for tmux
export TERM=screen-256color

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
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

export PS1="\t \[$(tput sgr0)\]\[\033[38;5;11m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]@\h > \[$(tput sgr0)\]\[\033[38;5;14m\][\w]\[$(tput sgr0)\]\[\033[38;5;15m\]: \[$(tput sgr0)\]"

export environ="$HOME/.ssh/environment"

# Uncomment for machine with private key
# if [ -f "$environ" ]; then
# . "$environ" >/dev/null
# fi
# if [ -z "$SSH_AUTH_SOCK" ] || ! ps -p "$SSH_AGENT_PID" | grep -q ssh-agent; then (umask 077; ssh-agent > "$environ")
# . "$environ" >/dev/null
# ssh-add $HOME/.ssh/$USER &> /dev/null
# ssh-add $HOME/moritzknorr.pk &> /dev/null
# fi

shopt -s no_empty_cmd_completion

# required functions for proxy
urlencode() {
    # urlencode <string>
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
    LC_COLLATE=$old_lc_collate
}

urldecode() {
    # urldecode <string>
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

getip() {
  curl -4 icanhazip.com
}

## Nicer shell experience
export GREP_OPTIONS="--color=auto"; # make grep colorful
export LSCOLORS=gxfxbEaEBxxEhEhBaDaCaD; # make ls more colorful as well
export HISTSIZE=32768; # Larger bash history (allow 32³ entries; default is 500)
export HISTFILESIZE=$HISTSIZE;
export HISTCONTROL=ignoredups; # Remove duplicates from history. I use `git status` a lot.
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"; # Make some commands not show up in history
export LANG="en_US.UTF-8"; # Language formatting is still important
export LC_ALL="en_US.UTF-8"; # byte-wise sorting and force language for those pesky apps
export MANPAGER="less -X"; # Less is more

# Add timestamps to history for better context
export HISTTIMEFORMAT="%F %T " # Format: YYYY-MM-DD HH:MM:SS

# A safer 'rm'
alias rm='rm -i'

# less with line numbers
alias less='less -N'

# A better 'ls' (your 'll' is good, this one is an alternative)
alias l='ls -lAh' # List all files, human-readable sizes

# Clear
alias c='clear'

# Auto-start tmux, if not called from vscode or in Hyprland
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ "$TERM_PROGRAM" != "vscode" ] && [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    # If a session named "main" exists, attach to it.
    # Otherwise, create a new session named "main".
    (tmux has-session -t main 2>/dev/null && tmux attach -t main) || tmux new-session -s main
fi

EDITOR="/usr/bin/vim"

# Add .local/bin to PATH for claude-code
export PATH="~/.local/bin:$PATH"
