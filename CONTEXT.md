# Context

## Objective
Reduce OpenCode context bloat from 154 Voltagent subagents by restricting the Task tool to built-in subagents only, and persist the restriction idempotently via `ai/install.sh`.

## Architecture
- **OpenCode config** (`~/.config/opencode/opencode.json`): `permission.task` block with `"*": "deny"` first, then `explore`/`general`/`scout`: `allow` (last-match-wins).
- **install.sh** (`ai/install.sh`): idempotent jq block inside the existing `if command -v jq` guard, after the Context7 block. Unconditionally writes the `permission.task` block (safe — same values every run).
- **Built-in primary agents** (build, plan): switched via Tab, not gated by `task` permission.
- **Built-in subagents** (explore, general, scout): explicitly allowed → auto-delegation intact.
- **Hidden system agents** (compaction, title, summary): `mode: primary`, not invoked via Task tool → unaffected.
- **Voltagent agents** (154 in `~/.config/opencode/agents/voltagent/`): denied from Task tool enum → removed from per-turn context. Manual `@mention` still works (task permissions don't block direct mentions).
- **Local agents** (`lexsecuritas-de.md`, `tech-markenstratege.md`): both `mode: primary` → unaffected.

## Work State
### Completed
- Context7 MCP added to install.sh (interactive key prompt, rc persistence, Claude + OpenCode registration). Committed `977b9eb`.
- `permission.task` block added to `~/.config/opencode/opencode.json`.
- Idempotent jq block added to `ai/install.sh` (after Context7 block).
- Verified idempotency: re-running install.sh leaves config unchanged.
- jq-not-found warning branch updated with manual instruction for `permission.task`.

### Verified
- Re-run of install.sh: config unchanged, "OpenCode task permissions set" logged.

## tmux OSC-leak fix (2026-07-10)
### Symptom
Garbage text like `rgb:1313/a1a1/0e0e` / `848;56564;13;rgb:b4b4/0000/9e9e` printed on
mouse tab-switch and on SSH reconnect+jump into the session.

### Root cause
Those strings are **OSC color-query responses** (OSC 4/10/11) and DA/DA2 replies. A program
inside tmux queries the terminal's colors; the reply normally gets consumed silently. On redraw
events (tab-switch, detach/reattach, reconnect) the reply arrives with no consumer and tmux
prints it as literal text. `~/.tmux.conf` had three aggravators:
- Line 18 `set -g extended-keys off` was **contradicted** by line 87 `set -s extended-keys on`
  (self-conflicting config; the bottom Claude Code block re-enabled what the top disabled).
- `set -g allow-passthrough on` let raw escape responses pass straight through tmux and echo on redraw.
- Nested tmux (`TERM_PROGRAM=tmux`) with mismatched inner/outer `TERM` (inner `tmux-256color`,
  outer `screen-256color`) routes color queries through two layers.

### Fix (user chose: prioritize killing the leak over passthrough features)
In **both** `dotfiles/.tmux.conf` (repo source of truth) and live `~/.tmux.conf`:
- Removed dead `set -g extended-keys off` (resolves the self-conflict).
- `allow-passthrough on` → **off** (primary leak source on redraw).
- `extended-keys on` → **off** (extended-key negotiation triggers CSI/DA replies that leak).
- Removed `set -as terminal-features 'xterm*:extkeys'` (moot once extended-keys off).
- Revised the comment block to explain the trade-off.
- Trade-off: loses tmux passthrough (image protocols, some Claude Code escape features).

### Verified
- `diff dotfiles/.tmux.conf ~/.tmux.conf` → IDENTICAL.
- `tmux source-file ~/.tmux.conf` reloaded OK; `allow-passthrough off`, `extended-keys off` confirmed via `show-options`.
- **NOTE:** install.sh (`dotfiles/install.sh:8`) `cp`s repo file → `~/.tmux.conf` (plain copy, not symlink), so both must be edited in sync.
- **Residual risk:** nested tmux — if garbage persists it's the outer tmux layer or a specific
  app's background-color query (would need per-app fix, e.g. neovim bg detection).

## tmux DA-reply leak on login (2026-07-10, follow-up)
### Symptom (DIFFERENT from the OSC/rgb leak above)
On device reboot → SSH login → auto-tmux, garbage printed ONCE at the first prompt:
`^[[?61;4;6;7;14;21;22;23;24;28;32;42;52c^[[>0;10;1c ... 61;4;...52c0;10;1c`

### Root cause
Those are **Device-Attributes replies** — DA1 (`^[[?...c`) and DA2 (`^[[>...c`), NOT color
queries. Chain:
- Client = **Windows OpenSSH** (Windows Terminal), which advertises `TERM=screen-256color`.
- `.bashrc` line 23 **hard-forced** `export TERM=screen-256color`, overriding it before tmux starts.
- `.bashrc` line ~133 auto-starts/attaches tmux `main` on login (`[ -z "$TMUX" ]` guard).
- `screen-*` terminfo makes tmux 3.6 send **DA1/DA2 queries** to the outer terminal on attach.
- Windows Terminal replies `?61;4;...c` / `>0;10;1c`; the reply lands **while bash is drawing the
  first prompt** → no consumer → leaks as literal text, exactly once per login.
- NOTE: there is **no local tmux process** on this box in the reboot case — `TMUX`/`TERM_PROGRAM=tmux`
  seen in the opencode shell are only because opencode itself runs inside tmux. Real SSH login has
  `TMUX` empty → auto-start fires.

### Fix (root cause, in BOTH `dotfiles/.bashrc` + live `~/.bashrc`)
1. **TERM** (line 22-24): replaced hard `export TERM=screen-256color` with — only when NOT in tmux —
   `export TERM=xterm-256color`. tmux itself sets `tmux-256color` inside a session (per .tmux.conf
   `default-terminal`). Kills the aggressive DA-query behaviour of `screen-*`.
2. **Drain guard** (auto-start tmux block): before attaching, drain pending terminal-query replies
   from stdin so late DA1/DA2 answers don't render:
   `if [ -t 0 ]; then while read -r -t 0.1 -n 256 _discard; do :; done; fi`

### Verified
- `bash -n` on both files OK.
- `diff dotfiles/.bashrc ~/.bashrc` → only difference is the live-only context7 API-key block (secret,
  intentionally NOT in repo).
- Drain-loop does not hang (returns instantly with empty stdin).
- TERM logic: outside tmux → `xterm-256color`; inside tmux → left untouched.
- **NOTE:** `dotfiles/install.sh` copies `.bashrc` → `~/` (plain copy), so both must stay in sync;
  the context7 secret block is appended to live `~/.bashrc` only.
- **User test pending:** log out fully + SSH back in → auto-tmux → confirm no `?61;...c` garbage.

## Relevant Files
- `/home/knorr/init/ai/install.sh` — install script; superpowers + context7 + permission.task blocks.
- `~/.config/opencode/opencode.json` — target config; now has `permission.task`.
- `~/.config/opencode/agents/voltagent/` — 154 Voltagent agent .md files (installed by install.sh).
- `~/.config/opencode/agents/local/` — user's 2 local primary agents.
- `/home/knorr/init/dotfiles/.tmux.conf` — repo source of truth for tmux config; OSC-leak fix applied.
- `~/.tmux.conf` — live copy (plain copy, not symlink); kept in sync with repo file.
- `/home/knorr/init/dotfiles/.bashrc` — repo source of truth for bashrc; TERM + drain-guard fix applied.
- `~/.bashrc` — live copy (plain copy); same fix + context7 secret block (live-only).
- `/home/knorr/init/dotfiles/install.sh` — copies dotfiles → `~/`; installs kitty.conf and
  the OSC-52 shim (as `~/.local/bin/{xclip,xsel}`).
- `/home/knorr/init/dotfiles/bin/osc52-clip` — OSC-52 clipboard shim (source of truth);
  installed as both `xclip` and `xsel` so OpenCode's Linux clipboard path reaches tmux→Windows.
- `~/.local/bin/xclip`, `~/.local/bin/xsel` — live copies of the shim (plain copies).

## OSC-52 clipboard fix (2026-07-10)
### Symptom
OpenCode TUI shows "copied to clipboard" when text is selected, but the copy is NOT
available via tmux `PREFIX+]` paste, and NOT in the host (Windows) clipboard. Copying
WITH tmux's own copy-mode works fine.

### Root cause (CORRECTED — first assumption was wrong)
**Initial (wrong) assumption:** "OpenCode copies via OSC 52, tmux drops it." Investigated
via `systematic-debugging`. The tmux side turned out NOT to be the cause.
**Actual root cause (verified against OpenCode docs + binary):** OpenCode on **Linux does
NOT emit OSC 52**. It shells out to an external clipboard tool — `wl-copy` if Wayland is
detected, else `xclip`, else `xsel` (see opencode.ai/docs/troubleshooting → "Copy/paste
not working on Linux"). On this box:
- `xclip`/`xsel`/`wl-copy` are **all missing**; `DISPLAY`/`WAYLAND_DISPLAY` are **unset**.
- OpenCode's copy therefore fails silently while the TUI still shows "copied to clipboard".
- tmux was never involved — a program spawn is not a terminal escape, so tmux has nothing
  to intercept. This is why "let tmux handle it" is not possible.
- Process chain (verified): Windows OpenSSH → tmux server (pts, xterm-256color) → bash →
  opencode. No nested tmux. Ubuntu (cloud VM from scripts/ec2.sh|hetzner.sh), not NixOS.

### Fix — two parts
**Part 1 (tmux, still valid & necessary):** in both `dotfiles/.tmux.conf` + `~/.tmux.conf`:
- `set -g set-clipboard on` — tmux stores OSC 52 into its buffer (PREFIX+] paste) AND
  forwards it to Windows Terminal via the `Ms` cap.
- `set -as terminal-features ',*:clipboard'` — forces OSC-52 forwarding even if the outer
  terminal doesn't advertise the cap.
- Unrelated to the `allow-passthrough off` leak fix — OSC 52 is handled natively by
  `set-clipboard`, NOT via passthrough (verified: passthrough off, escape still intercepted).

**Part 2 (the actual missing piece — OSC-52 shim):** repo `dotfiles/bin/osc52-clip`,
installed by `dotfiles/install.sh` as BOTH `~/.local/bin/xclip` and `~/.local/bin/xsel`.
It intercepts OpenCode's `xclip`/`xsel` call, base64-encodes stdin, and emits an
`ESC ] 52 ; c ; <b64> BEL` OSC-52 escape to the terminal. tmux (Part 1) then buffers it and
forwards to Windows. No X server, no root, no extra packages (uses `base64`/`printf`).
- `~/.local/bin` is already first in PATH (`dotfiles/.bashrc:117`) → shim beats any real xclip.
- Copy path (`-i`/default): emits OSC 52 to every plausible terminal fd (stdout-if-tty,
  /dev/tty, own tty) — idempotent, whichever reaches tmux wins.
- Paste path (`-o`/`-out`): returns empty immediately (no hang); OpenCode paste uses
  bracketed paste from the terminal, not this tool.
- Debug: `OSC52_SHIM_DEBUG=1` logs to `$TMPDIR/osc52-shim.log`.

### Verified
- `diff dotfiles/.tmux.conf ~/.tmux.conf` → IDENTICAL; `set-clipboard` → `on`;
  `terminal-features` contains `clipboard`.
- **Direct proof:** `printf '\033]52;c;<b64>\a' > <pane_tty>` → `tmux show-buffer` returns the
  decoded test string. tmux interception confirmed working with passthrough OFF.
- **Shim proof:** piping a string through `~/.local/bin/xclip -selection clipboard` with
  stdout pointed at the pane tty → `tmux show-buffer` shows the exact string. No warnings.
  `xclip -o` returns instantly (no hang).
- **install.sh:** tested against a throwaway `$HOME` → xclip+xsel land in `.local/bin`, both
  executable, content matches repo shim.
- **USER TEST STILL PENDING (the decisive one):** in a session where OpenCode's TUI actually
  spawns the shim — select text in OpenCode → confirm `PREFIX+]` pastes it AND it reaches the
  Windows clipboard. My tests prove the tmux chain + shim mechanics but NOT that OpenCode's
  TUI hands the child a terminal-connected fd. If it fails, run with `OSC52_SHIM_DEBUG=1` and
  inspect `/tmp/osc52-shim.log` to see which fds the shim saw.
- **Fallback:** if buffer fills (PREFIX+] works) but Windows clipboard stays empty → cause is
  Windows Terminal-side (OSC 52 disabled there), not tmux/shim.

