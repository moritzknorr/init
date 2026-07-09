#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VOLTAGENT_REPO="https://github.com/VoltAgent/awesome-claude-code-subagents.git"
VOLTAGENT_REF="main"               # pin to a tag/commit for reproducibility
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/voltagent-subagents"

CLAUDE_VOLT="$HOME/.claude/agents/voltagent"
OPENCODE_VOLT="$HOME/.config/opencode/agents/voltagent"

# OpenCode plugins to ensure are registered (obra/superpowers etc.)
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
SUPERPOWERS_PLUGIN="superpowers@git+https://github.com/obra/superpowers.git"

# Superpowers as a Claude Code plugin (obra/superpowers -> marketplace "superpowers-dev")
SUPERPOWERS_REPO="obra/superpowers"
SUPERPOWERS_MARKETPLACE="superpowers-dev"

# Context7 MCP server (Upstash-hosted remote). Requires a free API key from
# https://context7.com for higher rate limits. The key is passed as a custom
# "CONTEXT7_API_KEY" header (NOT a Bearer token) and OAuth auto-detection must
# be disabled to avoid OpenCode startup failures.
CONTEXT7_NAME="context7"
CONTEXT7_URL="https://mcp.context7.com/mcp"
CONTEXT7_API_KEY_ENV="CONTEXT7_API_KEY"

echo "Installing AI configurations..."

# --- Guards -----------------------------------------------------------------
command -v git >/dev/null 2>&1 || { echo "Error: git not found."; exit 1; }

# --- Context7 API key -------------------------------------------------------
# Prompt the user for a Context7 API key (optional but recommended). The key is
# persisted to ~/.bashrc and ~/.zshrc so any shell-launched OpenCode/Claude
# process has it in its environment, then exported for the rest of this script.
if [ -z "${!CONTEXT7_API_KEY_ENV:-}" ]; then
    echo
    echo "Context7 MCP uses an API key for higher rate limits."
    echo "Get a free key at https://context7.com (sign up -> API Keys)."
    printf "Paste your Context7 API key (blank to skip, anonymous tier): "
    read -r CONTEXT7_API_KEY
else
    CONTEXT7_API_KEY="${!CONTEXT7_API_KEY_ENV}"
fi

if [ -n "$CONTEXT7_API_KEY" ]; then
    export "$CONTEXT7_API_KEY_ENV"="$CONTEXT7_API_KEY"
    # Idempotently persist the export to shell rc files using marker blocks.
    persist_rc() {
        local rc="$1" marker="# >>> context7 api key >>>"
        [ -f "$rc" ] || return 0
        # Remove any previous marker block, then append fresh.
        if grep -q "$marker" "$rc"; then
            local tmp; tmp="$(mktemp)"
            awk -v m="$marker" '
                $0 ~ m { skip=1; next }
                skip && $0 ~ /^# <<< context7 api key <<</ { skip=0; next }
                !skip { print }
            ' "$rc" > "$tmp" && mv "$tmp" "$rc"
        fi
        {
            printf '\n%s\n' "$marker"
            printf 'export %s=%q\n' "$CONTEXT7_API_KEY_ENV" "$CONTEXT7_API_KEY"
            printf '%s\n' "# <<< context7 api key <<<"
        } >> "$rc"
    }
    persist_rc "$HOME/.bashrc"
    persist_rc "$HOME/.zshrc"
    echo "Context7 API key persisted to ~/.bashrc and ~/.zshrc"
    echo "  (restart your shell or run: source ~/.bashrc)"
else
    echo "No Context7 API key provided; using anonymous rate-limited tier."
fi

# --- Global instruction files ----------------------------------------------
# Claude Code reads ~/.claude/CLAUDE.md
mkdir -p ~/.claude/agents
cp "$DIR/AI.md" ~/.claude/CLAUDE.md
ln -sfn "$DIR/agents" ~/.claude/agents/local
ln -sfn "$DIR/commands" ~/.claude/commands

# Register the superpowers plugin for Claude Code (idempotent; re-runs are no-ops)
if command -v claude >/dev/null 2>&1; then
    claude plugin marketplace add "$SUPERPOWERS_REPO" >/dev/null 2>&1 || true
    claude plugin install "superpowers@$SUPERPOWERS_MARKETPLACE" --scope user >/dev/null 2>&1 || true
    echo "Claude Code superpowers plugin registered."
else
    echo "Warning: claude CLI not found; skipping Claude superpowers plugin."
fi

# Register Context7 MCP for Claude Code (idempotent; re-runs are no-ops).
# Claude's HTTP transport sends custom headers via --header "Key: Value".
if command -v claude >/dev/null 2>&1; then
    if [ -n "$CONTEXT7_API_KEY" ]; then
        claude mcp add "$CONTEXT7_NAME" --transport http "$CONTEXT7_URL" \
            --header "${CONTEXT7_API_KEY_ENV}: ${CONTEXT7_API_KEY}" \
            --scope user >/dev/null 2>&1 || true
    else
        claude mcp add "$CONTEXT7_NAME" --transport http "$CONTEXT7_URL" \
            --scope user >/dev/null 2>&1 || true
    fi
    echo "Claude Code Context7 MCP registered."
else
    echo "Warning: claude CLI not found; skipping Claude Context7 MCP."
fi

