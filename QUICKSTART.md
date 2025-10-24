# Guide de Démarrage Rapide

Ce guide vous permet de démarrer la plateforme Video AI en moins de 10 minutes.

## Prérequis

- ✅ **Java 21** - [Télécharger](https://adoptium.net/)
- ✅ **Maven 3.9+** - [Télécharger](https://maven.apache.org/download.cgi)
- ✅ **Python 3.11** - [Télécharger](https://www.python.org/downloads/)
- ✅ **Docker Desktop** - [Télécharger](https://www.docker.com/products/docker-desktop/)
- ✅ **Git** - [Télécharger](https://git-scm.com/downloads)

### Vérification des prérequis

```bash
java -version    # Java 21.x.x
mvn -version     # Maven 3.9.x
python --version # Python 3.11.x
docker --version # Docker 24.x
```

## Installation (5 minutes)

### Étape 1 : Démarrage de l'infrastructure

**Windows :**
```batch
cd E:\devaiplat\video-ai-platform
infrastructure\scripts\start-dev.bat
```

**Linux/Mac :**
```bash
cd /path/to/video-ai-platform
./infrastructure/scripts/start-dev.sh
```

Ce script va :
1. Démarrer Docker Compose (PostgreSQL, Redis, Kafka, MinIO, Keycloak, Temporal, Prometheus, Grafana)
2. Attendre l'initialisation des services (30s)
3. Exécuter les migrations de base de données

### Étape 2 : Démarrage du service Projects

Ouvrez un **nouveau terminal** :

```bash
cd services/projects
mvnw.cmd quarkus:dev    # Windows
# ou
./mvnw quarkus:dev      # Linux/Mac
```

Attendez le message :
```
Quarkus 3.6.4 started in 2.345s. Listening on: http://localhost:8080
```

### Étape 3 : Démarrage du worker Transcription

Ouvrez un **autre terminal** :

```bash
cd services/transcription

# Installation des dépendances (première fois seulement)
pip install -r requirements.txt

# Démarrage du worker
python worker.py
```

Attendez le message :
```
INFO:     Uvicorn running on http://0.0.0.0:8001
```

## Test de l'Installation

### 1. Health Checks

```bash
# Service Projects
curl http://localhost:8080/q/health

# Worker Transcription
curl http://localhost:8001/health
```

### 2. Accès aux interfaces Web

Ouvrez votre navigateur :

| Service | URL | Identifiants |
|---------|-----|--------------|
| **Swagger API** | http://localhost:8080/swagger-ui | - |
| **Keycloak** | http://localhost:8180 | admin / admin |
| **MinIO** | http://localhost:9001 | minioadmin / minioadmin |
| **Temporal UI** | http://localhost:8088 | - |
| **Grafana** | http://localhost:3000 | admin / admin |
| **Prometheus** | http://localhost:9090 | - |

### 3. Configuration Keycloak (Première fois)

1. Connectez-vous à Keycloak : http://localhost:8180
2. Créez un nouveau Realm `videoai`
3. Créez un client `projects-service`
4. Créez un utilisateur test

> **Note** : Un script d'initialisation automatique sera ajouté prochainement

## Premiers Pas

### Créer un projet d'analyse vidéo

```bash
# 1. Obtenir un token (à remplacer par vraie auth)
export TOKEN="test-token"

# 2. Créer un projet
curl -X POST http://localhost:8080/api/v1/projects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "type": "ANALYZE_VIDEO",
    "config": {
      "clipTargetDurations": [30, 60],
      "language": "en",
      "stylePreset": "default",
      "enableSubtitles": true,
      "enableAnimations": false
    },
    "estimatedDuration": 120
  }'

# 3. Récupérer le statut
curl http://localhost:8080/api/v1/projects/{project-id} \
  -H "Authorization: Bearer $TOKEN"
```

## Arrêt des Services

```bash
# Arrêt des services applicatifs
# Ctrl+C dans chaque terminal (Projects, Transcription)

# Arrêt de l'infrastructure Docker
cd infrastructure/docker
docker-compose down

# Arrêt + suppression des volumes (attention : perte de données)
docker-compose down -v
```

## Problèmes Courants

### Erreur : "Port 8080 already in use"

```bash
# Trouver le processus
netstat -ano | findstr :8080    # Windows
lsof -i :8080                   # Linux/Mac

# Arrêter le processus
taskkill /PID <PID> /F          # Windows
kill -9 <PID>                   # Linux/Mac
```

### Erreur : "Cannot connect to Docker daemon"

```bash
# Windows : Démarrer Docker Desktop
# Linux : sudo systemctl start docker
# Mac : Ouvrir Docker.app
```

### Erreur : "Flyway migration failed"

```bash
# Réinitialiser la base de données
cd infrastructure/docker
docker-compose down -v
docker-compose up -d postgres
# Attendre 10s
cd ../../services/projects
mvnw.cmd flyway:clean flyway:migrate
```

## Prochaines Étapes

- 📖 Lire la [documentation complète](README.md)
- 🏗️ Consulter l'[architecture](docs/ARCHITECTURE.md)
- 🔒 Voir les [recommandations sécurité](docs/security/SECURITY.md)
- 🧪 Lancer les [tests](docs/TESTING.md)

## Support

- **Issues** : https://github.com/your-org/video-ai-platform/issues
- **Email** : support@videoai.example.com
- **Slack** : #video-ai-platform
