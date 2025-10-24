# ✅ Installation Complète - Video AI Platform

**Date** : 15 Janvier 2025
**Localisation** : `E:\devaiplat\video-ai-platform`
**Version** : 1.0.0-SNAPSHOT

---

## 🎉 Projet Créé avec Succès !

Le projet **Video AI Platform** a été créé avec succès dans `E:\devaiplat\video-ai-platform`.

### 📊 Statistiques

- **Total fichiers créés** : 30+
- **Lignes de code** : ~3500+
- **Technologies** : Java 21, Python 3.11, PostgreSQL, Kafka, Docker
- **Architecture** : Microservices Hexagonaux

---

## 📁 Structure Créée

```
E:\devaiplat\video-ai-platform\
│
├── 📄 README.md                    # Documentation principale
├── 📄 QUICKSTART.md                # Guide démarrage rapide (10 min)
├── 📄 PROJECT_STATUS.md            # État du projet
├── 📄 COMMANDS_CHEATSHEET.md       # Aide-mémoire commandes
├── 📄 .gitignore                   # Fichiers à ignorer
│
├── 📂 docs/                        # Documentation technique
│   ├── 📂 ADR/
│   │   └── 001-architecture-hexagonale.md
│   └── 📂 security/
│       └── SECURITY.md             # Analyse STRIDE + OWASP
│
├── 📂 infrastructure/              # Infrastructure as Code
│   ├── 📂 docker/
│   │   ├── docker-compose.yml      # Stack complète (13 services)
│   │   └── init-db.sql
│   ├── 📂 prometheus/
│   │   └── prometheus.yml
│   ├── 📂 grafana/                 # À configurer
│   ├── 📂 helm/                    # Kubernetes charts (à créer)
│   ├── 📂 k8s/                     # Manifests (à créer)
│   └── 📂 scripts/
│       ├── start-dev.bat           # Script Windows
│       └── start-dev.sh            # Script Linux/Mac
│
├── 📂 services/                    # Microservices
│   │
│   ├── 📂 projects/                # Service principal (Quarkus)
│   │   ├── pom.xml                 # Maven dependencies
│   │   ├── mvnw.cmd / mvnw         # Maven Wrapper
│   │   └── src/
│   │       ├── main/
│   │       │   ├── java/com/videoai/projects/
│   │       │   │   ├── domain/
│   │       │   │   │   ├── model/          # 8 classes
│   │       │   │   │   ├── event/          # 3 classes
│   │       │   │   │   └── exception/      # 1 classe
│   │       │   │   ├── application/
│   │       │   │   │   └── port/out/       # 2 interfaces
│   │       │   │   └── infrastructure/     # À implémenter
│   │       │   └── resources/
│   │       │       ├── application.properties
│   │       │       └── db/migration/
│   │       │           └── V1.0.0__initial_schema.sql
│   │       └── test/                       # À créer
│   │
│   └── 📂 transcription/           # Worker Python (Whisper)
│       ├── worker.py               # API FastAPI (330 lignes)
│       ├── requirements.txt
│       └── Dockerfile
│
├── 📂 frontend/                    # Angular Microfrontends (à créer)
│   ├── shell/
│   └── mfe-projects/
│
├── 📂 shared/                      # Code partagé (à créer)
│   ├── events/
│   └── contracts/
│
└── 📂 tests/                       # Tests E2E (à créer)
    ├── performance/
    └── e2e/
```

---

## 🚀 Démarrage en 3 Étapes

### Étape 1️⃣ : Infrastructure (2 minutes)

**Windows :**
```batch
cd E:\devaiplat\video-ai-platform
infrastructure\scripts\start-dev.bat
```

**Linux/Mac :**
```bash
cd /e/devaiplat/video-ai-platform
./infrastructure/scripts/start-dev.sh
```

✅ **Services démarrés** :
- PostgreSQL (5432)
- Redis (6379)
- Kafka (9092)
- MinIO (9000/9001)
- Keycloak (8180)
- Temporal (7233) + UI (8088)
- Prometheus (9090)
- Grafana (3000)

### Étape 2️⃣ : Service Projects (1 minute)

**Nouveau terminal :**
```bash
cd services\projects
mvnw.cmd quarkus:dev    # Windows
# ou
./mvnw quarkus:dev      # Linux/Mac
```

✅ **Attendez** : `Quarkus started in 2.3s. Listening on: http://localhost:8080`

### Étape 3️⃣ : Worker Transcription (1 minute)

**Nouveau terminal :**
```bash
cd services\transcription
pip install -r requirements.txt
python worker.py
```

✅ **Attendez** : `Uvicorn running on http://0.0.0.0:8001`

---

## ✅ Vérification de l'Installation

### 1. Health Checks

```bash
# Service Projects
curl http://localhost:8080/q/health
# ✅ Attendu: {"status":"UP"}

# Worker Transcription
curl http://localhost:8001/health
# ✅ Attendu: {"status":"healthy","model":"base","device":"cpu"}
```

