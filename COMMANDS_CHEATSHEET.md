# Aide-Mémoire Commandes - Video AI Platform

## 🚀 Démarrage Rapide

### Windows

```batch
REM Infrastructure
cd E:\devaiplat\video-ai-platform
infrastructure\scripts\start-dev.bat

REM Service Projects (nouveau terminal)
cd services\projects
mvnw.cmd quarkus:dev

REM Worker Transcription (nouveau terminal)
cd services\transcription
pip install -r requirements.txt
python worker.py
```

### Linux/Mac

```bash
# Infrastructure
cd /path/to/video-ai-platform
./infrastructure/scripts/start-dev.sh

# Service Projects (nouveau terminal)
cd services/projects
./mvnw quarkus:dev

# Worker Transcription (nouveau terminal)
cd services/transcription
pip install -r requirements.txt
python worker.py
```

## 🐳 Docker Compose

```bash
# Démarrer tous les services
cd infrastructure/docker
docker-compose up -d

# Voir les logs
docker-compose logs -f

# Voir les logs d'un service spécifique
docker-compose logs -f postgres
docker-compose logs -f kafka

# Statut des services
docker-compose ps

# Arrêter
docker-compose down

# Arrêter + supprimer volumes (⚠️ perte de données)
docker-compose down -v

# Redémarrer un service
docker-compose restart postgres

# Rebuild un service
docker-compose up -d --build minio
```

## 💾 Base de Données

```bash
cd services/projects

# Info migrations
mvnw.cmd flyway:info    # Windows
./mvnw flyway:info      # Linux/Mac

# Exécuter migrations
mvnw.cmd flyway:migrate

# Nettoyer DB (⚠️ supprime toutes les données)
mvnw.cmd flyway:clean

# Réparer metadata Flyway
mvnw.cmd flyway:repair

# Connexion directe PostgreSQL
docker exec -it videoai-postgres psql -U videoai -d videoai

# Export DB
docker exec videoai-postgres pg_dump -U videoai videoai > backup.sql

# Import DB
cat backup.sql | docker exec -i videoai-postgres psql -U videoai -d videoai
```

## 🏗️ Build & Tests

```bash
cd services/projects

# Compiler (sans tests)
mvnw.cmd clean compile -DskipTests

# Tests unitaires
mvnw.cmd test

# Tests intégration
mvnw.cmd verify

# Tests avec couverture
mvnw.cmd test jacoco:report
# Rapport: target/site/jacoco/index.html

# Build complet
mvnw.cmd clean package

# Mode dev (hot reload)
mvnw.cmd quarkus:dev

# Build native (GraalVM)
mvnw.cmd package -Pnative
```

## 🔍 Debugging

```bash
# Mode debug Quarkus (port 5005)
mvnw.cmd quarkus:dev -Ddebug=5005

# Logs verbeux
mvnw.cmd quarkus:dev -Dquarkus.log.level=DEBUG

# Profiling
mvnw.cmd quarkus:dev -Dquarkus.vertx.eventbus.metrics.enabled=true
```

## 📦 Docker Images

```bash
# Build image Projects
cd services/projects
docker build -t videoai/projects:latest .

# Build image Transcription
cd services/transcription
docker build -t videoai/transcription:latest .

# Run image
docker run -p 8080:8080 \
  -e DB_PASSWORD=dev_password \
  -e KAFKA_BOOTSTRAP_SERVERS=host.docker.internal:9092 \
  videoai/projects:latest

# Push registry
docker tag videoai/projects:latest registry.example.com/videoai/projects:v1.0.0
docker push registry.example.com/videoai/projects:v1.0.0
```

## ☸️ Kubernetes (Production)

```bash
# Créer namespace
kubectl create namespace videoai-production

# Créer secrets
kubectl create secret generic videoai-secrets \
  --from-literal=db-password=XXX \
  --from-literal=oidc-client-secret=YYY \
  -n videoai-production

# Déployer avec Helm
helm upgrade --install videoai-projects \
  infrastructure/helm/projects \
  --namespace videoai-production \
  --set image.tag=v1.0.0 \
  --wait

# Voir status
kubectl get pods -n videoai-production
kubectl get services -n videoai-production

# Logs
kubectl logs -f deployment/videoai-projects -n videoai-production

# Port-forward
kubectl port-forward service/videoai-projects 8080:8080 -n videoai-production

# Rollback
helm rollback videoai-projects -n videoai-production
```

