#!/bin/bash

# Portainer Rollback Script
# Stellt eine Portainer Installation aus einem Backup wieder her
#
# Verwendung:
#   ./rollback.sh backup-name             # Restore von Backup-Datei
#   ./rollback.sh --list                  # Verfügbare Backups anzeigen
#   ./rollback.sh --help                  # Hilfe anzeigen

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="$SCRIPT_DIR/backups"

# ============================================================================
# Hilfsfunktionen
# ============================================================================

show_help() {
    echo -e "${BLUE}Portainer Rollback Script${NC}"
    echo ""
    echo "Stellt Portainer aus einem Backup wieder her"
    echo ""
    echo "Verwendung:"
    echo "  ./rollback.sh backup-name           Restore von spezifischem Backup"
    echo "  ./rollback.sh --list                Verfügbare Backups anzeigen"
    echo "  ./rollback.sh --latest              Neuestes Backup verwenden"
    echo "  ./rollback.sh --help                Diese Hilfe anzeigen"
    echo ""
    echo "Beispiele:"
    echo "  ./rollback.sh portainer-backup-20240726_143022.tar.gz"
    echo "  ./rollback.sh portainer-backup-20240726_143022  # auch ohne .tar.gz"
    echo "  ./rollback.sh --latest  # Stellt neuestes Backup wieder her"
    echo ""
}

list_backups() {
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}Kein Backup-Verzeichnis gefunden${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Verfügbare Backups:${NC}"
    echo ""
    
    if ls "$BACKUP_DIR"/portainer-backup-*.tar.gz 1> /dev/null 2>&1; then
        ls -lh "$BACKUP_DIR"/portainer-backup-*.tar.gz | awk '{print "  " $9, "(" $5 ")"}'
    else
        echo -e "${YELLOW}Keine Backups gefunden${NC}"
        return 1
    fi
    
    echo ""
}

get_latest_backup() {
    local latest=$(ls -t "$BACKUP_DIR"/portainer-backup-*.tar.gz 2>/dev/null | head -1)
    
    if [ -z "$latest" ]; then
        echo -e "${RED}✗ Kein Backup gefunden!${NC}"
        return 1
    fi
    
    echo "$latest"
}

restore_backup() {
    local backup_file="$1"
    
    # Überprüfe ob Datei existiert
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}✗ Backup-Datei nicht gefunden: $backup_file${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Restore Portainer Backup...${NC}"
    echo -e "${BLUE}Backup: $(basename "$backup_file")${NC}"
    echo -e "${BLUE}Größe: $(ls -lh "$backup_file" | awk '{print $5}')${NC}"
    echo ""
    
    read -p "Fortfahren? (j/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Jj]$ ]]; then
        echo -e "${YELLOW}Rollback abgebrochen.${NC}"
        return 0
    fi
    
    echo -e "\n${YELLOW}[1/3] Stoppe Portainer Container...${NC}"
    cd "$SCRIPT_DIR"
    docker-compose down || true
    
    echo -e "\n${YELLOW}[2/3] Stelle Daten aus Backup wieder her...${NC}"
    docker run --rm \
        -v portainer-data:/data \
        -v "$(dirname "$backup_file")":/backup \
        alpine tar xzf "/backup/$(basename "$backup_file")" -C /
    
    echo -e "${GREEN}✓ Daten wiederhergestellt${NC}"
    
    echo -e "\n${YELLOW}[3/3] Starte Portainer neu...${NC}"
    docker-compose up -d
    
    echo -e "\n${GREEN}================================================${NC}"
    echo -e "${GREEN}✓ Rollback erfolgreich!${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
    echo -e "${BLUE}Portainer verfügbar unter:${NC}"
    echo -e "  ${GREEN}http://portainer.docker.lan${NC}"
}

# ============================================================================
# Hauptprogramm
# ============================================================================

if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

case "$1" in
    --help)
        show_help
        exit 0
        ;;
    --list)
        list_backups
        exit 0
        ;;
    --latest)
        latest=$(get_latest_backup)
        if [ $? -eq 0 ]; then
            echo -e "${BLUE}Verwende neuestes Backup: $(basename "$latest")${NC}"
            restore_backup "$latest"
        fi
        exit $?
        ;;
    *)
        # Versuch Backup-Datei zu finden
        backup_name="$1"
        
        # Falls .tar.gz nicht enthalten, hinzufügen
        if [[ ! "$backup_name" =~ .tar.gz$ ]]; then
            backup_name="$BACKUP_DIR/$backup_name.tar.gz"
        else
            # Falls kompletter Pfad nicht vorhanden, im Backup-Verzeichnis suchen
            if [[ ! "$backup_name" =~ ^/ ]]; then
                backup_name="$BACKUP_DIR/$backup_name"
            fi
        fi
        
        if [ -f "$backup_name" ]; then
            restore_backup "$backup_name"
        else
            echo -e "${RED}✗ Backup nicht gefunden: $1${NC}"
            echo ""
            list_backups
            exit 1
        fi
        ;;
esac
