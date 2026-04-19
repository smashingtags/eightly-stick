#!/bin/bash
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
#  Portable AI USB - Dashboard (macOS)
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'
DIM='\033[90m'; BOLD='\033[1m'; RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
DASHBOARD="$ROOT_DIR/dashboard/server.mjs"

# Find Node.js
NODE=""
for d in "$BIN_DIR"/node-v*-darwin-*/; do
    [ -f "$d/bin/node" ] && NODE="$d/bin/node" && break
done
[ -z "$NODE" ] && NODE=$(which node 2>/dev/null)
if [ -z "$NODE" ]; then
    echo -e "  ${RED}[ERROR] Node.js not found. Run setup_first_time.sh first.${RESET}"
    exit 1
fi

# Portable data
DATA_DIR="$ROOT_DIR/data"
export CLAUDE_CONFIG_DIR="$DATA_DIR/openclaude"
export XDG_CONFIG_HOME="$DATA_DIR/config"
export XDG_DATA_HOME="$DATA_DIR/app_data"
mkdir -p "$CLAUDE_CONFIG_DIR" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"

echo ""
echo -e "${CYAN}=========================================================${RESET}"
echo -e "  ${BOLD}Portable AI USB - Configuration Dashboard${RESET}"
echo -e "${CYAN}=========================================================${RESET}"
echo ""

# Check dashboard exists
if [ ! -f "$DASHBOARD" ]; then
    echo -e "  ${RED}[ERROR] Dashboard files not found!${RESET}"
    echo -e "  ${YELLOW}Expected: $DASHBOARD${RESET}"
    exit 1
fi

# Check port 3000
if lsof -i :3000 >/dev/null 2>&1 || lsof -i :3000 2>/dev/null | grep -q ':3000 ' || lsof -i :3000 >/dev/null 2>&1; then
    echo -e "  ${YELLOW}[WARNING] Port 3000 is already in use!${RESET}"
    echo ""
    echo -e "  ${CYAN}1)${RESET} Open browser anyway"
    echo -e "  ${CYAN}2)${RESET} Cancel"
    echo ""
    read -p "  Select (1 or 2): " PORT_CHOICE
    if [ "$PORT_CHOICE" = "1" ]; then
        open "http://localhost:3000" 2>/dev/null &
        echo -e "  ${GREEN}[OK] Browser opened!${RESET}"
        exit 0
    fi
    echo -e "  ${DIM}Cancelled.${RESET}"
    exit 0
fi

echo -e "  ${CYAN}[~] Starting dashboard server...${RESET}"
echo -e "  ${DIM}Dashboard will be available at ${BOLD}http://localhost:3000${RESET}"
echo ""

# Open browser
if command -v open &>/dev/null; then
    (sleep 1 && open "http://localhost:3000") &
elif command -v termux-open-url &>/dev/null; then
    (sleep 1 && termux-open-url "http://localhost:3000") &
fi

echo -e "  ${GREEN}[OK] Browser opening...${RESET}"
echo -e "  ${DIM}Press Ctrl+C to stop the dashboard.${RESET}"
echo ""

"$NODE" "$DASHBOARD"
