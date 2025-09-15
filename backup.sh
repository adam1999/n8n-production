#!/bin/bash

# n8n Docker Stack Backup Script
# This script creates backups of PostgreSQL database and n8n data

set -e

# Configuration
BACKUP_DIR="./backups"
DATE=$(date +"%Y%m%d_%H%M%S")
POSTGRES_CONTAINER="n8n-postgres"
N8N_DATA_DIR="./n8n"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

print_status "Starting backup process..."

# Check if PostgreSQL container is running
if ! docker ps | grep -q "$POSTGRES_CONTAINER"; then
    print_error "PostgreSQL container '$POSTGRES_CONTAINER' is not running!"
    print_status "Please start the stack with: docker-compose up -d"
    exit 1
fi

# Backup PostgreSQL database
print_status "Backing up PostgreSQL database..."
POSTGRES_BACKUP_FILE="$BACKUP_DIR/postgres_backup_$DATE.sql"

if docker exec "$POSTGRES_CONTAINER" pg_dump -U n8n -d n8n > "$POSTGRES_BACKUP_FILE"; then
    print_status "PostgreSQL backup completed: $POSTGRES_BACKUP_FILE"
else
    print_error "PostgreSQL backup failed!"
    exit 1
fi

# Backup n8n data directory
print_status "Backing up n8n data directory..."
N8N_BACKUP_FILE="$BACKUP_DIR/n8n_data_backup_$DATE.tar.gz"

if [ -d "$N8N_DATA_DIR" ]; then
    if tar -czf "$N8N_BACKUP_FILE" -C "$(dirname "$N8N_DATA_DIR")" "$(basename "$N8N_DATA_DIR")"; then
        print_status "n8n data backup completed: $N8N_BACKUP_FILE"
    else
        print_error "n8n data backup failed!"
        exit 1
    fi
else
    print_warning "n8n data directory '$N8N_DATA_DIR' not found, skipping..."
fi

# Create combined backup archive
print_status "Creating combined backup archive..."
COMBINED_BACKUP_FILE="$BACKUP_DIR/n8n_complete_backup_$DATE.tar.gz"

cd "$BACKUP_DIR"
if tar -czf "n8n_complete_backup_$DATE.tar.gz" "postgres_backup_$DATE.sql" "n8n_data_backup_$DATE.tar.gz" 2>/dev/null; then
    print_status "Combined backup created: $COMBINED_BACKUP_FILE"
    
    # Clean up individual backup files
    rm -f "postgres_backup_$DATE.sql" "n8n_data_backup_$DATE.tar.gz"
    print_status "Individual backup files cleaned up"
else
    print_warning "Could not create combined backup, individual files preserved"
fi

cd - > /dev/null

# Display backup information
print_status "Backup process completed successfully!"
print_status "Backup location: $(realpath "$BACKUP_DIR")"
ls -lh "$BACKUP_DIR"/*_$DATE*

# Clean up old backups (keep last 7 days)
print_status "Cleaning up old backups (keeping last 7 days)..."
find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +7 -delete
find "$BACKUP_DIR" -name "*.sql" -type f -mtime +7 -delete

print_status "Backup script completed!"
