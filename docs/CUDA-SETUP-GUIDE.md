# Guide d'installation CUDA pour Video AI Platform

## 🎯 Objectif

Configurer NVIDIA GPU avec CUDA sur votre VM Proxmox pour accélérer la transcription Whisper de **30 min → 3 min** par heure de vidéo.

## 📋 Prérequis

- ✅ Proxmox VE installé
- ✅ VM Docker (192.168.1.23) fonctionnelle
- ✅ GPU NVIDIA (architecture Pascal ou plus récent)
  - Recommandé: RTX 3060 (12GB), RTX 4060 Ti (16GB)
  - Minimum: GTX 1060 (6GB)

## 🔧 Étape 1: Configurer GPU Passthrough sur Proxmox

### 1.1 Activer IOMMU dans le BIOS

```
BIOS Settings:
├── VT-d (Intel) ou AMD-Vi (AMD): Enabled
├── IOMMU: Enabled
└── PCIe ACS: Enabled (si disponible)
```

### 1.2 Modifier GRUB sur Proxmox

```bash
# SSH vers Proxmox host
ssh root@192.168.1.50

# Éditer GRUB
nano /etc/default/grub

# Pour Intel:
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"

# Pour AMD:
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"

# Mettre à jour GRUB
update-grub

# Rebooter Proxmox
reboot
```

### 1.3 Charger les modules VFIO

```bash
# Après reboot, SSH vers Proxmox
ssh root@192.168.1.50

# Éditer modules
nano /etc/modules

# Ajouter ces lignes:
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd

# Mettre à jour initramfs
update-initramfs -u -k all

# Rebooter
reboot
```

### 1.4 Identifier votre GPU

```bash
# Lister les devices PCI
lspci -nn | grep NVIDIA

# Exemple de sortie:
# 01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA106 [GeForce RTX 3060] [10de:2503] (rev a1)
# 01:00.1 Audio device [0403]: NVIDIA Corporation GA106 High Definition Audio Controller [10de:228e] (rev a1)

# Noter les IDs: 01:00.0 et 01:00.1
```

### 1.5 Bloquer les drivers NVIDIA sur l'hôte

```bash
# Éditer blacklist
nano /etc/modprobe.d/blacklist.conf

# Ajouter:
blacklist nouveau
blacklist nvidia
blacklist nvidiafb
blacklist nvidia_drm
blacklist nvidia_modeset

# Mettre à jour
update-initramfs -u
reboot
```

### 1.6 Attacher le GPU à la VM

```bash
# Via l'interface Proxmox (192.168.1.50:8006)
# 1. Sélectionner votre VM Docker (ID: 100 par exemple)
# 2. Hardware → Add → PCI Device
# 3. Sélectionner votre GPU NVIDIA
# 4. Cocher "All Functions"
# 5. Cocher "Primary GPU" (si pas de GPU iGPU)
# 6. Apply

# OU via CLI:
qm set 100 -hostpci0 01:00,pcie=1,x-vga=1
```

### 1.7 Démarrer la VM et vérifier

```bash
# Démarrer la VM
qm start 100

# SSH vers la VM
ssh root@192.168.1.23

# Vérifier que le GPU est visible
lspci | grep NVIDIA
# Devrait afficher votre GPU
```

---

## 🐧 Étape 2: Installer NVIDIA Drivers dans la VM

### 2.1 Installer les drivers

```bash
# SSH vers VM Docker
ssh root@192.168.1.23

# Mettre à jour le système
apt update && apt upgrade -y

# Installer les headers kernel
apt install -y linux-headers-$(uname -r)

# Ajouter le repo NVIDIA
apt install -y software-properties-common
add-apt-repository ppa:graphics-drivers/ppa
apt update

# Installer le driver (version 535 recommandée)
apt install -y nvidia-driver-535

# Rebooter la VM
reboot
```

### 2.2 Vérifier l'installation

```bash
# Après reboot
ssh root@192.168.1.23

# Vérifier le driver
nvidia-smi

# Sortie attendue:
# +-----------------------------------------------------------------------------+
# | NVIDIA-SMI 535.xx.xx    Driver Version: 535.xx.xx    CUDA Version: 12.2     |
# |-------------------------------+----------------------+----------------------+
# | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
# |   0  NVIDIA GeForce ...  Off  | 00000000:01:00.0 Off |                  N/A |
# +-------------------------------+----------------------+----------------------+
```

