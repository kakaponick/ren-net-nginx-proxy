#!/bin/bash

# Source common configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# Configuration
NPM_URL="http://5.181.1.59:81"
API_URL="$NPM_URL/api"
LETSENCRYPT_EMAIL="hauwauabu623@gmail.com"

# NPM Admin credentials (default or custom)
ADMIN_EMAIL="${NPM_ADMIN_EMAIL:-admin@example.com}"
ADMIN_PASSWORD="${NPM_ADMIN_PASSWORD:-changeme}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# Authenticate and get token
authenticate() {
    log "Authenticating with NPM API..."
    
    local response
    response=$(curl -s -X POST "$API_URL/tokens" \
        -H "Content-Type: application/json" \
        -d "{\"identity\":\"$ADMIN_EMAIL\",\"secret\":\"$ADMIN_PASSWORD\"}")
    
    local token=$(echo "$response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$token" ]; then
        error_exit "Failed to authenticate. Check credentials. Response: $response"
    fi
    
    log "Authentication successful"
    echo "$token"
}

# Request SSL certificate for a host
request_ssl_certificate() {
    local token="$1"
    local host_id="$2"
    local domain_names="$3"
    local forward_host="$4"
    local forward_port="$5"
    local forward_scheme="$6"
    
    log "Requesting SSL certificate for host ID $host_id (domains: $domain_names)..."
    
    # Clean up any whitespace/newlines from variables
    domain_names=$(echo "$domain_names" | tr -d '\n\r' | xargs)
    forward_host=$(echo "$forward_host" | tr -d '\n\r' | xargs)
    forward_scheme=$(echo "$forward_scheme" | tr -d '\n\r' | xargs)
    forward_port=$(echo "$forward_port" | tr -d '\n\r' | xargs)
    
    # Build the payload as a single line using printf
    local payload
    payload=$(printf '{"domain_names":%s,"forward_scheme":"%s","forward_host":"%s","forward_port":%s,"block_exploits":true,"access_list_id":0,"certificate_id":"new","ssl_forced":true,"http2_support":true,"hsts_enabled":true,"hsts_subdomains":false,"meta":{"letsencrypt_email":"%s","letsencrypt_agree":true,"dns_challenge":false},"advanced_config":"","locations":[],"caching_enabled":false,"allow_websocket_upgrade":false}' \
        "$domain_names" "$forward_scheme" "$forward_host" "$forward_port" "$LETSENCRYPT_EMAIL")
    
    # Debug: log the payload
    log "Payload: $payload"
    
    local response
    response=$(curl -s -X PUT "$API_URL/nginx/proxy-hosts/$host_id" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    # Check if successful
    if echo "$response" | grep -q '"id"'; then
        log "Successfully requested SSL certificate for host ID $host_id"
        return 0
    else
        log "Failed to request SSL for host ID $host_id: $response"
        return 1
    fi
}

# Parse JSON and process hosts
process_hosts() {
    local token="$1"
    
    local count=0
    local success=0
    local failed=0
    local skipped=0
    
    # Get database password for direct query
    local db_password
    db_password=$(grep "MariaDB User Password:" "$WORK_DIR/passwords.txt" | cut -d':' -f2 | xargs)
    
    if [ -z "$db_password" ]; then
        error_exit "Could not extract database password from passwords.txt"
    fi
    
    # Query database for hosts without SSL
    log "Querying database for hosts without SSL certificates..."
    local query="SELECT id, domain_names, forward_host, forward_port, forward_scheme FROM proxy_host WHERE certificate_id = 0 AND is_deleted = 0 AND enabled = 1;"
    
    local hosts_data
    hosts_data=$(docker exec nginx-proxy-manager_db_1 mariadb -u npm -p"$db_password" npm -sN -e "$query" 2>/dev/null)
    
    if [ -z "$hosts_data" ]; then
        log "No hosts found without SSL certificates"
        return
    fi
    
    # Process each host
    while IFS=$'\t' read -r id domain_names forward_host forward_port forward_scheme; do
        ((count++))
        
        # Skip if any field is empty
        if [ -z "$id" ] || [ -z "$domain_names" ]; then
            log "Skipping host ID $id - missing data"
            ((skipped++))
            continue
        fi
        
        log "Processing host ID $id: $domain_names"
        
        if request_ssl_certificate "$token" "$id" "$domain_names" "$forward_host" "$forward_port" "$forward_scheme"; then
            ((success++))
        else
            ((failed++))
        fi
        
        # Small delay to avoid overwhelming the API
        sleep 2
    done <<< "$hosts_data"
    
    log "SSL request completed: $count processed, $success successful, $failed failed, $skipped skipped"
}

main() {
    log "Starting SSL certificate request process..."
    
    check_work_dir
    
    # Check if containers are running
    if ! docker ps | grep -q "nginx-proxy-manager_app"; then
        error_exit "Nginx Proxy Manager container is not running"
    fi
    
    # Authenticate
    local token
    token=$(authenticate)
    
    if [ -z "$token" ]; then
        error_exit "Authentication failed"
    fi
    
    # Process hosts and request SSL
    process_hosts "$token"
    
    log "SSL request process completed!"
    log "Check the NPM web interface to monitor certificate issuance"
}

main "$@"

