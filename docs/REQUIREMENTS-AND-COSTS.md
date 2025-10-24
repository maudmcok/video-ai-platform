# Video AI Platform - Besoins, Licences et Coûts

## 📋 Table des matières

1. [Licences Logicielles](#licences-logicielles)
2. [Besoins en Capacité](#besoins-en-capacité)
3. [Coûts d'Infrastructure](#coûts-dinfrastructure)
4. [Optimisations et Automatisation](#optimisations-et-automatisation)
5. [Accélération GPU avec CUDA](#accélération-gpu-avec-cuda)
6. [Recommandations par Échelle](#recommandations-par-échelle)

---

## 🔑 Licences Logicielles

### Composants Open Source (Gratuits)

| Composant | Licence | Utilisation | Coût |
|-----------|---------|-------------|------|
| **Quarkus** | Apache 2.0 | Framework backend | ✅ Gratuit |
| **PostgreSQL** | PostgreSQL License | Base de données | ✅ Gratuit |
| **Redis** | BSD-3-Clause | Cache | ✅ Gratuit |
| **Apache Kafka** | Apache 2.0 | Message broker | ✅ Gratuit |
| **MinIO** | AGPL v3 | Stockage objet | ✅ Gratuit (communautaire) |
| **Keycloak** | Apache 2.0 | Authentification | ✅ Gratuit |
| **Temporal** | MIT | Orchestration workflows | ✅ Gratuit |
| **Prometheus** | Apache 2.0 | Métriques | ✅ Gratuit |
| **Grafana** | AGPL v3 | Visualisation | ✅ Gratuit |
| **OpenAI Whisper** | MIT | Transcription audio | ✅ Gratuit |
| **FFmpeg** | LGPL/GPL | Traitement vidéo | ✅ Gratuit |
| **Docker** | Apache 2.0 | Conteneurisation | ✅ Gratuit |

**Total licences logicielles: 0€ pour usage interne**

### ⚠️ Considérations Commerciales

Si vous **commercialisez** l'application comme SaaS:
- **MinIO (AGPL v3)**: Nécessite de publier le code source si modifié, OU acheter licence commerciale (~$2,000/an)
- **Grafana (AGPL v3)**: Licence commerciale disponible si besoin (~$1,000/an)
- **Alternative**: Remplacer par des équivalents (AWS S3 compatible, Kibana, etc.)

---

## 💻 Besoins en Capacité

### Configuration Minimale (Dev/Test)

**Une seule machine:**
- CPU: 4 cores (8 threads)
- RAM: 16 GB
- Stockage: 100 GB SSD
- GPU: Optionnel (pour Whisper CPU)

**Charge supportée:**
- 1-2 vidéos simultanées
- ~100 utilisateurs/jour
- Temps de transcription: 1h vidéo = ~30-45 min

**Coût hardware:** ~1,500€ (serveur d'occasion)

---

### Configuration Qualification (Votre Proxmox actuel)

**Recommandé pour votre setup:**

| Service | CPU | RAM | Stockage | Notes |
|---------|-----|-----|----------|-------|
| PostgreSQL | 2 cores | 2 GB | 50 GB | Données transactionnelles |
| Redis | 1 core | 1 GB | 10 GB | Cache |
| Kafka + Zookeeper | 2 cores | 3 GB | 20 GB | Message queue |
| MinIO | 2 cores | 2 GB | 500 GB | Stockage vidéos |
| Keycloak | 1 core | 1 GB | 5 GB | Auth |
| Temporal | 2 cores | 2 GB | 10 GB | Workflows |
| Prometheus + Grafana | 1 core | 2 GB | 50 GB | Monitoring |
| **Projects Service** | 2 cores | 2 GB | - | API REST |
| **Transcription Worker** | 4 cores | 8 GB | - | Whisper (CPU) |
| **Transcription Worker + GPU** | 4 cores | 4 GB | - | Whisper (GPU) |

**Total recommandé:**
- **CPU:** 16-20 cores
- **RAM:** 24-32 GB
- **Stockage:** 1 TB (évolutif)
- **GPU:** NVIDIA RTX 3060+ (12GB VRAM) - **Optionnel mais recommandé**

**Charge supportée:**
- 5-10 vidéos simultanées
- ~1,000 utilisateurs/jour
- Temps de transcription GPU: 1h vidéo = ~3-5 min (10x plus rapide!)

**Coût hardware:** ~3,000-5,000€

---

### Configuration Production (Scalable)

**Architecture distribuée:**

**Cluster Kubernetes (3 nodes minimum):**

| Node Type | Specs | Quantité | Usage |
|-----------|-------|----------|-------|
| **Control Plane** | 4 CPU, 8 GB RAM | 3 | Orchestration |
| **Worker - Standard** | 8 CPU, 16 GB RAM, 200 GB SSD | 3-5 | Services API, DB |
| **Worker - GPU** | 8 CPU, 32 GB RAM, RTX 4090 | 2-4 | Transcription, AI |
| **Storage Node** | 4 CPU, 8 GB RAM, 10 TB HDD | 2 | MinIO (réplication) |

**Total pour 1,000 utilisateurs actifs simultanés:**
- **CPU:** 80-120 cores
- **RAM:** 200-300 GB
- **GPU:** 2-4 cartes (RTX 4090 ou A4000)
- **Stockage:** 20-50 TB

**Charge supportée:**
- 50-100 vidéos simultanées
- ~100,000 utilisateurs/jour
- Haute disponibilité (99.9% uptime)

**Coût hardware:** ~50,000-100,000€

**Coût Cloud (alternative):**
- AWS/GCP/Azure: ~5,000-10,000€/mois
- GPU instances: ~2-5€/heure selon GPU

---

## 💰 Coûts d'Infrastructure

### Hébergement On-Premise (Votre Proxmox)

**Investissement initial:**
- Serveur Proxmox existant: ✅ Déjà possédé
- GPU NVIDIA RTX 3060/4060: ~400-600€
- Stockage additionnel (2TB SSD): ~200-300€
- **Total:** ~600-900€

**Coûts récurrents:**
- Électricité (500W x 24h x 30j x 0.15€/kWh): ~55€/mois
- Internet business (si nécessaire): 50-100€/mois
- Maintenance: ~50€/mois (backups, mises à jour)
- **Total:** ~155-205€/mois

**Avantages:**
- ✅ Contrôle total
- ✅ Données on-premise
- ✅ Pas de facturation à l'usage
- ✅ Pas de limite de bande passante

**Inconvénients:**
- ⚠️ Vous gérez tout
- ⚠️ Scaling manuel
- ⚠️ Pas de SLA

---

### Cloud Public

**AWS/GCP/Azure (Estimation mensuelle):**

| Service | AWS Équivalent | Coût/mois |
|---------|----------------|-----------|
| PostgreSQL | RDS PostgreSQL (db.t3.medium) | ~80€ |
| Redis | ElastiCache (cache.t3.small) | ~40€ |
| Kafka | MSK (kafka.m5.large x2) | ~300€ |
| Object Storage | S3 (500 GB + transfer) | ~50€ |
| Compute (API) | ECS Fargate (2 vCPU, 4GB) | ~100€ |
| **GPU Transcription** | g4dn.xlarge (à la demande) | ~600-1,500€ |
| Load Balancer | ALB | ~30€ |
| Monitoring | CloudWatch | ~20€ |

**Total Cloud: ~1,220-2,120€/mois**

**Pour 100h de transcription GPU/mois:**
- Option 1: Instance on-demand: ~600€/mois
- Option 2: Spot instances (70% discount): ~180€/mois
- Option 3: Reserved (1 an): ~350€/mois

---

### Cloud Hybride (Recommandé)

**Services stateful on-premise (Proxmox):**
- PostgreSQL, Redis, Kafka, MinIO
- Coût: ~200€/mois (électricité + maintenance)

**Services compute dans le Cloud (burst):**
- Workers de transcription GPU (spot instances)
- Coût: ~200-500€/mois selon charge

**Total hybride: ~400-700€/mois**

**Avantages:**
- ✅ Meilleur rapport coût/performance
- ✅ Scaling automatique pour pics
- ✅ Données sensibles on-premise

---

## 🚀 Optimisations et Automatisation

### Option 1: n8n (Workflow Automation)

**Architecture proposée:**

```
n8n (Orchestrateur)
    ├─ Trigger: Upload vidéo (MinIO webhook)
    ├─ Workflow:
    │   1. Validation format (FFmpeg probe)
    │   2. Compression intelligente (si >1GB)
    │   3. Extraction audio
    │   4. Queue Kafka → Transcription
    │   5. Analyse NLP (quand transcription terminée)
    │   6. Génération clips (selon keywords)
    │   7. Notifications (email, webhook, Slack)
    └─ Monitoring: Métriques vers Prometheus
```

**Avantages:**
- ✅ Workflows visuels (low-code)
- ✅ 400+ intégrations
- ✅ Self-hosted (gratuit)
- ✅ Retry automatique
- ✅ Scheduling (cron jobs)

**Coût:**
- Self-hosted: **Gratuit** (licence Apache 2.0)
- Cloud (n8n.io): À partir de 20€/mois
- RAM nécessaire: +2 GB

**Exemple de gains:**
- Temps de setup workflow: ~80% plus rapide
- Moins de code custom: ~60% moins de développement
- Time-to-market: 2-3x plus rapide

---

### Option 2: Apache Airflow

**Pour workflows complexes et data pipelines**

**Avantages:**
- ✅ Très puissant pour data engineering
- ✅ Monitoring intégré
- ✅ Scaling horizontal

**Inconvénients:**
- ⚠️ Plus complexe que n8n
- ⚠️ Nécessite compétences Python
- ⚠️ +4 GB RAM

---

### Option 3: Temporal (Déjà intégré)

**Vous avez déjà Temporal dans votre stack!**

**À utiliser pour:**
- ✅ Workflows longs (transcription, rendering)
- ✅ Retry automatique
- ✅ State management
- ✅ Durabilité garantie

**Complétez avec n8n pour:**
- Intégrations tierces
- Workflows simples
- Webhooks
- Notifications

---

### Recommandation: Architecture Hybride

```
┌─────────────────────────────────────────────────────┐
│                    n8n (Orchestrateur)              │
│  • Webhooks externes                                │
│  • Intégrations SaaS                                │
│  • Notifications                                    │
│  • Workflows simples                                │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────┐
│             Video AI Platform (Quarkus)             │
│  • API REST                                         │
│  • Business Logic                                   │
│  • Authentification                                 │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────┐
│              Temporal (Workflows)                    │
│  • Transcription (long-running)                     │
│  • Rendering vidéo                                  │
│  • Batch processing                                 │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────┐
│          Workers (GPU CUDA)                         │
│  • Whisper (transcription)                          │
│  • FFmpeg (encoding)                                │
│  • PyTorch (ML)                                     │
└─────────────────────────────────────────────────────┘
```

**Gains estimés:**
- Développement: -40% de temps
- Maintenance: -30% d'efforts
- Time-to-market: -50%
- Coût infrastructure: Similaire (+2GB RAM pour n8n)

---

## 🎮 Accélération GPU avec CUDA

### Pourquoi utiliser CUDA localement?

**Avantages:**
- ✅ **10-50x plus rapide** que CPU
- ✅ Pas de frais Cloud GPU (économie ~500-1,000€/mois)
- ✅ Données restent locales (RGPD)
- ✅ Latence minimale
- ✅ Pas de limite d'utilisation

**Coûts:**
- GPU NVIDIA RTX 3060 (12GB): ~400€
- GPU NVIDIA RTX 4060 Ti (16GB): ~600€
- GPU NVIDIA RTX 4090 (24GB): ~2,000€
- Électricité (+200W): ~20-30€/mois

### Comparaison CPU vs GPU (Whisper)

| Vidéo | CPU (8 cores) | GPU (RTX 3060) | GPU (RTX 4090) |
|-------|---------------|----------------|----------------|
| 10 min | ~5 min | ~30 sec | ~15 sec |
| 1 heure | ~30 min | ~3 min | ~1.5 min |
| 2 heures | ~60 min | ~6 min | ~3 min |

**ROI GPU:**
- Coût GPU: 600€
- Économie Cloud: 500€/mois
- **ROI: 1.2 mois** ✅

### Configuration CUDA recommandée

**Setup matériel:**
1. GPU NVIDIA (Architecture Turing ou plus récent)
   - RTX 3060 (12GB): Bon rapport qualité/prix
   - RTX 4060 Ti (16GB): Excellent choix
   - RTX 4090 (24GB): Maximum performance

2. Drivers & Toolkit
   - NVIDIA Driver: 535+
   - CUDA Toolkit: 12.0+
   - cuDNN: 8.9+

3. Installation sur Proxmox VM
```bash
# Passer le GPU à la VM (GPU Passthrough)
# Documentation Proxmox: PCIe Passthrough
```

**Configuration Docker:**
```yaml
# docker-compose.yml
services:
  transcription-worker:
    image: videoai/transcription-worker:latest
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    environment:
      - CUDA_VISIBLE_DEVICES=0
      - WHISPER_DEVICE=cuda
```

**Code Python (Whisper avec CUDA):**
```python
import whisper
import torch

# Charger le modèle sur GPU
device = "cuda" if torch.cuda.is_available() else "cpu"
model = whisper.load_model("base", device=device)

# Transcription
result = model.transcribe("audio.mp3", fp16=True)  # fp16 pour GPU
```

**Performances attendues:**
- Modèle `base`: ~30 sec pour 1h vidéo
- Modèle `medium`: ~2-3 min pour 1h vidéo
- Modèle `large-v2`: ~5-7 min pour 1h vidéo

---

### Multi-GPU Setup (Scaling)

Pour traiter plusieurs vidéos en parallèle:

```yaml
# Déployer 2 workers avec 2 GPUs
services:
  transcription-worker-1:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              device_ids: ['0']
              capabilities: [gpu]

  transcription-worker-2:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              device_ids: ['1']
              capabilities: [gpu]
```

**Throughput:**
- 1 GPU (RTX 3060): ~20 heures de vidéo/heure
- 2 GPUs: ~40 heures de vidéo/heure
- 4 GPUs: ~80 heures de vidéo/heure

---

## 📊 Recommandations par Échelle

### 🏠 Petit projet (< 50 utilisateurs)

**Infrastructure:**
- 1 serveur Proxmox
- CPU: 8 cores, 32 GB RAM
- GPU: RTX 3060 (12GB)
- Stockage: 1 TB SSD

**Coût total:**
- Setup: ~2,500€
- Mensuel: ~150€ (électricité + internet)

**Automatisation:**
- Temporal (déjà inclu)
- Optionnel: n8n pour webhooks

---

### 🏢 Moyenne entreprise (50-500 utilisateurs)

**Infrastructure:**
- Votre Proxmox actuel
- CPU: 24 cores, 64 GB RAM
- GPU: RTX 4060 Ti (16GB) ou 2x RTX 3060
- Stockage: 5 TB (SSD + HDD)

**Coût total:**
- Setup: ~5,000€
- Mensuel: ~300€

**Automatisation:**
- ✅ n8n (workflows)
- ✅ Temporal (orchestration)
- ✅ Grafana (dashboards)

**Hybride Cloud:**
- Burst workers sur AWS Spot instances
- +200-400€/mois selon pics

---

### 🏭 Grande entreprise (> 500 utilisateurs)

**Infrastructure:**
- Cluster Kubernetes (3+ nodes)
- CPU: 80+ cores
- GPU: 4x RTX 4090 ou cloud GPU
- Stockage: 20+ TB (réplication)

**Coût total:**
- Setup: ~50,000€
- Mensuel: ~2,000-5,000€

**OU Cloud Native:**
- AWS/GCP/Azure
- ~3,000-8,000€/mois

**Automatisation:**
- ✅ n8n Enterprise
- ✅ Temporal Cloud
- ✅ CI/CD complet (GitLab CI, ArgoCD)
- ✅ IaC (Terraform)

---

## 💡 Optimisations de Coûts

### 1. Compression Intelligente

Avant transcription, compresser les vidéos:
```bash
# FFmpeg avec preset medium (bon compromis)
ffmpeg -i input.mp4 -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k output.mp4

# Économie: ~50-70% d'espace
# Impact qualité: Minimal
# Temps transcription: -30-50%
```

### 2. Modèles Whisper adaptatifs

```python
# Sélection automatique selon durée
if duration < 5 * 60:  # < 5 min
    model = "tiny"      # Très rapide
elif duration < 30 * 60:  # < 30 min
    model = "base"      # Rapide
else:
    model = "medium"    # Précis
```

**Économie GPU: ~40%**

### 3. Batch Processing

Grouper plusieurs petites vidéos:
```python
# Traiter 10 vidéos de 1 min en batch
# vs 10 fois séparément
# Gain: ~30% de temps GPU
```

### 4. Caching intelligent

```python
# Cache des transcriptions
# Si même vidéo uploadée plusieurs fois
# Gain: ~80% de ressources
```

### 5. Scheduled Processing

```yaml
# n8n workflow
# Traiter les vidéos non-urgentes la nuit
# Utilisation GPU optimale 24/7
# Gain: +100% de throughput
```

---

## 📈 Projection de Croissance

### Année 1: MVP (0-100 utilisateurs)

**Infrastructure:**
- Proxmox actuel + RTX 3060
- Coût: 150€/mois

**Automatisation:**
- Temporal + n8n basique

### Année 2: Scaling (100-1,000 utilisateurs)

**Infrastructure:**
- Proxmox + 2x RTX 3060
- + Cloud burst (spot instances)
- Coût: 500-800€/mois

**Automatisation:**
- n8n + Temporal + monitoring avancé

### Année 3: Enterprise (1,000-10,000 utilisateurs)

**Infrastructure:**
- Cluster K8s ou migration Cloud
- Coût: 2,000-5,000€/mois

**Automatisation:**
- Full DevOps pipeline
- Auto-scaling

---

## ✅ Conclusion et Recommandations

### Pour votre cas (Proxmox @ home)

**Investissement recommandé:**
1. **GPU NVIDIA RTX 4060 Ti (16GB)**: ~600€
   - ROI: 1-2 mois vs Cloud GPU
   - Performance: 10-20x CPU

2. **n8n (self-hosted)**: Gratuit
   - Gain développement: -40%
   - Intégrations: +400 services

3. **Stockage additionnel (2TB SSD)**: ~300€
   - Pour vidéos + backups

**Total: ~900€ d'investissement initial**

**Coût mensuel:**
- Électricité: ~70€/mois (GPU inclus)
- Internet: ~50€/mois
- Maintenance: ~30€/mois
- **Total: ~150€/mois**

**VS Cloud équivalent: ~1,500-2,000€/mois**

**Économie: ~1,350€/mois = ROI en < 1 mois** ✅

### Architecture finale recommandée

```
Your Proxmox (192.168.1.23)
├── n8n (Orchestration & Webhooks)
├── Video AI Platform (Quarkus API)
├── Temporal (Workflows)
├── PostgreSQL, Redis, Kafka (Data)
├── MinIO (Stockage)
├── Transcription Workers (GPU CUDA)
│   └── Whisper + FFmpeg + PyTorch
└── Monitoring (Prometheus + Grafana)
```

**Capacité:**
- 10-20 vidéos simultanées
- ~5,000 utilisateurs/jour
- 1h vidéo → 3-5 min transcription
- Stockage: 5-10 TB (évolutif)

---

## 📞 Prochaines Étapes

1. ✅ Déployer l'infrastructure actuelle (fait)
2. 🎯 Acheter GPU NVIDIA RTX 4060 Ti
3. 🎯 Installer CUDA sur Proxmox VM
4. 🎯 Configurer GPU passthrough
5. 🎯 Déployer n8n
6. 🎯 Intégrer Whisper avec CUDA
7. 🎯 Créer workflows n8n
8. 🎯 Mesurer et optimiser

**Voulez-vous que je vous aide à:**
- Configurer le GPU CUDA sur Proxmox?
- Installer et configurer n8n?
- Créer les workflows d'automatisation?
- Autre chose?
