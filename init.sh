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
FORCE_RESET_REMOTE=false
PROJECT_NAME=""

for arg in "$@"; do
    case "$arg" in
        --clean-git) FORCE_CLEAN=true ;;
        --keep-git) FORCE_KEEP=true ;;
        --reset-remote) FORCE_RESET_REMOTE=true ;;
        --help|-h)
            echo -e "${BOLD}Agent Harness — CLI Reference${NC}"
            echo ""
            echo "Usage:"
            echo "  ./init.sh                     Run smart setup / health check"
            echo "  ./init.sh [project_name]      Bootstrap a new project (detaches git)"
            echo "  /path/to/agent-harness/init.sh  Install harness into current directory from external repo"
            echo "  ./init.sh --clean-git         Force detach and reinitialize fresh git repository"
            echo "  ./init.sh --reset-remote      Disconnect remote origin (keep commit history)"
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

# ── Resolution of Script Location & Execution Context ─────
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)"
CURRENT_DIR="$(pwd -P)"

IS_EXTERNAL_RUN=false
if [ "$SCRIPT_DIR" != "$CURRENT_DIR" ]; then
    IS_EXTERNAL_RUN=true
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Agent Harness — Setup & Environment Verification       ${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo ""

# ── 0. Remote Deployment Mode (if executed from external dir) ──
if [ "$IS_EXTERNAL_RUN" = true ]; then
    echo -e "${BLUE}▸ Remote deployment mode detected.${NC}"
    echo -e "  Template Source : ${BOLD}${SCRIPT_DIR}${NC}"
    echo -e "  Target Project  : ${BOLD}${CURRENT_DIR}${NC}"
    echo ""
    echo -e "${BLUE}▸ Deploying Agent Harness into target project...${NC}"

    # Directories
    for dir in agents docs progress; do
        if [ -d "$SCRIPT_DIR/$dir" ]; then
            mkdir -p "$CURRENT_DIR/$dir"
            cp -R "$SCRIPT_DIR/$dir/." "$CURRENT_DIR/$dir/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Deployed $dir/"
        fi
    done

    # Tool config directories
    if [ -d "$SCRIPT_DIR/.github" ]; then
        mkdir -p "$CURRENT_DIR/.github"
        if [ ! -f "$CURRENT_DIR/.github/copilot-instructions.md" ]; then
            cp "$SCRIPT_DIR/.github/copilot-instructions.md" "$CURRENT_DIR/.github/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Deployed .github/copilot-instructions.md"
        fi
    fi

    if [ -d "$SCRIPT_DIR/.claude" ]; then
        mkdir -p "$CURRENT_DIR/.claude"
        if [ ! -f "$CURRENT_DIR/.claude/settings.json" ]; then
            cp "$SCRIPT_DIR/.claude/settings.json" "$CURRENT_DIR/.claude/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Deployed .claude/settings.json"
        fi
    fi

    # Core files (do not overwrite if already existing in target)
    for file in AGENTS.md TASKS.md CHECKPOINTS.md SETUP.md CLAUDE.md .cursorrules .windsurfrules .env.example; do
        if [ -f "$SCRIPT_DIR/$file" ]; then
            if [ ! -f "$CURRENT_DIR/$file" ]; then
                cp "$SCRIPT_DIR/$file" "$CURRENT_DIR/$file"
                echo -e "  ${GREEN}✓${NC} Deployed $file"
            fi
        fi
    done

    # .gitignore handling
    if [ ! -f "$CURRENT_DIR/.gitignore" ]; then
        if [ -f "$SCRIPT_DIR/.gitignore" ]; then
            cp "$SCRIPT_DIR/.gitignore" "$CURRENT_DIR/.gitignore"
            echo -e "  ${GREEN}✓${NC} Created .gitignore"
        fi
    else
        if ! grep -q "^\.env" "$CURRENT_DIR/.gitignore" 2>/dev/null; then
            cat << 'EOF' >> "$CURRENT_DIR/.gitignore"

# Environment & Secrets (Added by agent-harness)
.env
.env.*
!.env.example
*.pem
*.key
*.p12
*.pfx
EOF
            echo -e "  ${GREEN}✓${NC} Appended security ignore rules to existing .gitignore"
        fi
    fi

    # Copy init.sh to target project
    if [ ! -f "$CURRENT_DIR/init.sh" ]; then
        cp "$SCRIPT_DIR/init.sh" "$CURRENT_DIR/init.sh"
        chmod +x "$CURRENT_DIR/init.sh"
        echo -e "  ${GREEN}✓${NC} Copied init.sh into project"
    fi

    echo ""
fi

# ── 1. Smart Git Detection & Preservation ───────────────
REMOTE_URL=$(git remote get-url origin 2>/dev/null || git config --get remote.origin.url 2>/dev/null || echo "")

IS_TEMPLATE_REPO=false
if [ "$IS_EXTERNAL_RUN" = false ] && [[ "$REMOTE_URL" =~ agent-harness ]]; then
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
    elif [ "$FORCE_RESET_REMOTE" = true ]; then
        if git remote get-url origin > /dev/null 2>&1; then
            OLD_REMOTE=$(git remote get-url origin)
            git remote remove origin
            echo -e "  ${GREEN}✓${NC} Disconnected remote origin (${OLD_REMOTE})."
            echo -e "  ${BLUE}▸${NC} Ready to connect your repo: ${BOLD}git remote add origin <your-repo-url>${NC}"
        else
            echo -e "  ${YELLOW}—${NC} No remote origin configured."
        fi
    elif [ -n "$PROJECT_NAME" ]; then
        # Explicit project name passed -> Bootstrap new project from this repo (whether template or cloned 3rd-party)
        echo -e "${BLUE}▸ Repository detected (${REMOTE_URL:-local git repo}).${NC}"
        echo -e "${BLUE}▸ Bootstrapping new project '${PROJECT_NAME}' (detaching git history)...${NC}"
        rm -rf .git
        git init -b main > /dev/null 2>&1 || git init > /dev/null 2>&1
        echo -e "  ${GREEN}✓${NC} Initialized fresh Git repository (branch: main)"
        CREATE_BASELINE_COMMIT=true
    elif [ "$IS_TEMPLATE_REPO" = true ]; then
        # Running inside the template repository itself without project name
        if [ -t 0 ]; then
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
        # Running inside an existing external repository!
        if [ -t 0 ] && [ -n "$REMOTE_URL" ]; then
            echo -e "${YELLOW}▸ Existing git repository detected (${REMOTE_URL}).${NC}"
            echo -e "  Is this a base for a new project of your own?"
            echo -e "    1) Yes: Start fresh git repository (clean slate, recommended for new project)"
            echo -e "    2) Yes: Keep commit history, but disconnect remote origin (ready for your repo)"
            echo -e "    3) No: Keep existing git, history, and remotes 100% intact (contributor / own repo)"
            echo -ne "${BOLD}  Select [1/2/3, default: 3]: ${NC}"
            read -r GIT_CHOICE
            case "$GIT_CHOICE" in
                1)
                    echo -e "${BLUE}▸ Detaching git history...${NC}"
                    rm -rf .git
                    git init -b main > /dev/null 2>&1 || git init > /dev/null 2>&1
                    echo -e "  ${GREEN}✓${NC} Initialized fresh Git repository (branch: main)"
                    CREATE_BASELINE_COMMIT=true
                    ;;
                2)
                    git remote remove origin 2>/dev/null || true
                    echo -e "  ${GREEN}✓${NC} Removed remote origin (${REMOTE_URL})."
                    echo -e "  ${BLUE}▸${NC} Ready to connect your repo: ${BOLD}git remote add origin <your-repo-url>${NC}"
                    ;;
                *)
                    echo -e "  ${GREEN}✓${NC} Git history, branches, and remotes preserved 100% intact"
                    ;;
            esac
        else
            echo -e "  ${GREEN}✓${NC} Existing project repository detected (${REMOTE_URL:-local git repo})"
            echo -e "  ${GREEN}✓${NC} Git history, branches, and remotes preserved 100% intact"
        fi
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
PATTERNS='password\s*=\s*["\x27][^"\x27]+["\x27]|api_key\s*=\s*["\x27]|secret\s*=\s*["\x27]|token\s*=\s*["\x27]|Bearer\s+[A-Za-z0-9_\-\.]{20,}|PRIVATE_KEY|-----BEGIN|ghp_[A-Za-z0-9_]{36}|github_pat_[A-Za-z0-9_]{82}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|sk-ant-[A-Za-z0-9\-]{20,}|xoxb-[0-9]{10,}|xoxp-[0-9]{10,}|glpat-[A-Za-z0-9\-]{20,}'
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
PATTERNS='password\s*=\s*["\x27][^"\x27]+["\x27]|api_key\s*=\s*["\x27]|secret\s*=\s*["\x27]|token\s*=\s*["\x27]|Bearer\s+[A-Za-z0-9_\-\.]{20,}|PRIVATE_KEY|-----BEGIN|ghp_[A-Za-z0-9_]{36}|github_pat_[A-Za-z0-9_]{82}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|sk-ant-[A-Za-z0-9\-]{20,}|xoxb-[0-9]{10,}|xoxp-[0-9]{10,}|glpat-[A-Za-z0-9\-]{20,}'
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

