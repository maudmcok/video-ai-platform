# 🔗 URLs & Accès - Video AI Platform

## 🌐 Interfaces Web

### Services Applicatifs

| Service | URL | Identifiants | Description |
|---------|-----|--------------|-------------|
| **Swagger API** | http://localhost:8080/swagger-ui | - | Documentation API interactive |
| **Health Check** | http://localhost:8080/q/health | - | Statut du service Projects |
| **Metrics** | http://localhost:8080/q/metrics | - | Métriques Prometheus |
| **Transcription API** | http://localhost:8001/docs | - | Documentation FastAPI |
| **Transcription Health** | http://localhost:8001/health | - | Statut worker Whisper |

### Infrastructure

| Service | URL | Identifiants | Description |
|---------|-----|--------------|-------------|
| **Keycloak Admin** | http://localhost:8180 | admin / admin | Gestion identités OAuth2 |
| **MinIO Console** | http://localhost:9001 | minioadmin / minioadmin | Stockage S3 compatible |
| **Temporal UI** | http://localhost:8088 | - | Orchestration workflows |
| **Grafana** | http://localhost:3000 | admin / admin | Dashboards monitoring |
| **Prometheus** | http://localhost:9090 | - | Métriques time-series |

## 🔌 Endpoints API

### Service Projects

**Base URL** : `http://localhost:8080`

| Méthode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| `GET` | `/q/health` | Health check | ❌ |
| `GET` | `/q/health/ready` | Readiness probe | ❌ |
| `GET` | `/q/health/live` | Liveness probe | ❌ |
| `GET` | `/q/metrics` | Métriques Prometheus | ❌ |
| `GET` | `/openapi` | Spécification OpenAPI | ❌ |
| `POST` | `/api/v1/projects` | Créer un projet | ✅ |
| `GET` | `/api/v1/projects/{id}` | Obtenir un projet | ✅ |
| `GET` | `/api/v1/projects` | Lister les projets | ✅ |
| `DELETE` | `/api/v1/projects/{id}` | Supprimer un projet | ✅ |

### Worker Transcription

**Base URL** : `http://localhost:8001`

| Méthode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| `GET` | `/` | Info service | ❌ |
| `GET` | `/health` | Health check | ❌ |
| `GET` | `/docs` | Documentation FastAPI | ❌ |
| `POST` | `/transcribe` | Créer job transcription | ❌ |
| `GET` | `/status/{job_id}` | Status d'un job | ❌ |

## 🗄️ Connexions Base de Données

### PostgreSQL

```bash
# Via Docker
docker exec -it videoai-postgres psql -U videoai -d videoai

# Via client externe
Host: localhost
Port: 5432
Database: videoai
User: videoai
Password: dev_password
```

**Connexion URL** :
```
postgresql://videoai:dev_password@localhost:5432/videoai
```

### Redis

```bash
# Via Docker
docker exec -it videoai-redis redis-cli

# Via client externe
Host: localhost
Port: 6379
Password: (aucun)
```

**Connexion URL** :
```
redis://localhost:6379
```

## 📨 Kafka

### Bootstrap Servers

```
localhost:9092
```

### Topics Principaux

- `domain-events` - Événements de domaine
- `project.created` - Projets créés
- `project.status-changed` - Changements de statut
- `asr.completed` - Transcriptions terminées
- `nlp.scored` - Analyses NLP terminées
- `clips.created` - Clips générés

### Commandes Utiles

```bash
# Lister les topics
docker exec -it videoai-kafka kafka-topics --list \
  --bootstrap-server localhost:9092

# Consommer un topic
docker exec -it videoai-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic domain-events \
  --from-beginning
```

## 🪣 MinIO (S3)

### Connexion Console Web

- **URL** : http://localhost:9001
- **Access Key** : minioadmin
- **Secret Key** : minioadmin

### Buckets Créés

- `videoai-uploads` - Uploads utilisateurs
- `videoai-assets` - Médias traités
- `videoai-outputs` - Rendus finaux

### Connexion S3 API

```
Endpoint: http://localhost:9000
Access Key: minioadmin
Secret Key: minioadmin
Region: us-east-1
```

### Exemple AWS CLI

