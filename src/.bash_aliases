if [ -f ~/.bash_profile ]; then
    . ~/.bash_profile
fi

# Custom Aliases
alias cls='clear'
alias reboot='sudo systemctl reboot'
alias shutdown='sudo systemctl poweroff'
alias netinfo='ip -c a && ip r && ping -c 3 8.8.8.8'
alias ls='ls -l --color=auto'
