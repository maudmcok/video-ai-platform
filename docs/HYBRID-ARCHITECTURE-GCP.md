# Architecture Hybride: Proxmox + Google Cloud GPU

## 🎯 Stratégie: Validation du concept avec GCP

**Approche recommandée:**
- ✅ Infrastructure stateful sur **Proxmox** (192.168.1.23)
- ✅ Workers GPU de transcription sur **Google Cloud** (NVIDIA T4)
- ✅ Validation du concept AVANT investissement matériel
- ✅ Scalabilité automatique selon la charge

## 💰 Analyse des Coûts GPU

### NVIDIA T4 sur Google Cloud

| Type d'instance | GPU | vCPU | RAM | Prix On-Demand | Prix Preemptible | Prix Spot |
|----------------|-----|------|-----|----------------|------------------|-----------|
| **n1-standard-4 + T4** | 1x T4 (16GB) | 4 | 15 GB | **$0.35/h** | **$0.22/h** | **$0.16/h** |

**Calcul mensuel (pour validation concept):**

#### Scénario 1: Utilisation légère (50h/mois)
```
Usage: 50 heures/mois
- On-Demand: 50h × $0.35 = $17.50/mois (~16€)
- Preemptible: 50h × $0.22 = $11/mois (~10€)
- Spot: 50h × $0.16 = $8/mois (~7€)
```

#### Scénario 2: Utilisation modérée (200h/mois)
```
Usage: 200 heures/mois (6-7h/jour)
- On-Demand: 200h × $0.35 = $70/mois (~65€)
- Preemptible: 200h × $0.22 = $44/mois (~40€)
- Spot: 200h × $0.16 = $32/mois (~30€)
```

#### Scénario 3: Utilisation intensive (500h/mois)
```
Usage: 500 heures/mois (16-17h/jour)
- On-Demand: 500h × $0.35 = $175/mois (~160€)
- Preemptible: 500h × $0.22 = $110/mois (~100€)
- Spot: 500h × $0.16 = $80/mois (~75€)
```

### Comparaison: GCP vs Achat GPU local

| Option | Coût initial | Coût mensuel (200h) | ROI | Avantages |
|--------|--------------|---------------------|-----|-----------|
| **GCP Spot (validation)** | 0€ | ~30€ | - | ✅ Pas d'investissement<br>✅ Test sans risque<br>✅ Scalable |
| **GCP On-Demand** | 0€ | ~65€ | - | ✅ Disponibilité garantie<br>✅ Pas de maintenance |
| **RTX 4060 Ti local** | 600€ | ~20€ (électricité) | **6-9 mois** | ✅ Pas de limite d'usage<br>✅ Latence minimale<br>✅ Données locales |

**Recommandation:**
1. **Phase 1 (0-3 mois): GCP Spot** → Valider le concept (~30€/mois)
2. **Phase 2 (3-6 mois): GCP Preemptible** → Scaling (~100€/mois)
3. **Phase 3 (6+ mois): GPU local** → ROI atteint, autonomie totale

---

## 🏗️ Architecture Hybride Proposée

```
┌────────────────────────────────────────────────────────────┐
│                    PROXMOX (192.168.1.23)                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Services Stateful (Always-On)                       │  │
│  │  ├── PostgreSQL        (Données permanentes)         │  │
│  │  ├── Redis             (Cache)                       │  │
│  │  ├── Kafka             (Message broker)             │  │
│  │  ├── MinIO             (Stockage vidéos)            │  │
│  │  ├── Keycloak          (Auth)                       │  │
│  │  ├── Temporal          (Orchestration)              │  │
│  │  ├── n8n               (Automation)                 │  │
│  │  ├── Prometheus        (Monitoring)                 │  │
│  │  ├── Grafana           (Dashboards)                 │  │
│  │  └── Projects Service  (API REST)                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Coût: ~150€/mois (électricité + internet)                 │
└──────────────────┬───────────────────────────────────────────┘
                   │
                   │ VPN/Tunnel sécurisé
                   │ (Cloud NAT + VPN Gateway)
                   │
                   ▼
┌────────────────────────────────────────────────────────────┐
│              GOOGLE CLOUD PLATFORM                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Workers GPU (Auto-scaling)                          │  │
│  │  ├── Transcription Worker 1  (NVIDIA T4)            │  │
│  │  ├── Transcription Worker 2  (NVIDIA T4) [optional] │  │
│  │  └── Transcription Worker N  (selon charge)         │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Type: n1-standard-4 + NVIDIA T4 (Spot instances)          │
│  Coût: ~$0.16/h (~30€/mois pour 200h)                     │
└────────────────────────────────────────────────────────────┘

Total Hybride: ~180€/mois (vs 1,500€ full cloud)
```

