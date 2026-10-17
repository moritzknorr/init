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

# Google Workspace remote MCP servers (8 endpoints sharing one OAuth 2.0 client).
GW_CLIENT_ID_ENV="GOOGLE_WORKSPACE_CLIENT_ID"
GW_CLIENT_SECRET_ENV="GOOGLE_WORKSPACE_CLIENT_SECRET"
GW_SCOPES="https://www.googleapis.com/auth/gmail.readonly https://www.googleapis.com/auth/gmail.compose https://www.googleapis.com/auth/drive.readonly https://www.googleapis.com/auth/drive.file https://www.googleapis.com/auth/documents.readonly https://www.googleapis.com/auth/documents https://www.googleapis.com/auth/spreadsheets.readonly https://www.googleapis.com/auth/spreadsheets https://www.googleapis.com/auth/presentations.readonly https://www.googleapis.com/auth/presentations https://www.googleapis.com/auth/calendar.calendarlist.readonly https://www.googleapis.com/auth/calendar.events.freebusy https://www.googleapis.com/auth/calendar.events.readonly https://www.googleapis.com/auth/chat.spaces.readonly https://www.googleapis.com/auth/chat.memberships.readonly https://www.googleapis.com/auth/chat.messages.readonly https://www.googleapis.com/auth/chat.messages.create https://www.googleapis.com/auth/chat.users.readstate https://www.googleapis.com/auth/directory.readonly https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/contacts.readonly"

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
    read -r CONTEXT7_API_KEY || true
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

# --- Google Workspace MCP OAuth credentials ---------------------------------
GW_CLIENT_ID="${!GW_CLIENT_ID_ENV:-}"
GW_CLIENT_SECRET="${!GW_CLIENT_SECRET_ENV:-}"
if [ -z "$GW_CLIENT_ID" ] || [ -z "$GW_CLIENT_SECRET" ]; then
    gw_secret_file="$(find "$DIR/.." "$DIR" -maxdepth 1 -name 'client_secret_*.json' 2>/dev/null | head -n 1 || true)"
    if [ -n "$gw_secret_file" ] && command -v jq >/dev/null 2>&1; then
        GW_CLIENT_ID="$(jq -r '(.installed // .web).client_id // empty' "$gw_secret_file")"
        GW_CLIENT_SECRET="$(jq -r '(.installed // .web).client_secret // empty' "$gw_secret_file")"
    fi
fi
if [ -z "$GW_CLIENT_ID" ] || [ -z "$GW_CLIENT_SECRET" ]; then
    echo
    printf "Paste Google Workspace OAuth Client ID (blank to skip): "
    read -r GW_CLIENT_ID || true
    if [ -n "$GW_CLIENT_ID" ]; then
        printf "Paste Google Workspace OAuth Client Secret: "
        read -r GW_CLIENT_SECRET || true
    fi
fi

if [ -n "$GW_CLIENT_ID" ] && [ -n "$GW_CLIENT_SECRET" ]; then
    export "$GW_CLIENT_ID_ENV"="$GW_CLIENT_ID"
    export "$GW_CLIENT_SECRET_ENV"="$GW_CLIENT_SECRET"
    persist_gw_rc() {
        local rc="$1" marker="# >>> google workspace mcp >>>"
        [ -f "$rc" ] || return 0
        if grep -q "$marker" "$rc"; then
            local tmp; tmp="$(mktemp)"
            awk -v m="$marker" '
                $0 ~ m { skip=1; next }
                skip && $0 ~ /^# <<< google workspace mcp <<</ { skip=0; next }
                !skip { print }
            ' "$rc" > "$tmp" && mv "$tmp" "$rc"
        fi
        {
            printf '\n%s\n' "$marker"
            printf 'export %s=%q\n' "$GW_CLIENT_ID_ENV" "$GW_CLIENT_ID"
            printf 'export %s=%q\n' "$GW_CLIENT_SECRET_ENV" "$GW_CLIENT_SECRET"
            printf '%s\n' "# <<< google workspace mcp <<<"
        } >> "$rc"
    }
    persist_gw_rc "$HOME/.bashrc"
    persist_gw_rc "$HOME/.zshrc"
    echo "Google Workspace OAuth credentials persisted to ~/.bashrc and ~/.zshrc"
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

