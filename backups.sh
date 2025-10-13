#!/bin/bash

set -e

# Source common configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

create_backup() {
    local backup_name="proxy-backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log "Creating backup: $backup_name"
    
    mkdir -p "$backup_path" || error_exit "Failed to create backup directory"
    
    log "Stopping containers for backup..."
    check_work_dir
    docker-compose down || error_exit "Failed to stop containers"
    
    log "Backing up entire work directory..."
    tar -czf "$backup_path/backup.tar.gz" -C "$WORK_DIR" . || error_exit "Failed to backup work directory"
    
    log "Creating backup manifest..."
    cat > "$backup_path/manifest.txt" << EOF
Backup created: $(date)
Server IP: $(curl -s ifconfig.me)
Docker version: $(docker --version)
Docker Compose version: $(docker-compose --version)
Backup size: $(du -sh "$backup_path" | cut -f1)
EOF
    
    log "Starting containers..."
    docker-compose up -d || error_exit "Failed to start containers"
    
    log "Backup completed: $backup_path"
    log "Backup size: $(du -sh "$backup_path" | cut -f1)"
}

restore_backup() {
    local backup_name="$1"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    if [ -z "$backup_name" ]; then
        log "Available backups:"
        ls -la "$BACKUP_DIR" | grep "proxy-backup-" | while read line; do
            log "  $line"
        done
        error_exit "Please specify backup name"
    fi
    
    if [ ! -d "$backup_path" ]; then
        error_exit "Backup not found: $backup_path"
    fi
    
    log "Restoring backup: $backup_name"
    
    if [ -d "$WORK_DIR" ]; then
        log "Stopping containers..."
        cd "$WORK_DIR" || error_exit "Failed to change to working directory"
        docker-compose down 2>/dev/null
    fi
    
    log "Restoring work directory..."
    tar -xzf "$backup_path/backup.tar.gz" -C "$WORK_DIR" || error_exit "Failed to restore work directory"
    
    log "Starting containers..."
    docker-compose up -d || error_exit "Failed to start containers"
    
    log "Waiting for containers to start..."
    sleep 30
    
    log "Restore completed successfully!"
}

list_backups() {
    log "Available backups:"
    if [ ! -d "$BACKUP_DIR" ]; then
        log "No backup directory found"
        return
    fi
    
    ls -la "$BACKUP_DIR" | grep "proxy-backup-" | while read line; do
        log "  $line"
    done
}

main() {
    mkdir -p "$BACKUP_DIR" || error_exit "Failed to create backup directory"
    
    case "$1" in
        "create")
            create_backup
            ;;
        "restore")
            restore_backup "$2"
            ;;
        "list")
            list_backups
            ;;
        *)
            log "Usage: $0 {create|restore|list} [backup_name]"
            log "  create - Create new backup"
            log "  restore <backup_name> - Restore from backup"
            log "  list - List available backups"
            exit 1
            ;;
    esac
}

main "$@"
