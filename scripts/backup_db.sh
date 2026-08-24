#!/bin/bash

##############################################################################
# Database Backup Script for Docker Local Network
# Supports: PostgreSQL, MySQL, MariaDB
# Features: Interactive credential input, ZIP compression, Cron scheduling
# Usage:
#   ./scripts/backup_db.sh                # Interactive mode
#   ./scripts/backup_db.sh --auto         # Run auto backup from legacy .backup-config
#   ./scripts/backup_db.sh --auto --config FILE
#                                         # Run auto backup from a specific config
#   ./scripts/backup_db.sh --setup-cron   # Create Cron entry
#   ./scripts/backup_db.sh --remove-cron  # Remove Cron entry
#   ./scripts/backup_db.sh --list-cron    # List Cron entries
#   ./scripts/backup_db.sh --cleanup 30   # Delete backups older than 30 days
#   ./scripts/backup_db.sh --list         # List existing backup ZIP files
##############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_ROOT/backups"
BACKUP_LOG="$BACKUP_DIR/backup.log"
ENV_FILE="$PROJECT_ROOT/.env"

# Load environment if exists
if [[ -f "$ENV_FILE" ]]; then
    set +u  # Allow unset variables temporarily
    # Support .env files with Windows line endings (CRLF)
    # shellcheck disable=SC1090
    source <(sed 's/\r$//' "$ENV_FILE")
    set -u
fi

# Default values
BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
echo "Using backup retention days: $BACKUP_RETENTION_DAYS"

BACKUP_SCHEDULE=${BACKUP_SCHEDULE:-"0 2 * * *"}  # Default: 02:00 daily
BACKUP_CONFIG_DIR=${BACKUP_CONFIG_DIR:-"$PROJECT_ROOT/.backup-configs"}

# Runtime state for interactive DB discovery
DB_DISCOVERY_COUNT=0
SELECTED_DB_INDEX=-1
SELECTED_DB_CONTAINER=""
DB_DISCOVERY_NAMES=()
DB_DISCOVERY_IMAGES=()
DB_DISCOVERY_TYPES=()
DB_DISCOVERY_PROJECTS=()
DB_DISCOVERY_ENV_FILES=()

##############################################################################
# Logging Functions
##############################################################################

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

log_error() {
    echo -e "${RED}❌ $@${NC}"
    log "ERROR" "$@"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $@${NC}"
    log "WARNING" "$@"
}

##############################################################################
# Helper Functions
##############################################################################

ensure_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Created backup directory: $BACKUP_DIR"
    fi
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Required command not found: $1"
        return 1
    fi
}

validate_docker_network() {
    if ! docker network inspect docker_lan_network &> /dev/null; then
        log_error "Docker network 'docker_lan_network' not found"
        return 1
    fi
}

ensure_backup_config_dir() {
    if [[ -e "$BACKUP_CONFIG_DIR" && ! -d "$BACKUP_CONFIG_DIR" ]]; then
        log_error "Backup config path is not a directory: $BACKUP_CONFIG_DIR"
        return 1
    fi

    if ! mkdir -p "$BACKUP_CONFIG_DIR"; then
        log_error "Failed to create backup config directory: $BACKUP_CONFIG_DIR"
        return 1
    fi

    if ! chmod 700 "$BACKUP_CONFIG_DIR"; then
        log_error "Failed to secure backup config directory: $BACKUP_CONFIG_DIR"
        return 1
    fi
}

backup_config_file_for() {
    local name=${1:-manual-${DB_TYPE:-database}}
    local safe_name

    safe_name=$(printf '%s' "$name" | tr -c '[:alnum:]_.-' '_')
    printf '%s/%s.conf\n' "$BACKUP_CONFIG_DIR" "$safe_name"
}

load_backup_config() {
    local config_file=$1
    local load_status

    if [[ ! -f "$config_file" ]]; then
        log_error "No backup configuration found at $config_file"
        return 1
    fi

    set +u
    if source <(sed 's/\r$//' "$config_file"); then
        load_status=0
    else
        load_status=$?
    fi
    set -u

    return "$load_status"
}

