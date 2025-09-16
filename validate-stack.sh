#!/bin/bash

# n8n Stack Validation Script
set -euo pipefail

echo "🔍 n8n Production Stack - Validation"
echo "===================================="

# Check if required files exist
echo "📁 Checking required files..."
required_files=(
    "docker-compose.yml"
    ".env.example"
    ".gitignore"
    "backup.sh"
    "restore-notes.txt"
    "reverse-proxy/dynamic/tls.yml"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file"
    else
        echo "❌ Missing: $file"
        exit 1
    fi
done

# Check directory structure
echo -e "\n📂 Checking directory structure..."
required_dirs=(
    "reverse-proxy/certs"
    "reverse-proxy/dynamic"
    "postgres"
    "n8n"
    "backups"
)

for dir in "${required_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        echo "✅ $dir/"
    else
        echo "❌ Missing directory: $dir/"
        exit 1
    fi
done

# Validate Docker Compose syntax
echo -e "\n🐳 Validating Docker Compose..."
if command -v docker &> /dev/null && command -v docker compose &> /dev/null; then
    if docker compose config > /dev/null 2>&1; then
        echo "✅ docker-compose.yml syntax valid"
    else
        echo "❌ docker-compose.yml syntax error:"
        docker compose config
        exit 1
    fi
else
    echo "⚠️  Docker not available - skipping syntax check"
fi

# Check .env.example content
echo -e "\n🔧 Checking .env.example..."
if grep -q "DOMAIN_N8N=" .env.example && \
   grep -q "POSTGRES_PASSWORD=" .env.example && \
   grep -q "N8N_ENCRYPTION_KEY=" .env.example && \
   grep -q "TZ=" .env.example; then
    echo "✅ .env.example contains all required variables"
else
    echo "❌ .env.example missing required variables"
    exit 1
fi

# Check gitignore
echo -e "\n🙈 Checking .gitignore..."
if grep -q ".env" .gitignore && \
   grep -q "postgres/data/" .gitignore && \
   grep -q "n8n/" .gitignore && \
   grep -q "reverse-proxy/certs/" .gitignore; then
    echo "✅ .gitignore properly configured"
else
    echo "❌ .gitignore missing critical patterns"
    exit 1
fi

echo -e "\n🎉 Stack validation successful!"
echo -e "\n📋 Next steps:"
echo "1. Copy .env.example to .env and configure values"
echo "2. Add SSL certificates to reverse-proxy/certs/"
echo "3. Run: docker compose pull && docker compose up -d"
echo "4. Test backup script: bash backup.sh"
echo "5. Verify access at https://your-domain"