### 2. Accès Interfaces Web

| Service | URL | Login | Statut |
|---------|-----|-------|--------|
| **Swagger API** | http://localhost:8080/swagger-ui | - | ✅ |
| **Keycloak** | http://localhost:8180 | admin/admin | ✅ |
| **MinIO Console** | http://localhost:9001 | minioadmin/minioadmin | ✅ |
| **Temporal UI** | http://localhost:8088 | - | ✅ |
| **Grafana** | http://localhost:3000 | admin/admin | ✅ |
| **Prometheus** | http://localhost:9090 | - | ✅ |

### 3. Base de Données

```bash
# Connexion PostgreSQL
docker exec -it videoai-postgres psql -U videoai -d videoai

# Vérifier tables
\dt
# ✅ Attendu: users, projects, media, clips, scenes, transcripts, outputs
```

---

## 📚 Documentation Disponible

1. **[QUICKSTART.md](QUICKSTART.md)** - Guide démarrage rapide détaillé
2. **[README.md](README.md)** - Vue d'ensemble & architecture
3. **[PROJECT_STATUS.md](PROJECT_STATUS.md)** - État actuel + roadmap
4. **[COMMANDS_CHEATSHEET.md](COMMANDS_CHEATSHEET.md)** - Toutes les commandes utiles
5. **[docs/security/SECURITY.md](docs/security/SECURITY.md)** - Analyse sécurité STRIDE/OWASP
6. **[docs/ADR/001-architecture-hexagonale.md](docs/ADR/001-architecture-hexagonale.md)** - Décision architecture

---

## 🎯 Prochaines Actions Recommandées

### Aujourd'hui (2h)

1. ✅ Lire [QUICKSTART.md](QUICKSTART.md)
2. ✅ Démarrer infrastructure
3. ✅ Tester accès aux interfaces
4. ⏳ Configurer Keycloak :
   - Créer realm `videoai`
   - Créer client `projects-service`
   - Créer utilisateur test

### Cette Semaine (10h)

5. ⏳ Implémenter Use Cases (Application Layer)
   - `CreateProjectUseCase`
   - `GetProjectStatusUseCase`
   - `ListUserProjectsUseCase`

6. ⏳ Implémenter Adapters (Infrastructure)
   - REST Controller
   - Repository Panache
   - Event Publisher Kafka

7. ⏳ Créer tests unitaires Domain
8. ⏳ Créer tests intégration Repository

### Semaine Prochaine (20h)

9. ⏳ Implémenter Temporal Workflows
10. ⏳ Intégrer services (Media-Ingest, NLP, Clipper)
11. ⏳ Tests end-to-end complets
12. ⏳ Frontend Angular Shell

---

## 🔧 Troubleshooting Rapide

### Erreur : "Port 8080 already in use"

```bash
# Windows
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# Linux/Mac
lsof -i :8080
kill -9 <PID>
```

### Erreur : "Cannot connect to Docker"

- **Windows** : Démarrer Docker Desktop
- **Linux** : `sudo systemctl start docker`
- **Mac** : Ouvrir Docker.app

### Erreur : "Flyway migration failed"

```bash
cd infrastructure/docker
docker-compose down -v
docker-compose up -d postgres
# Attendre 10s
cd ../../services/projects
mvnw.cmd flyway:clean flyway:migrate
```

### Logs en cas de problème

```bash
# Logs infrastructure
cd infrastructure/docker
docker-compose logs -f

# Logs service spécifique
docker-compose logs -f postgres
docker-compose logs -f kafka

# Logs Quarkus
# (visible dans le terminal où tourne quarkus:dev)
```

---

## 📞 Support & Ressources

### Documentation

- **GitHub** : (à définir)
- **Confluence** : (à définir)
- **Slack** : #video-ai-platform

### Contacts

- **Tech Lead** : tech-lead@videoai.example.com
- **Architecte** : architect@videoai.example.com
- **DevOps** : devops@videoai.example.com

### Liens Utiles

- [Quarkus Guides](https://quarkus.io/guides/)
- [Temporal Documentation](https://docs.temporal.io/)
- [Whisper GitHub](https://github.com/openai/whisper)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

---

## ⚡ Commandes Rapides

```bash
# Démarrer infrastructure
infrastructure\scripts\start-dev.bat

# Démarrer Projects
cd services\projects && mvnw.cmd quarkus:dev

# Démarrer Transcription
cd services\transcription && python worker.py

# Health checks
curl http://localhost:8080/q/health
curl http://localhost:8001/health

# Arrêter infrastructure
cd infrastructure\docker && docker-compose down

# Rebuild complet
mvnw.cmd clean install -DskipTests
```

---

## 🎊 Félicitations !

Votre environnement **Video AI Platform** est maintenant prêt !

Pour toute question, consultez la documentation ou contactez l'équipe technique.

**Bon développement ! 🚀**

---

**Dernière mise à jour** : 2025-01-15
**Version** : 1.0.0-SNAPSHOT
