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

# ── Interactive TUI Picker (WhisperNinja fzf style) ────────
inline_pick() {
    local title="$1"
    local default_idx="${2:-0}"
    shift 2
    local options=("$@")

    if [ ${#options[@]} -eq 0 ]; then
        echo "-1"
        return
    fi

    # Check if fzf is available and a controlling terminal exists
    if command -v fzf >/dev/null 2>&1 && [ -c /dev/tty ]; then
        local selected
        selected=$(printf "%s\n" "${options[@]}" | fzf \
            --prompt="${title} › " \
            --height=40% \
            --border=rounded \
            --color="fg:#cdd6f4,bg:#1e1e2e,hl:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,header:#a6adc8,border:#585b70" \
            --pointer="▶" \
            --layout=reverse \
            --no-sort \
            --cycle \
            --header="↑↓ navigate   Enter select   Esc cancel" \
            --header-first || true)

        if [ -n "$selected" ]; then
            for i in "${!options[@]}"; do
                if [ "${options[$i]}" = "$selected" ]; then
                    echo "$i"
                    return
                fi
            done
        fi
        echo "$default_idx"
        return
    fi

    # Fallback to styled numbered prompt if fzf not available
    echo "" >&2
    echo -e "${YELLOW}▸ ${title}:${NC}" >&2
    for i in "${!options[@]}"; do
        local marker=" "
        [ "$i" -eq "$default_idx" ] && marker="▶"
        echo -e "  ${marker} [$((i + 1))] ${options[$i]}" >&2
    done

    local raw=""
    if [ -c /dev/tty ]; then
        read -r -p "  Select [1-${#options[@]}, default: $((default_idx + 1))]: " raw < /dev/tty || true
    elif [ -t 0 ]; then
        read -r -p "  Select [1-${#options[@]}, default: $((default_idx + 1))]: " raw || true
    fi

    if [[ "$raw" =~ ^[0-9]+$ ]] && [ "$raw" -ge 1 ] && [ "$raw" -le "${#options[@]}" ]; then
        echo "$((raw - 1))"
        return
    fi

    echo "$default_idx"
}

FORCE_CLEAN=false
FORCE_KEEP=false
IS_UPDATE_MODE=false
HARNESS_PROFILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean-git) FORCE_CLEAN=true; shift ;;
        --keep-git) FORCE_KEEP=true; shift ;;
        --update)
            IS_UPDATE_MODE=true
            FORCE_KEEP=true
            shift
            ;;
        --profile|-p)
            HARNESS_PROFILE="$2"
            shift 2
            ;;
        --profile=*)
            HARNESS_PROFILE="${1#*=}"
            shift
            ;;
        --help|-h)
            echo -e "${BOLD}Agent Harness — Setup & Environment Verification${NC}"
            echo ""
            echo "Usage:"
            echo "  ./init.sh                               Smart setup (prompts profile & git options)"
            echo "  ./init.sh --profile <name>              Choose profile: balanced, lite, security, full"
            echo "  /path/to/agent-harness/init.sh          Run remotely from any project"
            echo "  /path/to/agent-harness/init.sh --update Update existing project safely"
            echo "  ./init.sh --clean-git                   Force clean slate (reset Git from zero)"
            echo "  ./init.sh --keep-git                    Force preserve existing Git repository"
            echo "  ./init.sh --help                        Show this screen"
            echo ""
            exit 0
            ;;
        *)
            shift
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

# ── Profile Selection & Normalization ──────────────────────
if [ -z "$HARNESS_PROFILE" ]; then
    if [ "$IS_UPDATE_MODE" = false ] && { [ -t 0 ] || [ -c /dev/tty ]; }; then
        PROFILE_OPTIONS=(
            "Balanced [Default] — Low token footprint (~460 tks), self-review + tests + local security"
            "Lite — Ultra-lightweight (~380 tks), 1 direct agent for forks, scripts & MVPs"
            "Security — Hardened perimeter (~480 tks), zero-trust, dedicated security reviewer"
            "Full — Full autonomous pipeline (4 agents, ADRs, context, exhaustive checkpoints)"
        )
        P_IDX=$(inline_pick "Select Harness Profile" 0 "${PROFILE_OPTIONS[@]}")
        case "$P_IDX" in
            1) HARNESS_PROFILE="lite" ;;
            2) HARNESS_PROFILE="security" ;;
            3) HARNESS_PROFILE="full" ;;
            *) HARNESS_PROFILE="balanced" ;;
        esac
    else
        HARNESS_PROFILE="balanced"
    fi