# OpenCode reads ~/.config/opencode/AGENTS.md
mkdir -p ~/.config/opencode/agents
cp "$DIR/AI.md" ~/.config/opencode/AGENTS.md
ln -sfn "$DIR/agents" ~/.config/opencode/agents/local

# Register the superpowers plugin in OpenCode config (idempotent, preserves
# existing plugins/MCP/secrets). Requires jq.
if command -v jq >/dev/null 2>&1; then
    if [ ! -f "$OPENCODE_CONFIG" ]; then
        printf '{\n  "$schema": "https://opencode.ai/config.json"\n}\n' > "$OPENCODE_CONFIG"
    fi
    tmp="$(mktemp)"
    jq --arg p "$SUPERPOWERS_PLUGIN" '
        .plugin = (.plugin // [])
        | if (.plugin | index($p)) then . else .plugin += [$p] end
    ' "$OPENCODE_CONFIG" > "$tmp" && mv "$tmp" "$OPENCODE_CONFIG"
    echo "OpenCode superpowers plugin registered."

    # Register Context7 MCP in OpenCode config (idempotent).
    # type must be "remote" (not "http"); oauth:false disables OpenCode's
    # auto-OAuth discovery so an API-key server starts cleanly. The key is
    # passed as a custom CONTEXT7_API_KEY header using {env:VAR} substitution,
    # which OpenCode resolves from the launching process environment.
    tmp="$(mktemp)"
    if [ -n "$CONTEXT7_API_KEY" ]; then
        jq --arg name "$CONTEXT7_NAME" --arg url "$CONTEXT7_URL" --arg env "$CONTEXT7_API_KEY_ENV" '
            .mcp = (.mcp // {})
            | .mcp[$name] = {
                "type": "remote",
                "url": $url,
                "oauth": false,
                "headers": { ($env): ("{env:" + $env + "}") }
            }
        ' "$OPENCODE_CONFIG" > "$tmp" && mv "$tmp" "$OPENCODE_CONFIG"
    else
        jq --arg name "$CONTEXT7_NAME" --arg url "$CONTEXT7_URL" '
            .mcp = (.mcp // {})
            | .mcp[$name] = {"type": "remote", "url": $url, "oauth": false}
        ' "$OPENCODE_CONFIG" > "$tmp" && mv "$tmp" "$OPENCODE_CONFIG"
    fi
    echo "OpenCode Context7 MCP registered."
else
    echo "Warning: jq not found; skipping superpowers plugin registration."
    echo "  Add manually to $OPENCODE_CONFIG plugin array: $SUPERPOWERS_PLUGIN"
    echo "  Add manually to $OPENCODE_CONFIG mcp.$CONTEXT7_NAME (type=remote, oauth=false, url=$CONTEXT7_URL)"
fi

# Gemini CLI reads ~/.gemini/GEMINI.md
mkdir -p ~/.gemini
cp "$DIR/AI.md" ~/.gemini/GEMINI.md

# --- Fetch Voltagent subagents (cached) -------------------------------------
echo "Fetching Voltagent agents from GitHub..."
if [ -d "$CACHE_DIR/.git" ]; then
    git -C "$CACHE_DIR" fetch --depth 1 origin "$VOLTAGENT_REF" >/dev/null 2>&1
    git -C "$CACHE_DIR" reset --hard FETCH_HEAD >/dev/null 2>&1
else
    rm -rf "$CACHE_DIR"
    git clone --depth 1 --branch "$VOLTAGENT_REF" "$VOLTAGENT_REPO" "$CACHE_DIR" >/dev/null 2>&1
fi

if [ ! -d "$CACHE_DIR/categories" ]; then
    echo "Warning: Voltagent repo fetched but 'categories/' missing. Skipping agents."
    echo "AI configs installed (without Voltagent agents)."
    exit 0
fi

# install_voltagent <dest_dir> <patch_mode:0|1>
# Copies all category agents into dest_dir. When patch_mode=1, ensures each
# file has "mode: subagent" frontmatter (subagent-only, not primary) and drops
# Claude-only frontmatter keys that fail OpenCode's schema.
install_voltagent() {
    local dest="$1" patch_mode="$2" file name

    rm -rf "$dest"          # purge stale agents removed upstream
    mkdir -p "$dest"

    while IFS= read -r -d '' file; do
        name="$(basename "$file")"
        cp "$file" "$dest/$name"

        # OpenCode: add "mode: subagent", and drop Claude-only frontmatter keys
        # ("tools:" string and unprefixed "model:") that fail OpenCode's schema.
        if [ "$patch_mode" = "1" ] && grep -q "^---" "$dest/$name"; then
            awk '
            BEGIN { fm=0; done=0 }
            /^---$/ {
                if (!fm && !done) { fm=1; print; next }
                if (fm && !done)  { print "mode: subagent"; fm=0; done=1; print; next }
            }
            fm && /^(tools|model):/ { next }
            { print }
            ' "$dest/$name" > "$dest/$name.tmp" && mv "$dest/$name.tmp" "$dest/$name"
        fi
    done < <(find "$CACHE_DIR/categories" -type f -name "*.md" \
                ! -name "README.md" ! -name "CLAUDE.md" -print0)
}

echo "Installing Voltagent agents..."
install_voltagent "$CLAUDE_VOLT" 0
install_voltagent "$OPENCODE_VOLT" 1

count="$(find "$OPENCODE_VOLT" -type f -name "*.md" | wc -l | tr -d ' ')"
echo "Voltagent agents installed ($count agents)."

echo "AI configs installed."