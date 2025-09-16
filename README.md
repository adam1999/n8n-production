# n8n Production Stack

Production-ready n8n deployment with Traefik reverse proxy, PostgreSQL database, and automated backups.

## 🏗️ Architecture

- **Traefik**: Reverse proxy with automatic HTTPS (Let's Encrypt)
- **PostgreSQL 16**: Database backend with health checks
- **n8n**: Workflow automation platform
- **Docker Compose**: Orchestration

## 📋 Prerequisites

- Docker & Docker Compose installed
- Domain name pointing to your server
- SSL certificates (or Let's Encrypt setup)
- Ports 80/443 available

## 🚀 Quick Start

### 1. Clone & Configure

```bash
git clone <your-repo> n8n-production
cd n8n-production

# Configure environment
cp .env.example .env
nano .env
```

### 2. Required Environment Variables

```bash
# Your domain (without https://)
DOMAIN_N8N=n8n.yourdomain.com

# Database password (strong!)
POSTGRES_PASSWORD=your_secure_password_here

# Encryption key (CRITICAL - keep this safe!)
N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)

# Timezone
TZ=Europe/Paris
```

### 3. SSL Certificates

Place your certificates in:
```
reverse-proxy/certs/
├── n8n.crt
└── n8n.key
```

### 4. Deploy

```bash
# Pull latest images
docker compose pull

# Start the stack
docker compose up -d

# Check status
docker compose ps
docker compose logs -f
```

## 🔒 Security Checklist

- [ ] Strong `POSTGRES_PASSWORD` (16+ chars)
- [ ] Secure `N8N_ENCRYPTION_KEY` (keep it safe!)
- [ ] Valid SSL certificates
- [ ] Firewall: only 80/443 exposed
- [ ] Regular backups scheduled

## 🛡️ Post-Deployment Verification

```bash
# Check running services
docker compose ps

# Verify ports (should only show 80/443)
ss -tulpen | grep -E ':80|:443|:5678|:5432'

# Test access
curl -I https://your-domain.com
```

## 💾 Backups

### Manual Backup
```bash
bash backup.sh
```

### Automated Backups (Crontab)
```bash
# Add to crontab for daily backups at 2 AM
0 2 * * * cd /path/to/n8n-production && bash backup.sh
```

## 🚨 Restore Procedure

See `restore-notes.txt` for detailed instructions.

**⚠️ CRITICAL**: Keep the same `N8N_ENCRYPTION_KEY` or credentials will be unreadable!

## 🔧 Maintenance

### Update Stack
```bash
docker compose pull
docker compose up -d
```

### View Logs
```bash
docker compose logs -f n8n
docker compose logs -f postgres
docker compose logs -f traefik
```

### Cleanup
```bash
docker system prune -f
```

## 📊 Monitoring

- n8n Web UI: `https://your-domain.com`
- Traefik Dashboard: `https://traefik.your-domain.com` (if enabled)
- Logs: `docker compose logs -f`

## 🆘 Troubleshooting

### Common Issues

1. **503 Service Unavailable**
   - Check n8n container: `docker compose logs n8n`
   - Verify domain DNS resolution

2. **Database Connection Error**
   - Check PostgreSQL: `docker compose logs postgres`
   - Verify `POSTGRES_PASSWORD` in `.env`

3. **SSL Certificate Issues**
   - Check certificate paths in `reverse-proxy/certs/`
   - Verify `tls.yml` configuration

### Health Checks
```bash
# Check container health
docker compose ps

# Database connectivity
docker compose exec postgres pg_isready -U n8n

# n8n health endpoint
curl -f http://localhost:5678/healthz
```

## ⚠️ Important Notes

- **Never commit `.env`** (contains secrets)
- **Backup `N8N_ENCRYPTION_KEY`** separately
- **Test restores** regularly
- **Monitor disk space** (logs + backups)
- **Update regularly** for security patches

## 📝 License

This configuration is provided as-is for production use.
