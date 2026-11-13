# Optional tool integrations — each only activates if the tool is installed

# fzf: Ctrl-R fuzzy history, Ctrl-T file picker, Alt-C fuzzy cd
if command -v fzf >/dev/null; then
    if fzf --bash >/dev/null 2>&1; then
        eval "$(fzf --bash)"                      # fzf ≥ 0.48
    else
        for f in /usr/share/doc/fzf/examples/key-bindings.bash \
                 /usr/share/fzf/shell/key-bindings.bash \
                 /usr/share/fzf/key-bindings.bash; do
            [[ -r $f ]] && { . "$f"; break; }
        done
        unset f
    fi
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"
    if command -v fd >/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    elif command -v fdfind >/dev/null; then
        export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --exclude .git'
    fi
    [[ -n ${FZF_DEFAULT_COMMAND-} ]] && export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# zoxide: "z foo" jumps to the most-used directory matching foo
command -v zoxide >/dev/null && eval "$(zoxide init bash)"

# bat as the man pager
if command -v bat >/dev/null; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
elif command -v batcat >/dev/null; then
    export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
fi
