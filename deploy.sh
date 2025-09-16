#!/bin/bash

# n8n Production Deployment Script
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "${BLUE}[DEPLOY]${NC} $1"; }

print_header "🚀 n8n Production Deployment"
echo "===================================="

# Pre-flight checks
print_status "Running pre-flight checks..."

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker not found! Please install Docker."
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    print_error "Docker Compose not found! Please install Docker Compose."
    exit 1
fi

# Check .env file
if [[ ! -f ".env" ]]; then
    print_error ".env file not found!"
    echo "Please copy .env.example to .env and configure your values:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

# Load environment variables
source .env

# Validate required variables
required_vars=("DOMAIN_N8N" "POSTGRES_PASSWORD" "N8N_ENCRYPTION_KEY" "ACME_EMAIL" "TZ")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        print_error "Required variable $var is not set in .env"
        exit 1
    fi
done

print_status "✅ All required environment variables set"

# Validate DNS (basic check)
print_status "Checking DNS resolution for ${DOMAIN_N8N}..."
if command -v dig &> /dev/null; then
    if dig +short "${DOMAIN_N8N}" | grep -q .; then
        print_status "✅ DNS resolution OK for ${DOMAIN_N8N}"
    else
        print_warning "⚠️  DNS may not be configured for ${DOMAIN_N8N}"
    fi
fi

# Create directories with correct permissions
print_status "Creating directories..."
mkdir -p postgres/data n8n reverse-proxy/certs backups
chmod 755 postgres/data n8n reverse-proxy/certs backups

# Validate Docker Compose
print_status "Validating Docker Compose configuration..."
if docker compose config > /dev/null 2>&1; then
    print_status "✅ Docker Compose configuration valid"
else
    print_error "❌ Docker Compose configuration invalid:"
    docker compose config
    exit 1
fi

# Pull images
print_status "Pulling latest Docker images..."
docker compose pull

# Create acme.json for Let's Encrypt
print_status "Preparing Let's Encrypt configuration..."
touch reverse-proxy/certs/acme.json
chmod 600 reverse-proxy/certs/acme.json

# Start services
print_status "Starting services..."
docker compose up -d

# Wait for services to be healthy
print_status "Waiting for services to be healthy..."
timeout=300
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker compose ps --format "table {{.Name}}\t{{.Status}}" | grep -q "Up.*healthy.*Up.*healthy.*Up.*healthy"; then
        print_status "✅ All services are healthy!"
        break
    fi
    echo -n "."
    sleep 5
    elapsed=$((elapsed + 5))
done

if [ $elapsed -ge $timeout ]; then
    print_error "❌ Services failed to become healthy within ${timeout}s"
    print_status "Service status:"
    docker compose ps
    print_status "Logs:"
    docker compose logs
    exit 1
fi

# Post-deployment checks
print_status "Running post-deployment checks..."

# Check ports
print_status "Checking exposed ports..."
if ss -tulpen | grep -E ':(80|443)\s' > /dev/null; then
    print_status "✅ Ports 80/443 are exposed"
else
    print_warning "⚠️  Ports 80/443 not found exposed"
fi

# Check that sensitive ports are NOT exposed
if ss -tulpen | grep -E ':(5678|5432)\s' > /dev/null; then
    print_error "❌ SECURITY RISK: Ports 5678/5432 are exposed!"
    print_error "These should only be accessible internally via Docker network"
else
    print_status "✅ Sensitive ports (5678/5432) are not exposed"
fi

# Test HTTP redirect
print_status "Testing HTTP to HTTPS redirect..."
if curl -sSL -o /dev/null -w "%{http_code}" "http://${DOMAIN_N8N}" 2>/dev/null | grep -E '^(301|302)$' > /dev/null; then
    print_status "✅ HTTP to HTTPS redirect working"
else
    print_warning "⚠️  HTTP to HTTPS redirect may not be working"
fi

# Display final status
echo ""
print_header "🎉 Deployment Complete!"
echo "===================================="
print_status "Services:"
docker compose ps

echo ""
print_status "Access URLs:"
echo "  n8n Interface: https://${DOMAIN_N8N}"
echo "  Traefik Dashboard: https://traefik.${DOMAIN_N8N} (admin:password)"

echo ""
print_status "Next steps:"
echo "  1. Open https://${DOMAIN_N8N} to configure n8n"
echo "  2. Create your admin account"
echo "  3. Test webhook functionality"
echo "  4. Run: bash backup.sh (test backups)"
echo "  5. Setup monitoring and log rotation"

echo ""
print_warning "Security reminders:"
echo "  - Change Traefik dashboard password (see docker-compose.yml)"
echo "  - Keep N8N_ENCRYPTION_KEY backed up securely"
echo "  - Monitor logs: docker compose logs -f"
echo "  - Setup automated backups"
