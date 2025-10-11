# Nginx Proxy Manager Setup

Automatic setup of a proxy server using Nginx Proxy Manager to protect your website servers.

## Quick Start

### Full Automatic Install (Recommended)

1. Connect to your server via SSH
2. Download all project files
3. Set executable permissions:
```bash
chmod +x *.sh
```

4. Start the full, secure installation:
```bash
sudo ./full-setup.sh
```

### Manual Installation

1. Connect to your server via SSH
2. Download the install script:
```bash
wget https://raw.githubusercontent.com/your-repo/nginx-proxy-setup/main/setup-proxy-server.sh
chmod +x setup-proxy-server.sh
```

3. Run the setup:
```bash
sudo ./setup-proxy-server.sh
```

## What the Scripts Do

### full-setup.sh (Full Install)
- Installs the proxy server with secure passwords
- Sets up the firewall
- Creates a backup
- Checks system status

### setup-proxy-server.sh (Basic Install)
- Updates system packages
- Installs Docker and Docker Compose
- Generates secure passwords
- Starts and configures Docker service
- Creates the working directory `~/nginx-proxy-manager`
- Deploys Nginx Proxy Manager with MariaDB
- Checks container status
- Saves passwords to a secure file
- Displays web interface access info

## Accessing the Admin Panel

After installation, open your browser and go to:
```
http://YOUR_SERVER_IP:81
```

**Default credentials:**
- Email: `admin@example.com`
- Password: `changeme`

⚠️ **IMPORTANT:** Change your password immediately after your first login!

## Proxy Setup

1. Log in to the admin panel
2. Go to `Hosts` → `Proxy Hosts` → `Add Proxy Host`
3. Enter:
   - Domain names: your domain
   - Forward Hostname/IP: IP of your website server
   - Forward Port: 443 (for HTTPS)
   - Enable SSL: enabled
4. On the SSL tab choose `Request a new SSL Certificate`
5. Enable `Force SSL`
6. Save changes

## DNS Setup in Cloudflare

1. Log in to your Cloudflare dashboard
2. Go to the DNS section of your domain
3. Update your A records:
   - `@` → proxy server's IP
   - `www` → proxy server's IP
4. Wait for DNS updates to propagate (usually 1–5 minutes)

## Checking Status

To check the status of the services, use:
```bash
sudo ./check-status.sh
```

## Logs

- Unified log of all operations: `/var/log/proxy-manager.log`
- Container logs: `docker logs nginx-proxy-manager_app_1`

## Managing Containers

```bash
# Stop
cd ~/nginx-proxy-manager
docker-compose down

# Start
docker-compose up -d

# Restart
docker-compose restart

# Update images
docker-compose pull
docker-compose up -d
```

## Security

1. Change default passwords in `docker-compose.yml`
2. Set up the firewall:
```bash
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 81
ufw enable
```

3. Regularly update Docker images
4. Monitor logs for suspicious activity

## Project Structure

```
nginx-proxy-manager/
├── setup-proxy-server.sh    # Install script
├── check-status.sh          # Status check script
├── update-passwords.sh      # Update passwords
├── backup-restore.sh        # Backup/restore
├── setup-firewall.sh        # Firewall setup
├── docker-compose.yml       # Docker config
├── Makefile                 # Convenience commands
├── data/                    # App data
│   └── mysql/               # MariaDB database
└── letsencrypt/             # SSL certificates
```

## Additional Scripts

### Update Passwords
```bash
sudo ./update-passwords.sh
```
Generates new secure passwords for all services.

### Backup & Restore
```bash
# Create a backup
sudo ./backup-restore.sh create

# List backups
sudo ./backup-restore.sh list

# Restore from a backup
sudo ./backup-restore.sh restore backup-name
```

### Firewall Setup
```bash
# Set up firewall with basic rules
sudo ./setup-firewall.sh setup

# Show firewall status
sudo ./setup-firewall.sh status

# Add a rule
sudo ./setup-firewall.sh add 8080 tcp "Custom port"

# Remove a rule
sudo ./setup-firewall.sh remove 1
```

## Using the Makefile

For easier management, use Make commands:

```bash
make install          # Install proxy server
make status           # Check status
make backup           # Create a backup
make restore BACKUP_NAME=name  # Restore
make update-passwords # Update passwords
make clean            # Remove all data
make logs             # View logs
make restart          # Restart containers
make update           # Update images
make test             # Test setup
make help             # Help
```

## Troubleshooting

### Containers Won't Start
```bash
docker-compose logs
```

### SSL Issues
- Check your DNS records in Cloudflare
- Make sure your domain points to the proxy server
- Check logs: `docker logs nginx-proxy-manager_app_1`

### Port 81 Is Unavailable
```bash
netstat -tuln | grep 81
ufw status
```

## Support

If you have issues, check:
1. The unified log: `/var/log/proxy-manager.log`
2. Docker service status
3. Port availability
4. DNS settings in Cloudflare