## 🔐 Keycloak

```bash
# Créer Realm via CLI
docker exec -it videoai-keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin --password admin

docker exec -it videoai-keycloak /opt/keycloak/bin/kcadm.sh create realms \
  -s realm=videoai \
  -s enabled=true

# Export Realm
docker exec -it videoai-keycloak /opt/keycloak/bin/kc.sh export \
  --dir /tmp/export \
  --realm videoai
```

## 📊 MinIO

```bash
# Créer bucket via CLI
docker exec -it videoai-minio mc alias set myminio http://localhost:9000 minioadmin minioadmin
docker exec -it videoai-minio mc mb myminio/videoai-test

# Lister buckets
docker exec -it videoai-minio mc ls myminio

# Upload fichier
docker exec -it videoai-minio mc cp /tmp/test.mp4 myminio/videoai-uploads/

# Politique publique
docker exec -it videoai-minio mc policy set download myminio/videoai-outputs
```

## 🔥 Kafka

```bash
# Créer topic
docker exec -it videoai-kafka kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --partitions 3 \
  --replication-factor 1

# Lister topics
docker exec -it videoai-kafka kafka-topics --list \
  --bootstrap-server localhost:9092

# Consommer messages
docker exec -it videoai-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic domain-events \
  --from-beginning

# Produire message
docker exec -it videoai-kafka kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic test-topic

# Décrire consumer groups
docker exec -it videoai-kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --describe --group my-group
```

## 📈 Monitoring

```bash
# Prometheus - vérifier targets
curl http://localhost:9090/api/v1/targets

# Métriques service
curl http://localhost:8080/q/metrics

# Health check
curl http://localhost:8080/q/health
curl http://localhost:8080/q/health/ready
curl http://localhost:8080/q/health/live

# Transcription health
curl http://localhost:8001/health
```

## 🧪 Tests API

```bash
# Créer projet (avec auth)
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
    }
  }'

# Get projet
curl http://localhost:8080/api/v1/projects/{id} \
  -H "Authorization: Bearer $TOKEN"

# Lister projets
curl "http://localhost:8080/api/v1/projects?page=0&size=20" \
  -H "Authorization: Bearer $TOKEN"

# Transcription job
curl -X POST http://localhost:8001/transcribe \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "test-123",
    "audio_url": "s3://videoai-uploads/test.mp3",
    "language": "en"
  }'

# Status transcription
curl http://localhost:8001/status/{job_id}
```

## 🛠️ Utilitaires

```bash
# Nettoyer Maven
mvnw.cmd clean
rm -rf target/

# Nettoyer Docker
docker system prune -a
docker volume prune

# Vérifier ports occupés (Windows)
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# Vérifier ports occupés (Linux/Mac)
lsof -i :8080
kill -9 <PID>

# Variables d'environnement
# Windows
set DB_PASSWORD=secret
set KAFKA_BOOTSTRAP_SERVERS=localhost:9092

# Linux/Mac
export DB_PASSWORD=secret
export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
```

## 🔄 Git

```bash
# Clone
git clone https://github.com/your-org/video-ai-platform.git

# Nouvelle branche
git checkout -b feature/my-feature

# Commit
git add .
git commit -m "feat: add new feature"

# Push
git push origin feature/my-feature

# Pull Request
gh pr create --title "Add new feature" --body "Description"
```

## 📚 Documentation

```bash
# Générer Javadoc
mvnw.cmd javadoc:javadoc
# Rapport: target/site/apidocs/index.html

# OpenAPI spec
curl http://localhost:8080/openapi > openapi.json

# Swagger UI
open http://localhost:8080/swagger-ui
```

## 🚨 Troubleshooting

```bash
# Réinitialiser complètement
cd infrastructure/docker
docker-compose down -v
docker system prune -a -f
docker-compose up -d
cd ../../services/projects
mvnw.cmd flyway:clean flyway:migrate

# Vérifier connectivité DB
docker exec -it videoai-postgres pg_isready -U videoai

# Vérifier logs erreurs
docker-compose logs -f | grep ERROR

# Rebuild total Maven
mvnw.cmd clean install -U -DskipTests

# Clear cache Python
rm -rf __pycache__
pip cache purge
```

---

**Dernière mise à jour** : 2025-01-15
