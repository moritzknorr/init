# AI

Shared AI agent configuration deployed across **Claude Code**, **OpenCode**, and **Gemini CLI** from a single source of truth.

## What it does

`install.sh` performs two jobs:

1. **Global instructions** — copies `AI.md` to each tool's global instruction file.
2. **Custom agents** — symlinks this repo's `agents/` into each tool, and downloads the
   [VoltAgent](https://github.com/VoltAgent/awesome-claude-code-subagents) subagent collection
   into the tools' system directories (kept out of this repo).
3. **Plugins** — registers the [superpowers](https://github.com/obra/superpowers) plugin
   for both **OpenCode** (via `opencode.json`) and **Claude Code** (via the `claude` CLI).
   Idempotent; existing plugins/MCP/secrets preserved.

## Usage

```bash
ai/install.sh
```

Re-run any time to refresh the VoltAgent agents. The script is idempotent.

## Layout

```
ai/
├── AI.md          Global instructions (persona, workflow, guardrails)
├── agents/        Your own custom agents (committed)
├── commands/      Custom slash commands (committed)
└── install.sh     Deploys everything
```

## Install targets

| Tool        | Global instructions          | Local agents (symlink)                | VoltAgent agents (downloaded)         |
| ----------- | ---------------------------- | ------------------------------------- | ------------------------------------- |
| Claude Code | `~/.claude/CLAUDE.md`        | `~/.claude/agents/local`              | `~/.claude/agents/voltagent`          |
| OpenCode    | `~/.config/opencode/AGENTS.md` | `~/.config/opencode/agents/local`   | `~/.config/opencode/agents/voltagent` |
| Gemini CLI  | `~/.gemini/GEMINI.md`        | —                                     | —                                     |

VoltAgent agents are **not** committed to this repo. They are cached in
`~/.cache/voltagent-subagents` and copied into each tool's system directory on install.
For OpenCode the script normalises their frontmatter (`mode: all`, and drops the Claude-only
`tools:`/`model:` keys that fail OpenCode's schema).

## Custom agents

Drop a markdown file in `agents/` to add your own agent. Frontmatter for OpenCode:

```markdown
---
description: One line on what this agent does.
mode: primary        # primary = selectable in the UI; subagent = spawned by others
---

System prompt goes here.
```

It becomes available in all tools after the next `install.sh` run.

## Switching agents

- **OpenCode (TUI):** `/agent <name>` — e.g. `/agent tech-markenstratege`
- **OpenCode (Web):** agent dropdown (only `mode: primary`/`all` agents appear)
- **Claude Code:** referenced via the `agents/` directory
- **Gemini CLI:** `gemini --system-prompt ~/.gemini/agents/<name>.md` (or shell alias)

## Pinning VoltAgent

The collection tracks `main` by default. For reproducible installs, set `VOLTAGENT_REF`
in `install.sh` to a tag or commit SHA.

## OpenCode plugins

`install.sh` adds the [superpowers](https://github.com/obra/superpowers) plugin to
`~/.config/opencode/opencode.json`. The merge is done with `jq` and is idempotent — your
existing plugins, MCP servers, and API keys are left untouched. If `jq` is missing, the
script prints the entry to add manually. Restart OpenCode after install to load the plugin.

## Claude Code plugins

`install.sh` also installs [superpowers](https://github.com/obra/superpowers) for Claude
Code via the `claude` CLI:

```bash
claude plugin marketplace add obra/superpowers
claude plugin install superpowers@superpowers-dev --scope user
```

Both commands are idempotent (re-runs are no-ops). Requires the `claude` CLI on `PATH`;
if absent, the step is skipped with a warning. Restart Claude Code to load the skills.
