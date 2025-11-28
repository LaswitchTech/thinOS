#!/bin/bash

# OS/architecture detection
UNAME_OS="$(uname -s)"
case "$UNAME_OS" in
    Linux)
        OS="linux"
        ;;
    Darwin)
        OS="macos"
        ;;
    *)
        echo "Unsupported OS: $UNAME_OS" >&2
        exit 1
        ;;
esac

ARCH="$(uname -m)"
case "$ARCH" in
    i386|i686|x86|i86pc)
        ARCH="x86_64"
        ;;
    amd64|x86_64)
        ARCH="x86_64"
        ;;
    armv6l|armv7l|armhf)
        ARCH="armhf"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH" >&2
        exit 1
        ;;
esac

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

# Set FreeRDP library paths
export LD_LIBRARY_PATH="/usr/share/PyRDPConnect/src/bin/freerdp/${OS}/${ARCH}/lib"
export FREERDP_PLUGIN_PATH="/usr/share/PyRDPConnect/src/bin/freerdp/${OS}/${ARCH}/plugins"
# xfreerdp with recommended options
alias xfreerdp="/usr/share/PyRDPConnect/src/bin/freerdp/${OS}/${ARCH}/xfreerdp"

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
