.PHONY: install status backup restore update-passwords clean cleanup test help

install:
	@echo "Installing proxy server..."
	@sudo ./setup-proxy-server.sh

status:
	@echo "Checking proxy server status..."
	@sudo ./check-status.sh

backup:
	@echo "Creating backup..."
	@sudo ./backup-restore.sh create

restore:
	@echo "Available backups:"
	@sudo ./backup-restore.sh list
	@echo "Usage: make restore BACKUP_NAME=backup-name"

update-passwords:
	@echo "Updating default passwords..."
	@sudo ./update-passwords.sh

clean:
	@echo "Cleaning up containers and data..."
	@cd ~/nginx-proxy-manager && docker-compose down -v
	@sudo rm -rf ~/nginx-proxy-manager
	@echo "Cleanup completed"

cleanup:
	@echo "Cleaning up Docker system..."
	@sudo ./cleanup.sh full

logs:
	@echo "Showing container logs..."
	@cd ~/nginx-proxy-manager && docker-compose logs -f

view-logs:
	@echo "Showing proxy manager logs..."
	@sudo tail -f /var/log/proxy-manager.log

restart:
	@echo "Restarting proxy server..."
	@cd ~/nginx-proxy-manager && docker-compose restart

update:
	@echo "Updating proxy server..."
	@cd ~/nginx-proxy-manager && docker-compose pull
	@cd ~/nginx-proxy-manager && docker-compose up -d

test:
	@echo "Testing proxy server setup..."
	@sudo ./test-setup.sh

fix-db:
	@echo "Fixing database connection..."
	@sudo ./fix-database.sh

help:
	@echo "Available commands:"
	@echo "  install          - Install proxy server"
	@echo "  status           - Check server status"
	@echo "  backup           - Create backup"
	@echo "  restore          - Restore from backup (use BACKUP_NAME=name)"
	@echo "  update-passwords - Update default passwords"
	@echo "  clean            - Remove all containers and data"
	@echo "  cleanup          - Clean Docker system"
	@echo "  logs             - Show container logs"
	@echo "  view-logs        - Show proxy manager logs"
	@echo "  restart          - Restart containers"
	@echo "  update           - Update container images"
	@echo "  test             - Test setup functionality"
	@echo "  fix-db           - Fix database connection issues"
	@echo "  help             - Show this help"