```bash
aws s3 ls s3://videoai-uploads \
  --endpoint-url http://localhost:9000
```

## ⚙️ Temporal

### UI Web

- **URL** : http://localhost:8088
- **Namespaces** : default

### API gRPC

```
localhost:7233
```

### Workflows Disponibles

- `AnalyzeVideoWorkflow` (à implémenter)
- `Text2VideoWorkflow` (à implémenter)
- `FusionWorkflow` (à implémenter)

## 📊 Monitoring

### Prometheus

- **URL** : http://localhost:9090
- **Targets** : http://localhost:9090/targets
- **Queries** : http://localhost:9090/graph

#### Métriques Importantes

```promql
# Requêtes HTTP
http_server_requests_seconds_count

# Projets créés
projects_created_total

# Erreurs
projects_failed_total

# Latence P95
projects_processing_duration_seconds{quantile="0.95"}
```

### Grafana

- **URL** : http://localhost:3000
- **Login** : admin / admin
- **Datasource** : Prometheus (http://prometheus:9090)

#### Dashboards À Créer

1. **Projects Overview** - Métriques projets
2. **Infrastructure** - CPU/Memory/Disk
3. **Kafka** - Topics/Lag/Throughput
4. **Database** - Connexions/Queries/Locks

## 🔐 Keycloak

### Admin Console

- **URL** : http://localhost:8180
- **Login** : admin / admin

### Configuration Nécessaire

1. **Créer Realm** : `videoai`
2. **Créer Client** : `projects-service`
   - Client Protocol: openid-connect
   - Access Type: confidential
   - Valid Redirect URIs: http://localhost:8080/*
3. **Créer Utilisateur Test**
   - Username: testuser
   - Email: test@videoai.local
   - Password: test123

### Endpoints OAuth2

```
# Base URL
http://localhost:8180/realms/videoai

# Token endpoint
POST http://localhost:8180/realms/videoai/protocol/openid-connect/token

# Authorization endpoint
GET http://localhost:8180/realms/videoai/protocol/openid-connect/auth

# User Info
GET http://localhost:8180/realms/videoai/protocol/openid-connect/userinfo
```

## 🧪 Endpoints de Test

### Health Checks Rapides

```bash
# Tout en une commande (PowerShell)
curl http://localhost:8080/q/health; `
curl http://localhost:8001/health; `
curl http://localhost:9090/-/healthy; `
curl http://localhost:3000/api/health

# Tout en une commande (Bash)
curl http://localhost:8080/q/health && \
curl http://localhost:8001/health && \
curl http://localhost:9090/-/healthy && \
curl http://localhost:3000/api/health
```

### Test Complet

```bash
# 1. Health checks
curl http://localhost:8080/q/health

# 2. Métriques
curl http://localhost:8080/q/metrics

# 3. OpenAPI spec
curl http://localhost:8080/openapi

# 4. Transcription health
curl http://localhost:8001/health

# 5. Prometheus targets
curl http://localhost:9090/api/v1/targets
```

## 📝 Exemples Requêtes

### Créer un Projet

```bash
curl -X POST http://localhost:8080/api/v1/projects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "type": "ANALYZE_VIDEO",
    "config": {
      "clipTargetDurations": [30, 60],
      "language": "en",
      "stylePreset": "default",
      "enableSubtitles": true,
      "enableAnimations": false
    }
  }'
```

### Lancer une Transcription

```bash
curl -X POST http://localhost:8001/transcribe \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "test-123",
    "audio_url": "s3://videoai-uploads/test.mp3",
    "language": "en"
  }'
```

## 🔍 Résolution de Problèmes

### Vérifier que Tous les Services Sont UP

```bash
cd infrastructure/docker
docker-compose ps
```

✅ **Attendu** : Tous les services avec statut `Up`

### Tester la Connectivité DB

```bash
docker exec -it videoai-postgres pg_isready -U videoai
```

✅ **Attendu** : `accepting connections`

### Tester Kafka

```bash
docker exec -it videoai-kafka kafka-broker-api-versions \
  --bootstrap-server localhost:9092
```

✅ **Attendu** : Liste des versions API

---

**Dernière mise à jour** : 2025-01-15

**Astuce** : Bookmarkez cette page dans votre navigateur ! 🔖
