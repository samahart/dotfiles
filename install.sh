#!/usr/bin/env bash
# Dotfiles installer for openSUSE (Tumbleweed/Leap) and Ubuntu (and Debian-likes).
#
#   ./install.sh               install packages + link dotfiles
#   ./install.sh --no-packages only link dotfiles (no sudo needed)
#   ./install.sh --dry-run     show what would happen, change nothing
#   ./install.sh --yes         don't ask questions
#
# Existing files are moved to ~/.dotfiles-backup/<timestamp>/ before linking.
# Run ./uninstall.sh to remove the links and restore the most recent backup.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$DOTFILES_DIR/home"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

DO_PACKAGES=1 DRY_RUN=0 ASSUME_YES=0
for arg in "$@"; do
    case $arg in
        --no-packages) DO_PACKAGES=0 ;;
        --dry-run)     DRY_RUN=1 ;;
        -y|--yes)      ASSUME_YES=1 ;;
        -h|--help)     sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $arg (try --help)" >&2; exit 1 ;;
    esac
done

# ── Output helpers ───────────────────────────────────────────────────────
if [[ -t 1 ]]; then B=$'\e[1m' G=$'\e[32m' Y=$'\e[33m' R=$'\e[31m' C=$'\e[36m' N=$'\e[0m'
else B='' G='' Y='' R='' C='' N=''; fi
info() { printf '%s==>%s %s\n' "$C$B" "$N" "$*"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
die()  { printf '%sError:%s %s\n' "$R$B" "$N" "$*" >&2; exit 1; }
run()  { if ((DRY_RUN)); then printf '  %s[dry-run]%s %s\n' "$Y" "$N" "$*"; else "$@"; fi; }
ask()  { ((ASSUME_YES)) && return 0; [[ -t 0 ]] || return 1; local r; read -rp "  $1 [Y/n] " r; [[ -z $r || $r =~ ^[Yy] ]]; }

[[ $EUID -eq 0 ]] && die "Run this as your normal user, not root (it will use sudo when needed)."
[[ -d $SRC_DIR ]] || die "Can't find $SRC_DIR"

# ── Detect distro ────────────────────────────────────────────────────────
[[ -r /etc/os-release ]] || die "/etc/os-release not found — unsupported system."
# shellcheck disable=SC1091
. /etc/os-release
DISTRO_FAMILY=""
case " ${ID:-} ${ID_LIKE:-} " in
    *" opensuse"*|*" suse "*|*" sles "*) DISTRO_FAMILY=suse ;;
    *" ubuntu "*|*" debian "*)           DISTRO_FAMILY=debian ;;
esac
info "Detected ${B}${PRETTY_NAME:-$ID}${N} (family: ${DISTRO_FAMILY:-unknown})"

# ── Packages ─────────────────────────────────────────────────────────────
# Names that are the same everywhere
COMMON_PKGS=(git curl wget vim bash-completion fzf bat ripgrep htop tree unzip zoxide)
# Names that differ (or only exist on one side)
SUSE_PKGS=(fd eza 7zip)
DEBIAN_PKGS=(fd-find eza p7zip-full)

pkg_available() {
    case $DISTRO_FAMILY in
        debian) apt-cache show "$1" >/dev/null 2>&1 ;;
        suse)   sudo zypper --non-interactive --quiet search --match-exact "$1" >/dev/null 2>&1 ;;
    esac
}

install_packages() {
    local wanted=("${COMMON_PKGS[@]}") available=() missing=() p
    case $DISTRO_FAMILY in
        suse)   wanted+=("${SUSE_PKGS[@]}") ;;
        debian) wanted+=("${DEBIAN_PKGS[@]}") ;;
        *) warn "Unsupported distro — skipping packages. Install them yourself: ${COMMON_PKGS[*]}"; return ;;
    esac

    command -v sudo >/dev/null || die "sudo is required to install packages (or use --no-packages)."

    info "Refreshing package metadata (sudo may ask for your password)"
    case $DISTRO_FAMILY in
        debian) run sudo apt-get update -qq ;;
        suse)   run sudo zypper --non-interactive --quiet refresh ;;
    esac

    # Skip anything this release doesn't have (e.g. eza on older Ubuntu)
    for p in "${wanted[@]}"; do
        if pkg_available "$p"; then available+=("$p"); else missing+=("$p"); fi
    done
    ((${#missing[@]})) && warn "Not in your repos, skipping: ${missing[*]}"

    info "Installing: ${available[*]}"
    case $DISTRO_FAMILY in
        debian) run sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${available[@]}" ;;
        suse)   run sudo zypper --non-interactive install --no-recommends "${available[@]}" ;;
    esac
    ok "Packages installed"
}

if ((DO_PACKAGES)); then
    if ask "Install packages with ${DISTRO_FAMILY:-your package manager}?"; then
        install_packages
    else
        warn "Skipping packages"
    fi
fi

# ── Link dotfiles ────────────────────────────────────────────────────────
info "Linking dotfiles into $HOME"
backed_up=0
while IFS= read -r -d '' src; do
    rel="${src#"$SRC_DIR"/}"
    dest="$HOME/$rel"

    # Already linked to us? nothing to do
    if [[ -L $dest && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
        ok "$rel (already linked)"
        continue
    fi

    # Back up whatever is there
    if [[ -e $dest || -L $dest ]]; then
        run mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
        run mv "$dest" "$BACKUP_DIR/$rel"
        backed_up=1
    fi

    run mkdir -p "$(dirname "$dest")"
    run ln -s "$src" "$dest"
    ok "$rel"
done < <(find "$SRC_DIR" -type f -print0 | sort -z)

((backed_up)) && warn "Your previous files were saved in $BACKUP_DIR"

# Directories some configs expect
run mkdir -p "$HOME/.vim/undo" "$HOME/.local/bin"

# ── Local config files (never overwritten, not tracked) ──────────────────
if [[ ! -e $HOME/.bashrc.local ]]; then
    if ((DRY_RUN)); then
        run touch "$HOME/.bashrc.local"
    else
        cat >"$HOME/.bashrc.local" <<'EOF'
# ~/.bashrc.local — machine-specific settings, not tracked by the dotfiles repo.
# Examples:
#   export DOTFILES_PROMPT_ASCII=1        # plain ASCII prompt if your font lacks ╭─❯
#   export PATH="$HOME/go/bin:$PATH"
#   alias work='cd ~/work'
EOF
        ok "Created ~/.bashrc.local for your own tweaks"
    fi
fi

if [[ ! -e $HOME/.gitconfig.local ]] && ! ((DRY_RUN)); then
    name="" email=""
    if ((ASSUME_YES == 0)) && [[ -t 0 ]]; then
        info "Git identity (stored in ~/.gitconfig.local; leave blank to skip)"
        read -rp "  Name:  " name
        read -rp "  Email: " email
    fi
    {
        echo "# ~/.gitconfig.local — personal git settings, not tracked"
        echo "[user]"
        [[ -n $name ]]  && echo "    name = $name"  || echo "#   name = Your Name"
        [[ -n $email ]] && echo "    email = $email" || echo "#   email = you@example.com"
    } >"$HOME/.gitconfig.local"
    ok "Created ~/.gitconfig.local"
fi

echo
info "${G}Done!${N} Open a new terminal, or run:  ${B}source ~/.bashrc${N}"
