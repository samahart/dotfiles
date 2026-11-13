# Two-line prompt, pure bash (no plugins, no special fonts required):
#
#   ╭─ sam@laptop  ~/projects/app   main ↑1 +2 !1 ?3   took 12s
#   ╰─❯
#
# • user@host is always shown; host turns yellow over SSH, user turns red as root
# • git branch + status: ↑ahead ↓behind  +staged  !modified  ?untracked
# • Python virtualenv / conda env when active
# • duration of the last command when it took ≥ 3 s
# • the ❯ turns red (with the exit code) when the last command failed
#
# Set DOTFILES_PROMPT_ASCII=1 in ~/.bashrc.local if your font lacks the box characters.

# Colours (wrapped in \[ \] so bash measures the prompt correctly)
__c() { printf '\\[\\e[%sm\\]' "$1"; }
__C_RESET=$(__c 0)
__C_DIM=$(__c '2;37')
__C_USER=$(__c '1;32')
__C_ROOT=$(__c '1;31')
__C_HOST=$(__c '1;34')
__C_SSH=$(__c '1;33')
__C_DIR=$(__c '1;36')
__C_GIT=$(__c '1;35')
__C_OK=$(__c '1;32')
__C_ERR=$(__c '1;31')
__C_WARN=$(__c '0;33')
__C_INFO=$(__c '0;34')
unset -f __c

if [[ -n ${DOTFILES_PROMPT_ASCII-} ]]; then
    __P_TOP='+-' __P_BOT='`->' __P_ARROW='$' __P_BRANCH='' __P_AHEAD='^' __P_BEHIND='v'
else
    __P_TOP='╭─' __P_BOT='╰─' __P_ARROW='❯' __P_BRANCH=' ' __P_AHEAD='↑' __P_BEHIND='↓'
fi

# Let the prompt draw the venv name instead of venv's activate script
export VIRTUAL_ENV_DISABLE_PROMPT=1

__prompt_git() {
    command -v git >/dev/null || return
    local out
    out=$(git status --porcelain=v2 --branch 2>/dev/null) || return

    local branch="" oid="" ahead=0 behind=0 staged=0 modified=0 untracked=0 conflicts=0 line
    while IFS= read -r line; do
        case $line in
            "# branch.head "*) branch=${line#\# branch.head } ;;
            "# branch.oid "*)  oid=${line#\# branch.oid } ;;
            "# branch.ab "*)
                read -r _ _ ahead behind <<<"$line"
                ahead=${ahead#+}; behind=${behind#-} ;;
            "1 "*|"2 "*)
                [[ ${line:2:1} != . ]] && ((staged++))
                [[ ${line:3:1} != . ]] && ((modified++)) ;;
            "u "*) ((conflicts++)) ;;
            "? "*) ((untracked++)) ;;
        esac
    done <<<"$out"

    [[ $branch == "(detached)" ]] && branch="@${oid:0:7}"

    local s="${__C_GIT}${__P_BRANCH}${branch}${__C_RESET}"
    ((ahead))     && s+=" ${__C_INFO}${__P_AHEAD}${ahead}${__C_RESET}"
    ((behind))    && s+=" ${__C_INFO}${__P_BEHIND}${behind}${__C_RESET}"
    ((conflicts)) && s+=" ${__C_ERR}✖${conflicts}${__C_RESET}"
    ((staged))    && s+=" ${__C_OK}+${staged}${__C_RESET}"
    ((modified))  && s+=" ${__C_WARN}!${modified}${__C_RESET}"
    ((untracked)) && s+=" ${__C_DIM}?${untracked}${__C_RESET}"
    printf '  %s' "$s"
}

__prompt_duration() {
    local secs=$1
    ((secs < 3)) && return
    local out=""
    ((secs >= 3600)) && out+="$((secs / 3600))h "
    ((secs >= 60))   && out+="$((secs % 3600 / 60))m "
    out+="$((secs % 60))s"
    printf '  %stook %s%s' "$__C_WARN" "$out" "$__C_RESET"
}

__prompt_command() {
    local exit=$?

    # Keep history in sync across open terminals
    history -a

    # Elapsed time (start is recorded by PS0 just before a command runs)
    local elapsed=""
    if [[ -n ${__prompt_t0-} ]]; then
        elapsed=$(__prompt_duration $((SECONDS - __prompt_t0)))
        unset __prompt_t0
    fi

    # user@host
    local ucol=$__C_USER hcol=$__C_HOST
    ((EUID == 0)) && ucol=$__C_ROOT
    [[ -n ${SSH_CONNECTION-}${SSH_TTY-} ]] && hcol=$__C_SSH
    local who="${ucol}\\u${__C_DIM}@${hcol}\\h${__C_RESET}"

    # Environment (venv / conda)
    local env=""
    if [[ -n ${VIRTUAL_ENV-} ]]; then
        env="${__C_WARN}(${VIRTUAL_ENV##*/})${__C_RESET} "
    elif [[ -n ${CONDA_DEFAULT_ENV-} && ${CONDA_DEFAULT_ENV} != base ]]; then
        env="${__C_WARN}(${CONDA_DEFAULT_ENV})${__C_RESET} "
    fi

    # Arrow colour from exit status
    local arrow
    if ((exit == 0)); then
        arrow="${__C_OK}${__P_ARROW}${__C_RESET}"
    else
        arrow="${__C_ERR}${exit} ${__P_ARROW}${__C_RESET}"
    fi

    # Terminal title: user@host: dir
    local title='\[\e]0;\u@\h: \w\a\]'

    PS1="${title}\n${__C_DIM}${__P_TOP}${__C_RESET} ${env}${who}  ${__C_DIR}\\w${__C_RESET}$(__prompt_git)${elapsed}\n${__C_DIM}${__P_BOT}${__C_RESET}${arrow} "
    PS2="${__C_DIM}  ${__P_ARROW}${__C_RESET} "
}

# PS0 is expanded right before each command runs; the arithmetic inside records
# the start time in the current shell without printing anything (bash ≥ 4.4).
# shellcheck disable=SC2016
PS0='${PS1:$((__prompt_t0=SECONDS,0)):0}'

# Run ours first so it sees the real $?; keep anything the distro already set (e.g. VTE).
if [[ ${PROMPT_COMMAND-} != *__prompt_command* ]]; then
    PROMPT_COMMAND="__prompt_command${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi
