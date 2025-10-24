# Déploiement sur Proxmox - Video AI Platform

## 📋 Vue d'ensemble

Ce guide explique comment déployer Video AI Platform sur votre serveur Proxmox avec Docker.

**Environnement cible:**
- Proxmox VE: https://192.168.1.50:8006/
- VM Docker: 192.168.1.23
- Réseau Docker: 172.17.0.0/16

## 🏗️ Architecture de déploiement

```
Proxmox (192.168.1.50)
    └─ VM Docker (192.168.1.23)
        ├─ PostgreSQL      → 5432
        ├─ Redis           → 6379
        ├─ Kafka           → 9092, 29092
        ├─ MinIO           → 9000, 9001
        ├─ Keycloak        → 8180
        ├─ Temporal        → 7233
        ├─ Temporal UI     → 8088
        ├─ Prometheus      → 9090
        ├─ Grafana         → 3000
        ├─ Projects API    → 8080
        └─ Transcription   → (worker)
```

## ✅ Prérequis

### Sur votre machine locale

- [x] Git
- [x] Docker (pour builder les images)
- [x] SSH client
- [x] Bash (Git Bash sur Windows)

### Sur le serveur Proxmox Docker (192.168.1.23)

- [x] Docker Engine installé
- [x] Docker Compose installé
- [x] SSH activé
- [x] Minimum 8GB RAM
- [x] Minimum 50GB disque

## 🚀 Déploiement

### Étape 1: Configuration SSH

Configurez l'accès SSH à votre VM Docker:

```bash
# Testez la connexion SSH
ssh root@192.168.1.23

# (Optionnel) Configurez une clé SSH pour éviter le mot de passe
ssh-copy-id root@192.168.1.23
```

### Étape 2: Configuration des variables d'environnement

```bash
cd infrastructure/proxmox

# Copiez le fichier d'exemple
cp .env.example .env

# Éditez .env avec vos mots de passe sécurisés
nano .env  # ou votre éditeur préféré
```

**Important:** Changez TOUS les mots de passe par défaut!

### Étape 3: Déploiement automatique

```bash
# Rendez le script exécutable
chmod +x deploy.sh

# Lancez le déploiement
./deploy.sh
```

Le script va:
1. ✅ Vérifier la connexion SSH
2. ✅ Créer les répertoires sur le serveur distant
3. ✅ Copier les fichiers de configuration
4. ✅ Builder les images Docker
5. ✅ Transférer les images au serveur
6. ✅ Démarrer tous les services

### Étape 4: Vérification

Une fois le déploiement terminé, vérifiez que tous les services sont UP:

```bash
ssh root@192.168.1.23 "cd /opt/video-ai-platform && docker-compose ps"
```

## 🌐 Accès aux services

Une fois déployé, accédez à vos services:

| Service | URL | Identifiants par défaut |
|---------|-----|------------------------|
| **API Swagger** | http://192.168.1.23:8080/swagger-ui | - |
| **Grafana** | http://192.168.1.23:3000 | admin / (voir .env) |
| **Prometheus** | http://192.168.1.23:9090 | - |
| **Keycloak** | http://192.168.1.23:8180 | admin / (voir .env) |
| **MinIO Console** | http://192.168.1.23:9001 | (voir .env) |
| **Temporal UI** | http://192.168.1.23:8088 | - |

## 🔧 Gestion des services

### Voir les logs

```bash
ssh root@192.168.1.23
cd /opt/video-ai-platform

# Tous les services
docker-compose logs -f

# Un service spécifique
docker-compose logs -f projects-service
docker-compose logs -f postgres
```

### Redémarrer un service

```bash
# Redémarrer tous les services
docker-compose restart

# Redémarrer un service spécifique
docker-compose restart projects-service
```

### Mettre à jour l'application

```bash
# Depuis votre machine locale
cd infrastructure/proxmox
./deploy.sh
```

### Arrêter tous les services

```bash
ssh root@192.168.1.23
cd /opt/video-ai-platform
docker-compose down
```

### Arrêter et supprimer les volumes (ATTENTION: perte de données!)

```bash
docker-compose down -v
```

## 📊 Monitoring

### Health Checks

```bash
# Vérifier la santé de l'API
curl http://192.168.1.23:8080/q/health

# Vérifier les métriques
curl http://192.168.1.23:8080/q/metrics
```

### Dashboards Grafana

1. Accédez à http://192.168.1.23:3000
2. Connectez-vous avec admin / (votre mot de passe)
3. Importez les dashboards depuis infrastructure/grafana/

## 🔐 Configuration post-déploiement

### 1. Keycloak

```bash
# Accédez à http://192.168.1.23:8180
# Créez un realm "videoai"
# Créez un client "video-ai-platform"
# Configurez les redirects URIs
```

### 2. MinIO

```bash
# Accédez à http://192.168.1.23:9001
# Créez les buckets:
- video-uploads
- video-outputs
- transcriptions
```

### 3. Prometheus

Les targets sont auto-configurées via docker-compose.

## 🐛 Dépannage

### Les services ne démarrent pas

```bash
# Vérifier les logs
docker-compose logs

# Vérifier l'espace disque
df -h

# Vérifier la mémoire
free -h
```

### Impossible de se connecter en SSH

```bash
# Depuis Proxmox, accédez à la console de la VM
# Vérifiez que SSH est actif:
systemctl status sshd
systemctl start sshd
systemctl enable sshd
```

### Les images ne se construisent pas

```bash
# Vérifiez que Docker Desktop est démarré sur votre machine locale
docker info

# Nettoyez le cache Docker
docker system prune -a
```

## 📁 Structure des fichiers

```
infrastructure/proxmox/
├── docker-compose.proxmox.yml  # Configuration Docker Compose pour Proxmox
├── .env.example                # Template des variables d'environnement
├── .env                        # Vos variables (ignoré par Git)
├── deploy.sh                   # Script de déploiement automatique
└── README.md                   # Ce fichier
```

## 🔄 Mise à jour

Pour mettre à jour une version:

```bash
# 1. Committez vos changements sur GitHub
git add .
git commit -m "Update: votre message"
git push

# 2. Sur votre machine locale, buildez et déployez
cd infrastructure/proxmox
./deploy.sh
```

## 📞 Support

Pour toute question:
- Documentation principale: ../../README.md
- Guide de démarrage rapide: ../../QUICKSTART.md
- Commandes utiles: ../../COMMANDS_CHEATSHEET.md

## ⚠️ Sécurité

**IMPORTANT pour la production:**

- [ ] Changez TOUS les mots de passe par défaut
- [ ] Configurez un firewall (UFW, iptables)
- [ ] Activez HTTPS (reverse proxy Nginx/Traefik)
- [ ] Configurez des backups automatiques
- [ ] Restreignez l'accès SSH (clés uniquement)
- [ ] Mettez à jour régulièrement les images Docker

## 📝 Notes

- L'environnement de qualification utilise le réseau 172.18.0.0/16
- Les volumes Docker persistent les données
- Les logs sont stockés dans les conteneurs Docker
- Le monitoring est activé par défaut
