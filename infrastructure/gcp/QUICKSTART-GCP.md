# 🚀 Démarrage Rapide - Déploiement GCP

**⏱️ Temps estimé:** 30 minutes
**💰 Coût:** ~$12-20/mois (avec crédits gratuits: $0 les 3 premiers mois)

---

## 📋 Prérequis

- ✅ Compte Google Cloud Platform (créer sur [console.cloud.google.com](https://console.cloud.google.com))
- ✅ Carte bancaire (pour activer les $300 de crédits gratuits)
- ✅ Bash/Terminal (Linux, macOS, Git Bash sur Windows)
- ✅ Docker installé localement

---

## 🎯 Vue d'ensemble

```
┌─────────────────────────────────────────────────────────┐
│  Votre Machine (Windows)                                │
│  ├── Build Docker Image → Push to GCR                  │
│  └── Run deployment scripts                             │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  Google Cloud Platform                                   │
│  ├── VM with NVIDIA T4 GPU                              │
│  │   ├── CUDA 12.0                                      │
│  │   ├── Docker + nvidia-container-toolkit              │
│  │   └── Transcription Worker (Whisper)                │
│  └── VPN (WireGuard) ──────────────────────┐            │
└────────────────────────────────────────────┼────────────┘
                                              ↓
┌─────────────────────────────────────────────────────────┐
│  Proxmox Home Server (192.168.1.23)                     │
│  ├── Kafka (message queue)                              │
│  ├── MinIO (object storage)                             │
│  ├── PostgreSQL (database)                              │
│  └── Other services...                                  │
└─────────────────────────────────────────────────────────┘
```

---

## ⚡ Déploiement en 5 Étapes

### Étape 1: Installer Google Cloud SDK

```bash
# Sur Windows (PowerShell en admin)
(New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", "$env:Temp\GoogleCloudSDKInstaller.exe")
& $env:Temp\GoogleCloudSDKInstaller.exe

# Sur Linux/macOS
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Initialiser gcloud
gcloud init

# Authentification
gcloud auth login
gcloud auth application-default login
```

---

### Étape 2: Créer un Projet GCP

```bash
# Via l'interface web: https://console.cloud.google.com/projectcreate
# Ou via CLI:
gcloud projects create video-ai-platform-XXXXX --name="Video AI Platform"

# Activer la facturation (requis pour GPU)
# https://console.cloud.google.com/billing

# Lier le projet à la facturation
gcloud billing projects link video-ai-platform-XXXXX \
    --billing-account=VOTRE-BILLING-ACCOUNT-ID

# Vérifier les crédits gratuits ($300)
# https://console.cloud.google.com/billing/credits
```

---

### Étape 3: Configurer les Variables d'Environnement

```bash
cd e:\devaiplat\video-ai-platform\infrastructure\gcp

# Copier l'exemple
cp .env.example .env

# Éditer .env avec vos valeurs
notepad .env
```

**Valeurs minimales à remplir:**
```env
GCP_PROJECT_ID=video-ai-platform-XXXXX
GCP_REGION=us-central1
GCP_ZONE=us-central1-a

KAFKA_BOOTSTRAP_SERVERS=192.168.1.23:9092
MINIO_ENDPOINT=http://192.168.1.23:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=MinIO!Qualif2024#Storage456

ALERT_EMAIL=votre-email@example.com
MONTHLY_BUDGET=50
```

---

### Étape 4: Initialiser le Projet GCP

```bash
# Rendre le script exécutable (Git Bash sur Windows)
chmod +x *.sh

# Exécuter le setup
./setup-gcp-project.sh
```

**Ce script va:**
- ✅ Activer les APIs nécessaires (Compute Engine, Cloud Build, etc.)
- ✅ Créer un compte de service
- ✅ Configurer le réseau VPC
- ✅ Créer les règles de firewall
- ✅ Configurer les alertes budgétaires

**Sortie attendue:**
```
================================================
✅ GCP Project Setup Complete!
================================================
   Project ID: video-ai-platform-12345
   Region: us-central1
   Zone: us-central1-a
   Service Account: videoai-gpu-worker@...
```

---

### Étape 5: Builder et Déployer le Worker GPU

```bash
# 5.1 Builder l'image Docker avec CUDA
./build-and-push-image.sh

# Durée: ~5-10 minutes
# Taille finale: ~8 GB

# 5.2 Déployer l'instance GPU
./deploy-gpu-worker.sh

# Durée: ~5-10 minutes
```

**Sortie attendue:**
```
================================================
✅ Instance created successfully!
================================================
   Name: videoai-gpu-worker
   Type: n1-standard-4
   GPU: nvidia-tesla-t4 (x1)
   Pricing: spot
   External IP: 34.123.45.67

💰 Cost Estimate
   Hourly: ~$0.16 USD
   Monthly (75h): ~$12 USD
```

---

### Étape 6 (Optionnel): Configurer le VPN

Si Kafka/MinIO ne sont pas exposés publiquement, configurez le VPN:

```bash
./setup-vpn.sh
```

Suivez les instructions affichées pour configurer WireGuard sur Proxmox.

---

## 🧪 Vérification

### 1. Vérifier que l'instance est running

```bash
gcloud compute instances list --filter="name=videoai-gpu-worker"

# Devrait afficher:
# NAME                  ZONE           MACHINE_TYPE   STATUS
# videoai-gpu-worker    us-central1-a  n1-standard-4  RUNNING
```

### 2. Se connecter à l'instance

```bash
gcloud compute ssh videoai-gpu-worker --zone=us-central1-a
```

### 3. Vérifier le GPU

```bash
nvidia-smi

# Devrait afficher:
# +-----------------------------------------------------------------------------+
# | NVIDIA-SMI 535.xx       Driver Version: 535.xx       CUDA Version: 12.2   |
# |-------------------------------+----------------------+----------------------+
# | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
# |   0  Tesla T4            Off  | 00000000:00:04.0 Off |                    0 |
# +-------------------------------+----------------------+----------------------+
```

### 4. Vérifier le worker Docker

```bash
sudo docker ps

# Devrait afficher:
# CONTAINER ID   IMAGE                                    STATUS
# abc123def456   gcr.io/.../transcription-worker:cuda    Up 2 minutes
```

### 5. Voir les logs du worker

```bash
sudo docker logs -f videoai-transcription-worker

# Devrait afficher:
# Using device: cuda
# GPU: Tesla T4
# CUDA Version: 12.0
# Memory: 16.00 GB
# Loading Whisper model: base
# Connected to Kafka: 192.168.1.23:9092
# Worker ready ✓
```

### 6. Tester une transcription

```bash
# Depuis votre machine locale, envoyer un message Kafka de test
# (nécessite que Kafka soit accessible ou VPN configuré)
```

---

## 📊 Monitoring

### Voir les métriques GPU en temps réel

```bash
gcloud compute ssh videoai-gpu-worker --zone=us-central1-a

# Une fois connecté:
watch -n 1 nvidia-smi
```

### Voir les logs dans GCP Console

```
https://console.cloud.google.com/logs/query?project=video-ai-platform-XXXXX
```

**Filtre:**
```
resource.type="gce_instance"
resource.labels.instance_id="<your-instance-id>"
```

### Voir les coûts en temps réel

```
https://console.cloud.google.com/billing
```

---

## 💰 Gestion des Coûts

### Stopper l'instance (pas de frais GPU)

```bash
gcloud compute instances stop videoai-gpu-worker --zone=us-central1-a

# Coût pendant arrêt: ~$1/mois (stockage disque uniquement)
```

### Démarrer l'instance

```bash
gcloud compute instances start videoai-gpu-worker --zone=us-central1-a
```

### Supprimer l'instance (plus aucun frais)

```bash
gcloud compute instances delete videoai-gpu-worker --zone=us-central1-a
```

### Auto-scaling (économie d'argent)

Éditez `deploy-gpu-worker.sh` pour ajouter:
```bash
MIN_INSTANCES=0  # Scale to 0 quand inactif
MAX_INSTANCES=3  # Scale up si charge élevée
```

---

## 🔧 Dépannage

### Problème: "Quota 'GPUS_ALL_REGIONS' exceeded"

**Solution:** Demander une augmentation de quota GPU:
```
https://console.cloud.google.com/iam-admin/quotas
```

Filtrer par "GPU" et demander:
- NVIDIA T4 GPUs: 1-5 (selon vos besoins)

Délai d'approbation: 1-2 jours ouvrés.

---

### Problème: "CUDA out of memory"

**Solution:** Utiliser un modèle Whisper plus petit:
```bash
# Dans .env
WHISPER_MODEL=tiny    # Au lieu de base ou medium
```

**Ou** augmenter la taille de la VM:
```bash
# Dans .env
INSTANCE_TYPE=n1-standard-8  # Au lieu de n1-standard-4
```

---

### Problème: Worker ne se connecte pas à Kafka

**Solutions:**

1. **Vérifier la connectivité réseau:**
```bash
gcloud compute ssh videoai-gpu-worker --zone=us-central1-a
ping 192.168.1.23
```

2. **Configurer le VPN:**
```bash
./setup-vpn.sh
```

3. **Exposer Kafka publiquement (non recommandé pour prod):**
```bash
# Sur Proxmox
sudo ufw allow 9092/tcp
```

---

### Problème: Image Docker trop volumineuse

**Solution:** Utiliser Cloud Build au lieu de build local:
```bash
gcloud builds submit \
    --tag gcr.io/$GCP_PROJECT_ID/transcription-worker:cuda \
    ../../services/transcription
```

---

## 📈 Optimisations Avancées

### 1. Utiliser des Instances Préemptibles

Économie: 60-80%
Risque: Instance peut être stoppée par GCP

```bash
# Dans .env
PRICING_MODEL=preemptible
```

### 2. Utiliser des Instances Spot

Économie: 80-90%
Risque: Instance peut être stoppée encore plus souvent

```bash
# Dans .env
PRICING_MODEL=spot
```

### 3. Activer le Multi-GPU

Pour charge intensive:
```bash
# Dans .env
GPU_COUNT=4
INSTANCE_TYPE=n1-standard-16
```

### 4. Région optimale (prix + latence)

```bash
# Moins cher:
GCP_REGION=us-central1  # Iowa (recommandé)
GCP_REGION=us-west1     # Oregon

# Plus cher mais basse latence Europe:
GCP_REGION=europe-west1  # Belgique
GCP_REGION=europe-west4  # Pays-Bas
```

---

## 📞 Support

### Documentation officielle
- [GCP GPU Documentation](https://cloud.google.com/compute/docs/gpus)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)
- [Whisper Documentation](https://github.com/openai/whisper)

### Communauté
- [GCP Discord](https://discord.gg/google-cloud)
- [Stack Overflow - google-cloud-platform](https://stackoverflow.com/questions/tagged/google-cloud-platform)

---

## ✅ Checklist de Validation

- [ ] gcloud CLI installé et configuré
- [ ] Projet GCP créé avec facturation activée
- [ ] Crédits gratuits ($300) confirmés
- [ ] `.env` configuré avec vos valeurs
- [ ] `setup-gcp-project.sh` exécuté avec succès
- [ ] Image Docker buildée et pushée vers GCR
- [ ] Instance GPU déployée et running
- [ ] `nvidia-smi` affiche le GPU T4
- [ ] Worker Docker en cours d'exécution
- [ ] Logs du worker affichent "Using device: cuda"
- [ ] Connexion Kafka/MinIO fonctionnelle
- [ ] Test de transcription réussi

---

## 🎉 Prochaines Étapes

Maintenant que votre GPU worker est déployé:

1. **Tester avec une vraie vidéo** depuis votre frontend
2. **Configurer n8n** pour automatiser les workflows (voir `docs/N8N-INTEGRATION-GUIDE.md`)
3. **Monitorer les performances** pendant 1-2 semaines
4. **Évaluer le ROI**: GCP vs GPU local
5. **Décider** de continuer avec GCP ou acheter un GPU local

---

**🚀 Bon déploiement!**
