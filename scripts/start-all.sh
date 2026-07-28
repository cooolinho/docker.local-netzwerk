#!/bin/bash
# Docker Local Network - Startup Script
# Startet alle Services in der richtigen Reihenfolge

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Docker Local Network - Startup${NC}"
echo -e "${BLUE}================================================${NC}"

# Arbeitsverzeichnis
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 1. Prüfe, ob Netzwerk existiert
echo -e "\n${YELLOW}[1/5] Prüfe Docker Network...${NC}"
if ! docker network inspect docker_lan_network > /dev/null 2>&1; then
    echo -e "${YELLOW}Erstelle docker_lan_network...${NC}"
    docker network create docker_lan_network --driver bridge
    echo -e "${GREEN}✓ Network erstellt${NC}"
else
    echo -e "${GREEN}✓ Network existiert${NC}"
fi

# 2. Starte Traefik
echo -e "\n${YELLOW}[2/5] Starte Traefik...${NC}"
docker-compose up -d traefik
echo -e "${GREEN}✓ Traefik wird gestartet${NC}"

# Warte kurz bis Traefik ready ist
sleep 3

# 3. Starte alle Projekte
echo -e "\n${YELLOW}[3/5] Starte Projekte...${NC}"
for project_dir in projects/*/; do
    project_name=$(basename "$project_dir")
    echo -e "${YELLOW}  → $project_name...${NC}"
    cd "$project_dir"
    docker-compose up -d
    cd "$SCRIPT_DIR"
    echo -e "${GREEN}    ✓ $project_name gestartet${NC}"
done

# 4. Warte bis Services ready sind
echo -e "\n${YELLOW}[4/5] Warte bis Services bereit sind...${NC}"
sleep 5

# 5. Zeige Status
echo -e "\n${YELLOW}[5/5] Service-Status:${NC}"
docker-compose ps
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}✓ Startup abgeschlossen!${NC}"
echo -e "${GREEN}================================================${NC}"

# Zeige URLs
echo -e "\n${BLUE}Verfügbare Services:${NC}"
echo -e "  🏠 Dashy:            ${GREEN}http://dashy.docker.lan${NC}"
echo -e "  🛠️ IT-Tools:         ${GREEN}http://it-tools.docker.lan${NC}"
echo -e "  📋 Planka:           ${GREEN}http://planka.docker.lan${NC}"
echo -e "  🔍 Traefik Dashboard: ${GREEN}http://traefik.docker.lan${NC}"

echo -e "\n${BLUE}Logs anzeigen:${NC}"
echo -e "  docker-compose logs -f traefik"
echo -e "  docker logs -f dashy"
echo ""

