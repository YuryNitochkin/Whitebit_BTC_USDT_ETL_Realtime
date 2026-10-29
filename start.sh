#!/usr/bin/env bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🚀 Starting Data Engineering Portfolio Project 1 ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed. Please install Docker Desktop.${NC}"
    exit 1
fi

# 2. Start docker compose in the background
echo -e "\n${YELLOW}[1/3] Building and starting containers...${NC}"
docker compose up -d > /dev/null 2>&1 &

# 3. Spinner
spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
spin_idx=0
MAX_WAIT=60
COUNTER=0

echo -e -n "${YELLOW}[2/3] Waiting for Rill to initialize (this may take up to 30 seconds)... ${NC}"

until curl -s http://localhost:9009 > /dev/null; do
    # \r returns cursor to start of line, then prints spinner
    printf "\r${YELLOW}[2/3] Waiting for Rill to initialize (this may take up to 30 seconds)... ${spinner[$spin_idx]}${NC}"
    spin_idx=$(( (spin_idx + 1) % 10 ))
    sleep 1
    COUNTER=$((COUNTER + 1))
    if [ $COUNTER -ge $MAX_WAIT ]; then
        echo -e "\n${YELLOW}⚠️  Wait time exceeded. Rill might still be starting.${NC}"
        break
    fi
done

# Final state of the lineecho -e "\r${GREEN}[2/3] Rill initialized successfully! ${NC}                                                    "
# 4. Link
LINK="http://localhost:9009/explore/parse_trades_metrics?tr=60m+as+of+latest%2Fm%2B1m"

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   🎉 Project successfully launched!${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "\nOpen the following link in your browser:\n"
echo -e "   👉  ${BLUE}${LINK}${NC}\n"
echo -e "To stop the project, run: ${YELLOW}docker compose down${NC}\n"
