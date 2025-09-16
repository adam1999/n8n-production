# 📋 Checklist Déploiement n8n - Jour J

## 🚀 Pré-déploiement

### ✅ Prérequis serveur
- [ ] Docker + Docker Compose installés
- [ ] Firewall configuré (ports 80/443 ouverts uniquement)
- [ ] DNS configuré (A record vers votre IP)
- [ ] Utilisateur non-root avec sudo

### ✅ Préparation fichiers
- [ ] Repo cloné sur le serveur
- [ ] `.env` configuré (copié depuis `.env.example`)
- [ ] Certificats SSL placés dans `reverse-proxy/certs/`
  - [ ] `n8n.crt` (certificat)
  - [ ] `n8n.key` (clé privée - chmod 600)

## 🔧 Variables .env critiques

```bash
# Vérifiez ces valeurs avant déploiement:
TZ=Europe/Paris                           # ✅ Votre timezone
DOMAIN_N8N=n8n.votredomaine.com          # ✅ SANS https://
POSTGRES_PASSWORD=VotreMotDePasseSecure   # ✅ 16+ caractères
N8N_ENCRYPTION_KEY=VotreCleDeChiffrement  # ✅ Base64, 32 chars min
```

**🚨 BACKUP `N8N_ENCRYPTION_KEY` séparément - perte = données irrécupérables !**

## 🧪 Tests de validation

### 1. Syntaxe Docker Compose
```bash
cd n8n-production
docker compose config  # Doit être propre
```

### 2. Script de validation
```bash
bash validate-stack.sh  # Tous les ✅ requis
```

## 🚀 Déploiement

### 1. Pull des images
```bash
docker compose pull
```

### 2. Démarrage
```bash
docker compose up -d
```

### 3. Vérification des services
```bash
docker compose ps
# Attendu: 3 services UP (healthy)
```

## 🔍 Vérifications post-déploiement

### 1. Ports exposés (sécurité critique)
```bash
ss -tulpen | grep -E ':(80|443)\s'
# Attendu: 80/443 par Traefik uniquement

ss -tulpen | grep -E ':(5678|5432)\s' || echo "✅ OK: 5678/5432 NON exposés"
# Attendu: "OK: 5678/5432 NON exposés"
```

### 2. Certificat SSL
```bash
openssl s_client -connect ${DOMAIN_N8N}:443 -servername ${DOMAIN_N8N} </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer
# Vérifiez: Subject et Issuer corrects
```

### 3. Redirection HTTP → HTTPS
```bash
curl -I http://${DOMAIN_N8N}
# Attendu: 301/302 + Location: https://
```

### 4. Santé des services
```bash
# Logs en temps réel
docker compose logs -f traefik
docker compose logs -f n8n
docker compose logs -f postgres

# Healthchecks
docker compose ps
# Tous services: Up + healthy
```

### 5. Dashboard Traefik (optionnel)
```bash
# Test accès dashboard avec basic auth
curl -u admin:password https://traefik.${DOMAIN_N8N}
# Attendu: 200 OK + HTML dashboard
```

## 🎯 Tests fonctionnels

### 1. Accès n8n
- [ ] `https://votre-domaine.com` accessible
- [ ] Page de création compte admin s'affiche
- [ ] Création compte admin réussie
- [ ] Login/logout fonctionnel

### 2. Webhooks
- [ ] Créer workflow test avec webhook
- [ ] Tester endpoint: `https://votre-domaine.com/webhook/test`

### 3. Base de données
- [ ] Créer/modifier workflow → sauvegarde OK
- [ ] Redémarrer stack → données persistées

## 💾 Test des sauvegardes

```bash
# Test backup
bash backup.sh
ls -la backups/
# Vérifiez: fichier backup récent créé

# Test connectivité DB
docker compose exec postgres pg_isready -U n8n
# Attendu: accepting connections
```

## 🚨 Troubleshooting rapide

### 503 Service Unavailable
```bash
docker compose logs n8n
# Vérifiez: n8n démarré + healthy
```

### Certificat SSL invalide
```bash
ls -la reverse-proxy/certs/
# Vérifiez: n8n.crt + n8n.key présents
# Vérifiez: permissions (600 pour .key)
```

### Base de données inaccessible
```bash
docker compose logs postgres
# Vérifiez: PostgreSQL démarré + accepting connections
```

## ✅ Déploiement réussi !

Si tous les tests passent:
- [ ] n8n accessible via HTTPS
- [ ] Dashboard Traefik protégé
- [ ] Pas de ports sensibles exposés
- [ ] Backups fonctionnels
- [ ] Logs propres

**🎉 Production ready !**

---

## 📝 Maintenance

### Mises à jour
```bash
docker compose pull
docker compose up -d
```

### Monitoring quotidien
```bash
docker compose ps        # Santé services
df -h                    # Espace disque
docker system df         # Images Docker
```

### Backups automatisés
Ajoutez à crontab:
```bash
0 2 * * * cd /path/to/n8n-production && bash backup.sh
```
