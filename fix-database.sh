#!/bin/bash

set -e

# Source common configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

fix_database_connection() {
    log "Fixing database connection issue..."
    
    check_work_dir
    
    log "Stopping containers..."
    docker-compose down || error_exit "Failed to stop containers"
    
    log "Starting containers with proper dependency order..."
    docker-compose up -d || error_exit "Failed to start containers"
    
    log "Containers started - Docker Compose handles the dependency order!"
    
    log "Checking final status..."
    docker-compose ps
    
    log "Database connection fix completed!"
}

main() {
    log "Starting database connection fix..."
    fix_database_connection
    log "Fix completed successfully!"
}

main "$@"
