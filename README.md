# dotfiles

Bash setup for openSUSE (Tumbleweed / Leap) and Ubuntu. Pure bash: no frameworks, no special fonts.

```
╭─ sam@laptop  ~/projects/app   main ↑1 +2 !1 ?3   took 12s
╰─❯
```

[![test](https://github.com/samahart/dotfiles/actions/workflows/test.yml/badge.svg)](https://github.com/samahart/dotfiles/actions/workflows/test.yml)

## Install on a new machine

One line, nothing to install first (only `curl`, which both distros ship with):

```bash
curl -fsSL https://raw.githubusercontent.com/samahart/dotfiles/main/bootstrap.sh | bash
```

No curl? Use `wget -qO- <same URL> | bash`.

This installs git if needed, clones the repo to `~/dotfiles`, and runs `install.sh`. Running it again pulls the latest changes and re-links everything, so it's also how you **update**.

Pass options to the installer after `bash -s --`:

```bash
curl -fsSL https://raw.githubusercontent.com/samahart/dotfiles/main/bootstrap.sh | bash -s -- --no-packages
```

| Flag | What it does |
|---|---|
| `--no-packages` | Only link the dotfiles (no sudo) |
| `--dry-run` | Show what would happen, change nothing |
| `--yes` | Don't ask any questions |

Prefer to read before running? `git clone https://github.com/samahart/dotfiles ~/dotfiles && ~/dotfiles/install.sh`

The installer:
1. Detects your distro from `/etc/os-release` and installs packages with `zypper` or `apt`, skipping any your release doesn't carry (e.g. `eza` on Ubuntu 22.04)
2. Symlinks everything in `home/` into `~`, moving any existing files to `~/.dotfiles-backup/<timestamp>/`
3. Configures git as `samahart <25089526+samahart@users.noreply.github.com>` (GitHub's no-reply address) via `home/.gitconfig`
4. Creates empty `~/.bashrc.local` and `~/.gitconfig.local` for machine-specific settings (e.g. a work email)

Because the files are **symlinks**, editing `~/.bashrc` edits the repo. Commit and push, then re-run the one-liner (or `git -C ~/dotfiles pull`) on your other machines.

`~/dotfiles/uninstall.sh` removes the links and restores your previous files.

Every push is tested on fresh openSUSE Tumbleweed, Leap, and Ubuntu 22.04/24.04 containers by GitHub Actions (`.github/workflows/test.yml`).

## What's included

**Prompt** (`.config/bash/prompt.bash`)
- `user@host`: host turns yellow over SSH, user turns red as root
- Git branch plus ↑ahead ↓behind, `+`staged, `!`modified, `?`untracked, `✖`conflicts
- Python venv / conda env name
- `took 12s` when a command runs ≥ 3 seconds
- `❯` turns red and shows the exit code when a command fails
- Font missing `╭─❯`? Add `export DOTFILES_PROMPT_ASCII=1` to `~/.bashrc.local`

**Shell** (`.bashrc`, `.inputrc`)
- 50k-line shared history with timestamps and no duplicates
- Up/Down arrows search history for what you've already typed
- Case-insensitive tab completion that lists matches on the first Tab
- `autocd` (type a folder name to enter it), typo correction for `cd`, `**` globbing

**Aliases & functions**
- `ll`, `la`, `lt` (uses `eza` with git status when available)
- `update`: full system update on either distro (it knows `zypper dup` vs `zypper up`), plus Flatpak
- `install`, `remove`, `search`: same commands on both distros
- `mkcd dir`, `extract file.tar.gz`, `bak file`, `ff '*.conf'`, `port 8080`
- Git: `gs`, `gd`, `ga`, `gc`, `gp`, `gl`, `glog`
- Ubuntu's `batcat`/`fdfind` are aliased to `bat`/`fd`, so commands match openSUSE
- `cp`/`mv`/`rm` ask before overwriting; `>` won't clobber files (use `>|` to force)
- `reload` re-sources your bashrc

**Tools** (each turns on only if it's installed)
- `fzf`: Ctrl-R fuzzy history, Ctrl-T file picker, Alt-C fuzzy cd
- `zoxide`: `z proj` jumps to your most-used matching directory
- `bat` as the man-page pager

**Also:** `.gitconfig` with your identity plus sensible defaults (main branch, rebase on pull, auto-setup remote) and a minimal `.vimrc`.

## Packages installed

Both: `git curl wget vim bash-completion fzf bat ripgrep htop tree unzip zoxide`
openSUSE: `fd eza 7zip`. Ubuntu: `fd-find eza p7zip-full`

Edit the arrays at the top of `install.sh` to change them.

## Customising

- Machine-specific stuff → `~/.bashrc.local` (not tracked)
- New aliases for every machine → `home/.config/bash/aliases.bash`
- Prompt colours → the `__C_*` variables at the top of `prompt.bash`