# Install the OpenCode global config from the declarative template in this repo.
# Secrets are NOT inlined here — they live in shell rc files and are pulled in
# via OpenCode's {env:VAR} substitution (see context7 headers). A plain copy is
# intentional: the template is the source of truth, clobbering any local drift.
cp "$DIR/opencode.json" "$OPENCODE_CONFIG"
echo "OpenCode config installed from template ($DIR/opencode.json)."

# Google Workspace MCP endpoints return 200 on initialize/tools/list and only
# challenge with 401 on tools/call, so `opencode mcp auth` skips the browser flow.
# Seed all 8 endpoints in ~/.local/share/opencode/mcp-auth.json from one OAuth code.
MCP_AUTH_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/opencode/mcp-auth.json"
if [ -n "${GW_CLIENT_ID:-}" ] && [ -n "${GW_CLIENT_SECRET:-}" ] && [ -t 0 ] && command -v jq >/dev/null 2>&1; then
    has_gw_token=""
    if [ -f "$MCP_AUTH_FILE" ]; then
        has_gw_token="$(jq -r '.gmail.tokens.refreshToken // empty' "$MCP_AUTH_FILE" 2>/dev/null || true)"
    fi
    if [ -z "$has_gw_token" ]; then
        gw_auth_url="https://accounts.google.com/o/oauth2/v2/auth?client_id=${GW_CLIENT_ID}&redirect_uri=http%3A%2F%2Flocalhost&response_type=code&access_type=offline&prompt=consent&scope=${GW_SCOPES// /+}"
        echo
        echo "Google Workspace MCP (one-time OAuth for all 8 services):"
        echo "  1. Open in browser: $gw_auth_url"
        echo "  2. Sign in & approve; browser will redirect to http://localhost/?code=..."
        printf "  3. Paste the full redirect URL (or code) here (blank to skip): "
        read -r gw_input
        if [ -n "$gw_input" ]; then
            gw_code="$(python3 -c 'import sys, urllib.parse as u; s=sys.argv[1].strip(); q=u.parse_qs(u.urlparse(s).query); print(q["code"][0] if "code" in q else u.unquote(s))' "$gw_input")"
            gw_resp="$(curl -sS -X POST "https://oauth2.googleapis.com/token" \
                --data-urlencode "code=$gw_code" \
                --data-urlencode "client_id=$GW_CLIENT_ID" \
                --data-urlencode "client_secret=$GW_CLIENT_SECRET" \
                --data-urlencode "redirect_uri=http://localhost" \
                --data-urlencode "grant_type=authorization_code")"
            if echo "$gw_resp" | jq -e '.access_token' >/dev/null 2>&1; then
                mkdir -p "$(dirname "$MCP_AUTH_FILE")"
                [ -f "$MCP_AUTH_FILE" ] || echo "{}" > "$MCP_AUTH_FILE"
                now_ts="$(date +%s)"
                tmp_auth="$(mktemp)"
                jq --argjson resp "$gw_resp" --argjson now "$now_ts" \
                   --arg cid "$GW_CLIENT_ID" --arg csec "$GW_CLIENT_SECRET" '
                    ($resp.access_token) as $at |
                    ($resp.refresh_token // .gmail.tokens.refreshToken) as $rt |
                    ($now + ($resp.expires_in // 3600)) as $exp |
                    ($resp.scope // "") as $sc |
                    {
                        gmail:    "https://gmailmcp.googleapis.com/mcp/v1",
                        drive:    "https://drivemcp.googleapis.com/mcp/v1",
                        docs:     "https://docsmcp.googleapis.com/mcp/v1",
                        sheets:   "https://sheetsmcp.googleapis.com/mcp/v1",
                        slides:   "https://slidesmcp.googleapis.com/mcp/v1",
                        calendar: "https://calendarmcp.googleapis.com/mcp/v1",
                        chat:     "https://chatmcp.googleapis.com/mcp/v1",
                        people:   "https://people.googleapis.com/mcp/v1"
                    } as $servers |
                    reduce ($servers | keys_unsorted[]) as $k (.;
                        .[$k] = {
                            tokens: {
                                accessToken: $at,
                                refreshToken: $rt,
                                expiresAt: $exp,
                                scope: $sc
                            },
                            clientInfo: {
                                clientId: $cid,
                                clientSecret: $csec
                            },
                            serverUrl: $servers[$k]
                        }
                    )
                ' "$MCP_AUTH_FILE" > "$tmp_auth" && chmod 600 "$tmp_auth" && mv "$tmp_auth" "$MCP_AUTH_FILE"
                echo "Google Workspace MCP tokens stored for all 8 services."
            else
                echo "Warning: Google OAuth token exchange failed: $gw_resp"
            fi
        fi
    fi
fi

# OpenCode v2 stores MCP OAuth credentials in its credential store (via `opencode auth import`)
# rather than reading legacy mcp-auth.json. Sync any tokens in mcp-auth.json into OpenCode v2.
if [ -f "$MCP_AUTH_FILE" ] && command -v opencode >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    python3 - "$MCP_AUTH_FILE" <<'PY' >/dev/null 2>&1 || true
import hashlib, json, subprocess, sys

with open(sys.argv[1]) as f:
    mcp_auth = json.load(f)

existing = subprocess.run(["opencode", "auth", "export"], text=True, capture_output=True)
by_integ = {
    item["integrationID"]: item["id"]
    for item in (json.loads(existing.stdout) if existing.returncode == 0 and existing.stdout.strip() else [])
    if "integrationID" in item and "id" in item
}

items = []
for name, entry in mcp_auth.items():
    url = entry.get("serverUrl", "")
    tokens = entry.get("tokens", {})
    client = entry.get("clientInfo", {})
    if not url or not tokens.get("accessToken"):
        continue
    integ_id = "mcp_" + hashlib.sha1(f"{name}\x00{url}".encode()).hexdigest()[:16]
    if integ_id in by_integ:
        continue
    exp = tokens.get("expiresAt", 0)
    exp_ms = int(exp * 1000) if exp < 1e11 else int(exp)
    meta = {"serverUrl": url, "tokenType": "Bearer"}
    if tokens.get("scope"):
        meta["scope"] = tokens["scope"]
    if client.get("clientId"):
        meta["client"] = {
            "client_id": client["clientId"],
            **({"client_secret": client["clientSecret"]} if client.get("clientSecret") else {}),
        }
    items.append({
        "id": "cred_" + hashlib.sha1(integ_id.encode()).hexdigest()[:24],
        "integrationID": integ_id,
        "label": name,
        "active": True,
        "value": {
            "type": "oauth",
            "methodID": integ_id,
            "access": tokens["accessToken"],
            "refresh": tokens.get("refreshToken", ""),
            "expires": exp_ms,
            "metadata": meta,
        },
    })

if items:
    subprocess.run(["opencode", "auth", "import"], input=json.dumps(items), text=True, check=False)
PY
fi

# Superpowers normally requires a skill whenever there is even a 1% chance
# it applies. Raise that threshold to avoid process overhead for routine work.
# (Patches the cached skill file, not opencode.json — independent of the copy.)
if command -v jq >/dev/null 2>&1; then
    superpowers_patches=0
    while IFS= read -r -d '' skill; do
        if grep -q 'even a 1% chance' "$skill"; then
            sed -i 's/even a 1% chance/even a 10% chance/' "$skill"
            superpowers_patches=$((superpowers_patches + 1))
        fi
    done < <(find "${XDG_CACHE_HOME:-$HOME/.cache}/opencode" \
        -path '*/node_modules/superpowers/skills/using-superpowers/SKILL.md' -print0 2>/dev/null)
    if [ "$superpowers_patches" -gt 0 ]; then
        echo "OpenCode superpowers skill threshold set to 10%."
    fi
else
    echo "Warning: jq not found; skipping superpowers skill threshold patch."
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