save_backup_config() {
    local config_file=$1
    local temp_file
    local old_umask

    ensure_backup_config_dir || return 1

    old_umask=$(umask)
    umask 077
    if ! temp_file=$(mktemp "$BACKUP_CONFIG_DIR/.backup-config.XXXXXX"); then
        umask "$old_umask"
        log_error "Failed to create temporary backup configuration"
        return 1
    fi

    if ! {
        printf 'DB_CONTAINER=%q\n' "${SELECTED_DB_CONTAINER:-}"
        printf 'DB_TYPE=%q\n' "${DB_TYPE:-}"
        printf 'DB_HOST=%q\n' "${DB_HOST:-}"
        printf 'DB_PORT=%q\n' "${DB_PORT:-}"
        printf 'DB_USER=%q\n' "${DB_USER:-}"
        printf 'DB_PASSWORD=%q\n' "${DB_PASSWORD:-}"
        printf 'DB_NAME=%q\n' "${DB_NAME:-}"
        printf 'BACKUP_RETENTION_DAYS=%q\n' "${BACKUP_RETENTION_DAYS:-30}"
    } > "$temp_file"; then
        rm -f "$temp_file"
        umask "$old_umask"
        log_error "Failed to write backup configuration"
        return 1
    fi

    if ! chmod 600 "$temp_file" || ! mv -f "$temp_file" "$config_file"; then
        rm -f "$temp_file"
        umask "$old_umask"
        log_error "Failed to save backup configuration: $config_file"
        return 1
    fi

    umask "$old_umask"
}

get_env_value_from_file() {
    local key=$1
    local file=$2

    awk -v k="$key" '
        {
            sub(/\r$/, "", $0)
            if ($0 ~ /^[[:space:]]*#/ || $0 ~ /^[[:space:]]*$/) {
                next
            }

            line = $0
            sub(/^[[:space:]]*export[[:space:]]+/, "", line)
            pos = index(line, "=")
            if (pos == 0) {
                next
            }

            name = substr(line, 1, pos - 1)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
            if (name != k) {
                next
            }

            value = substr(line, pos + 1)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            if ((value ~ /^".*"$/) || (value ~ /^'\''.*'\''$/)) {
                value = substr(value, 2, length(value) - 2)
            }
            print value
        }
    ' "$file" | tail -n1
}

first_non_empty_env_value() {
    local env_file=$1
    shift
    local key
    local value

    for key in "$@"; do
        value=$(get_env_value_from_file "$key" "$env_file")
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    done

    return 1
}

