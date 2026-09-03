#!/usr/bin/env bash
# init.sh — One-Time Setup & Baseline Verification Tool
#
# RUN THIS ONCE when creating a new project from this template:
#   ./init.sh [project_name]
#
# After initial setup, you NEVER need to run this script again.
# Your AI agents (Leader, Implementer, Reviewer, Security Reviewer)
# handle all verification and test execution autonomously.
#
set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    local description="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $description"
        ((PASS++)) || true
    else
        echo -e "  ${RED}✗${NC} $description"
        ((FAIL++)) || true
    fi
}

file_exists() { [ -f "$1" ]; }
dir_exists() { [ -d "$1" ]; }

PROJECT_NAME="${1:-}"

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Agent Harness — One-Time Project Setup & Bootstrap     ${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo ""

# ── 1. Clean Git History & Initialize Fresh Repo ────────
if [ -d ".git" ]; then
    # Check if this is the original template repository
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ -n "$REMOTE_URL" || -n "$PROJECT_NAME" ]]; then
        echo -e "${BLUE}▸ Detaching template git history...${NC}"
        rm -rf .git
        git init -b main > /dev/null 2>&1 || git init > /dev/null 2>&1
        echo -e "  ${GREEN}✓${NC} Initialized fresh, clean Git repository (branch: main)"
    fi
else
    git init -b main > /dev/null 2>&1 || git init > /dev/null 2>&1
    echo -e "  ${GREEN}✓${NC} Initialized fresh Git repository (branch: main)"
fi

# ── 2. Reset Active Progress Files ──────────────────────
if file_exists "progress/current.md"; then
    cat << 'EOF' > progress/current.md
# Active Session

## Task
- **Slug:** None active
- **Agent:** None

## Plan
Tell your AI what you want to build. The Leader will break it down into TASKS.md.

## Log
| Time | Action | Result |
|------|--------|--------|

## Next Step
Awaiting user request.
EOF
    echo -e "  ${GREEN}✓${NC} Reset progress/current.md"
fi

if file_exists "progress/history.md"; then
    cat << 'EOF' > progress/history.md
# Session History

> Append-only audit log of completed agent tasks.

---

EOF
    echo -e "  ${GREEN}✓${NC} Reset progress/history.md"
fi

# ── 3. Install Automated Pre-Commit Safety Hook ──────────
if [ -d ".git" ]; then
    mkdir -p .git/hooks
    cat << 'HOOK_EOF' > .git/hooks/pre-commit
#!/usr/bin/env bash
# Automated Git Safety Gate — Pre-commit hook
PATTERNS='password\s*=\s*["\x27][^"\x27]+["\x27]|api_key\s*=\s*["\x27]|secret\s*=\s*["\x27]|token\s*=\s*["\x27]|Bearer\s+[A-Za-z0-9_\-\.]{20,}|PRIVATE_KEY|-----BEGIN'
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null | grep -E '\.(py|js|ts|jsx|tsx|go|rs|env|json|yaml|yml)$' | grep -v 'TASKS\.md' || true)

if [ -n "$STAGED_FILES" ]; then
    FOUND=$(git diff --cached -S"*" -- $STAGED_FILES 2>/dev/null | grep -E "$PATTERNS" || true)
    if [ -n "$FOUND" ]; then
        echo -e "\033[0;31m[SECURITY GATE BLOCKED] Potential hardcoded secret detected in staged changes:\033[0m"
        echo "$FOUND" | head -5
        echo -e "\033[0;33mPlease use environment variables or remove sensitive data before committing.\033[0m"
        exit 1
    fi
fi
HOOK_EOF
    chmod +x .git/hooks/pre-commit
    echo -e "  ${GREEN}✓${NC} Installed pre-commit git security hook (blocks secret leaks automatically)"
fi

echo ""
echo -e "${BOLD}▸ Validating Harness Integrity...${NC}"

# Core files
check "AGENTS.md exists" file_exists "AGENTS.md"
check "TASKS.md exists" file_exists "TASKS.md"
check "CHECKPOINTS.md exists" file_exists "CHECKPOINTS.md"
check "progress/current.md exists" file_exists "progress/current.md"
check "progress/history.md exists" file_exists "progress/history.md"
check "docs/architecture.md exists" file_exists "docs/architecture.md"
check "docs/conventions.md exists" file_exists "docs/conventions.md"
check "docs/security.md exists" file_exists "docs/security.md"
check "docs/verification.md exists" file_exists "docs/verification.md"

# Agents
check "agents/leader.md exists" file_exists "agents/leader.md"
check "agents/implementer.md exists" file_exists "agents/implementer.md"
check "agents/reviewer.md exists" file_exists "agents/reviewer.md"
check "agents/security-reviewer.md exists" file_exists "agents/security-reviewer.md"

# Universal Tool Adapters
check ".cursorrules exists (Cursor)" file_exists ".cursorrules"
check ".windsurfrules exists (Windsurf)" file_exists ".windsurfrules"
check ".github/copilot-instructions.md exists (GitHub Copilot)" file_exists ".github/copilot-instructions.md"
check "CLAUDE.md exists (Claude Code)" file_exists "CLAUDE.md"
check ".gitignore exists" file_exists ".gitignore"

echo ""

# ── 4. Initial Baseline Git Commit ──────────────────────
if [ -d ".git" ]; then
    git add . > /dev/null 2>&1
    git commit -m "chore: initial project baseline from agent harness" > /dev/null 2>&1 || true
    echo -e "  ${GREEN}✓${NC} Created initial git baseline commit"
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
if [ $FAIL -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✓ HARNESS READY AND ROCK SOLID!${NC}"
    echo ""
    echo -e "  ${BOLD}You are done with setup.${NC}"
    echo -e "  You do ${YELLOW}NOT${NC} need to run init.sh again."
    echo ""
    echo -e "  ${BLUE}Next Step:${NC}"
    echo -e "  Open your tool (Antigravity, Cursor, Copilot, Windsurf, Claude Code)"
    echo -e "  and describe what you want to build. Your agents will handle the rest."
else
    echo -e "  ${RED}${BOLD}✗ Setup encountered $FAIL issue(s). Please review above.${NC}"
fi
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo ""

exit $FAIL