# ── 4. Auto-Provision Missing Tool Adapters (Self-Healing) ──
# If files were copied with 'cp -r dir/*' (which ignores dotfiles),
# auto-generate the adapters so the repo is immediately functional.
if [ ! -f ".cursorrules" ]; then
    cat << 'EOF' > .cursorrules
# Cursor Rules — Agent Harness
Read `AGENTS.md` before doing any work in this repository.

## Roles
- You act according to `agents/leader.md` by default: coordinate, plan, verify.
- To implement code, follow `agents/implementer.md` (exactly 1 feature at a time).
- To review code, follow `agents/reviewer.md` (double-check quality & tests).
- Before closing or committing, run the security checklist in `agents/security-reviewer.md`.

## Non-Negotiable Rules
1. Follow `TASKS.md` for task tracking.
2. Follow `docs/architecture.md`, `docs/conventions.md`, and `docs/security.md`.
3. Never hardcode credentials, secrets, or tokens.
EOF
    echo -e "  ${GREEN}✓${NC} Auto-provisioned missing .cursorrules"
fi

if [ ! -f ".windsurfrules" ]; then
    cat << 'EOF' > .windsurfrules
# Windsurf Rules — Agent Harness
Read `AGENTS.md` before doing any work in this repository.

## Roles
- Act according to `agents/leader.md` by default.
- Follow `agents/implementer.md` for coding (1 feature at a time).
- Follow `agents/reviewer.md` for quality review and test validation.
- Follow `agents/security-reviewer.md` for secret scanning and git safety.