resolve_env_file_for_container() {
    local container_name=$1
    local project_workdir
    local project_name
    local candidate

    project_workdir=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' "$container_name" 2>/dev/null || true)
    project_name=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$container_name" 2>/dev/null || true)

    if [[ -n "$project_workdir" && -f "$project_workdir/.env" ]]; then
        echo "$project_workdir/.env"
        return 0
    fi

    if [[ -n "$project_name" ]]; then
        candidate="$PROJECT_ROOT/projects/$project_name/.env"
        if [[ -f "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    fi

    echo ""
}

resolve_effective_db_host_for_exec() {
    local host=$1
    if [[ -n "$SELECTED_DB_CONTAINER" && "$host" == "$SELECTED_DB_CONTAINER" ]]; then
        echo "127.0.0.1"
    else
        echo "$host"
    fi
}

run_pg_isready() {
    local host=$1
    local port=$2
    local user=$3
    local database=$4
    local password=$5
    if command -v pg_isready &> /dev/null; then
        PGPASSWORD="$password" pg_isready -h "$host" -p "$port" -U "$user" -d "$database" &> /dev/null
        return $?
    fi

    if [[ -n "$SELECTED_DB_CONTAINER" ]]; then
        local effective_host
        effective_host=$(resolve_effective_db_host_for_exec "$host")
        docker exec -e PGPASSWORD="$password" "$SELECTED_DB_CONTAINER" \
            pg_isready -h "$effective_host" -p "$port" -U "$user" -d "$database" &> /dev/null
        return $?
    fi

    log_error "pg_isready not found locally and no selected DB container for docker exec fallback"
    return 1
}

run_pg_dump() {
    local host=$1
    local port=$2
    local user=$3
    local database=$4
    local password=$5
    local output_file=$6
    if command -v pg_dump &> /dev/null; then
        PGPASSWORD="$password" pg_dump -h "$host" -p "$port" -U "$user" -d "$database" > "$output_file" 2>> "$BACKUP_LOG"
        return $?
    fi

    if [[ -n "$SELECTED_DB_CONTAINER" ]]; then
        local effective_host
        effective_host=$(resolve_effective_db_host_for_exec "$host")
        docker exec -e PGPASSWORD="$password" "$SELECTED_DB_CONTAINER" \
            pg_dump -h "$effective_host" -p "$port" -U "$user" -d "$database" > "$output_file" 2>> "$BACKUP_LOG"
        return $?
    fi

    log_error "pg_dump not found locally and no selected DB container for docker exec fallback"
    return 1
}

run_mysqladmin_ping() {
    local host=$1
    local port=$2
    local user=$3
    local password=$4
    if command -v mysqladmin &> /dev/null; then
        mysqladmin ping -h "$host" -P "$port" -u "$user" -p"$password" &> /dev/null
        return $?
    fi

    if [[ -n "$SELECTED_DB_CONTAINER" ]]; then
        local effective_host
        effective_host=$(resolve_effective_db_host_for_exec "$host")
        docker exec -e MYSQL_PWD="$password" "$SELECTED_DB_CONTAINER" \
            mysqladmin ping -h "$effective_host" -P "$port" -u "$user" &> /dev/null
        return $?
    fi

    log_error "mysqladmin not found locally and no selected DB container for docker exec fallback"
    return 1
}

run_mysqldump() {
    local host=$1
    local port=$2
    local user=$3
    local password=$4
    local database=$5
    local output_file=$6
    if command -v mysqldump &> /dev/null; then
        mysqldump --no-tablespaces -h "$host" -P "$port" -u "$user" -p"$password" "$database" > "$output_file" 2>> "$BACKUP_LOG"
        return $?
    fi

    if [[ -n "$SELECTED_DB_CONTAINER" ]]; then
        local effective_host
        effective_host=$(resolve_effective_db_host_for_exec "$host")
        docker exec -e MYSQL_PWD="$password" "$SELECTED_DB_CONTAINER" \
            mysqldump --no-tablespaces -h "$effective_host" -P "$port" -u "$user" "$database" > "$output_file" 2>> "$BACKUP_LOG"
        return $?
    fi

    log_error "mysqldump not found locally and no selected DB container for docker exec fallback"
    return 1
}

discover_running_db_containers() {
    local entries
    local entry
    local container_name
    local image
    local image_lower
    local db_type
    local project_name
    local env_file

    DB_DISCOVERY_COUNT=0
    SELECTED_DB_INDEX=-1
    DB_DISCOVERY_NAMES=()
    DB_DISCOVERY_IMAGES=()
    DB_DISCOVERY_TYPES=()
    DB_DISCOVERY_PROJECTS=()
    DB_DISCOVERY_ENV_FILES=()

    mapfile -t entries < <(docker ps --format '{{.Names}}|{{.Image}}')

    for entry in "${entries[@]}"; do
        container_name=${entry%%|*}
        image=${entry#*|}
        image_lower=$(echo "$image" | tr '[:upper:]' '[:lower:]')

        db_type=""
        if [[ "$image_lower" == *postgres* ]]; then
            db_type="postgres"
        elif [[ "$image_lower" == *mysql* || "$image_lower" == *mariadb* ]]; then
            db_type="mysql"
        fi

        if [[ -z "$db_type" ]]; then
            continue
        fi

        project_name=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$container_name" 2>/dev/null || true)
        env_file=$(resolve_env_file_for_container "$container_name")

        DB_DISCOVERY_NAMES+=("$container_name")
        DB_DISCOVERY_IMAGES+=("$image")
        DB_DISCOVERY_TYPES+=("$db_type")
        DB_DISCOVERY_PROJECTS+=("${project_name:-n/a}")
        DB_DISCOVERY_ENV_FILES+=("$env_file")
        ((++DB_DISCOVERY_COUNT))
    done
}

prompt_db_container_selection() {
    local choice
    local i
    local env_info

    if [[ "$DB_DISCOVERY_COUNT" -eq 0 ]]; then
        SELECTED_DB_INDEX=-1
        return 1
    fi

    echo -e "\n${BLUE}=== Running Database Containers ===${NC}"
    for ((i = 0; i < DB_DISCOVERY_COUNT; i++)); do
        env_info="no project .env found"
        if [[ -n "${DB_DISCOVERY_ENV_FILES[$i]}" ]]; then
            env_info=".env: ${DB_DISCOVERY_ENV_FILES[$i]}"
        fi

        printf "%d) %s [%s] (project: %s, %s)\n" \
            "$((i + 1))" \
            "${DB_DISCOVERY_NAMES[$i]}" \
            "${DB_DISCOVERY_TYPES[$i]}" \
            "${DB_DISCOVERY_PROJECTS[$i]}" \
            "$env_info"
    done
    echo "m) Manual database input"

    read -p "Choose container [1-$DB_DISCOVERY_COUNT or m]: " choice
    if [[ "$choice" == "m" || "$choice" == "M" ]]; then
        SELECTED_DB_INDEX=-1
        return 0
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "$DB_DISCOVERY_COUNT" ]]; then
        SELECTED_DB_INDEX=$((choice - 1))
        return 0
    fi

    log_error "Invalid choice"
    prompt_db_container_selection
}

prefill_credentials_from_selected_container() {
    local index=$1
    local db_type=${DB_DISCOVERY_TYPES[$index]}
    local env_file=${DB_DISCOVERY_ENV_FILES[$index]}
    local default_host=${DB_DISCOVERY_NAMES[$index]}
    local default_port
    local value

    DB_HOST="$default_host"
    DB_NAME=""
    DB_USER=""
    DB_PASSWORD=""

    if [[ "$db_type" == "postgres" ]]; then
        default_port=5432
    else
        default_port=3306
    fi
    DB_PORT="$default_port"

    if [[ -n "$env_file" && -f "$env_file" ]]; then
        if [[ "$db_type" == "postgres" ]]; then
            value=$(first_non_empty_env_value "$env_file" POSTGRES_HOST DB_HOST PGHOST 2>/dev/null || true)
            DB_HOST=${value:-$DB_HOST}
            value=$(first_non_empty_env_value "$env_file" POSTGRES_PORT DB_PORT PGPORT 2>/dev/null || true)
            DB_PORT=${value:-$DB_PORT}
            DB_NAME=$(first_non_empty_env_value "$env_file" POSTGRES_DB DB_NAME 2>/dev/null || true)
            DB_USER=$(first_non_empty_env_value "$env_file" POSTGRES_USER DB_USER 2>/dev/null || true)
            DB_PASSWORD=$(first_non_empty_env_value "$env_file" POSTGRES_PASSWORD DB_PASSWORD 2>/dev/null || true)
        else
            value=$(first_non_empty_env_value "$env_file" MYSQL_HOST MARIADB_HOST DB_HOST ROUNDCUBEMAIL_DB_HOST 2>/dev/null || true)
            DB_HOST=${value:-$DB_HOST}
            value=$(first_non_empty_env_value "$env_file" MYSQL_PORT MARIADB_PORT DB_PORT ROUNDCUBEMAIL_DB_PORT 2>/dev/null || true)
            DB_PORT=${value:-$DB_PORT}
            DB_NAME=$(first_non_empty_env_value "$env_file" MYSQL_DATABASE MARIADB_DATABASE DB_NAME ROUNDCUBEMAIL_DB_NAME 2>/dev/null || true)
            DB_USER=$(first_non_empty_env_value "$env_file" MYSQL_USER MARIADB_USER DB_USER ROUNDCUBEMAIL_DB_USER 2>/dev/null || true)
            DB_PASSWORD=$(first_non_empty_env_value "$env_file" MYSQL_PASSWORD MARIADB_PASSWORD DB_PASSWORD ROUNDCUBEMAIL_DB_PASSWORD 2>/dev/null || true)
        fi
    fi

    [[ -n "$DB_HOST" && -n "$DB_PORT" && -n "$DB_NAME" && -n "$DB_USER" && -n "$DB_PASSWORD" ]]
}

load_saved_credentials_for_selected_container() {
    local index=$1
    local container_name=${DB_DISCOVERY_NAMES[$index]}
    local config_file

    config_file=$(backup_config_file_for "$container_name")
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi

    if ! load_backup_config "$config_file"; then
        log_error "Could not load saved credentials for $container_name"
        return 1
    fi

    return 0
}

##############################################################################
# Database Connection Testing
##############################################################################

test_postgres_connection() {
    local host=$1
    local port=$2
    local user=$3
    local password=$4
    local database=$5

    if run_pg_isready "$host" "$port" "$user" "$database" "$password"; then
        return 0
    else
        return 1
    fi
}

test_mysql_connection() {
    local host=$1
    local port=$2
    local user=$3
    local password=$4
    local database=$5

    if run_mysqladmin_ping "$host" "$port" "$user" "$password"; then
        return 0
    else
        return 1
    fi
}

##############################################################################
# Interactive Input Functions
##############################################################################

prompt_db_type() {
    echo -e "\n${BLUE}=== Select Database Type ===${NC}"
    echo "1) PostgreSQL"
    echo "2) MySQL/MariaDB"
    read -p "Choose [1-2]: " choice

    case $choice in
        1) echo "postgres" ;;
        2) echo "mysql" ;;
        *)
            log_error "Invalid choice"
            prompt_db_type
            ;;
    esac
}