✅ Si vous voyez cette sortie, le GPU est correctement configuré!

---

## 🐳 Étape 3: Configurer Docker avec NVIDIA

### 3.1 Installer NVIDIA Container Toolkit

```bash
# Ajouter le repo NVIDIA Docker
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Installer
apt update
apt install -y nvidia-container-toolkit

# Configurer Docker
nvidia-ctk runtime configure --runtime=docker

# Redémarrer Docker
systemctl restart docker
```

### 3.2 Tester Docker + GPU

```bash
# Test avec container CUDA
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi

# Devrait afficher nvidia-smi output
```

✅ Si ça fonctionne, Docker peut utiliser le GPU!

---

## 🐍 Étape 4: Configurer le Worker Transcription avec CUDA

### 4.1 Mettre à jour le Dockerfile

```dockerfile
# services/transcription/Dockerfile
FROM nvidia/cuda:12.0.0-cudnn8-runtime-ubuntu22.04

# Install Python
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3-pip \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Install PyTorch with CUDA support
RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu120

# Copy application code
COPY worker.py .

CMD ["python3", "worker.py"]
```

### 4.2 Mettre à jour requirements.txt

```txt
# services/transcription/requirements.txt
fastapi==0.109.0
uvicorn[standard]==0.27.0
openai-whisper==20231117
# torch sera installé depuis le Dockerfile avec CUDA
boto3==1.34.34
pydantic==2.5.3
structlog==24.1.0
python-multipart==0.0.6
kafka-python==2.0.2
```

### 4.3 Mettre à jour worker.py pour utiliser CUDA

```python
# services/transcription/worker.py
import whisper
import torch
import logging

# Configuration
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
WHISPER_MODEL = os.getenv("WHISPER_MODEL", "base")

logger = logging.getLogger(__name__)
logger.info(f"Using device: {DEVICE}")

if DEVICE == "cuda":
    logger.info(f"GPU: {torch.cuda.get_device_name(0)}")
    logger.info(f"CUDA Version: {torch.version.cuda}")
    logger.info(f"Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")

# Load Whisper model
logger.info(f"Loading Whisper model: {WHISPER_MODEL}")
model = whisper.load_model(WHISPER_MODEL, device=DEVICE)

def transcribe_audio(audio_path: str) -> dict:
    """Transcribe audio file using Whisper with GPU acceleration"""
    logger.info(f"Transcribing: {audio_path}")

    # Transcribe with FP16 for GPU (faster)
    result = model.transcribe(
        audio_path,
        fp16=(DEVICE == "cuda"),  # Use FP16 on GPU
        language="fr",  # Adapt selon besoin
        task="transcribe"
    )

    logger.info(f"Transcription completed: {len(result['text'])} characters")
    return result
```

### 4.4 Mettre à jour docker-compose pour GPU

```yaml
# infrastructure/proxmox/docker-compose.proxmox.yml
services:
  transcription-worker:
    image: videoai/transcription-worker:cuda
    container_name: videoai-transcription-cuda
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    environment:
      - CUDA_VISIBLE_DEVICES=0
      - WHISPER_MODEL=base  # ou medium, large
      - WHISPER_DEVICE=cuda
      - KAFKA_BOOTSTRAP_SERVERS=kafka:9092
    networks:
      - videoai-network
    restart: unless-stopped
```

---

## 🧪 Étape 5: Builder et Tester

### 5.1 Builder l'image CUDA

```bash
# Sur votre machine locale
cd e:\devaiplat\video-ai-platform\services\transcription

# Build avec tag cuda
docker build -t videoai/transcription-worker:cuda .

# Ou avec buildx pour multi-arch
docker buildx build --platform linux/amd64 -t videoai/transcription-worker:cuda .
```

### 5.2 Transférer vers Proxmox

```bash
# Sauvegarder l'image
docker save videoai/transcription-worker:cuda | gzip > transcription-cuda.tar.gz

# Transférer (remplacez par votre méthode)
scp transcription-cuda.tar.gz root@192.168.1.23:/tmp/

# Sur Proxmox VM
ssh root@192.168.1.23
gunzip -c /tmp/transcription-cuda.tar.gz | docker load
```

### 5.3 Tester le worker

