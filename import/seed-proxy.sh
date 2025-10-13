#!/bin/bash

# Source common configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

DOMAINS_FILE="$SCRIPT_DIR/domains.txt"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

parse_domains_file() {
    log "Parsing domains file: $DOMAINS_FILE"
    
    if [ ! -f "$DOMAINS_FILE" ]; then
        error_exit "Domains file not found: $DOMAINS_FILE"
    fi
    
    local count=0
    local success=0
    local failed=0
    
    while IFS=' ' read -r domain ip || [[ -n "$domain" ]]; do
        # Skip empty lines and comments
        [[ -z "$domain" || "$domain" =~ ^# ]] && continue
        [[ -z "$ip" ]] && continue
        
        log "Processing: $domain -> $ip:443 (HTTPS)"
        if add_proxy_host "$domain" "$ip"; then
            ((success++))
        else
            ((failed++))
        fi
        ((count++))
    done < "$DOMAINS_FILE"
    
    log "Processed $count domains: $success successful, $failed failed"
    
    if [ $failed -gt 0 ]; then
        log "Warning: Some domains failed to be added"
    fi
}

add_proxy_host() {
    local domain="$1"
    local ip="$2"
    
    if [ -z "$domain" ] || [ -z "$ip" ]; then
        log "Skipping invalid entry: domain='$domain', ip='$ip'"
        return
    fi
    
    log "Adding proxy host: $domain -> $ip:443 (HTTPS)"
    
    # Get database password from passwords.txt
    local db_password
    db_password=$(grep "MariaDB User Password:" "$WORK_DIR/passwords.txt" | cut -d':' -f2 | xargs)
    
    if [ -z "$db_password" ]; then
        error_exit "Could not extract database password from passwords.txt"
    fi
    
    # Create SQL for this domain with correct schema
    local sql="INSERT INTO proxy_host (
        created_on, modified_on, owner_user_id, is_deleted,
        domain_names, forward_host, forward_port, forward_scheme,
        access_list_id, certificate_id, ssl_forced, caching_enabled,
        block_exploits, advanced_config, meta, allow_websocket_upgrade,
        http2_support, enabled, hsts_enabled, hsts_subdomains
    ) VALUES (
        NOW(), NOW(), 1, 0,
        '[\"$domain\"]', '$ip', 443, 'https',
        0, 0, 0, 0,
        0, '', '{}', 0,
        0, 1, 0, 0
    );"
    
    # Execute SQL
    local result
    result=$(echo "$sql" | docker exec -i nginx-proxy-manager_db_1 mariadb -u npm -p"$db_password" npm 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log "Successfully added: $domain"
        return 0
    else
        log "Failed to add: $domain - $result"
        return 1
    fi
}


check_database_connection() {
    log "Checking database connection..."
    
    check_work_dir
    
    # Check if containers are running
    if ! docker ps | grep -q "nginx-proxy-manager_db"; then
        error_exit "Database container is not running"
    fi
    
    # Test database connection
    local db_password
    db_password=$(grep "MariaDB User Password:" "$WORK_DIR/passwords.txt" | cut -d':' -f2 | xargs)
    
    if ! docker exec nginx-proxy-manager_db_1 mariadb -u npm -p"$db_password" npm -e "SELECT 1;" >/dev/null 2>&1; then
        error_exit "Cannot connect to database"
    fi
    
    log "Database connection successful"
}

main() {
    log "Starting proxy host seeding..."
    
    check_database_connection
    
    parse_domains_file
    
    log "Seeding completed successfully!"
    log "Check the NPM web interface to verify the proxy hosts were added"
}

main "$@"
