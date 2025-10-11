#!/bin/bash

# Shared configuration for all proxy manager scripts
# This file should be sourced by all other scripts

# Common variables
LOG_FILE="/var/log/proxy-manager.log"
WORK_DIR="$HOME/nginx-proxy-manager"
BACKUP_DIR="$HOME/proxy-backups"

# Common functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "Please run as root (use sudo)"
    fi
}

check_work_dir() {
    if [ ! -d "$WORK_DIR" ]; then
        error_exit "Working directory not found: $WORK_DIR"
    fi
    cd "$WORK_DIR" || error_exit "Failed to change to working directory"
}
