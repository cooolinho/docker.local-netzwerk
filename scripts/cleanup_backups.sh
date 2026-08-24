#!/bin/bash

##############################################################################
# Database Backup Cleanup Script
# Removes old backup files based on retention period
# Usage: ./cleanup_backups.sh [RETENTION_DAYS]
##############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backups"
BACKUP_LOG="$BACKUP_DIR/backup.log"

# Load environment if exists
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    set +u
    source "$PROJECT_ROOT/.env"
    set -u
fi

# Default retention: 30 days or argument
RETENTION_DAYS=${1:-${BACKUP_RETENTION_DAYS:-30}}

# Logging
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp}] [${level}] ${message}" | tee -a "$BACKUP_LOG"
}

log_info() {
    echo -e "${BLUE}ℹ️  $@${NC}"
    log "INFO" "$@"
}

log_success() {
    echo -e "${GREEN}✅ $@${NC}"
    log "SUCCESS" "$@"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $@${NC}"
    log "WARNING" "$@"
}

# Main cleanup logic
main() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_warning "Backup directory not found: $BACKUP_DIR"
        exit 0
    fi

    log_info "Starting cleanup: Removing backups older than $RETENTION_DAYS days"

    local now=$(date +%s)
    local cutoff=$((now - RETENTION_DAYS * 86400))
    local cleaned=0

    while IFS= read -r backup_file; do
        local file_time

        # Cross-platform file timestamp extraction
        if [[ -f "$backup_file" ]]; then
            file_time=$(stat -f%m "$backup_file" 2>/dev/null || stat -c%Y "$backup_file" 2>/dev/null || echo 0)

            if [[ $file_time -lt $cutoff ]]; then
                local file_size=$(du -h "$backup_file" | cut -f1)
                log_warning "Removing: $(basename "$backup_file") ($file_size)"
                rm -f "$backup_file"
                ((cleaned++))
            fi
        fi
    done < <(find "$BACKUP_DIR" -name "backup_*.zip" -type f 2>/dev/null || true)

    if [[ $cleaned -gt 0 ]]; then
        log_success "Cleanup complete: Removed $cleaned backup file(s)"
    else
        log_info "No backups to clean up"
    fi
}

main "$@"

