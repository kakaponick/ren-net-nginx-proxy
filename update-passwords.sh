#!/bin/bash

set -e

# Source common configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

change_passwords() {
    log "Generating new secure passwords..."
    
    NEW_ROOT_PASSWORD=$(generate_password)
    NEW_USER_PASSWORD=$(generate_password)
    NEW_DB_PASSWORD=$(generate_password)
    
    log "Stopping containers..."
    check_work_dir
    docker-compose down || error_exit "Failed to stop containers"
    
    log "Backing up current configuration..."
    cp docker-compose.yml docker-compose.yml.backup || error_exit "Failed to backup configuration"
    
    log "Updating docker-compose.yml with new passwords..."
    cat > docker-compose.yml << EOF
version: '3'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: always
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    environment:
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "npm"
      DB_MYSQL_PASSWORD: "$NEW_DB_PASSWORD"
      DB_MYSQL_NAME: "npm"
    depends_on:
      - db
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt

  db:
    image: 'mariadb:latest'
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: "$NEW_ROOT_PASSWORD"
      MYSQL_DATABASE: "npm"
      MYSQL_USER: "npm"
      MYSQL_PASSWORD: "$NEW_DB_PASSWORD"
    volumes:
      - ./data/mysql:/var/lib/mysql
EOF

    log "Starting containers with new configuration..."
    docker-compose up -d || error_exit "Failed to start containers"
    
    log "Waiting for containers to start and database to initialize..."
    sleep 90
    
    log "Saving passwords to secure file..."
    cat > passwords.txt << EOF
# Generated on $(date)
# KEEP THIS FILE SECURE AND DELETE AFTER USE

MariaDB Root Password: $NEW_ROOT_PASSWORD
MariaDB User Password: $NEW_DB_PASSWORD
Database Name: npm
Database User: npm

# Web Interface Access
URL: http://$(curl -s ifconfig.me):81
Email: admin@example.com
Password: changeme (CHANGE THIS IMMEDIATELY!)
EOF
    
    chmod 600 passwords.txt
    log "Passwords saved to passwords.txt (chmod 600 applied)"
    log "IMPORTANT: Delete passwords.txt after copying the information!"
    
    log "Security update completed successfully!"
}

main() {
    log "Starting security password update..."
    
    if [ ! -f "$WORK_DIR/docker-compose.yml" ]; then
        error_exit "Docker compose file not found. Run setup-proxy-server.sh first."
    fi
    
    change_passwords
}

main "$@"
