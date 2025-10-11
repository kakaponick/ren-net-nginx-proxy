#!/bin/bash

set -e

# Source common configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

main() {
    log "Starting full proxy server setup with security..."
    
    check_root
    
    log "Step 1: Installing proxy server with secure passwords..."
    ./setup-proxy-server.sh || error_exit "Proxy server installation failed"
    
    log "Step 2: Setting up firewall..."
    ./setup-firewall.sh setup || error_exit "Firewall setup failed"
    
    log "Step 3: Creating initial backup..."
    ./backup-restore.sh create || error_exit "Initial backup failed"
    
    log "Step 4: Final status check..."
    ./check-status.sh || error_exit "Status check failed"
    
    log "Full setup completed successfully!"
    log "Web interface: http://$(curl -s ifconfig.me):81"
    log "Default login: admin@example.com / changeme"
    log "IMPORTANT: Change default password immediately!"
    log "Passwords saved in: ~/nginx-proxy-manager/passwords.txt"
    log "Delete passwords.txt after copying the information!"
}

main "$@"
