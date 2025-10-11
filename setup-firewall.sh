#!/bin/bash

set -e

# Source common configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

setup_firewall() {
    log "Installing UFW firewall..."
    apt update -y || error_exit "Failed to update packages"
    apt install -y ufw || error_exit "Failed to install UFW"
    
    log "Configuring firewall rules..."
    
    ufw --force reset || error_exit "Failed to reset firewall"
    
    ufw default deny incoming || error_exit "Failed to set default deny incoming"
    ufw default allow outgoing || error_exit "Failed to set default allow outgoing"
    
    ufw allow 22/tcp comment 'SSH' || error_exit "Failed to allow SSH"
    ufw allow 80/tcp comment 'HTTP' || error_exit "Failed to allow HTTP"
    ufw allow 443/tcp comment 'HTTPS' || error_exit "Failed to allow HTTPS"
    ufw allow 81/tcp comment 'NPM Admin' || error_exit "Failed to allow NPM Admin"
    
    log "Enabling firewall..."
    ufw --force enable || error_exit "Failed to enable firewall"
    
    log "Firewall configuration completed"
    log "Active rules:"
    ufw status numbered | while read line; do
        log "  $line"
    done
}

show_status() {
    log "Firewall status:"
    ufw status verbose | while read line; do
        log "  $line"
    done
}

add_rule() {
    local port="$1"
    local protocol="${2:-tcp}"
    local comment="$3"
    
    if [ -z "$port" ]; then
        error_exit "Port not specified"
    fi
    
    log "Adding rule for port $port/$protocol"
    ufw allow "$port/$protocol" comment "$comment" || error_exit "Failed to add rule"
    log "Rule added successfully"
}

remove_rule() {
    local rule_number="$1"
    
    if [ -z "$rule_number" ]; then
        error_exit "Rule number not specified"
    fi
    
    log "Removing rule number $rule_number"
    ufw --force delete "$rule_number" || error_exit "Failed to remove rule"
    log "Rule removed successfully"
}

main() {
    case "$1" in
        "setup")
            setup_firewall
            ;;
        "status")
            show_status
            ;;
        "add")
            add_rule "$2" "$3" "$4"
            ;;
        "remove")
            remove_rule "$2"
            ;;
        *)
            log "Usage: $0 {setup|status|add|remove}"
            log "  setup - Configure firewall with default rules"
            log "  status - Show firewall status"
            log "  add <port> [protocol] [comment] - Add new rule"
            log "  remove <rule_number> - Remove rule by number"
            exit 1
            ;;
    esac
}

main "$@"
