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
- `/home/knorr/init/dotfiles/install.sh` — copies `.tmux.conf` and `.bashrc` → `~/`.

## OSC-52 clipboard fix (2026-07-10)
### Symptom
OpenCode TUI shows "copied to clipboard" when text is selected, but the copy is NOT
available via tmux `PREFIX+]` paste, and NOT in the host (Windows) clipboard. Copying
WITH tmux's own copy-mode works fine.

### Root cause
OpenCode copies via **OSC 52** (terminal "set system clipboard" escape). tmux dropped it:
- `set-clipboard` was left at default (leer) — not explicitly `on`.
- No explicit `terminal-features ':clipboard'` declared, so tmux would only forward OSC 52
  if the outer terminal advertised the `Ms` capability itself.
- The current session was running as `TERM=screen-256color` (inherited/started before the
  conf took effect); `screen-256color` terminfo has **no `Ms`** → tmux ignores OSC 52 for
  the outer channel. `tmux-256color` (the configured `default-terminal`) DOES have `Ms`.
- NOTE: **unrelated** to the earlier `allow-passthrough off` leak fix — OSC 52 is handled
  natively via `set-clipboard`+`Ms`, not passthrough. No conflict; leak fix stays intact.

### Fix (both `dotfiles/.tmux.conf` + live `~/.tmux.conf`, near the terminal block ~L15-17)
- `set -g set-clipboard on` — stores OSC 52 into the tmux buffer (PREFIX+] works) AND forwards
  it out to Windows Terminal via `Ms`.
- `set -as terminal-features ',*:clipboard'` — forces OSC-52 forwarding even if the outer
  terminal doesn't advertise the capability.

### Verified
- `diff dotfiles/.tmux.conf ~/.tmux.conf` → IDENTICAL.
- `tmux source-file ~/.tmux.conf` → OK; `show-options -g set-clipboard` → `on`;
  `terminal-features` now contains `clipboard`.
- **User test pending:** in a NEW tmux session (so `TERM=tmux-256color` with `Ms` applies —
  a running `screen-256color` session won't pick it up retroactively): select text in
  OpenCode → confirm `PREFIX+]` pastes it AND it lands in the Windows clipboard.
- **Fallback:** if Windows clipboard stays empty but `PREFIX+]` works → cause is Windows
  Terminal-side (OSC 52 disabled there), not tmux.

## Next Move
- Commit `ai/install.sh` change (config file is outside repo, not committed).
- Commit `dotfiles/.tmux.conf` + `dotfiles/.bashrc` + `CONTEXT.md` (tmux + login-leak fixes).
- User must restart opencode for the permission.task block to take effect.
- Test tmux OSC fix: tab-switch, detach/reattach, SSH reconnect+jump → confirm no `rgb:...` garbage.
- Test DA-reply fix: full logout + SSH re-login → auto-tmux → confirm no `?61;...c` garbage.
- Test OSC-52 clipboard fix: in a NEW tmux session, select text in OpenCode → confirm
  `PREFIX+]` pastes AND Windows clipboard has it.
