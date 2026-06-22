#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Claude Code
cp "$DIR/AI.md" ~/.claude.md
mkdir -p ~/.claude
ln -sf "$DIR/agents"   ~/.claude/agents
ln -sf "$DIR/commands" ~/.claude/commands

# OpenCode
mkdir -p ~/.config/opencode
cp "$DIR/AI.md" ~/.config/opencode/AGENTS.md

# GeminiCLI
cp "$DIR/AI.md" ~/.gemini.md

echo "AI configs installed."