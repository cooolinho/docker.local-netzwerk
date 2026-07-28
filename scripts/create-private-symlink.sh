#!/bin/bash
# Docker Local Network - Private Project Symlink Helper
# Erstellt oder loescht interaktiv Symlinks in projects/private

set -euo pipefail

# Farben
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
DEFAULT_PRIVATE_DIR="$REPO_ROOT/projects/private"
PRIVATE_DIR="${PRIVATE_PROJECTS_DIR:-$DEFAULT_PRIVATE_DIR}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --private-dir)
      if [[ -z "${2:-}" ]]; then
        echo -e "${RED}Fehler: --private-dir benoetigt einen Pfad.${NC}"
        exit 1
      fi
      PRIVATE_DIR="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Unbekannter Parameter: $1${NC}"
      echo "Nutzung: bash scripts/create-private-symlink.sh [--private-dir /voller/pfad]"
      exit 1
      ;;
  esac
done

print_header() {
  echo -e "${BLUE}================================================${NC}"
  echo -e "${BLUE}Symlink-Assistent fuer projects/private${NC}"
  echo -e "${BLUE}================================================${NC}"
  echo ""
  echo -e "Zielordner: ${YELLOW}$PRIVATE_DIR${NC}"
}

ensure_private_dir() {
  if [[ ! -d "$PRIVATE_DIR" ]]; then
    echo -e "${YELLOW}Hinweis: Zielordner existiert noch nicht, wird erstellt...${NC}"
    mkdir -p "$PRIVATE_DIR"
  fi
}

collect_symlinks() {
  mapfile -t SYMLINKS < <(find "$PRIVATE_DIR" -mindepth 1 -maxdepth 1 -type l -exec basename {} \; | sort)
}

create_symlink() {
  local link_type=""
  local source_path=""
  local link_name=""
  local link_path=""
  local target_path=""
  local type_label=""

  echo ""
  echo "Welche Art von Symlink moechtest du erstellen?"
  echo "  1) Absoluter Symlink (stabil, unabhaengig vom aktuellen Pfad)"
  echo "  2) Relativer Symlink (portabler, wenn ganze Ordnerstruktur verschoben wird)"
  read -rp "Auswahl [1/2]: " link_type

  if [[ "$link_type" != "1" && "$link_type" != "2" ]]; then
    echo -e "${RED}Ungueltige Auswahl. Bitte 1 oder 2 waehlen.${NC}"
    exit 1
  fi

  echo ""
  read -rp "Voller Pfad zum bestehenden Projektordner (Quelle): " source_path

  if [[ -z "$source_path" ]]; then
    echo -e "${RED}Fehler: Quelle darf nicht leer sein.${NC}"
    exit 1
  fi

  if [[ ! -d "$source_path" ]]; then
    echo -e "${RED}Fehler: Quellordner existiert nicht: $source_path${NC}"
    exit 1
  fi

  echo ""
  read -rp "Wie soll der Link in projects/private heissen? " link_name

  if [[ -z "$link_name" ]]; then
    echo -e "${RED}Fehler: Link-Name darf nicht leer sein.${NC}"
    exit 1
  fi

  if [[ "$link_name" == *"/"* ]]; then
    echo -e "${RED}Fehler: Bitte nur den Link-Namen ohne '/'.${NC}"
    exit 1
  fi

  link_path="$PRIVATE_DIR/$link_name"

  if [[ "$link_type" == "1" ]]; then
    target_path="$source_path"
    type_label="absolut"
  else
    if command -v realpath >/dev/null 2>&1; then
      target_path="$(realpath --relative-to="$PRIVATE_DIR" "$source_path")"
    else
      echo -e "${RED}Fehler: 'realpath' wird fuer relative Symlinks benoetigt.${NC}"
      echo -e "${YELLOW}Tipp: Nutze Typ 1 (absolut) oder installiere coreutils.${NC}"
      exit 1
    fi
    type_label="relativ"
  fi

  if [[ -e "$link_path" || -L "$link_path" ]]; then
    echo ""
    echo -e "${YELLOW}Am Ziel existiert bereits etwas: $link_path${NC}"
    if [[ -L "$link_path" ]]; then
      echo -e "Aktuelles Ziel: ${YELLOW}$(readlink "$link_path")${NC}"
    else
      echo -e "${RED}Achtung: Das Ziel ist kein Symlink.${NC}"
    fi

    read -rp "Soll es ersetzt werden? [y/N]: " replace
    if [[ "${replace,,}" == "y" ]]; then
      rm -rf "$link_path"
    else
      echo -e "${YELLOW}Abgebrochen. Nichts geaendert.${NC}"
      exit 0
    fi
  fi

  ln -s "$target_path" "$link_path"

  echo ""
  echo -e "${GREEN}✓ Symlink erstellt.${NC}"
  echo -e "  Typ:   ${YELLOW}$type_label${NC}"
  echo -e "  Link:  ${YELLOW}$link_path${NC}"
  echo -e "  Ziel:  ${YELLOW}$target_path${NC}"
}

delete_symlink() {
  local selection=""
  local selected=""
  local selected_path=""
  local selected_target=""
  local confirm=""

  collect_symlinks

  if [[ ${#SYMLINKS[@]} -eq 0 ]]; then
    echo ""
    echo -e "${YELLOW}Keine Symlinks in $PRIVATE_DIR gefunden.${NC}"
    exit 0
  fi

  echo ""
  echo "Welche Symlink-Verknuepfung soll geloescht werden?"
  for i in "${!SYMLINKS[@]}"; do
    selected_path="$PRIVATE_DIR/${SYMLINKS[$i]}"
    selected_target="$(readlink "$selected_path" 2>/dev/null || echo '?')"
    echo "  $((i + 1))) ${SYMLINKS[$i]} -> $selected_target"
  done

  read -rp "Auswahl [1-${#SYMLINKS[@]}]: " selection
  if ! [[ "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#SYMLINKS[@]} )); then
    echo -e "${RED}Ungueltige Auswahl.${NC}"
    exit 1
  fi

  selected="${SYMLINKS[$((selection - 1))]}"
  selected_path="$PRIVATE_DIR/$selected"
  selected_target="$(readlink "$selected_path" 2>/dev/null || echo '?')"

  echo ""
  echo -e "Ausgewaehlt: ${YELLOW}$selected${NC} -> ${YELLOW}$selected_target${NC}"
  read -rp "Wirklich loeschen? [y/N]: " confirm

  if [[ "${confirm,,}" != "y" ]]; then
    echo -e "${YELLOW}Abgebrochen. Nichts geaendert.${NC}"
    exit 0
  fi

  rm "$selected_path"
  echo -e "${GREEN}✓ Symlink geloescht: $selected_path${NC}"
}

print_header
ensure_private_dir

echo ""
echo "Was moechtest du tun?"
echo "  1) Symlink erstellen"
echo "  2) Symlink loeschen"
read -rp "Auswahl [1/2]: " ACTION

case "$ACTION" in
  1)
    create_symlink
    ;;
  2)
    delete_symlink
    ;;
  *)
    echo -e "${RED}Ungueltige Auswahl. Bitte 1 oder 2 waehlen.${NC}"
    exit 1
    ;;
esac

echo ""
echo "Pruefen mit:"
echo "  ls -la \"$PRIVATE_DIR\""