```bash
# Sur Proxmox VM
cd /opt/video-ai-platform

# Démarrer uniquement le worker transcription
docker-compose up transcription-worker

# Vérifier les logs
docker-compose logs -f transcription-worker

# Sortie attendue:
# Using device: cuda
# GPU: NVIDIA GeForce RTX 3060
# CUDA Version: 12.0
# Memory: 12.00 GB
# Loading Whisper model: base
```

✅ Si vous voyez "Using device: cuda", c'est bon!

---

## 📊 Étape 6: Benchmarking

### 6.1 Test de performance

```bash
# Télécharger une vidéo de test (1h)
# Tester CPU vs GPU

# CPU (désactiver GPU):
time docker run --rm -v $(pwd):/data videoai/transcription-worker:cpu \
  python -c "import whisper; m=whisper.load_model('base'); m.transcribe('/data/test.mp4')"

# GPU:
time docker run --rm --gpus all -v $(pwd):/data videoai/transcription-worker:cuda \
  python -c "import whisper; m=whisper.load_model('base','cuda'); m.transcribe('/data/test.mp4',fp16=True)"
```

### 6.2 Résultats attendus

| Modèle | Durée vidéo | CPU (8 cores) | GPU (RTX 3060) | Accélération |
|--------|-------------|---------------|----------------|--------------|
| tiny | 10 min | ~2 min | ~10 sec | 12x |
| base | 10 min | ~5 min | ~30 sec | 10x |
| small | 1 heure | ~20 min | ~2 min | 10x |
| medium | 1 heure | ~40 min | ~4 min | 10x |
| large-v2 | 1 heure | ~80 min | ~8 min | 10x |

---

## 🔧 Dépannage

### Problème: nvidia-smi not found

```bash
# Vérifier que les drivers sont installés
apt list --installed | grep nvidia

# Réinstaller si nécessaire
apt install --reinstall nvidia-driver-535
```

### Problème: Docker ne voit pas le GPU

```bash
# Vérifier nvidia-container-toolkit
dpkg -l | grep nvidia-container-toolkit

# Réinstaller
apt install --reinstall nvidia-container-toolkit
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker
```

### Problème: Out of Memory sur GPU

```python
# Utiliser un modèle plus petit
WHISPER_MODEL="tiny"  # Au lieu de "large"

# Ou traiter par chunks
model.transcribe(audio, chunk_length=30)
```

### Problème: GPU pas passthrough correctement

```bash
# Sur Proxmox host
lspci | grep NVIDIA  # Vérifier PCI ID

# Vérifier IOMMU groups
find /sys/kernel/iommu_groups/ -type l

# Réaffecter le GPU
qm set 100 -delete hostpci0
qm set 100 -hostpci0 01:00,pcie=1
```

---

## 📈 Monitoring GPU

### Avec nvidia-smi

```bash
# Monitoring continu
watch -n 1 nvidia-smi

# Logs vers fichier
nvidia-smi dmon -s pucvmet -f logs/gpu.log
```

### Avec Prometheus

```bash
# Installer NVIDIA DCGM Exporter
docker run -d --rm \
  --gpus all \
  --name dcgm-exporter \
  -p 9400:9400 \
  nvidia/dcgm-exporter:latest

# Ajouter à Prometheus config
# scrape_configs:
#   - job_name: 'gpu'
#     static_configs:
#       - targets: ['192.168.1.23:9400']
```

### Dashboard Grafana

Importez le dashboard NVIDIA DCGM: ID `12239`

---

## ✅ Validation finale

**Checklist:**
- [ ] `nvidia-smi` fonctionne sur la VM
- [ ] `docker run --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi` fonctionne
- [ ] Worker transcription démarre sans erreur
- [ ] Logs montrent "Using device: cuda"
- [ ] Transcription test ~10x plus rapide que CPU
- [ ] Monitoring GPU fonctionnel

**Si toutes les cases sont cochées: ✅ CUDA est opérationnel!**

---

## 💰 ROI

**Investissement:**
- GPU RTX 3060: ~400€
- Temps d'installation: ~2-4h

**Gains:**
- Transcription 10x plus rapide
- Économie Cloud GPU: ~500€/mois
- **ROI: < 1 mois**

---

## 📞 Support

Pour plus d'aide:
- [NVIDIA GPU Passthrough](https://pve.proxmox.com/wiki/Pci_passthrough)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- [Whisper GitHub](https://github.com/openai/whisper)

**Prêt à déployer? 🚀**
