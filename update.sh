#!/usr/bin/env bash
# update.sh — Update existing projects with the latest Agent Harness
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CURRENT_DIR="$(pwd -P)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

PROFILE_FLAG=""
ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile|-p)
            PROFILE_FLAG="--profile $2"
            shift 2
            ;;
        --profile=*)
            PROFILE_FLAG="--profile ${1#*=}"
            shift
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

if [ ${#ARGS[@]} -eq 0 ]; then
    if [ "$CURRENT_DIR" = "$SCRIPT_DIR" ]; then
        # Search for candidate sibling directories
        CANDIDATES=()
        for d in "$CURRENT_DIR/.."/*; do
            if [ -d "$d" ]; then
                cand_abs="$(cd "$d" && pwd -P)"
                if [ "$cand_abs" != "$SCRIPT_DIR" ]; then
                    CANDIDATES+=("$(basename "$cand_abs")")
                fi
            fi
        done

        if [ ${#CANDIDATES[@]} -gt 0 ] && command -v fzf >/dev/null 2>&1 && [ -c /dev/tty ]; then
            fzf_input=$(printf "%s\n" "${CANDIDATES[@]}")
            SELECTED_NAMES=$(printf "%s" "$fzf_input" | fzf \
                --multi \
                --prompt="Update Projects › " \
                --height=45% \
                --border=rounded \
                --color="fg:#cdd6f4,bg:#1e1e2e,hl:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,header:#a6adc8,border:#585b70" \
                --pointer="▶" \
                --layout=reverse \
                --cycle \
                --header="Tab multi-select   ↑↓ navigate   Enter confirm   Esc cancel" \
                --header-first \
                2>/dev/tty </dev/tty || true)

            if [ -n "$SELECTED_NAMES" ]; then
                TARGETS=()
                while IFS= read -r name; do
                    [ -n "$name" ] && TARGETS+=("$CURRENT_DIR/../$name")
                done <<< "$SELECTED_NAMES"
            else
                echo -e "${YELLOW}Update cancelled.${NC}"
                exit 0
            fi
        else
            echo -e "${YELLOW}${BOLD}Usage:${NC}"
            echo -e "  ./update.sh <path-to-project> [<another-project>...]"
            echo ""
            echo -e "Examples:"
            echo -e "  ./update.sh ../my-project"
            echo -e "  ./update.sh --profile lite ../my-project"
            echo -e "  ./update.sh /path/to/another-repo"
            echo ""
            echo -e "${BLUE}Or directly from inside your target project directory:${NC}"
            echo -e "  cd my-project"
            echo -e "  $SCRIPT_DIR/update.sh"
            exit 1
        fi
    else
        TARGETS=("$CURRENT_DIR")
    fi
else
    TARGETS=("${ARGS[@]}")
fi

for TARGET in "${TARGETS[@]}"; do
    TARGET_ABS="$(cd "$TARGET" 2>/dev/null && pwd -P || true)"
    if [ -z "$TARGET_ABS" ] || [ ! -d "$TARGET_ABS" ]; then
        echo -e "${RED}✗ Error: Directory not found:${NC} $TARGET"
        continue
    fi

    if [ "$TARGET_ABS" = "$SCRIPT_DIR" ]; then
        echo -e "${YELLOW}⚠ Skipping master agent-harness template repository.${NC}"
        continue
    fi

    echo ""
    echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
    echo -e "  ${BLUE}Updating:${NC} ${BOLD}$TARGET_ABS${NC}"
    echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"

    (
        cd "$TARGET_ABS"
        # shellcheck disable=SC2086
        "$SCRIPT_DIR/init.sh" --update $PROFILE_FLAG
    )
done