prompt_db_credentials() {
    local db_type=$1
    local input
    local default_host
    local default_port
    local default_db
    local default_user

    echo -e "\n${BLUE}=== Database Connection Details ===${NC}"

    default_host=${DB_HOST:-localhost}
    read -p "Database Host (default: $default_host): " input
    DB_HOST=${input:-$default_host}

    if [[ "$db_type" == "postgres" ]]; then
        default_port=${DB_PORT:-5432}
    else
        default_port=${DB_PORT:-3306}
    fi
    read -p "Database Port (default: $default_port): " input
    DB_PORT=${input:-$default_port}

    default_db=${DB_NAME:-}
    if [[ -n "$default_db" ]]; then
        read -p "Database Name (default: $default_db): " input
        DB_NAME=${input:-$default_db}
    else
        read -p "Database Name: " DB_NAME
    fi
    if [[ -z "$DB_NAME" ]]; then
        log_error "Database name is required"
        prompt_db_credentials "$db_type"
        return
    fi

    default_user=${DB_USER:-}
    if [[ -n "$default_user" ]]; then
        read -p "Database User (default: $default_user): " input
        DB_USER=${input:-$default_user}
    else
        read -p "Database User: " DB_USER
    fi
    if [[ -z "$DB_USER" ]]; then
        log_error "Database user is required"
        prompt_db_credentials "$db_type"
        return
    fi

    if [[ -n "${DB_PASSWORD:-}" ]]; then
        read -sp "Database Password (press Enter to keep current): " input
        echo  # New line after password input
        if [[ -n "$input" ]]; then
            DB_PASSWORD=$input
        fi
    else
        read -sp "Database Password: " DB_PASSWORD
        echo  # New line after password input
    fi

    if [[ -z "$DB_PASSWORD" ]]; then
        log_error "Database password is required"
        prompt_db_credentials "$db_type"
        return
    fi
}

