#!/bin/bash

# n8n Permissions Setup Script
set -euo pipefail

echo "🔧 Setting up n8n directory permissions..."

# Create n8n directory if it doesn't exist
mkdir -p ./n8n

# Set correct ownership (n8n container runs as user 1000:1000)
chown -R 1000:1000 ./n8n

# Set correct permissions
chmod -R 755 ./n8n

echo "✅ Permissions set correctly!"
echo "n8n directory is now owned by user 1000:1000"

# Also ensure postgres directory has correct permissions
mkdir -p ./postgres/data
chmod 755 ./postgres/data

echo "✅ PostgreSQL directory permissions set!"

echo ""
echo "🚀 Ready for deployment! You can now run:"
echo "   docker compose up -d"
