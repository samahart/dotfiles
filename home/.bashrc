# ~/.bashrc — managed by dotfiles (https://github.com/samahart/dotfiles)
# Works on openSUSE and Ubuntu. Put machine-specific tweaks in ~/.bashrc.local

# Only run for interactive shells
[[ $- != *i* ]] && return

# Guard against being sourced twice in the same shell (e.g. .profile + .bash_profile)
[[ -n ${__DOTFILES_BASHRC_LOADED-} ]] && return
__DOTFILES_BASHRC_LOADED=1

DOTFILES_BASH_DIR="${HOME}/.config/bash"

# ── History ──────────────────────────────────────────────────────────────
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups      # skip dupes and lines starting with a space
HISTIGNORE="ls:ll:la:cd:pwd:exit:clear:history"
HISTTIMEFORMAT="%F %T  "
shopt -s histappend                   # append, don't overwrite
shopt -s cmdhist                      # save multi-line commands as one entry

# ── Shell behaviour ──────────────────────────────────────────────────────
shopt -s checkwinsize                 # update LINES/COLUMNS after each command
shopt -s autocd 2>/dev/null           # type a directory name to cd into it
shopt -s cdspell dirspell 2>/dev/null # fix small typos in cd paths
shopt -s globstar 2>/dev/null         # ** matches recursively
shopt -s nocaseglob                   # case-insensitive globbing
set -o noclobber                      # don't let > overwrite files (use >| to force)

# ── Environment ──────────────────────────────────────────────────────────
export EDITOR="${EDITOR:-vim}"
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-R -F -X -i"             # colours, quit if one screen, keep output, smart search
command -v nvim >/dev/null && export EDITOR=nvim VISUAL=nvim

# Coloured man pages
export LESS_TERMCAP_md=$'\e[1;36m' LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_us=$'\e[4;32m' LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_so=$'\e[1;44;33m' LESS_TERMCAP_se=$'\e[0m'
export GROFF_NO_SGR=1

# Add personal bin directories to PATH (only if they exist and aren't already there)
__path_prepend() { [[ -d $1 && ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"; }
__path_prepend "$HOME/.local/bin"
__path_prepend "$HOME/bin"
unset -f __path_prepend
export PATH

# ls colours
if command -v dircolors >/dev/null; then
    if [[ -r ~/.dircolors ]]; then eval "$(dircolors -b ~/.dircolors)"; else eval "$(dircolors -b)"; fi
fi

# ── Completion ───────────────────────────────────────────────────────────
# Ubuntu and openSUSE put bash-completion in slightly different places
if ! shopt -oq posix; then
    for f in /usr/share/bash-completion/bash_completion /etc/bash_completion; do
        [[ -r $f ]] && { . "$f"; break; }
    done
fi

# ── Modules ──────────────────────────────────────────────────────────────
for f in "$DOTFILES_BASH_DIR"/{aliases,functions,prompt,tools}.bash; do
    [[ -r $f ]] && . "$f"
done
unset f

# Local, untracked overrides (secrets, work-specific stuff, etc.)
[[ -r ~/.bashrc.local ]] && . ~/.bashrc.local
true
