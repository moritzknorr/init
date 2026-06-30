#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VOLTAGENT_REPO="https://github.com/VoltAgent/awesome-claude-code-subagents.git"
VOLTAGENT_REF="main"               # pin to a tag/commit for reproducibility
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/voltagent-subagents"

CLAUDE_VOLT="$HOME/.claude/agents/voltagent"
OPENCODE_VOLT="$HOME/.config/opencode/agents/voltagent"

echo "Installing AI configurations..."

# --- Guards -----------------------------------------------------------------
command -v git >/dev/null 2>&1 || { echo "Error: git not found."; exit 1; }

# --- Global instruction files ----------------------------------------------
# Claude Code reads ~/.claude/CLAUDE.md
mkdir -p ~/.claude/agents
cp "$DIR/AI.md" ~/.claude/CLAUDE.md
ln -sfn "$DIR/agents" ~/.claude/agents/local
ln -sfn "$DIR/commands" ~/.claude/commands

# OpenCode reads ~/.config/opencode/AGENTS.md
mkdir -p ~/.config/opencode/agents
cp "$DIR/AI.md" ~/.config/opencode/AGENTS.md
ln -sfn "$DIR/agents" ~/.config/opencode/agents/local

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
# file has "mode: all" frontmatter so OpenCode lists it as a primary agent.
install_voltagent() {
    local dest="$1" patch_mode="$2" file name

    rm -rf "$dest"          # purge stale agents removed upstream
    mkdir -p "$dest"

    while IFS= read -r -d '' file; do
        name="$(basename "$file")"
        cp "$file" "$dest/$name"

        # OpenCode: add "mode: all", and drop Claude-only frontmatter keys
        # ("tools:" string and unprefixed "model:") that fail OpenCode's schema.
        if [ "$patch_mode" = "1" ] && grep -q "^---" "$dest/$name"; then
            awk '
            BEGIN { fm=0; done=0 }
            /^---$/ {
                if (!fm && !done) { fm=1; print; next }
                if (fm && !done)  { print "mode: all"; fm=0; done=1; print; next }
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