---

## 📋 Workflow de Transcription Hybride

### 1. Upload vidéo (Proxmox)

```
User → MinIO (Proxmox) → Kafka message
```

### 2. Décision de routing (n8n sur Proxmox)

```javascript
// n8n Workflow: Smart Routing
const videoDuration = $json.duration;
const queueDepth = $json.queueDepth;

// Petites vidéos (<5 min) → CPU local (gratuit)
if (videoDuration < 300) {
  return {
    target: 'local-cpu',
    cost: 0
  };
}

// Longues vidéos → GCP GPU (payant mais rapide)
return {
  target: 'gcp-gpu-spot',
  expectedCost: (videoDuration / 3600) * 0.16  // $0.16/h
};
```

### 3. Traitement GCP

```
Proxmox → Kafka → GCP Worker (T4 GPU)
  1. Télécharge vidéo depuis MinIO (via VPN)
  2. Transcription Whisper avec CUDA
  3. Upload résultat vers MinIO
  4. Kafka message "completed"
```

### 4. Post-processing (Proxmox)

```
Temporal → NLP Analysis → Clip Generation → Notification
```

---

## 🚀 Déploiement GCP

### Étape 1: Créer le projet GCP

```bash
# Installer gcloud CLI
# https://cloud.google.com/sdk/docs/install

# Login
gcloud auth login

# Créer projet
gcloud projects create video-ai-platform-prod --name="Video AI Platform"

# Définir comme projet actif
gcloud config set project video-ai-platform-prod

# Activer les APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable storage.googleapis.com
```

### Étape 2: Créer l'instance GPU

```bash
# Créer instance avec GPU T4 (Spot)
gcloud compute instances create transcription-worker-spot \
  --zone=europe-west1-b \
  --machine-type=n1-standard-4 \
  --accelerator=type=nvidia-tesla-t4,count=1 \
  --maintenance-policy=TERMINATE \
  --provisioning-model=SPOT \
  --instance-termination-action=STOP \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=50GB \
  --boot-disk-type=pd-standard \
  --metadata-from-file startup-script=startup-script.sh

# Prix: ~$0.16/h (Spot) vs $0.35/h (On-Demand)
```

### Étape 3: Script de démarrage automatique

```bash
# startup-script.sh
#!/bin/bash

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install NVIDIA drivers
curl -O https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
dpkg -i cuda-keyring_1.1-1_all.deb
apt-get update
apt-get -y install cuda-drivers-535

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

apt-get update
apt-get install -y nvidia-container-toolkit
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

# Pull worker image
docker pull videoai/transcription-worker:cuda

# Configure VPN to Proxmox
# (À adapter selon votre solution VPN)

# Start worker
docker run -d --gpus all --restart=always \
  --name transcription-worker \
  -e KAFKA_BOOTSTRAP_SERVERS=192.168.1.23:9092 \
  -e MINIO_ENDPOINT=http://192.168.1.23:9000 \
  -e WHISPER_MODEL=base \
  videoai/transcription-worker:cuda
```

### Étape 4: Configuration réseau (VPN)

#### Option A: Cloud VPN (Recommandé)

```bash
# Sur GCP: Créer VPN Gateway
gcloud compute vpn-gateways create video-ai-vpn \
  --network=default \
  --region=europe-west1

# Sur Proxmox: Installer VPN client (WireGuard/OpenVPN)
# Configurer tunnel entre GCP et Proxmox

# Kafka accessible via: 192.168.1.23:9092
# MinIO accessible via: 192.168.1.23:9000
```

#### Option B: Exposition publique (Moins sécurisé)

```bash
# Sur Proxmox: Exposer Kafka et MinIO avec auth
# Utiliser HTTPS + authentification forte
# Pas recommandé pour production
```

---

## 🔄 Auto-Scaling GCP

### Managed Instance Group (MIG)

