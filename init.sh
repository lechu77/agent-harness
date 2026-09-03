#!/usr/bin/env bash
# init.sh — Agent Harness Setup & Verification Tool
#
# RUN THIS ONCE when adding or bootstrapping the harness:
#   ./init.sh                   Smart setup (preserves existing git; cleans ONLY if agent-harness template)
#   ./init.sh [project_name]    Bootstrap new project from template
#   ./init.sh --clean-git       Force detach and reinitialize git
#   ./init.sh --keep-git        Force preserve existing git repo
#   ./init.sh --help            Show usage
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

FORCE_CLEAN=false
FORCE_KEEP=false
PROJECT_NAME=""

for arg in "$@"; do
    case "$arg" in
        --clean-git) FORCE_CLEAN=true ;;
        --keep-git) FORCE_KEEP=true ;;
        --help|-h)
            echo -e "${BOLD}Agent Harness — CLI Reference${NC}"
            echo ""
            echo "Usage:"
            echo "  ./init.sh                     Run smart setup / health check"
            echo "  ./init.sh [project_name]      Bootstrap a new project from template"
            echo "  ./init.sh --clean-git         Force detach and reinitialize git repository"
            echo "  ./init.sh --keep-git          Force preserve existing git repository"
            echo "  ./init.sh --help              Show this screen"
            echo ""
            exit 0
            ;;
        *)
            if [[ -z "$PROJECT_NAME" && "$arg" != -* ]]; then
                PROJECT_NAME="$arg"
            fi
            ;;
    esac
done

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Agent Harness — Setup & Environment Verification       ${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo ""

# ── 1. Smart Git Detection & Preservation ───────────────
REMOTE_URL=$(git remote get-url origin 2>/dev/null || git config --get remote.origin.url 2>/dev/null || echo "")

IS_TEMPLATE_REPO=false
if [[ "$REMOTE_URL" =~ agent-harness ]]; then
    IS_TEMPLATE_REPO=true
fi

CREATE_BASELINE_COMMIT=false

if [ -d ".git" ]; then
    if [ "$FORCE_CLEAN" = true ]; then
        echo -e "${BLUE}▸ Detaching git history (--clean-git requested)...${NC}"
        rm -rf .git
        git init -b main > /dev/null 2>&1 || git init > /dev/null 2>&1
        echo -e "  ${GREEN}✓${NC} Initialized fresh Git repository (branch: main)"
        CREATE_BASELINE_COMMIT=true
    elif [ "$FORCE_KEEP" = true ]; then
        echo -e "  ${GREEN}✓${NC} Existing git repository preserved intact (--keep-git requested)"
    elif [ "$IS_TEMPLATE_REPO" = true ]; then
        # Running inside the template repository itself
        if [[ -n "$PROJECT_NAME" ]]; then
            echo -e "${BLUE}▸ Cloned template repository detected (${REMOTE_URL}).${NC}"
            echo -e "${BLUE}▸ Bootstrapping new project '${PROJECT_NAME}' (detaching template git)...${NC}"
            rm -rf .git
            git init -b main > /dev/null 2>&1 || git init > /dev/null 2>&1
            echo -e "  ${GREEN}✓${NC} Initialized fresh Git repository (branch: main)"
            CREATE_BASELINE_COMMIT=true
        elif [ -t 0 ]; then
            echo -e "${YELLOW}▸ Template repository detected (${REMOTE_URL}).${NC}"
            echo -ne "${BOLD}Do you want to detach template git history to start a fresh project? [Y/n]: ${NC}"
            read -r RESP
            if [[ "$RESP" =~ ^[Yy]?$ || -z "$RESP" ]]; then
                rm -rf .git
                git init -b main > /dev/null 2>&1 || git init > /dev/null 2>&1
                echo -e "  ${GREEN}✓${NC} Initialized fresh Git repository (branch: main)"
                CREATE_BASELINE_COMMIT=true
            else
                echo -e "  ${GREEN}✓${NC} Template git repository preserved intact."
            fi
        else
            echo -e "  ${GREEN}✓${NC} Template repository detected. Preserving git (pass a project name or --clean-git to detach)."
        fi
    else
        # Running inside an existing external project!
        echo -e "  ${GREEN}✓${NC} Existing project repository detected (${REMOTE_URL:-local git repo})"
        echo -e "  ${GREEN}✓${NC} Git history, branches, and remotes preserved 100% intact"
    fi
else
    echo -e "${BLUE}▸ No git repository detected. Initializing git...${NC}"
    git init -b main > /dev/null 2>&1 || git init > /dev/null 2>&1
    echo -e "  ${GREEN}✓${NC} Initialized fresh Git repository (branch: main)"
    CREATE_BASELINE_COMMIT=true
fi

# ── 2. Progress Files Initialization ────────────────────
if [ ! -f "progress/current.md" ] || [ "$CREATE_BASELINE_COMMIT" = true ]; then
    mkdir -p progress
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
    echo -e "  ${GREEN}✓${NC} Ready progress/current.md"
fi

if [ ! -f "progress/history.md" ] || [ "$CREATE_BASELINE_COMMIT" = true ]; then
    mkdir -p progress
    cat << 'EOF' > progress/history.md
# Session History

> Append-only audit log of completed agent tasks.

---

EOF
    echo -e "  ${GREEN}✓${NC} Ready progress/history.md"
fi

# ── 3. Install or Merge Pre-Commit Safety Hook ──────────
if [ -d ".git" ]; then
    mkdir -p .git/hooks
    HOOK_FILE=".git/hooks/pre-commit"
    if [ ! -f "$HOOK_FILE" ]; then
        cat << 'HOOK_EOF' > "$HOOK_FILE"
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
        chmod +x "$HOOK_FILE"
        echo -e "  ${GREEN}✓${NC} Installed pre-commit git security hook"
    elif ! grep -q "Automated Git Safety Gate" "$HOOK_FILE"; then
        cat << 'HOOK_EOF' >> "$HOOK_FILE"

# Automated Git Safety Gate — Appended by agent-harness
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
        chmod +x "$HOOK_FILE"
        echo -e "  ${GREEN}✓${NC} Appended security check to existing pre-commit hook"
    fi
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

# ── 4. Initial Baseline Git Commit (Template bootstrap only) ──
if [ "$CREATE_BASELINE_COMMIT" = true ] && [ -d ".git" ]; then
    git add . > /dev/null 2>&1
    git commit -m "chore: initial project baseline from agent harness" > /dev/null 2>&1 || true
    echo -e "  ${GREEN}✓${NC} Created initial git baseline commit"
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
if [ $FAIL -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✓ HARNESS READY AND ROCK SOLID!${NC}"
    echo ""
    echo -e "  ${BOLD}Setup complete.${NC}"
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
