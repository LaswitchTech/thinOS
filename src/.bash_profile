#!/bin/bash

# Prevent running this init more than once per shell session
if [ -n "$THINOS_INIT_PROFILE_DONE" ]; then
    # Already initialized in this shell; skip re-running
    return 2>/dev/null || :
fi
export THINOS_INIT_PROFILE_DONE=1

# Clear the screen
clear

# MOTD - Branding banner
echo "==========================================="
echo "              thinOS Terminal              "
echo "==========================================="
echo ""
echo " Type 'help' for available commands."
echo ""
echo "Hostname  : $(hostname)"
echo "OS        : $(lsb_release -ds 2>/dev/null || uname -a)"
echo "IP Address: $(hostname -I | awk '{print $1}')"
echo ""

# Disable history
unset HISTFILE
export HISTSIZE=0
export HISTFILESIZE=0

# Locale
export LANG="en_CA.UTF-8"
export LC_ALL="en_CA.UTF-8"

# Custom PS1 prompt
GREEN="\[\033[0;32m\]"
BLUE="\[\033[0;34m\]"
RESET="\[\033[0m\]"

PS1="$BLUE[thinOS]$GREEN \u@\h:\w \$ $RESET"

# # Prevent Ctrl+Z (suspend)
# set -o monitor

# # Prevent accidental exit
# trap '' 2 3

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
