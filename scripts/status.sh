#!/bin/bash
# Docker Local Network - Status Script
# Zeigt Status aller Services

# Farben
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Docker Local Network - Status${NC}"
echo -e "${BLUE}================================================${NC}"

echo -e "\n${BLUE}Container Status:${NC}"
echo ""

# Alle Container Status
for project_dir in traefik projects/*/; do
    if [ -f "$project_dir/docker-compose.yml" ]; then
        project_name=$(basename "$project_dir")
        echo -e "${YELLOW}$project_name:${NC}"

        # Finde Container für dieses Projekt
        if [ "$project_name" == "traefik" ]; then
            container_name="traefik"
        else
            # Für Projects: Container nach dem Verzeichnisnamen suchen
            container_names=$(docker-compose -f "$project_dir/docker-compose.yml" config --services)
        fi

        # Zeige Status
        docker ps -a --filter "name=$project_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true
        echo ""
    fi
done

echo -e "${BLUE}Netzwerk-Status:${NC}"
if docker network inspect docker-local-network > /dev/null 2>&1; then
    echo -e "${GREEN}✓ docker-local-network existiert${NC}"
    echo ""
    echo -e "Verbundene Container:"
    docker network inspect docker-local-network --format="{{range .Containers}}  - {{.Name}}: {{.IPv4Address}}\n{{end}}"
else
    echo -e "${RED}✗ docker-local-network nicht vorhanden${NC}"
fi

echo -e "\n${BLUE}Traefik Dashboard:${NC}"
if docker ps | grep -q traefik; then
    echo -e "${GREEN}✓ http://traefik.docker.local:8080${NC}"
else
    echo -e "${RED}✗ Traefik läuft nicht${NC}"
fi

echo -e "\n${BLUE}Quick Links:${NC}"
echo -e "  http://dashy.docker.local"
echo -e "  http://it-tools.docker.local"
echo -e "  http://planka.docker.local"
echo -e "  http://traefik.docker.local:8080"

echo -e "\n${BLUE}Commands:${NC}"
echo -e "  Alle starten:   ${GREEN}bash scripts/start-all.sh${NC}"
echo -e "  Alle stoppen:   ${RED}bash scripts/stop-all.sh${NC}"
echo -e "  Logs:           ${YELLOW}docker-compose logs -f [service]${NC}"
echo ""

