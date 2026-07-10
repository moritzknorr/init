# Dotfiles — Recommendations

Findings from the dotfiles review (2026-07-10). The **safe/clear fixes** were already
applied (see git log). This file lists the remaining items that are **judgement calls,
habit changes, or need a decision** — none applied automatically.

Scope reviewed: `dotfiles/{.bashrc,.bash_profile,.profile,.gitconfig,.tmux.conf,.vimrc,kitty.conf,install.sh}`.

---

## Already fixed (for reference)
- **`.bashrc`** — removed the dead first history block (lines 13-20 set `HISTSIZE=1000`,
  `HISTFILESIZE=2000`, `HISTCONTROL=ignoreboth`, all overwritten later by the block at
  ~line 105 with `32768` / `ignoredups`). Kept `shopt -s histappend`.
- **`.bashrc`** — `EDITOR="/usr/bin/vim"` → `export EDITOR=...` (was not exported, so git
  and other child processes never saw it).
- **`.gitconfig`** — `editor = vi` → `vim` (matches the `.vimrc` and `EDITOR`).
- **`install.sh`** — hard-coded `DIR_TARGET="/home/knorr"` → `$HOME`; added a diff-aware
  timestamped backup before overwriting; loop over a file list instead of six `cp` lines.

---

## Recommended, not yet applied

### 6. `export environ="$HOME/.ssh/environment"` (`.bashrc`)
Exports a very generic global var `environ` used only by the commented-out ssh-agent block
right below it. Namespace pollution. Recommend making it local to that block (and only
defining it if/when the block is uncommented), or removing it.
**Status: not applied (skipped by user).**

### 8. `.bashrc` history config now consolidated — keep it together
After the earlier merge, all history config lives in one block. Keep future history tweaks
there; don't reintroduce a second block near the top. **Status: informational, no action.**

### 9. Consider symlinks instead of `cp` in `install.sh`
Current model copies repo → `~`, so **every file must be edited in two places** and stay in
sync (this repeatedly bit the tmux/bashrc fixes). Symlinking `~/.bashrc → repo/.bashrc`
would make the repo the single source of truth. Caveat: the live `~/.bashrc` carries a
secret (`CONTEXT7_API_KEY`) that must NOT be committed — a symlink would expose it unless
the secret is sourced from a separate, git-ignored file (e.g. `~/.bashrc.local`). Recommended
combo: symlink dotfiles + move secrets to a sourced `~/.bashrc.local`.
**Status: not applied (skipped by user).**

---

## Applied in second cleanup pass (2026-07-10)
Recommendations 1, 2, 3, 4, 5, 7, 10 implemented in repo + live (synced):

- **#1** — removed unused `urlencode` / `urldecode` / `getip` from `.bashrc` (also eliminated
  the `printf "$c"` format-string bug).
- **#2** — removed `MANPAGER="less -X"` (alt-screen disable was harmful).
- **#3** — removed `alias less='less -N'` (line numbers in every less/git/man was noisy).
- **#4** — removed `[web] browser = google-chrome` from `.gitconfig` (no browser over SSH).
- **#5** — removed non-standard `username` key from `.gitconfig [user]`.
- **#7** — `install.sh` now installs `kitty.conf` → `~/.config/kitty/kitty.conf` (added a
  custom source:dest map + `install_file` helper; live copy also placed).
- **#10** — removed legacy `set t_Co=256` from `.vimrc` (modern vim autodetects; use
  `set termguicolors` if truecolor wanted).

Verified: `bash -n` on `.bashrc`/`install.sh` OK; `.gitconfig` valid; repo↔live diff = only
the live-only `CONTEXT7_API_KEY` block; install.sh tested against a throwaway `$HOME`
(kitty.conf lands at the right path).

---

## Not a problem (checked, leave as-is)
- File sizes are fine — `.bashrc` ~150 lines, `.tmux.conf` ~90. Not "huge".
- `.bash_profile` correctly sources `.bashrc` (standard).
- `.profile` duplicate-ish PATH logic is standard Debian skeleton; harmless.
- `.tmux.conf` — already cleaned during the OSC/DA leak fixes.