prepare_interactive_database() {
    local db_type
    local config_file

    SELECTED_DB_CONTAINER=""
    DB_TYPE=""
    DB_HOST=""
    DB_PORT=""
    DB_NAME=""
    DB_USER=""
    DB_PASSWORD=""

    discover_running_db_containers
    if [[ "$DB_DISCOVERY_COUNT" -gt 0 ]]; then
        prompt_db_container_selection || return 1
        if [[ "$SELECTED_DB_INDEX" -ge 0 ]]; then
            SELECTED_DB_CONTAINER="${DB_DISCOVERY_NAMES[$SELECTED_DB_INDEX]}"
            db_type=${DB_DISCOVERY_TYPES[$SELECTED_DB_INDEX]}
            DB_TYPE="$db_type"
            config_file=$(backup_config_file_for "$SELECTED_DB_CONTAINER")

            if [[ -f "$config_file" ]]; then
                if ! load_saved_credentials_for_selected_container "$SELECTED_DB_INDEX"; then
                    return 1
                fi
                DB_TYPE="$db_type"
                SELECTED_DB_CONTAINER="${DB_DISCOVERY_NAMES[$SELECTED_DB_INDEX]}"
                log_info "Loaded saved credentials for $SELECTED_DB_CONTAINER"
            else
                if prefill_credentials_from_selected_container "$SELECTED_DB_INDEX"; then
                    log_success "Credentials loaded from project .env"
                else
                    log_warning "Could not fully load credentials from .env - please complete manually"
                fi
            fi
        else
            db_type=$(prompt_db_type)
            DB_TYPE="$db_type"
        fi
    else
        log_warning "No running DB containers (postgres/mysql/mariadb) found - switching to manual input"
        db_type=$(prompt_db_type)
        DB_TYPE="$db_type"
    fi

    prompt_db_credentials "$db_type"
}

