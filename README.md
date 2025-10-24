# Video AI Platform

Plateforme de traitement vidéo intelligente avec **Analyse automatique**, **Génération Texte→Vidéo**, et **Fusion multi-vidéos**.

## Architecture

- **Backend** : Quarkus (microservices hexagonaux), Temporal.io (orchestration)
- **Workers** : Python (Whisper ASR, NLP, génération vidéo)
- **Frontend** : Angular 18+ (Module Federation)
- **Storage** : PostgreSQL, MinIO/S3, Redis
- **Messaging** : Kafka (événements), Temporal (workflows)
- **Observabilité** : OpenTelemetry, Prometheus, Grafana, ELK

## Structure du Projet

```
video-ai-platform/
├── services/              # Microservices backend
│   ├── projects/         # Service principal (Quarkus)
│   ├── media-ingest/     # Ingestion et normalisation
│   ├── transcription/    # Worker Whisper (Python)
│   ├── nlp-analysis/     # Analyse sémantique
│   ├── clipper/          # Découpage vidéo
│   ├── fusion/           # Fusion multi-vidéos
│   └── text2video/       # Génération texte→vidéo
├── workflows/            # Orchestration Temporal
│   └── temporal/
├── frontend/             # Microfrontends Angular
│   ├── shell/           # Shell principal
│   └── mfe-projects/    # MFE Projets
├── infrastructure/       # IaC et configuration
│   ├── docker/          # Docker Compose
│   ├── k8s/             # Manifests Kubernetes
│   ├── helm/            # Helm charts
│   ├── terraform/       # Terraform (cloud)
│   └── scripts/         # Scripts de déploiement
├── shared/              # Code partagé
│   ├── events/          # Schémas événements Kafka
│   └── contracts/       # Contrats OpenAPI
├── docs/                # Documentation
│   ├── ADR/             # Architecture Decision Records
│   └── security/        # Documentation sécurité
└── tests/               # Tests transverses
    ├── performance/     # Tests k6
    └── e2e/             # Tests end-to-end
```

## Prérequis

- **Java** 21+
- **Maven** 3.9+
- **Python** 3.11+
- **Node.js** 20+
- **Docker** 24+ & Docker Compose
- **kubectl** + **Helm** 3 (prod)
- **FFmpeg** 6.x (avec NVENC si GPU)

## Installation Locale

### 1. Clone + Dépendances

```bash
cd E:\devaiplat\video-ai-platform

# Services Quarkus
cd services/projects
mvnw.cmd install -DskipTests
cd ../..

# Worker Python
cd services/transcription
pip install -r requirements.txt
cd ../..

# Frontend
cd frontend/shell
npm install
cd ../..
```

### 2. Infrastructure (Docker Compose)

```bash
cd infrastructure/docker
docker-compose up -d

# Attendre initialisation (30s)
docker-compose ps
```

### 3. Migrations DB

```bash
cd services/projects
mvnw.cmd flyway:migrate
```

### 4. Démarrage Services

```bash
# Terminal 1 - Projects Service
cd services/projects
mvnw.cmd quarkus:dev

# Terminal 2 - Transcription Worker
cd services/transcription
python worker.py

# Terminal 3 - Frontend
cd frontend/shell
npm start
```

### 5. Accès

- **Frontend** : http://localhost:4200
- **API** : http://localhost:8080
- **Swagger** : http://localhost:8080/swagger-ui
- **Keycloak** : http://localhost:8180 (admin/admin)
- **MinIO** : http://localhost:9001 (minioadmin/minioadmin)
- **Temporal UI** : http://localhost:8088
- **Grafana** : http://localhost:3000 (admin/admin)

## Tests

```bash
# Unitaires
mvnw.cmd test

# Intégration
mvnw.cmd verify -Dquarkus.profile=test

# E2E
cd workflows
mvnw.cmd test

# Charge (k6)
k6 run tests/performance/create-project-load.js
```

## Déploiement Production

### Kubernetes (Helm)

```bash
# Setup cluster
kubectl create namespace videoai-production

# Secrets
kubectl create secret generic videoai-secrets \
  --from-literal=db-password=XXX \
  --from-literal=oidc-client-secret=YYY \
  -n videoai-production

# Déploiement
helm upgrade --install videoai-projects \
  infrastructure/helm/projects \
  --namespace videoai-production \
  --set image.tag=v1.0.0
```

## Sécurité

- **Auth** : OAuth2/OIDC (Keycloak)
- **Secrets** : Vault (prod), jamais en clair
- **Scans** : SAST (Semgrep), SCA (OWASP Dependency-Check), DAST (ZAP)
- **Containers** : Trivy, Cosign (signatures)
- **Network** : mTLS, Network Policies K8s

Voir [docs/security/SECURITY.md](docs/security/SECURITY.md) pour détails.

## Roadmap

### Phase 0 - Fondations (2 semaines)
- [x] Architecture hexagonale
- [x] Auth Keycloak
- [x] Service Projects (CRUD)
- [x] Infrastructure Docker Compose

### Phase 1 - Ingestion & Orchestration (3 semaines)
- [x] Media-Ingest (uploads S3)
- [x] Temporal workflows
- [x] Worker Transcription (Whisper)

### Phase 2 - Analyse & Clips (4 semaines)
- [x] NLP-Analysis (LLM)
- [x] Clipper (FFmpeg)
- [x] Subtitles + Animations
- [ ] Frontend MFE Projets

### Phase 3 - Fusion (2 semaines)
- [x] Service Fusion
- [ ] Layouts avancés
- [ ] Frontend Fusion Studio

### Phase 4 - Texte→Vidéo (4 semaines)
- [ ] Scene Planner (LLM)
- [ ] TTS (ElevenLabs/Coqui)
- [ ] Génération visuelle (Runway/SD)
- [ ] Frontend Text Studio

### Phase 5 - Durcissement (2 semaines)
- [x] Observabilité complète
- [x] Tests de charge
- [ ] Antivirus uploads
- [ ] Pentest

## Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit (`git commit -m 'Add AmazingFeature'`)
4. Push (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## Licence

MIT

## Support

- **Documentation** : [docs/](docs/)
- **Issues** : GitHub Issues
- **Email** : support@videoai.example.com
