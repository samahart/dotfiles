# ~/.bash_profile — read by login shells (SSH, TTY, some terminals)
# Load the distro's ~/.profile (PATH, locale, etc.), then the interactive config.

[[ -r ~/.profile ]] && . ~/.profile
[[ -r ~/.bashrc ]] && . ~/.bashrc
