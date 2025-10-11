#!/bin/bash

set -e

# Source common configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

log "Starting proxy server setup..."

log "Updating system packages..."
apt update -y || error_exit "Failed to update packages"

log "Installing Docker and Docker Compose..."
apt install -y docker.io docker-compose || error_exit "Failed to install Docker"

log "Starting Docker service..."
systemctl start docker || error_exit "Failed to start Docker"
systemctl enable docker || error_exit "Failed to enable Docker"

log "Checking Docker status..."
if ! systemctl is-active --quiet docker; then
    error_exit "Docker is not running"
fi

log "Creating working directory..."
mkdir -p "$WORK_DIR" || error_exit "Failed to create working directory"
cd "$WORK_DIR" || error_exit "Failed to change to working directory"

log "Generating secure passwords..."
ROOT_PASSWORD=$(generate_password)
DB_PASSWORD=$(generate_password)

log "Creating docker-compose.yml with secure passwords..."
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
      DB_MYSQL_PASSWORD: "$DB_PASSWORD"
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
      MYSQL_ROOT_PASSWORD: "$ROOT_PASSWORD"
      MYSQL_DATABASE: "npm"
      MYSQL_USER: "npm"
      MYSQL_PASSWORD: "$DB_PASSWORD"
    volumes:
      - ./data/mysql:/var/lib/mysql
EOF

log "Cleaning up any existing containers..."
docker-compose down -v 2>/dev/null || true
docker system prune -f || true

log "Creating data directories..."
mkdir -p data/mysql letsencrypt || error_exit "Failed to create data directories"

log "Starting Docker containers..."
docker-compose up -d || error_exit "Failed to start containers"

log "Checking container status..."
if ! docker ps | grep -q "nginx-proxy-manager_app"; then
    error_exit "Nginx Proxy Manager container is not running"
fi

if ! docker ps | grep -q "nginx-proxy-manager_db"; then
    error_exit "MariaDB container is not running"
fi

log "Containers are running - Docker Compose handles dependencies!"

log "Saving passwords to secure file..."
cat > passwords.txt << EOF
# Generated on $(date)
# KEEP THIS FILE SECURE AND DELETE AFTER USE

MariaDB Root Password: $ROOT_PASSWORD
MariaDB User Password: $DB_PASSWORD
Database Name: npm
Database User: npm

# Web Interface Access
URL: http://$(curl -s ifconfig.me):81
Email: admin@example.com
Password: changeme (CHANGE THIS IMMEDIATELY!)
EOF

chmod 600 passwords.txt
log "Passwords saved to passwords.txt (chmod 600 applied)"

log "Setup completed successfully!"
log "Web interface available at: http://$(curl -s ifconfig.me):81"
log "Default credentials: admin@example.com / changeme"
log "Please change default credentials immediately!"
log "Passwords saved in: passwords.txt"
log "IMPORTANT: Delete passwords.txt after copying the information!"
log "Log file: $LOG_FILE"