## Non-Negotiable Rules
1. Follow `TASKS.md` for task selection.
2. Follow `docs/architecture.md`, `docs/conventions.md`, and `docs/security.md`.
3. Keep git clean and check `.gitignore`.
EOF
    echo -e "  ${GREEN}✓${NC} Auto-provisioned missing .windsurfrules"
fi

if [ ! -f ".github/copilot-instructions.md" ]; then
    mkdir -p .github
    cat << 'EOF' > .github/copilot-instructions.md
# GitHub Copilot Instructions — Agent Harness
Read `AGENTS.md` as the primary project navigation map.

## Core Directives
- **Workflow & Rules**: Follow `AGENTS.md` and `CHECKPOINTS.md`.
- **Architecture**: Adhere strictly to `docs/architecture.md`. Do not bypass architectural layers.
- **Code Style & Conventions**: Follow `docs/conventions.md`.
- **Security**: Follow `docs/security.md` and `agents/security-reviewer.md`. Never hardcode secrets.
EOF
    echo -e "  ${GREEN}✓${NC} Auto-provisioned missing .github/copilot-instructions.md"
fi

if [ ! -f ".env.example" ]; then
    cat << 'EOF' > .env.example
# Environment Variables Template
# Copy this file to .env and fill in real values.
# NEVER commit .env to git.

# ──────────────────────────────────────────────
# CANARY TOKEN — Exfiltration Detection Trap
# If this token appears in ANY external log, webhook,
# analytics dashboard, or third-party service,
# assume immediate credential compromise.
# Generate your own at https://canarytokens.org
# ──────────────────────────────────────────────
CANARY_TOKEN=canary_NEVER_USE_THIS_VALUE_it_is_a_trap_abc123xyz