##############################################################################
# Backup Functions - PostgreSQL
##############################################################################

backup_postgres() {
    local host=$1
    local port=$2
    local user=$3
    local password=$4
    local database=$5

    log_info "Testing PostgreSQL connection..."
    if ! test_postgres_connection "$host" "$port" "$user" "$password" "$database"; then
        log_error "Failed to connect to PostgreSQL at $host:$port"
        return 1
    fi
    log_success "PostgreSQL connection test passed"

    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/backup_${database}_${timestamp}.sql"
    local zip_file="$BACKUP_DIR/backup_${database}_${timestamp}.zip"

    log_info "Creating PostgreSQL backup..."
    if run_pg_dump "$host" "$port" "$user" "$database" "$password" "$backup_file"; then
        log_success "PostgreSQL dump created: $(basename "$backup_file")"

        log_info "Compressing backup to ZIP..."
        if cd "$BACKUP_DIR" && zip -q "backup_${database}_${timestamp}.zip" "backup_${database}_${timestamp}.sql" && rm "$backup_file"; then
            log_success "Backup created: $(basename "$zip_file")"
            log_info "Backup size: $(du -h "$zip_file" | cut -f1)"
            return 0
        else
            log_error "Failed to compress backup"
            return 1
        fi
    else
        log_error "pg_dump failed"
        rm -f "$backup_file"
        return 1
    fi
}

##############################################################################
# Backup Functions - MySQL/MariaDB
##############################################################################

backup_mysql() {
    local host=$1
    local port=$2
    local user=$3
    local password=$4
    local database=$5

    log_info "Testing MySQL connection..."
    if ! test_mysql_connection "$host" "$port" "$user" "$password" "$database"; then
        log_error "Failed to connect to MySQL at $host:$port"
        return 1
    fi
    log_success "MySQL connection test passed"

    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/backup_${database}_${timestamp}.sql"
    local zip_file="$BACKUP_DIR/backup_${database}_${timestamp}.zip"

    log_info "Creating MySQL backup..."

    if run_mysqldump "$host" "$port" "$user" "$password" "$database" "$backup_file"; then
        log_success "MySQL dump created: $(basename "$backup_file")"

        log_info "Compressing backup to ZIP..."
        if cd "$BACKUP_DIR" && zip -q "backup_${database}_${timestamp}.zip" "backup_${database}_${timestamp}.sql" && rm "$backup_file"; then
            log_success "Backup created: $(basename "$zip_file")"
            log_info "Backup size: $(du -h "$zip_file" | cut -f1)"
            return 0
        else
            log_error "Failed to compress backup"
            return 1
        fi
    else
        log_error "mysqldump failed"
        rm -f "$backup_file"
        return 1
    fi
}

##############################################################################
# Cleanup Functions
##############################################################################

cleanup_old_backups() {
    local retention_days=$1
    local now=$(date +%s)
    local cutoff=$((now - retention_days * 86400))
    local cleaned=0

    log_info "Cleaning up backups older than $retention_days days..."

    while IFS= read -r backup_file; do
        local file_time=$(stat -f%m "$backup_file" 2>/dev/null || stat -c%Y "$backup_file" 2>/dev/null || echo 0)

        if [[ $file_time -lt $cutoff ]]; then
            log_warning "Removing old backup: $(basename "$backup_file")"
            rm -f "$backup_file"
            ((++cleaned))
        fi
    done < <(find "$BACKUP_DIR" -name "backup_*.zip" -type f)

    if [[ $cleaned -gt 0 ]]; then
        log_success "Removed $cleaned old backup(s)"
    else
        log_info "No backups to clean up"
    fi
}

##############################################################################
# Cron Job Management
##############################################################################