```bash
# Créer template d'instance
gcloud compute instance-templates create transcription-worker-template \
  --machine-type=n1-standard-4 \
  --accelerator=type=nvidia-tesla-t4,count=1 \
  --maintenance-policy=TERMINATE \
  --provisioning-model=SPOT \
  --instance-termination-action=DELETE \
  --metadata-from-file startup-script=startup-script.sh

# Créer groupe auto-scalé
gcloud compute instance-groups managed create transcription-workers \
  --template=transcription-worker-template \
  --size=0 \
  --zone=europe-west1-b

# Configurer autoscaling
gcloud compute instance-groups managed set-autoscaling transcription-workers \
  --zone=europe-west1-b \
  --min-num-replicas=0 \
  --max-num-replicas=5 \
  --target-cpu-utilization=0.6 \
  --cool-down-period=300

# Scale to 0 quand pas de charge = 0€
```

### Scaling basé sur la queue Kafka

```python
# Cloud Function pour scaler selon queue depth
import googleapiclient.discovery
from kafka import KafkaConsumer

def scale_workers(request):
    # Checker la queue Kafka
    consumer = KafkaConsumer(
        'video.transcription.requested',
        bootstrap_servers=['192.168.1.23:9092']
    )

    partitions = consumer.partitions_for_topic('video.transcription.requested')
    queue_depth = sum([
        consumer.position(TopicPartition('video.transcription.requested', p))
        for p in partitions
    ])

    # Calculer instances nécessaires
    # 1 instance peut traiter ~10 vidéos/heure
    desired_instances = min(5, max(0, queue_depth // 10))

    # Scaler
    compute = googleapiclient.discovery.build('compute', 'v1')
    compute.instanceGroupManagers().resize(
        project='video-ai-platform-prod',
        zone='europe-west1-b',
        instanceGroupManager='transcription-workers',
        size=desired_instances
    ).execute()

    return f'Scaled to {desired_instances} instances'

# Déployer Cloud Function
# gcloud functions deploy scale-workers --runtime python39 --trigger-http
```

---

## 💡 Optimisations de Coûts

### 1. Utiliser Spot/Preemptible Instances

**Économie: 70-80% vs On-Demand**

```yaml
# docker-compose pour worker GCP
services:
  transcription-worker:
    image: videoai/transcription-worker:cuda
    deploy:
      restart_policy:
        condition: any  # Redémarre si instance preempted
        delay: 10s
        max_attempts: 10
```

### 2. Scale to Zero

```bash
# Quand aucune vidéo en attente = 0 instances = 0€
# n8n workflow qui scale down après 10 min d'inactivité
```

### 3. Committed Use Discounts (si usage > 300h/mois)

```bash
# Engagement 1 an: -37% discount
# Engagement 3 ans: -55% discount

# Si utilisation > 300h/mois (10h/jour):
# Sans engagement: $105/mois
# Avec engagement 1 an: $66/mois (-37%)
# Avec engagement 3 ans: $47/mois (-55%)
```

### 4. Multi-région (pour latence)

```bash
# europe-west1 (Belgique): ~$0.16/h spot
# europe-west4 (Pays-Bas): ~$0.16/h spot
# us-central1 (Iowa): ~$0.13/h spot (moins cher!)

# Choisir selon votre audience
```

---

## 📊 Estimation Coûts Réels

### Scénario Réaliste: Phase de Validation (3 mois)

**Hypothèses:**
- 50 vidéos/jour en moyenne
- Durée moyenne: 30 minutes/vidéo
- Temps transcription: 3 minutes/vidéo (avec T4 GPU)
- Total: 50 × 3 min = 150 min/jour = 2.5h/jour

**Calcul mensuel:**
```
Usage: 2.5h/jour × 30 jours = 75h/mois
Coût Spot: 75h × $0.16 = $12/mois (~11€)

+ Storage egress (téléchargement vidéos): ~5€/mois
+ VPN Gateway: ~$45/mois (si Cloud VPN)

Total GCP: ~60€/mois
```

**Total architecture hybride:**
```
Proxmox: ~150€/mois
GCP GPU: ~60€/mois
Total: ~210€/mois

vs Full Cloud: ~1,500€/mois
Économie: ~86% 🎉
```

---

## 🔐 Sécurité

### VPN Configuration

