# Functions — sourced by ~/.bashrc

# Make a directory and cd into it
mkcd() { mkdir -p -- "$1" && cd -- "$1" || return; }

# Extract almost any archive
extract() {
    [[ -f $1 ]] || { echo "extract: '$1' is not a file" >&2; return 1; }
    case $1 in
        *.tar.bz2|*.tbz2) tar xjf "$1" ;;
        *.tar.gz|*.tgz)   tar xzf "$1" ;;
        *.tar.xz|*.txz)   tar xJf "$1" ;;
        *.tar.zst)        tar --zstd -xf "$1" ;;
        *.tar)            tar xf "$1" ;;
        *.bz2)            bunzip2 "$1" ;;
        *.gz)             gunzip "$1" ;;
        *.xz)             unxz "$1" ;;
        *.zip)            unzip "$1" ;;
        *.7z)             7z x "$1" ;;
        *.rar)            unrar x "$1" ;;
        *) echo "extract: don't know how to extract '$1'" >&2; return 1 ;;
    esac
}

# Update the whole system on either distro
update() {
    if command -v zypper >/dev/null; then
        sudo zypper refresh || return
        if grep -qi tumbleweed /etc/os-release 2>/dev/null; then
            sudo zypper dist-upgrade
        else
            sudo zypper update
        fi
    elif command -v apt >/dev/null; then
        sudo apt update && sudo apt full-upgrade
    fi
    command -v flatpak >/dev/null && flatpak update -y
}

# Find files by name in the current tree:  ff '*.conf'
ff() { find . -iname "${1:-*}" -not -path '*/.git/*' 2>/dev/null; }

# Back up a file with a timestamp:  bak nginx.conf  ->  nginx.conf.2026-11-12_2153.bak
bak() { cp -a -- "$1" "$1.$(date +%F_%H%M).bak"; }

# Show which process is listening on a port:  port 8080
port() { sudo ss -tulpn | grep -E ":${1}\b"; }
