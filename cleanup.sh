#!/bin/bash

set -e

# Source common configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cleanup_docker() {
    log "Starting Docker cleanup..."
    
    if [ -d "$WORK_DIR" ]; then
        log "Stopping containers in $WORK_DIR..."
        check_work_dir
        docker-compose down -v 2>/dev/null || true
    fi
    
    log "Removing all stopped containers..."
    docker container prune -f || true
    
    log "Removing unused images..."
    docker image prune -f || true
    
    log "Removing unused volumes..."
    docker volume prune -f || true
    
    log "Removing unused networks..."
    docker network prune -f || true
    
    log "Performing system cleanup..."
    docker system prune -f || true
    
    log "Cleanup completed successfully!"
}

cleanup_data() {
    log "Cleaning up proxy data..."
    
    WORK_DIR="$HOME/nginx-proxy-manager"
    
    if [ -d "$WORK_DIR" ]; then
        log "Removing data directories..."
        sudo rm -rf "$WORK_DIR/data" || error_exit "Failed to remove data directory"
        sudo rm -rf "$WORK_DIR/letsencrypt" || error_exit "Failed to remove letsencrypt directory"
        log "Data cleanup completed"
    else
        log "No proxy directory found, skipping data cleanup"
    fi
}

full_cleanup() {
    log "Starting full cleanup..."
    cleanup_docker
    cleanup_data
    log "Full cleanup completed!"
}

main() {
    case "$1" in
        "docker")
            cleanup_docker
            ;;
        "data")
            cleanup_data
            ;;
        "full")
            full_cleanup
            ;;
        *)
            log "Usage: $0 {docker|data|full}"
            log "  docker - Clean Docker containers, images, volumes"
            log "  data   - Clean proxy data directories"
            log "  full   - Clean everything (Docker + data)"
            exit 1
            ;;
    esac
}

main "$@"