# ──────────────────────────────────────────────
# Project-Specific Variables
# ──────────────────────────────────────────────
# DATABASE_URL=
# API_KEY=
# SECRET_KEY=
EOF
    echo -e "  ${GREEN}✓${NC} Auto-provisioned missing .env.example (with canary token)"
fi

# ── 5. Dev Environment Detection & Bootstrap ──────────────
# Detect project type and document commands for future agent sessions.
echo ""
echo -e "${BOLD}▸ Detecting Project Environment...${NC}"

DEV_DETECTED=false

if [ -f "package.json" ]; then
    DEV_DETECTED=true
    echo -e "  ${GREEN}✓${NC} Node.js project detected (package.json)"
    if [ ! -d "node_modules" ] && command -v npm &> /dev/null; then
        echo -e "  ${BLUE}▸${NC} Installing dependencies (npm install)..."
        npm install --silent 2>/dev/null && echo -e "  ${GREEN}✓${NC} Dependencies installed" || echo -e "  ${YELLOW}⚠${NC} npm install had warnings (non-blocking)"
    elif [ -d "node_modules" ]; then
        echo -e "  ${GREEN}✓${NC} Dependencies already installed (node_modules exists)"
    fi
fi

if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
    DEV_DETECTED=true
    echo -e "  ${GREEN}✓${NC} Python project detected"
    if [ -f "requirements.txt" ] && ! [ -d ".venv" ] && ! [ -d "venv" ]; then
        echo -e "  ${YELLOW}⚠${NC} No virtual environment found. Consider: python3 -m venv .venv && pip install -r requirements.txt"
    fi
fi

if [ -f "Cargo.toml" ]; then
    DEV_DETECTED=true
    echo -e "  ${GREEN}✓${NC} Rust project detected (Cargo.toml)"
fi

if [ -f "go.mod" ]; then
    DEV_DETECTED=true
    echo -e "  ${GREEN}✓${NC} Go project detected (go.mod)"
fi

if [ "$DEV_DETECTED" = false ]; then
    echo -e "  ${YELLOW}—${NC} No known project type detected (will be configured when you start building)"
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
check ".env.example exists (canary token)" file_exists ".env.example"

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
    echo ""
    
    # Prompt to delete init.sh since it is run only once
    if [ "$IS_EXTERNAL_RUN" = true ]; then
        echo -e "  ${GREEN}✓${NC} Master template preserved intact (${SCRIPT_DIR}/init.sh)"
        if [ -f "$CURRENT_DIR/init.sh" ] && [ -t 0 ]; then
            echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
            echo -ne "${BOLD}Since setup is complete, do you want to delete init.sh from this project? [y/N]: ${NC}"
            read -r DEL_INIT
            if [[ "$DEL_INIT" =~ ^[Yy]$ ]]; then
                echo -e "  ${GREEN}✓${NC} Removing local init.sh copy..."
                rm -f "$CURRENT_DIR/init.sh"
                echo -e "  ${GREEN}✓${NC} Local init.sh removed. Master template remains intact in ${SCRIPT_DIR}."
            else
                echo -e "  ${GREEN}✓${NC} Kept local copy of init.sh in target project."
            fi
        fi
    else
        # Running directly inside the harness/project directory
        if [ "$IS_TEMPLATE_REPO" = true ] && [ -z "$PROJECT_NAME" ]; then
            echo -e "  ${GREEN}✓${NC} Master template repository preserved (init.sh retained)."
        elif [ -t 0 ]; then
            echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
            echo -ne "${BOLD}Since init.sh is only run once, do you want to delete init.sh? [y/N]: ${NC}"
            read -r DEL_INIT
            if [[ "$DEL_INIT" =~ ^[Yy]$ ]]; then
                echo -e "  ${GREEN}✓${NC} Removing init.sh..."
                rm -f "$CURRENT_DIR/init.sh"
                echo -e "  ${GREEN}✓${NC} init.sh deleted. Happy vibecoding!"
            else
                echo -e "  ${GREEN}✓${NC} Kept init.sh in repository."
            fi
        fi
    fi
else
    echo -e "  ${RED}${BOLD}✗ Setup encountered $FAIL issue(s). Please review above.${NC}"
fi
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo ""

exit $FAIL
