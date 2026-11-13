#!/usr/bin/env bash
# Remove the dotfile symlinks and restore the most recent backup (if any).
# Packages are left installed. ~/.bashrc.local and ~/.gitconfig.local are kept.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$DOTFILES_DIR/home"
LATEST_BACKUP="$(find "$HOME/.dotfiles-backup" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n1)"; [[ -n $LATEST_BACKUP ]] && LATEST_BACKUP+=/

while IFS= read -r -d '' src; do
    rel="${src#"$SRC_DIR"/}"
    dest="$HOME/$rel"
    if [[ -L $dest && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
        rm "$dest"
        echo "removed  ~/$rel"
        if [[ -n $LATEST_BACKUP && -e $LATEST_BACKUP$rel ]]; then
            mv "$LATEST_BACKUP$rel" "$dest"
            echo "restored ~/$rel"
        fi
    fi
done < <(find "$SRC_DIR" -type f -print0)

# Ubuntu/openSUSE fallback: if no .bashrc is left, copy the distro default back
[[ -e $HOME/.bashrc || ! -r /etc/skel/.bashrc ]] || { cp /etc/skel/.bashrc "$HOME/.bashrc"; echo "restored ~/.bashrc from /etc/skel"; }

echo "Done. Open a new terminal to get your old setup back."
