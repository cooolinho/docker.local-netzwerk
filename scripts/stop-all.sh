#!/bin/bash
# Docker Local Network - Shutdown Script
# Fährt alle Services sauber herunter

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Docker Local Network - Shutdown${NC}"
echo -e "${BLUE}================================================${NC}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

# 1. Stoppe alle Projekte
echo -e "\n${YELLOW}[1/2] Stoppe Projekte...${NC}"
for project_dir in projects/*/; do
    project_name=$(basename "$project_dir")
    echo -e "${YELLOW}  → $project_name...${NC}"
    cd "$project_dir"
    docker-compose down 2>/dev/null || true
    cd "$SCRIPT_DIR/.."
done

# 2. Stoppe Traefik
echo -e "\n${YELLOW}[2/2] Stoppe Traefik...${NC}"
docker-compose down traefik 2>/dev/null || true

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}✓ Shutdown abgeschlossen!${NC}"
echo -e "${GREEN}================================================${NC}"