setup_cron() {
    local schedule=$1
    local config_file=$2
    local script_path
    local quoted_script_path
    local quoted_config_file
    local config_name
    local marker
    local cron_command

    if [[ ! -f "$config_file" ]]; then
        log_error "Backup configuration not found: $config_file"
        return 1
    fi

    script_path=$(cd "$SCRIPT_DIR" && pwd)
    quoted_script_path=$(printf '%q' "$script_path/backup_db.sh")
    quoted_config_file=$(printf '%q' "$config_file")
    config_name=$(basename "$config_file")
    marker="# docker-local-network-backup:$config_name"
    cron_command="$schedule /bin/bash $quoted_script_path --auto --config $quoted_config_file $marker"

    log_info "Setting up Cron job with schedule: $schedule"

    if crontab -l 2>/dev/null | grep -Fq -- "$marker"; then
        log_warning "Cron job already exists"
        return 1
    fi

    # Create temporary crontab file
    local temp_cron=$(mktemp)
    crontab -l 2>/dev/null > "$temp_cron" || true
    echo "$cron_command" >> "$temp_cron"

    if crontab "$temp_cron"; then
        log_success "Cron job installed successfully"
        log_info "Schedule: $schedule"
        log_info "Command: $cron_command"
        rm -f "$temp_cron"
        return 0
    else
        log_error "Failed to install Cron job"
        rm -f "$temp_cron"
        return 1
    fi
}

remove_cron() {
    local script_path

    script_path=$(cd "$SCRIPT_DIR" && pwd)

    log_info "Removing Cron job..."

    if ! crontab -l 2>/dev/null | grep -Fq -- "$script_path/backup_db.sh"; then
        log_warning "No Cron job found"
        return 1
    fi

    # Create temporary crontab file without our job
    local temp_cron=$(mktemp)
    crontab -l 2>/dev/null | grep -Fv -- "$script_path/backup_db.sh" > "$temp_cron" || true

    if crontab "$temp_cron"; then
        log_success "Cron job removed successfully"
        rm -f "$temp_cron"
        return 0
    else
        log_error "Failed to remove Cron job"
        rm -f "$temp_cron"
        return 1
    fi
}

list_cron() {
    local script_path

    script_path=$(cd "$SCRIPT_DIR" && pwd)

    echo -e "\n${BLUE}=== Cron Jobs ===${NC}"
    if crontab -l 2>/dev/null | grep -F -- "$script_path/backup_db.sh"; then
        echo -e "\n${GREEN}Cron job found:${NC}"
        crontab -l 2>/dev/null | grep -F -- "$script_path/backup_db.sh"
    else
        echo -e "${YELLOW}No Cron job found${NC}"
    fi
}

##############################################################################
# Auto-Backup Mode (for Cron)
##############################################################################

auto_backup_from_config() {
    local config_file=${1:-"$PROJECT_ROOT/.backup-config"}

    if ! load_backup_config "$config_file"; then
        return 1
    fi

    SELECTED_DB_CONTAINER=${DB_CONTAINER:-}

    if [[ -z "${DB_TYPE:-}" || -z "${DB_HOST:-}" || -z "${DB_PORT:-}" ||
        -z "${DB_USER:-}" || -z "${DB_PASSWORD:-}" || -z "${DB_NAME:-}" ]]; then
        log_error "Incomplete backup configuration: $config_file"
        return 1
    fi

    log_info "Running automatic backup for: $DB_NAME ($DB_TYPE)"

    case "$DB_TYPE" in
        postgres)
            backup_postgres "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_PASSWORD" "$DB_NAME"
            ;;
        mysql)
            backup_mysql "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_PASSWORD" "$DB_NAME"
            ;;
        *)
            log_error "Unknown database type: $DB_TYPE"
            return 1
            ;;
    esac

    cleanup_old_backups "$BACKUP_RETENTION_DAYS"
}

##############################################################################
# Main Menu
##############################################################################

show_menu() {
    echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Database Backup Tool - Main Menu      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo "1) Create Backup"
    echo "2) Setup Cron Job"
    echo "3) Remove Cron Job"
    echo "4) List Cron Jobs"
    echo "5) Cleanup Old Backups"
    echo "6) View Backup Log"
    echo "7) List Backups"
    echo "8) Exit"
    read -p "Choose [1-8]: " choice

    case $choice in
        1) interactive_backup ;;
        2) setup_cron_menu ;;
        3) remove_cron ;;
        4) list_cron ;;
        5) cleanup_old_backups_menu ;;
        6) view_log ;;
        7) list_backups ;;
        8) exit 0 ;;
        *)
            log_error "Invalid choice"
            show_menu
            ;;
    esac

    show_menu
}