else
    case "$HARNESS_PROFILE" in
        lite|Lite|2) HARNESS_PROFILE="lite" ;;
        security|Security|3) HARNESS_PROFILE="security" ;;
        full|Full|4) HARNESS_PROFILE="full" ;;
        *) HARNESS_PROFILE="balanced" ;;
    esac
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Agent Harness — Setup & Environment Verification       ${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "  Profile: ${BOLD}${HARNESS_PROFILE}${NC}"
echo ""

# ── 0. Remote Deployment Mode (if executed from external dir) ──
if [ "$IS_EXTERNAL_RUN" = true ]; then
    echo -e "${BLUE}▸ Remote deployment mode detected.${NC}"
    echo -e "  Template Source : ${BOLD}${SCRIPT_DIR}${NC}"
    echo -e "  Target Project  : ${BOLD}${CURRENT_DIR}${NC}"
    echo -e "  Harness Profile : ${BOLD}${HARNESS_PROFILE}${NC}"
    echo ""
    if [ "$IS_UPDATE_MODE" = true ]; then
        echo -e "${BLUE}▸ Updating Agent Harness in target project (--update)...${NC}"
    else
        echo -e "${BLUE}▸ Deploying Agent Harness into target project...${NC}"
    fi

    # 1. Profile-specific AGENTS.md
    if [ -f "$SCRIPT_DIR/profiles/$HARNESS_PROFILE/AGENTS.md" ]; then
        cp "$SCRIPT_DIR/profiles/$HARNESS_PROFILE/AGENTS.md" "$CURRENT_DIR/AGENTS.md"
        echo -e "  ${GREEN}✓${NC} Deployed AGENTS.md (${HARNESS_PROFILE} profile)"
    elif [ -f "$SCRIPT_DIR/AGENTS.md" ]; then
        cp "$SCRIPT_DIR/AGENTS.md" "$CURRENT_DIR/AGENTS.md"
        echo -e "  ${GREEN}✓${NC} Deployed AGENTS.md"
    fi

    # 2. Agent roles (only for security and full profiles)
    if [ "$HARNESS_PROFILE" = "full" ]; then
        if [ -d "$SCRIPT_DIR/agents" ]; then
            mkdir -p "$CURRENT_DIR/agents"
            cp -R "$SCRIPT_DIR/agents/." "$CURRENT_DIR/agents/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Deployed agents/ (all 4 orchestrator roles)"
        fi
    elif [ "$HARNESS_PROFILE" = "security" ]; then
        mkdir -p "$CURRENT_DIR/agents"
        for ag in implementer.md security-reviewer.md; do
            if [ -f "$SCRIPT_DIR/agents/$ag" ]; then
                cp "$SCRIPT_DIR/agents/$ag" "$CURRENT_DIR/agents/$ag" 2>/dev/null || true
            fi
        done
        echo -e "  ${GREEN}✓${NC} Deployed agents/ (implementer + security-reviewer)"
    fi

    # 3. Docs directory (profile-dependent)
    if [ "$HARNESS_PROFILE" = "full" ]; then
        if [ -d "$SCRIPT_DIR/docs" ]; then
            mkdir -p "$CURRENT_DIR/docs/adr"
            cp "$SCRIPT_DIR/docs/adr/template.md" "$CURRENT_DIR/docs/adr/" 2>/dev/null || true
            for doc in "$SCRIPT_DIR/docs"/*; do
                docname="$(basename "$doc")"
                if [ "$docname" != "adr" ]; then
                    if [ ! -f "$CURRENT_DIR/docs/$docname" ]; then
                        cp "$doc" "$CURRENT_DIR/docs/$docname" 2>/dev/null || true
                    fi
                fi
            done
            echo -e "  ${GREEN}✓${NC} Deployed docs/ (full architecture, conventions, security, verification, context & ADRs)"
        fi
    elif [ "$HARNESS_PROFILE" = "security" ]; then
        mkdir -p "$CURRENT_DIR/docs"
        for doc in architecture.md conventions.md security.md; do
            if [ -f "$SCRIPT_DIR/docs/$doc" ] && [ ! -f "$CURRENT_DIR/docs/$doc" ]; then
                cp "$SCRIPT_DIR/docs/$doc" "$CURRENT_DIR/docs/$doc" 2>/dev/null || true
            fi
        done
        echo -e "  ${GREEN}✓${NC} Deployed docs/ (architecture, conventions, security)"
    elif [ "$HARNESS_PROFILE" = "balanced" ]; then
        mkdir -p "$CURRENT_DIR/docs"
        for doc in architecture.md conventions.md; do
            if [ -f "$SCRIPT_DIR/docs/$doc" ] && [ ! -f "$CURRENT_DIR/docs/$doc" ]; then
                cp "$SCRIPT_DIR/docs/$doc" "$CURRENT_DIR/docs/$doc" 2>/dev/null || true
            fi
        done
        echo -e "  ${GREEN}✓${NC} Deployed docs/ (architecture, conventions)"
    fi

    # 4. Progress directory (only if not lite)
    if [ "$HARNESS_PROFILE" != "lite" ]; then
        mkdir -p "$CURRENT_DIR/progress"
        for prog in current.md history.md; do
            if [ ! -f "$CURRENT_DIR/progress/$prog" ] && [ -f "$SCRIPT_DIR/progress/$prog" ]; then
                cp "$SCRIPT_DIR/progress/$prog" "$CURRENT_DIR/progress/$prog" 2>/dev/null || true
            fi
        done
        echo -e "  ${GREEN}✓${NC} Preserved progress/ (active task & history safe)"
    fi

    # 5. Tool config directories (always deployed)
    if [ -d "$SCRIPT_DIR/.github" ]; then
        mkdir -p "$CURRENT_DIR/.github"
        if [ ! -f "$CURRENT_DIR/.github/copilot-instructions.md" ] || [ "$IS_UPDATE_MODE" = true ]; then
            cp "$SCRIPT_DIR/.github/copilot-instructions.md" "$CURRENT_DIR/.github/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Deployed .github/copilot-instructions.md"
        fi
    fi

    if [ -d "$SCRIPT_DIR/.claude" ]; then
        mkdir -p "$CURRENT_DIR/.claude"
        if [ ! -f "$CURRENT_DIR/.claude/settings.json" ] || [ "$IS_UPDATE_MODE" = true ]; then
            cp "$SCRIPT_DIR/.claude/settings.json" "$CURRENT_DIR/.claude/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Deployed .claude/settings.json"
        fi
    fi

    # 6. Universal adapters (always deployed)
    for file in CLAUDE.md .cursorrules .windsurfrules; do
        if [ -f "$SCRIPT_DIR/$file" ]; then
            if [ ! -f "$CURRENT_DIR/$file" ] || [ "$IS_UPDATE_MODE" = true ]; then
                cp "$SCRIPT_DIR/$file" "$CURRENT_DIR/$file"
                echo -e "  ${GREEN}✓${NC} Deployed $file"
            fi
        fi
    done

    # 7. Additional docs (CHECKPOINTS.md, SETUP.md, TASKS.md)
    if [ "$HARNESS_PROFILE" = "full" ]; then
        for file in CHECKPOINTS.md SETUP.md; do
            if [ -f "$SCRIPT_DIR/$file" ]; then
                if [ ! -f "$CURRENT_DIR/$file" ] || [ "$IS_UPDATE_MODE" = true ]; then
                    cp "$SCRIPT_DIR/$file" "$CURRENT_DIR/$file"
                    echo -e "  ${GREEN}✓${NC} Deployed $file"
                fi
            fi
        done
    fi

    if [ "$HARNESS_PROFILE" != "lite" ]; then
        if [ -f "$SCRIPT_DIR/TASKS.md" ] && [ ! -f "$CURRENT_DIR/TASKS.md" ]; then
            cp "$SCRIPT_DIR/TASKS.md" "$CURRENT_DIR/TASKS.md"
            echo -e "  ${GREEN}✓${NC} Deployed TASKS.md"
        fi
    fi

    if [ -f "$SCRIPT_DIR/.env.example" ] && [ ! -f "$CURRENT_DIR/.env.example" ]; then
        cp "$SCRIPT_DIR/.env.example" "$CURRENT_DIR/.env.example"
        echo -e "  ${GREEN}✓${NC} Deployed .env.example (canary token)"
    fi

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
        echo -e "${BLUE}▸ Resetting Git repository (--clean-git)...${NC}"
        rm -rf .git
        git init -b main > /dev/null 2>&1 || git init > /dev/null 2>&1
        echo -e "  ${GREEN}✓${NC} Git repository initialized from scratch (branch: main)"
        CREATE_BASELINE_COMMIT=true
    elif [ "$FORCE_KEEP" = true ]; then
        echo -e "  ${GREEN}✓${NC} Git repository preserved intact (--keep-git)"
    elif [ -t 0 ] || [ -c /dev/tty ]; then
        echo -e "${YELLOW}▸ Existing Git repository detected${NC}${REMOTE_URL:+ ($REMOTE_URL)}."
        GIT_OPTIONS=(
            "Keep existing repository intact (preserve history & remotes) [default]"
            "Clean slate: reset everything and start fresh (new repository 0km)"
        )
        GIT_CHOICE_IDX=$(inline_pick "Git Repository Action" 0 "${GIT_OPTIONS[@]}")
        if [ "$GIT_CHOICE_IDX" -eq 1 ]; then
            echo -e "${BLUE}▸ Resetting Git repository...${NC}"
            rm -rf .git
            git init -b main > /dev/null 2>&1 || git init > /dev/null 2>&1
            echo -e "  ${GREEN}✓${NC} Git repository initialized from scratch (branch: main)"
            CREATE_BASELINE_COMMIT=true
        else
            echo -e "  ${GREEN}✓${NC} Git repository preserved 100% intact"
        fi
    else
        # Non-interactive mode (pipes/CI) -> safe default: preserve
        echo -e "  ${GREEN}✓${NC} Existing Git repository detected (${REMOTE_URL:-local git repo}) — preserved intact"
    fi
else
    # No repo: initialize new
    git init -b main > /dev/null 2>&1 || git init > /dev/null 2>&1
    echo -e "  ${GREEN}✓${NC} Git repository initialized from scratch (branch: main)"
    CREATE_BASELINE_COMMIT=true
fi

# Configure profile-specific AGENTS.md for local runs
if [ "$IS_EXTERNAL_RUN" = false ] && [ "$IS_TEMPLATE_REPO" = false ]; then
    if [ -f "$SCRIPT_DIR/profiles/$HARNESS_PROFILE/AGENTS.md" ]; then
        cp "$SCRIPT_DIR/profiles/$HARNESS_PROFILE/AGENTS.md" "$CURRENT_DIR/AGENTS.md"
        echo -e "  ${GREEN}✓${NC} Configured AGENTS.md for profile: ${BOLD}${HARNESS_PROFILE}${NC}"
    fi
fi

# ── 2. Progress Files Initialization ────────────────────
if [ "$HARNESS_PROFILE" != "lite" ]; then
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

# SkillSpector Skill Gate — Autonomous Skill Scanning
STAGED_SKILLS=$(git diff --cached --name-only 2>/dev/null | grep -E '(^|\/)(skills\/|\.agents\/skills\/|\.claude\/skills\/).*\.(md|py|sh|json|yaml|yml)$|(\/|^)SKILL\.md$|(\/|^)skill\.md$' || true)
if [ -n "$STAGED_SKILLS" ]; then
    if command -v uvx >/dev/null 2>&1 || command -v skillspector >/dev/null 2>&1; then
        echo -e "\033[0;34m[SKILL GATE] Staged skills detected. Running NVIDIA SkillSpector static scan...\033[0m"
        for SKILL_TARGET in $STAGED_SKILLS; do
            if [ -e "$SKILL_TARGET" ]; then
                SCAN_CMD="uvx --from git+https://github.com/NVIDIA/skillspector.git skillspector scan"
                command -v skillspector >/dev/null 2>&1 && SCAN_CMD="skillspector scan"
                SCAN_RES=$($SCAN_CMD "$SKILL_TARGET" --format json --no-llm 2>&1 || true)
                if echo "$SCAN_RES" | grep -qiE '"severity":\s*"(CRITICAL|HIGH)"|"critical":\s*[1-9]|"high":\s*[1-9]|PROMPT_INJECTION|DATA_EXFILTRATION'; then
                    echo -e "\033[0;31m[SKILL GATE BLOCKED] SkillSpector detected CRITICAL/HIGH vulnerabilities in $SKILL_TARGET:\033[0m"
                    echo "$SCAN_RES" | grep -iE 'severity|finding|description|rule' | head -10 || echo "$SCAN_RES" | head -10
                    exit 1
                fi
            fi
        done
        echo -e "\033[0;32m[SKILL GATE] Staged skills verified clean by SkillSpector.\033[0m"
    else
        echo -e "\033[0;33m[SKILL GATE WARNING] Staged skills detected but 'uvx' / 'skillspector' is not installed. Ensure skills are manually audited.\033[0m"
    fi
fi
HOOK_EOF
        chmod +x "$HOOK_FILE"
        echo -e "  ${GREEN}✓${NC} Installed pre-commit git security hook (Secrets + SkillSpector)"
    else
        if ! grep -q "Automated Git Safety Gate" "$HOOK_FILE"; then
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
            echo -e "  ${GREEN}✓${NC} Appended security check to existing pre-commit hook"
        fi

        if ! grep -q "SkillSpector Skill Gate" "$HOOK_FILE"; then
            cat << 'HOOK_EOF' >> "$HOOK_FILE"

# SkillSpector Skill Gate — Appended by agent-harness
STAGED_SKILLS=$(git diff --cached --name-only 2>/dev/null | grep -E '(^|\/)(skills\/|\.agents\/skills\/|\.claude\/skills\/).*\.(md|py|sh|json|yaml|yml)$|(\/|^)SKILL\.md$|(\/|^)skill\.md$' || true)
if [ -n "$STAGED_SKILLS" ]; then
    if command -v uvx >/dev/null 2>&1 || command -v skillspector >/dev/null 2>&1; then
        echo -e "\033[0;34m[SKILL GATE] Staged skills detected. Running NVIDIA SkillSpector static scan...\033[0m"
        for SKILL_TARGET in $STAGED_SKILLS; do
            if [ -e "$SKILL_TARGET" ]; then
                SCAN_CMD="uvx --from git+https://github.com/NVIDIA/skillspector.git skillspector scan"
                command -v skillspector >/dev/null 2>&1 && SCAN_CMD="skillspector scan"
                SCAN_RES=$($SCAN_CMD "$SKILL_TARGET" --format json --no-llm 2>&1 || true)
                if echo "$SCAN_RES" | grep -qiE '"severity":\s*"(CRITICAL|HIGH)"|"critical":\s*[1-9]|"high":\s*[1-9]|PROMPT_INJECTION|DATA_EXFILTRATION'; then
                    echo -e "\033[0;31m[SKILL GATE BLOCKED] SkillSpector detected CRITICAL/HIGH vulnerabilities in $SKILL_TARGET:\033[0m"
                    echo "$SCAN_RES" | grep -iE 'severity|finding|description|rule' | head -10 || echo "$SCAN_RES" | head -10
                    exit 1
                fi
            fi
        done
        echo -e "\033[0;32m[SKILL GATE] Staged skills verified clean by SkillSpector.\033[0m"
    else
        echo -e "\033[0;33m[SKILL GATE WARNING] Staged skills detected but 'uvx' / 'skillspector' is not installed. Ensure skills are manually audited.\033[0m"
    fi
fi
HOOK_EOF
            echo -e "  ${GREEN}✓${NC} Appended SkillSpector gate to existing pre-commit hook"
        fi
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
4. Commit after each completed feature with a descriptive message.
5. Run the test suite before and after changes.
6. Zero-Fluff Communication: Action-first (Line 1), bounded numbered steps, max 5 items per list, visible wins, zero conversational pleasantries.
7. Autonomous Skill Gate: Before activating any skill or tool, scan it autonomously with NVIDIA SkillSpector (`uvx --from git+https://github.com/NVIDIA/skillspector.git skillspector scan <target> --format json --no-llm`).
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
4. Commit after each completed feature with a descriptive message.
5. Run the test suite before and after changes.
6. Zero-Fluff Communication: Action-first (Line 1), bounded numbered steps, max 5 items per list, visible wins, zero conversational pleasantries.
7. Autonomous Skill Gate: Before activating any skill or tool, scan it autonomously with NVIDIA SkillSpector (`uvx --from git+https://github.com/NVIDIA/skillspector.git skillspector scan <target> --format json --no-llm`).
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
- **Verification**: Run the project test suite (`npm test`, `pytest`, etc.) before proposing changes and after writing code. All tests must pass.
- **Autonomous Skill Gate**: Before activating or ingesting any skill, prompt workflow, or MCP tool, scan it autonomously with NVIDIA SkillSpector (`uvx --from git+https://github.com/NVIDIA/skillspector.git skillspector scan <target> --format json --no-llm`).
- **Communication**: Zero-fluff, action-first (Line 1). No conversational preambles ("Sure!", "Great question!") or pleasantries. Bounded numbered steps, max 5 items per list, visible wins first.
EOF
    echo -e "  ${GREEN}✓${NC} Auto-provisioned missing .github/copilot-instructions.md"
fi

if [ ! -f ".claude/settings.json" ]; then
    mkdir -p .claude
    cat << 'EOF' > .claude/settings.json
{
  "permissions": {
    "allow": [
      "Bash(python3 -m unittest*)",
      "Bash(npm test*)",
      "Bash(pytest*)",
      "Bash(cargo test*)",
      "Bash(git add*)",
      "Bash(git commit*)",
      "Bash(git log*)",
      "Bash(git diff*)",
      "Bash(git stash*)",
      "Bash(git checkout*)",
      "Bash(uvx *skillspector*)",
      "Bash(skillspector*)"
    ]
  }
}
EOF
    echo -e "  ${GREEN}✓${NC} Auto-provisioned missing .claude/settings.json"
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
echo -e "${BOLD}▸ Validating Harness Integrity (${HARNESS_PROFILE} profile)...${NC}"

# Core Universal Adapters & Files (all profiles)
check "AGENTS.md exists" file_exists "AGENTS.md"
check ".cursorrules exists (Cursor)" file_exists ".cursorrules"
check ".windsurfrules exists (Windsurf)" file_exists ".windsurfrules"
check ".github/copilot-instructions.md exists (GitHub Copilot)" file_exists ".github/copilot-instructions.md"
check "CLAUDE.md exists (Claude Code)" file_exists "CLAUDE.md"
check ".gitignore exists" file_exists ".gitignore"
check ".env.example exists (canary token)" file_exists ".env.example"
check ".claude/settings.json exists (Claude Code permissions)" file_exists ".claude/settings.json"

if [ "$HARNESS_PROFILE" != "lite" ]; then
    check "TASKS.md exists" file_exists "TASKS.md"
    check "progress/current.md exists" file_exists "progress/current.md"
    check "progress/history.md exists" file_exists "progress/history.md"
    check "docs/architecture.md exists" file_exists "docs/architecture.md"
    check "docs/conventions.md exists" file_exists "docs/conventions.md"
fi

if [ "$HARNESS_PROFILE" = "security" ] || [ "$HARNESS_PROFILE" = "full" ]; then
    check "docs/security.md exists" file_exists "docs/security.md"
    check "agents/implementer.md exists" file_exists "agents/implementer.md"
    check "agents/security-reviewer.md exists" file_exists "agents/security-reviewer.md"
fi

if [ "$HARNESS_PROFILE" = "full" ]; then
    check "CHECKPOINTS.md exists" file_exists "CHECKPOINTS.md"
    check "docs/context.md exists" file_exists "docs/context.md"
    check "docs/adr/template.md exists" file_exists "docs/adr/template.md"
    check "docs/verification.md exists" file_exists "docs/verification.md"
    check "agents/leader.md exists" file_exists "agents/leader.md"
    check "agents/reviewer.md exists" file_exists "agents/reviewer.md"
fi

# SkillSpector Autonomous Gate Readiness
if command -v uvx > /dev/null 2>&1 || command -v skillspector > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} uvx/skillspector available (Autonomous Skill Gate ready)"
else
    echo -e "  ${YELLOW}ℹ${NC} uvx not found in PATH (install 'uv' via https://astral.sh/uv to enable background skill scanning)"
fi

# ── 4. Initial Baseline Git Commit (Template bootstrap only) ──
if [ "$CREATE_BASELINE_COMMIT" = true ] && [ -d ".git" ]; then
    git add . > /dev/null 2>&1
    git commit -m "chore: initial project baseline from agent harness" > /dev/null 2>&1 || true
    echo -e "  ${GREEN}✓${NC} Created initial git baseline commit"
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
if [ $FAIL -eq 0 ]; then
    if [ "$IS_UPDATE_MODE" = true ]; then
        echo -e "  ${GREEN}${BOLD}✓ HARNESS SUCCESSFULLY UPDATED TO LATEST VERSION!${NC}"
        echo ""
        echo -e "  ${BOLD}Update complete.${NC}"
        echo -e "  Agents, ADR templates, domain context, and checkpoints are updated."
        echo -e "  Your tasks (TASKS.md), history, and custom architecture files were kept 100% intact."
    else
        echo -e "  ${GREEN}${BOLD}✓ HARNESS READY AND ROCK SOLID!${NC}"
        echo ""
        echo -e "  ${BOLD}Setup complete.${NC}"
        echo -e "  You do ${YELLOW}NOT${NC} need to run init.sh again."
        echo ""
        echo -e "  ${BLUE}Next Step:${NC}"
        echo -e "  Open your tool (Antigravity, Cursor, Copilot, Windsurf, Claude Code)"
        echo -e "  and describe what you want to build. Your agents will handle the rest."
    fi
    echo ""
    
    # Self-deletion only applies when running locally inside a project
    if [ "$IS_EXTERNAL_RUN" = true ]; then
        echo -e "  ${GREEN}✓${NC} Master template preserved intact (${SCRIPT_DIR}/init.sh)"
    else
        # Running directly inside the harness/project directory
        if [ "$IS_TEMPLATE_REPO" = true ]; then
            echo -e "  ${GREEN}✓${NC} Master template repository preserved (init.sh retained)."
        elif [ -t 0 ] || [ -c /dev/tty ]; then
            echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
            DEL_OPTIONS=(
                "Keep init.sh in repository [default]"
                "Delete init.sh (clean repo, one-time setup complete)"
            )
            DEL_CHOICE_IDX=$(inline_pick "Since init.sh runs once, do you want to delete it?" 0 "${DEL_OPTIONS[@]}")
            if [ "$DEL_CHOICE_IDX" -eq 1 ]; then
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
