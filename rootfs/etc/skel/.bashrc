# NexaOS Custom Bash Configuration

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History configuration
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Colored prompt with NexaOS branding
if [ "$color_prompt" = yes ]; then
    PS1='\[\033[38;5;99m\]\u@\h\[\033[00m\]:\[\033[38;5;141m\]\w\[\033[00m\]\$ '
else
    PS1='\u@\h:\w\$ '
fi

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias nexainfo='nexaos-info'

# Welcome message
if [ -f /usr/local/bin/nexaos-info ]; then
    echo ""
fi

