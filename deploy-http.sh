#!/bin/bash

# n8n HTTP Deployment Script (Port 5678)
set -euo pipefail

echo "🚀 Deploying n8n on HTTP port 5678..."
echo "======================================="

# Stop any existing containers
echo "📦 Stopping existing containers..."
docker compose down

# Setup permissions
echo "🔧 Setting up permissions..."
mkdir -p ./n8n ./postgres/data
chown -R 1000:1000 ./n8n
chmod -R u+rwX ./n8n
chmod 755 ./postgres/data

# Pull latest images
echo "⬇️  Pulling latest images..."
docker compose pull

# Start the stack
echo "🚀 Starting n8n stack..."
docker compose up -d

# Wait a bit for containers to start
echo "⏳ Waiting for services to start..."
sleep 10

# Show status
echo "📊 Container status:"
docker compose ps

echo ""
echo "🎉 Deployment complete!"
echo "======================================="
echo "📍 Access URLs:"
echo "   n8n Interface: http://193.252.56.212:5678"
echo "   Credentials: admin / password (Basic Auth)"
echo ""
echo "📋 Useful commands:"
echo "   View logs: docker compose logs -f n8n"
echo "   Stop stack: docker compose down"
echo "   Restart: docker compose restart"
echo ""
echo "🔍 Troubleshooting:"
echo "   - Ensure port 5678 is open in firewall"
echo "   - Check logs if n8n doesn't start"
echo "   - Verify PostgreSQL is healthy"
