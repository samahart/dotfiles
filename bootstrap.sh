#!/usr/bin/env bash
# One-line setup for a brand-new machine (needs only curl or wget):
#
#   curl -fsSL https://raw.githubusercontent.com/samahart/dotfiles/main/bootstrap.sh | bash
#   wget -qO-  https://raw.githubusercontent.com/samahart/dotfiles/main/bootstrap.sh | bash
#
# Pass installer flags after "bash -s --", e.g.:
#   curl -fsSL .../bootstrap.sh | bash -s -- --no-packages
#
# What it does: installs git if missing, clones (or updates) the repo into
# ~/dotfiles, then runs ./install.sh. Safe to run again at any time.
#
# Overrides: DOTFILES_REPO (owner/name), DOTFILES_BRANCH, DOTFILES_DIR,
#            DOTFILES_URL (full clone URL, e.g. git@github.com:you/dotfiles.git)

# Everything is inside main() so a half-downloaded script can't run partially.
main() {
    set -euo pipefail

    local repo="${DOTFILES_REPO:-samahart/dotfiles}"
    local branch="${DOTFILES_BRANCH:-main}"
    local dest="${DOTFILES_DIR:-$HOME/dotfiles}"
    local url="${DOTFILES_URL:-https://github.com/${repo}.git}"

    local C=$'\e[1;36m' Y=$'\e[33m' R=$'\e[1;31m' N=$'\e[0m'
    [[ -t 1 ]] || { C='' Y='' R='' N=''; }
    say()  { printf '%s==>%s %s\n' "$C" "$N" "$*"; }
    warn() { printf '%s!%s %s\n' "$Y" "$N" "$*"; }
    die()  { printf '%sError:%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

    [[ $EUID -eq 0 ]] && die "Run as your normal user, not root — sudo is used when needed."

    local no_packages=0 arg
    for arg in "$@"; do [[ $arg == --no-packages ]] && no_packages=1; done

    # ── Make sure git is available ─────────────────────────────────────
    if ! command -v git >/dev/null; then
        if ((no_packages)) || ! command -v sudo >/dev/null; then
            die "git is not installed and can't install it without sudo. Install git first."
        fi
        say "Installing git (sudo may ask for your password)"
        if command -v zypper >/dev/null; then
            sudo zypper --non-interactive install --no-recommends git-core
        elif command -v apt-get >/dev/null; then
            sudo apt-get update -qq
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git ca-certificates
        else
            die "Unsupported package manager — install git manually and re-run."
        fi
    fi

    # ── Clone or update ────────────────────────────────────────────────
    if [[ -d $dest/.git ]]; then
        say "Updating $dest"
        git -C "$dest" pull --ff-only --quiet || warn "Couldn't fast-forward (local changes?) — using what's there."
    elif [[ -e $dest ]]; then
        die "$dest exists but isn't a git repo. Move it aside or set DOTFILES_DIR."
    else
        say "Cloning $url into $dest"
        git clone --quiet --branch "$branch" "$url" "$dest"
    fi

    # ── Run the installer ──────────────────────────────────────────────
    # When piped (curl | bash) stdin is the script itself, so hand the
    # installer the terminal so its questions work.
    say "Running installer"
    if [[ ! -t 0 ]] && { : </dev/tty; } 2>/dev/null; then
        exec "$dest/install.sh" "$@" </dev/tty
    else
        exec "$dest/install.sh" "$@"
    fi
}

main "$@"
