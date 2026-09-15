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

if [ $# -eq 0 ]; then
    if [ "$CURRENT_DIR" = "$SCRIPT_DIR" ]; then
        echo -e "${YELLOW}${BOLD}Uso:${NC}"
        echo -e "  ./update.sh <ruta-a-tu-proyecto> [<otro-proyecto>...]"
        echo ""
        echo -e "Ejemplos:"
        echo -e "  ./update.sh ../mi-proyecto"
        echo -e "  ./update.sh /ruta/hacia/otro-repo"
        echo ""
        echo -e "${BLUE}O directamente desde la carpeta de tu proyecto destino:${NC}"
        echo -e "  cd mi-proyecto"
        echo -e "  $SCRIPT_DIR/update.sh"
        exit 1
    else
        TARGETS=("$CURRENT_DIR")
    fi
else
    TARGETS=("$@")
fi

for TARGET in "${TARGETS[@]}"; do
    TARGET_ABS="$(cd "$TARGET" 2>/dev/null && pwd -P || true)"
    if [ -z "$TARGET_ABS" ] || [ ! -d "$TARGET_ABS" ]; then
        echo -e "${RED}✗ Error: Directorio no encontrado:${NC} $TARGET"
        continue
    fi

    if [ "$TARGET_ABS" = "$SCRIPT_DIR" ]; then
        echo -e "${YELLOW}⚠ Omitiendo la plantilla maestra de agent-harness.${NC}"
        continue
    fi

    echo ""
    echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
    echo -e "  ${BLUE}Actualizando:${NC} ${BOLD}$TARGET_ABS${NC}"
    echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"

    (
        cd "$TARGET_ABS"
        "$SCRIPT_DIR/init.sh" --update
    )
done
