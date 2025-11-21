#!/bin/bash

# Clear the screen
clear

# MOTD - Branding banner
echo "==========================================="
echo "        LaswitchTech thinOS Terminal        "
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

# Prevent Ctrl+Z (suspend)
set -o monitor

# Prevent accidental exit
trap '' 2 3

# Help command
help() {
    echo "Available commands:"
    echo "  netinfo       - Show network details"
    echo "  cls           - Clear screen"
    echo "  reboot        - Reboot device"
    echo "  shutdown      - Power off device"
}
