# Guide de démarrage rapide - Déploiement Proxmox

## 🎯 Objectif

Déployer Video AI Platform sur votre serveur Proxmox en moins de 15 minutes.

## 📋 Checklist prérequis

Avant de commencer, assurez-vous d'avoir:

- [ ] Accès à Proxmox: https://192.168.1.50:8006/
- [ ] VM Docker fonctionnelle à 192.168.1.23
- [ ] Docker et Docker Compose installés sur la VM
- [ ] SSH activé sur la VM Docker
- [ ] Au moins 8GB RAM disponible
- [ ] Au moins 50GB d'espace disque

## ⚡ Déploiement en 5 étapes

### 1️⃣ Configurer SSH (2 minutes)

```bash
# Testez la connexion
ssh root@192.168.1.23

# Si ça ne fonctionne pas, depuis Proxmox console:
systemctl start sshd
systemctl enable sshd
```

### 2️⃣ Configurer les variables d'environnement (2 minutes)

```bash
# Sur votre machine Windows
cd e:\devaiplat\video-ai-platform\infrastructure\proxmox

# Copiez le template
copy .env.example .env

# Éditez .env avec vos mots de passe
notepad .env
```

**Changez ces valeurs:**
```env
POSTGRES_PASSWORD=VotreMotDePasseSecurise123!
MINIO_ROOT_PASSWORD=VotreMotDePasseMinIO456!
KEYCLOAK_ADMIN_PASSWORD=VotreMotDePasseKeycloak789!
GRAFANA_ADMIN_PASSWORD=VotreMotDePasseGrafana012!
```

### 3️⃣ Lancer le déploiement (10-15 minutes)

**Sur Windows:**
```cmd
deploy.bat
```

**Sur Linux/Mac:**
```bash
chmod +x deploy.sh
./deploy.sh
```

Le script va automatiquement:
- ✅ Vérifier la connexion SSH
- ✅ Copier les fichiers
- ✅ Builder les images Docker
- ✅ Déployer tous les services

### 4️⃣ Vérifier le déploiement (1 minute)

```bash
# Vérifiez que tous les services sont UP
ssh root@192.168.1.23 "cd /opt/video-ai-platform && docker-compose ps"
```

Tous les services doivent afficher "Up" ou "Up (healthy)".

### 5️⃣ Accéder aux services (1 minute)

Ouvrez votre navigateur et testez:

- ✅ **API:** http://192.168.1.23:8080/swagger-ui
- ✅ **Grafana:** http://192.168.1.23:3000 (admin/VotreMotDePasse)
- ✅ **MinIO:** http://192.168.1.23:9001

## 🎉 C'est terminé!

Votre plateforme Video AI est maintenant déployée sur Proxmox!

## 🔧 Configuration post-déploiement (optionnel)

### Keycloak - Créer le realm

1. Allez sur http://192.168.1.23:8180
2. Connectez-vous (admin/VotreMotDePasse)
3. Créez un nouveau realm: `videoai`
4. Créez un client: `video-ai-platform`

### MinIO - Créer les buckets

1. Allez sur http://192.168.1.23:9001
2. Connectez-vous
3. Créez les buckets:
   - `video-uploads`
   - `video-outputs`
   - `transcriptions`

## 🐛 Problèmes courants

### Erreur SSH "Connection refused"

```bash
# Depuis la console Proxmox de la VM:
systemctl status sshd
systemctl start sshd
```

### Les images ne se construisent pas

```bash
# Assurez-vous que Docker Desktop tourne sur votre machine
docker info

# Redémarrez Docker Desktop si nécessaire
```

### Services qui ne démarrent pas

```bash
# Vérifiez les logs
ssh root@192.168.1.23
cd /opt/video-ai-platform
docker-compose logs
```

## 📞 Besoin d'aide?

Consultez le guide complet: [README.md](README.md)

## 🔄 Mise à jour

Pour mettre à jour après des changements:

```bash
# Depuis votre machine
cd infrastructure/proxmox
deploy.bat  # ou ./deploy.sh
```

## ✅ Prochaines étapes

- [ ] Tester les endpoints API
- [ ] Configurer les dashboards Grafana
- [ ] Importer des vidéos de test
- [ ] Configurer les alertes
- [ ] Mettre en place les backups
