#!/bin/bash

# Prevent running this init more than once per shell session
if [ -n "$THINOS_INIT_ALIASES_DONE" ]; then
    # Already initialized in this shell; skip re-running
    return 2>/dev/null || :
fi
export THINOS_INIT_ALIASES_DONE=1

# Custom aliases
alias cls='clear'
alias reboot='systemctl reboot'
alias shutdown='systemctl poweroff'
alias ls='ls -l --color=auto'
alias connect='python3 /usr/share/PyRDPConnect/src/main.py'
alias configure='python3 /usr/share/thinOS/src/main.py'

# Command to show detailed network information
netinfo() {
    ip -c a
    ip r
    ping -c 3 8.8.8.8
}

# Help command
help() {
    echo "Available commands:"
    echo "  netinfo       - Show network details"
    echo "  cls           - Clear screen"
    echo "  reboot        - Reboot device"
    echo "  shutdown      - Power off device"
}

if [ -f ~/.bash_profile ]; then
    . ~/.bash_profile
fi
