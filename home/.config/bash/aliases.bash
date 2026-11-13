# Aliases — sourced by ~/.bashrc

# ── Navigation ──
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# ── Listing (eza if installed, otherwise coloured ls) ──
if command -v eza >/dev/null; then
    alias ls='eza --group-directories-first'
    alias ll='eza -l --git --group-directories-first --time-style=long-iso'
    alias la='eza -la --git --group-directories-first --time-style=long-iso'
    alias lt='eza --tree --level=2 --group-directories-first'
else
    alias ls='ls --color=auto --group-directories-first'
    alias ll='ls -lh'
    alias la='ls -lAh'
    alias lt='tree -L 2 --dirsfirst 2>/dev/null || ls -R'
fi

# ── Colour ──
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -color=auto'

# ── Safety nets ──
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -I'
alias mkdir='mkdir -pv'

# ── Handy ──
alias h='history | tail -n 30'
alias path='tr ":" "\n" <<<"$PATH"'
alias ports='ss -tulpn'
alias df='df -h -x tmpfs -x devtmpfs -x squashfs'
alias du1='du -h --max-depth=1 | sort -h'
alias free='free -h'
alias reload='unset __DOTFILES_BASHRC_LOADED; source ~/.bashrc && echo "bashrc reloaded"'
alias myip='curl -s https://ifconfig.me; echo'

# ── Git ──
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias gds='git diff --staged'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias glog='git log --oneline --graph --decorate -20'

# ── Ubuntu names some tools differently ──
command -v batcat >/dev/null && ! command -v bat >/dev/null && alias bat='batcat'
command -v fdfind >/dev/null && ! command -v fd  >/dev/null && alias fd='fdfind'
if command -v bat >/dev/null || command -v batcat >/dev/null; then
    alias cat='bat --paging=never --style=plain'   # use "\cat" for the real one
fi

# ── Package management: same commands on either distro ──
# ("update" is a function in functions.bash since Leap and Tumbleweed differ)
if command -v zypper >/dev/null; then
    alias install='sudo zypper install'
    alias remove='sudo zypper remove'
    alias search='zypper search'
elif command -v apt >/dev/null; then
    alias install='sudo apt install'
    alias remove='sudo apt remove'
    alias search='apt search'
fi
