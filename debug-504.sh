#!/bin/bash

# Source common configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

debug_upstream() {
		log "=== Checking Nginx error logs ==="
		docker exec nginx-proxy-manager_app_1 tail -50 /data/logs/error.log 2>&1 | while read line; do
				log "$line"
		done
		
		echo ""
		log "=== Checking Nginx access logs ==="
		docker exec nginx-proxy-manager_app_1 tail -50 /data/logs/default-host_access.log 2>&1 | while read line; do
				log "$line"
		done
		
		echo ""
		log "=== Checking all proxy host configs ==="
		docker exec nginx-proxy-manager_app_1 ls -la /data/nginx/proxy_host/ 2>&1 | while read line; do
				log "$line"
		done
		
		echo ""
		log "=== Active Nginx connections ==="
		docker exec nginx-proxy-manager_app_1 netstat -an | grep ESTABLISHED | while read line; do
				log "$line"
		done
}

test_upstream() {
		read -p "Enter upstream host (e.g., 192.168.1.10): " host
		read -p "Enter upstream port (e.g., 8080): " port
		
		log "=== Testing connectivity to $host:$port ==="
		
		# Test from host
		log "From host machine:"
		timeout 5 curl -v http://$host:$port 2>&1 | head -20 | while read line; do
				log "  $line"
		done
		
		echo ""
		# Test from container
		log "From nginx container:"
		docker exec nginx-proxy-manager_app_1 timeout 5 curl -v http://$host:$port 2>&1 | head -20 | while read line; do
				log "  $line"
		done
}

main() {
		log "Starting 504 Gateway Timeout debugging..."
		debug_upstream
		
		echo ""
		read -p "Do you want to test upstream connectivity? (y/n): " answer
		if [ "$answer" = "y" ]; then
				test_upstream
		fi
		
		log "Debug completed. Check /var/log/proxy-manager.log for full output"
}

main "$@"

