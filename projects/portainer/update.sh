#!/bin/bash

# Portainer Update Script
# Lädt die neueste Version von Portainer herunter und installiert sie
#
# Verwendung:
#   ./update.sh                    # Neueste Version (latest)
#   ./update.sh 2.18.3             # Spezifische Version
#   ./update.sh --backup           # Mit Backup vor Update
#   ./update.sh 2.18.3 --backup    # Spezifische Version mit Backup
#   ./update.sh --help             # Hilfe anzeigen

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Standard-Werte
PORTAINER_VERSION="latest"
CREATE_BACKUP=false
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# ============================================================================
# Hilfsfunktionen
# ============================================================================

show_help() {
    echo -e "${BLUE}Portainer Update Script${NC}"
    echo ""
    echo "Verwendung:"
    echo "  ./update.sh                    Neueste Version installieren (latest)"
    echo "  ./update.sh VERSION            Spezifische Version installieren (z.B. 2.18.3)"
    echo "  ./update.sh --backup           Mit Backup vor Update"
    echo "  ./update.sh VERSION --backup   Spezifische Version mit Backup"
    echo "  ./update.sh --help             Diese Hilfe anzeigen"
    echo ""
    echo "Beispiele:"
    echo "  ./update.sh                    # Aktualisiere auf neueste Version"
    echo "  ./update.sh 2.18.0             # Installiere spezifische Version 2.18.0"
    echo "  ./update.sh --backup           # Aktuelle Version mit Backup"
    echo ""
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker nicht gefunden!${NC}"
        exit 1
    fi

    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}✗ Docker-Daemon läuft nicht!${NC}"
        exit 1
    fi
}

create_backup() {
    echo -e "\n${YELLOW}[2/5] Erstelle Backup des portainer-data Volume...${NC}"

    BACKUP_DIR="$SCRIPT_DIR/backups"
    mkdir -p "$BACKUP_DIR"

    BACKUP_DATETIME=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/portainer-backup-$BACKUP_DATETIME.tar.gz"

    if docker volume inspect portainer-data > /dev/null 2>&1; then
        docker run --rm \
            -v portainer-data:/data \
            -v "$BACKUP_DIR":/backup \
            alpine tar czf /backup/portainer-backup-$BACKUP_DATETIME.tar.gz /data

        echo -e "${GREEN}✓ Backup erstellt: portainer-backup-$BACKUP_DATETIME.tar.gz${NC}"
        echo -e "${BLUE}   Pfad: $BACKUP_FILE${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ portainer-data Volume nicht gefunden, überspringe Backup${NC}"
        return 0
    fi
}

pull_image() {
    echo -e "\n${YELLOW}[3/5] Lade Portainer Image herunter (Version: $PORTAINER_VERSION)...${NC}"

    if [ "$PORTAINER_VERSION" = "latest" ]; then
        docker pull portainer/portainer-ce:latest
    else
        docker pull "portainer/portainer-ce:$PORTAINER_VERSION"
    fi

    echo -e "${GREEN}✓ Image erfolgreich heruntergeladen${NC}"
}

stop_and_rebuild() {
    echo -e "\n${YELLOW}[4/5] Stoppe und baue Container neu...${NC}"

    cd "$SCRIPT_DIR"

    # Stoppe Container
    echo -e "${YELLOW}  → Stoppe Portainer Container...${NC}"
    docker-compose down

    # Starte neu
    echo -e "${YELLOW}  → Starte Portainer neu...${NC}"
    docker-compose up -d

    echo -e "${GREEN}✓ Container erfolgreich neugestartet${NC}"
}

show_logs() {
    echo -e "\n${YELLOW}[5/5] Portainer Logs (erste 30 Sekunden)...${NC}"
    echo -e "${BLUE}================================================${NC}"

    cd "$SCRIPT_DIR"

    # Zeige Logs für 5 Sekunden oder bis zum Abschluss
    timeout 30s docker-compose logs -f || true

    echo -e "${BLUE}================================================${NC}"
}

# ============================================================================
# Argument-Verarbeitung
# ============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            exit 0
            ;;
        --backup)
            CREATE_BACKUP=true
            shift
            ;;
        *)
            # Annahme: erste nicht-Option ist die Version
            if [[ $1 != --* ]]; then
                PORTAINER_VERSION="$1"
            fi
            shift
            ;;
    esac
done

# ============================================================================
# Hauptprogramm
# ============================================================================

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}🐋 Portainer Update Script${NC}"
echo -e "${BLUE}================================================${NC}"

check_docker

# Zeige geplante Aktion
echo -e "\n${BLUE}Geplante Aktion:${NC}"
echo -e "  Version:       ${GREEN}$PORTAINER_VERSION${NC}"
echo -e "  Backup:        $([ "$CREATE_BACKUP" = true ] && echo -e "${GREEN}Ja${NC}" || echo -e "${YELLOW}Nein${NC}")${NC}"
echo -e "  Arbeitsverzeichnis: ${GREEN}$SCRIPT_DIR${NC}"

read -p "Fortfahren? (j/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Jj]$ ]]; then
    echo -e "${YELLOW}Update abgebrochen.${NC}"
    exit 0
fi

# Schritt 1: Backup (optional)
if [ "$CREATE_BACKUP" = true ]; then
    echo -e "\n${YELLOW}[1/5] Backup-Phase${NC}"
    create_backup
else
    echo -e "\n${YELLOW}[1/5] Überspringe Backup...${NC}"
fi

# Schritt 2: Image pullen
pull_image

# Schritt 3: Container stoppen und neu starten
stop_and_rebuild

# Schritt 4: Logs anzeigen
show_logs

# Erfolgs-Meldung
echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}✓ Update erfolgreich abgeschlossen!${NC}"
echo -e "${GREEN}================================================${NC}"

echo -e "\n${BLUE}Portainer verfügbar unter:${NC}"
echo -e "  ${GREEN}http://portainer.docker.lan${NC}"

echo -e "\n${BLUE}Weitere Befehle:${NC}"
echo -e "  docker-compose -f $SCRIPT_DIR/docker-compose.yml logs -f portainer"
echo -e "  docker-compose -f $SCRIPT_DIR/docker-compose.yml ps"
echo ""