## Merge-regression fixes (2026-07-11)
### Common root cause
A merge from another machine (`8213478 changes` → merge `3bd6d1f`) did NOT overwrite the
earlier tmux/bash fixes, but appended **duplicate / competing blocks** next to them. Two
regressions resulted.

### Regression 1 — `rgb:` colour-query leak came back on tab-switch
- **Symptom:** garbage like `dddd56616/c6c6/0c0cb4b4/0000/9e9e...` at the prompt when
  switching tmux tabs (same OSC colour-query leak class as before).
- **Cause:** the merge added a second, competing clipboard block to `.tmux.conf`:
  `set -as terminal-overrides ',*:Ms=\E]52;%p1%s;%p2%s\7'` — an `Ms` override for **all**
  terminal types (`*`). Combined with `focus-events on`, the redraw on tab-switch let
  OSC colour-query replies leak. Also a duplicate `set -s set-clipboard on` (line 6).
- **Fix:** removed the merged `FIXED CLIPBOARD CONFIG` block and the duplicate set-clipboard.
  Kept the clean, feature-based clipboard path already in place: `set -g set-clipboard on`
  + `set -as terminal-features ',*:clipboard'` (NOT an `Ms` override). Kept the harmless
  `MouseDragEnd1Pane … copy-selection-and-cancel` bindings. Live session reset
  (`set -gu terminal-overrides/terminal-features`) + reload → `*:Ms` gone, leak-fix intact
  (`allow-passthrough off`, `extended-keys off`).