interactive_backup() {
    ensure_backup_dir
    validate_docker_network || return 1
    check_command zip || return 1

    prepare_interactive_database || return 1

    echo -e "\n${YELLOW}Credentials Summary:${NC}"
    echo "  DB Type: $DB_TYPE"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    read -p "Continue with backup? (y/n): " confirm

    if [[ "$confirm" != "y" ]]; then
        log_warning "Backup cancelled"
        return 1
    fi

    case "$DB_TYPE" in
        postgres)
            backup_postgres "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_PASSWORD" "$DB_NAME"
            ;;
        mysql)
            backup_mysql "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_PASSWORD" "$DB_NAME"
            ;;
        *)
            log_error "Unknown database type: $DB_TYPE"
            return 1
            ;;
    esac

    cleanup_old_backups "$BACKUP_RETENTION_DAYS"
}

setup_cron_menu() {
    local config_file

    echo -e "\n${BLUE}=== Setup Cron Job ===${NC}"
    read -p "Enter Cron schedule (default: $BACKUP_SCHEDULE): " schedule
    schedule=${schedule:-$BACKUP_SCHEDULE}

    prepare_interactive_database || return 1

    echo -e "\n${YELLOW}Cron Configuration Summary:${NC}"
    echo "  DB Type: $DB_TYPE"
    echo "  Container: ${SELECTED_DB_CONTAINER:-manual connection}"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    read -p "Save configuration and install Cron job? (y/n): " confirm

    if [[ "$confirm" != "y" ]]; then
        log_warning "Cron setup cancelled"
        return 1
    fi

    if [[ -n "$SELECTED_DB_CONTAINER" ]]; then
        config_file=$(backup_config_file_for "$SELECTED_DB_CONTAINER")
    else
        config_file=$(backup_config_file_for "manual-$DB_TYPE")
    fi

    save_backup_config "$config_file" || return 1
    log_success "Backup configuration saved to $config_file"
    log_warning "This file contains credentials and should be protected!"

    setup_cron "$schedule" "$config_file"
}

cleanup_old_backups_menu() {
    echo -e "\n${BLUE}=== Cleanup Old Backups ===${NC}"
    read -p "Enter retention days (default: $BACKUP_RETENTION_DAYS): " retention
    retention=${retention:-$BACKUP_RETENTION_DAYS}

    cleanup_old_backups "$retention"
}

view_log() {
    if [[ ! -f "$BACKUP_LOG" ]]; then
        log_warning "No log file found yet"
        return
    fi

    echo -e "\n${BLUE}=== Backup Log ===${NC}"
    tail -50 "$BACKUP_LOG"
}

list_backups() {
    echo -e "\n${BLUE}=== Available Backups ===${NC}"
    if [[ -d "$BACKUP_DIR" ]]; then
        ls -lhS "$BACKUP_DIR"/backup_*.zip 2>/dev/null || log_warning "No backups found"
    else
        log_warning "Backup directory not found"
    fi
}

##############################################################################
# Help & Usage
##############################################################################

show_help() {
    cat <<EOF
${BLUE}Database Backup Tool${NC}

Usage: $0 [OPTION]

Options:
  --help              Show this help message
  --auto              Run automatic backup from .backup-config (for Cron)
  --auto --config FILE
                      Run automatic backup from a specific config file
  --setup-cron        Setup Cron job
  --remove-cron       Remove Cron job
  --list-cron         List Cron jobs
  --cleanup DAYS      Cleanup backups older than DAYS
  --list              List all backups

Examples:
  $0                          # Interactive mode
  $0 --auto                   # Auto-backup from saved config
  $0 --setup-cron             # Setup Cron job
  $0 --cleanup 30             # Remove backups older than 30 days

EOF
}

##############################################################################
# Main Script Entry
##############################################################################

main() {
    ensure_backup_dir

    # Parse arguments
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --help)
                show_help
                exit 0
                ;;
            --auto)
                if [[ "${2:-}" == "--config" ]]; then
                    if [[ -z "${3:-}" ]]; then
                        log_error "Missing config file after --config"
                        exit 1
                    fi
                    auto_backup_from_config "$3"
                else
                    auto_backup_from_config
                fi
                exit $?
                ;;
            --setup-cron)
                setup_cron_menu
                exit $?
                ;;
            --remove-cron)
                remove_cron
                exit $?
                ;;
            --list-cron)
                list_cron
                exit $?
                ;;
            --cleanup)
                cleanup_old_backups "${2:-30}"
                exit $?
                ;;
            --list)
                list_backups
                exit $?
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    fi

    # Interactive mode
    show_menu
}

main "$@"