```bash
# Sur Proxmox: Installer WireGuard
apt install wireguard

# Générer clés
wg genkey | tee privatekey | wg pubkey > publickey

# Configurer tunnel vers GCP
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = <votre_private_key>
Address = 10.8.0.1/24

[Peer]
PublicKey = <gcp_public_key>
Endpoint = <gcp_vpn_ip>:51820
AllowedIPs = 10.128.0.0/20
PersistentKeepalive = 25
EOF

# Démarrer VPN
wg-quick up wg0
systemctl enable wg-quick@wg0
```

### Firewall Rules

```bash
# GCP: Autoriser seulement le VPN
gcloud compute firewall-rules create allow-vpn \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=udp:51820 \
  --source-ranges=<votre_ip_publique>/32

# Bloquer tout le reste
gcloud compute firewall-rules create deny-all \
  --direction=INGRESS \
  --priority=65534 \
  --network=default \
  --action=DENY \
  --rules=all \
  --source-ranges=0.0.0.0/0
```

---

## 📈 Monitoring Hybride

### Grafana Dashboard

```yaml
# Métriques à monitorer:
- Proxmox:
  - CPU/RAM local
  - Kafka queue depth
  - MinIO storage usage
  - API response time

- GCP:
  - Nombre d'instances actives
  - GPU utilization
  - Coût accumulé
  - Transcriptions/heure
```

### Alertes

```yaml
# Alert si coût GCP > budget
- Alert: GCP Cost Threshold
  Condition: monthly_cost > $100
  Action: Email + Scale down to 0

# Alert si queue trop longue
- Alert: Queue Overload
  Condition: queue_depth > 100
  Action: Scale up GCP workers
```

---

## ✅ Plan d'Implémentation

### Phase 1: Setup Initial (Semaine 1)

- [ ] Créer compte GCP
- [ ] Activer $300 de crédits gratuits (90 jours)
- [ ] Créer projet video-ai-platform
- [ ] Déployer instance T4 Spot
- [ ] Configurer VPN Proxmox ↔ GCP
- [ ] Tester transcription end-to-end

### Phase 2: Intégration (Semaine 2)

- [ ] Configurer n8n pour routing hybride
- [ ] Implémenter auto-scaling
- [ ] Configurer monitoring
- [ ] Tests de charge

### Phase 3: Validation (Mois 1-3)

- [ ] Traiter vidéos réelles
- [ ] Mesurer coûts réels
- [ ] Optimiser workflows
- [ ] Décision: continuer GCP ou acheter GPU local

### Phase 4: Décision (Mois 3)

**Si usage > 500h/mois:**
- ROI GPU local atteint
- Acheter RTX 4060 Ti (600€)
- Migrer progressivement vers local

**Si usage < 200h/mois:**
- Rester sur GCP Spot (~30€/mois)
- Pas besoin d'investissement GPU

---

## 💰 ROI Final

### Option 1: GCP uniquement (validation 3 mois)

```
Coût total: 3 × 60€ = 180€
Investissement: 0€
Risque: Minimal ✅
```

### Option 2: Achat GPU après validation

```
Phase 1 (3 mois GCP): 180€
Phase 2 (achat GPU): 600€
Total investissement: 780€

Économie mensuelle vs GCP: 60€/mois
ROI: 780€ / 60€ = 13 mois

Mais économie vs full cloud: 1,300€/mois
ROI réel: < 1 mois ✅
```

---

## 🎯 Recommandation Finale

**Pour vous, stratégie optimale:**

1. **Mois 0-3: Validation avec GCP Spot**
   - Coût: ~60€/mois
   - Crédits gratuits GCP: $300 (couvre 5-6 mois!)
   - Risque: 0€

2. **Mois 3-6: Décision basée sur usage**
   - Si usage > 300h/mois → Acheter GPU local (ROI 6 mois)
   - Si usage < 200h/mois → Rester GCP Spot (~30-60€/mois)

3. **Mois 6+: Optimisation**
   - GPU local pour charge de base
   - GCP pour pics de charge
   - Coût optimal: ~150-200€/mois

**Économie totale vs full cloud: ~1,300€/mois (~15,600€/an)** 🎉

---

## 📞 Prochaines Étapes

Voulez-vous que je vous aide à:
1. 🌐 Créer et configurer le projet GCP?
2. 🔧 Préparer les scripts de déploiement GCP?
3. 🔐 Configurer le VPN Proxmox ↔ GCP?
4. 📊 Créer les dashboards de monitoring hybride?
5. 🚀 Déployer la première instance GPU T4?
