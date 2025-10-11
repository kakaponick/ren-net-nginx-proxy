#!/bin/bash

# Source common configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

check_docker_status() {
    log "Checking Docker service status..."
    if systemctl is-active --quiet docker; then
        log "Docker service: RUNNING"
        return 0
    else
        log "Docker service: STOPPED"
        return 1
    fi
}

check_containers() {
    log "Checking container status..."
    
    if docker ps | grep -q "nginx-proxy-manager_app"; then
        log "Nginx Proxy Manager: RUNNING"
    else
        log "Nginx Proxy Manager: STOPPED"
    fi
    
    if docker ps | grep -q "nginx-proxy-manager_db"; then
        log "MariaDB: RUNNING"
    else
        log "MariaDB: STOPPED"
    fi
}

check_ports() {
    log "Checking port availability..."
    
    for port in 80 81 443; do
        if netstat -tuln | grep -q ":$port "; then
            log "Port $port: LISTENING"
        else
            log "Port $port: NOT LISTENING"
        fi
    done
}

check_disk_space() {
    log "Checking disk space..."
    df -h | grep -E "(Filesystem|/dev/)" | while read line; do
        log "Disk usage: $line"
    done
}

check_memory() {
    log "Checking memory usage..."
    free -h | while read line; do
        log "Memory: $line"
    done
}

check_logs() {
    log "Checking recent container logs..."
    if docker ps | grep -q "nginx-proxy-manager_app"; then
        log "Nginx Proxy Manager logs (last 10 lines):"
        docker logs --tail 10 nginx-proxy-manager_app_1 2>&1 | while read line; do
            log "  $line"
        done
    fi
}

main() {
    log "Starting proxy server status check..."
    
    check_docker_status
    check_containers
    check_ports
    check_disk_space
    check_memory
    check_logs
    
    log "Status check completed"
}

main "$@"
