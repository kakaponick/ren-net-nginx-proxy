#!/bin/bash

set -e

# Source common configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

test_setup() {
    log "Testing proxy server setup..."
    
    check_work_dir
    
    log "Checking Docker containers..."
    if ! docker ps | grep -q "nginx-proxy-manager_app"; then
        error_exit "Nginx Proxy Manager container is not running"
    fi
    
    if ! docker ps | grep -q "nginx-proxy-manager_db"; then
        error_exit "MariaDB container is not running"
    fi
    
    log "Checking port availability..."
    for port in 80 81 443; do
        if ! netstat -tuln | grep -q ":$port "; then
            error_exit "Port $port is not listening"
        fi
    done
    
    log "Testing web interface accessibility..."
    SERVER_IP=$(curl -s ifconfig.me)
    if ! curl -s -o /dev/null -w "%{http_code}" "http://$SERVER_IP:81" | grep -q "200\|302"; then
        error_exit "Web interface is not accessible"
    fi
    
    log "Checking password file..."
    if [ ! -f "passwords.txt" ]; then
        error_exit "Password file not found"
    fi
    
    log "All tests passed!"
    log "Web interface: http://$SERVER_IP:81"
    log "Login: admin@example.com / changeme"
    log "Passwords saved in: passwords.txt"
}

main() {
    log "Starting proxy server test..."
    test_setup
    log "Test completed successfully!"
}

main "$@"