### Regression 2 — slow `PREFIX+C` (new tmux window took 1–2 s to give a shell)
- **Cause:** the same merge duplicated two `.bashrc` blocks — **NVM was sourced twice**
  (eager `. nvm.sh` at both line 124 and line 157) plus a duplicated xdg-open block.
  Eager nvm.sh costs ~140 ms (it runs `node --version` etc.); doubled + overhead ≈ 300 ms
  per interactive shell, on every new pane.
- **Measured (evidence, not guess):** full `.bashrc` interactive start = ~300 ms; with a
  fake `$HOME` (no nvm, no `~/init/.git`) = 12 ms; removing the duplicate nvm block alone
  = −140 ms. `_check_init_updates` was NOT the cause (removing it changed nothing; its
  `git fetch` is backgrounded and rate-limited, `rev-list` is 2 ms).
- **Fix (both `dotfiles/.bashrc` + live `~/.bashrc`):**
  1. Removed the merge-duplicated nvm + xdg-open blocks (each now appears once).
  2. **Lazy-load NVM:** register stub functions for `node`/`npm`/`npx`/`nvm`; the first
     call sources real nvm (`_load_nvm`), unsets the stubs, and re-runs the command.
     Shells that never touch node pay nothing.
- **Verified:** interactive start **300 ms → 27 ms** (3 runs); `node --version` via the stub
  → `v26.5.0` (loads on demand); `bash -n` OK; repo↔live IDENTICAL (no secret block exists
  in either bashrc — the earlier "context7 secret block" note was inaccurate).

## Next Move
- Commit `ai/install.sh` change (config file is outside repo, not committed).
- Commit `dotfiles/.tmux.conf` + `dotfiles/.bashrc` + `CONTEXT.md` (tmux + login-leak fixes).
- User must restart opencode for the permission.task block to take effect.
- Test tmux OSC fix: tab-switch, detach/reattach, SSH reconnect+jump → confirm no `rgb:...` garbage.
- Test DA-reply fix: full logout + SSH re-login → auto-tmux → confirm no `?61;...c` garbage.
- Test OSC-52 clipboard fix: in a NEW tmux session, select text in OpenCode → confirm
  `PREFIX+]` pastes AND Windows clipboard has it. If it fails, `OSC52_SHIM_DEBUG=1` +
  check `/tmp/osc52-shim.log`.
- Commit `dotfiles/bin/osc52-clip` + `dotfiles/install.sh` (shim install) + `CONTEXT.md`.
