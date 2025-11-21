alias cls='clear'
alias reboot='systemctl reboot'
alias shutdown='systemctl poweroff'
alias netinfo='ip -c a && ip r && ping -c 3 8.8.8.8'
alias ls='ls -l --color=auto'
alias connect='python3 /usr/share/PyRDPConnect/src/main.py'

if [ -f ~/.bash_profile ]; then
    . ~/.bash_profile
fi
