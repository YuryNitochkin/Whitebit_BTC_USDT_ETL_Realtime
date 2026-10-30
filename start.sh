#!/usr/bin/env bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🚀 Whitebit BTC USDT ETL Realtime starting ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed. Please install Docker Desktop.${NC}"
    exit 1
fi

# 2. Start docker compose in the background
echo -e "\n${YELLOW}[1/3] Building and starting containers...${NC}"
docker compose up -d > /dev/null 2>&1 &

# 3. Wait for ClickHouse to be healthy AND parse_trades table to have data
spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
spin_idx=0
MAX_WAIT=600
COUNTER=0
STATUS_MSG="[2/3] Waiting for data pipeline to initialize and receive first trades..."

echo -e -n "${YELLOW}${STATUS_MSG} ${NC}"

# Wait for ClickHouse to have at least one row
until COUNT=$(docker exec clickhouse clickhouse-client --query 'SELECT count() FROM analytics.parse_trades' 2>/dev/null) && [ "$COUNT" -gt 0 ]; do
    printf "\r\033[K${YELLOW}${STATUS_MSG} ${spinner[$spin_idx]}${NC}"
    spin_idx=$(( (spin_idx + 1) % 10 ))
    sleep 2
    COUNTER=$((COUNTER + 2))
    if [ $COUNTER -ge $MAX_WAIT ]; then
        echo -e "\n${RED}⚠️  Wait time exceeded. Data might not have arrived yet.${NC}"
        break
    fi
done

echo -e "\n${GREEN}✔ Data received!${NC}"

# 4. Force Rill to re-read metrics view
echo -e "${YELLOW}[3/3] Forcing Rill to refresh metrics view...${NC}"
docker exec rill-data rill project refresh --metrics-view parse_trades_metrics --local > /dev/null 2>&1 || true
sleep 1m
echo -e "${GREEN}✔ Metrics view refreshed!${NC}"

# 5. Link
LINK="http://localhost:9009/explore/parse_trades_metrics"

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   🎉 Project successfully launched!${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "\nOpen the following link in your browser:\n"
echo -e "   👉  ${BLUE}${LINK}${NC}\n"
echo -e "To stop the project, run: ${YELLOW}docker compose down${NC}\n"