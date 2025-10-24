# Guide d'intégration n8n pour Video AI Platform

## 🎯 Objectif

Intégrer n8n comme orchestrateur de workflows pour automatiser les traitements vidéo et réduire le temps de développement de 40%.

## 📋 Architecture proposée

```
┌──────────────────────────────────────────────────────┐
│                      n8n                             │
│  Workflows visuels + 400+ intégrations               │
└───────────────┬──────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────────────┐
│           Video AI Platform (Quarkus)                │
│  Business Logic + API REST                           │
└───────────────┬──────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────────────┐
│              Temporal                                │
│  Long-running workflows (transcription, rendering)   │
└───────────────┬──────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────────────┐
│         Workers (GPU + CPU)                          │
│  Whisper, FFmpeg, PyTorch                            │
└──────────────────────────────────────────────────────┘
```

## 🚀 Étape 1: Déployer n8n sur Proxmox

### 1.1 Ajouter n8n au docker-compose

```yaml
# infrastructure/proxmox/docker-compose.proxmox.yml

services:
  # ... (services existants)

  # n8n - Workflow Automation
  n8n:
    image: n8nio/n8n:latest
    container_name: videoai-n8n
    environment:
      - N8N_HOST=192.168.1.23
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - NODE_ENV=production
      - WEBHOOK_URL=http://192.168.1.23:5678/
      - GENERIC_TIMEZONE=Europe/Paris
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD:-n8n_secure_password}
      # Intégration avec les services
      - VIDEO_AI_API_URL=http://projects-service:8080
      - KAFKA_BOOTSTRAP_SERVERS=kafka:9092
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=videoai
      - POSTGRES_USER=videoai
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - MINIO_ENDPOINT=http://minio:9000
      - MINIO_ACCESS_KEY=${MINIO_ROOT_USER}
      - MINIO_SECRET_KEY=${MINIO_ROOT_PASSWORD}
    volumes:
      - n8n-data:/home/node/.n8n
    networks:
      videoai-network:
        ipv4_address: 172.18.0.30
    ports:
      - "5678:5678"
    depends_on:
      - postgres
      - kafka
      - minio
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  # ... (volumes existants)
  n8n-data:
```

### 1.2 Ajouter le mot de passe n8n dans .env

```bash
# infrastructure/proxmox/.env
# ... (variables existantes)

# n8n Configuration
N8N_PASSWORD=N8n!Workflow2024#Qualif567
```

### 1.3 Déployer n8n

```bash
# Sur votre machine locale
cd e:\devaiplat\video-ai-platform\infrastructure\proxmox

# Rebuild docker-compose
deploy.bat  # ou ./deploy.sh

# Vérifier que n8n démarre
ssh root@192.168.1.23 "cd /opt/video-ai-platform && docker-compose logs -f n8n"
```

### 1.4 Accéder à n8n

Ouvrez votre navigateur: **http://192.168.1.23:5678**

Identifiants:
- Username: `admin`
- Password: `N8n!Workflow2024#Qualif567`

---

## 📝 Étape 2: Workflows de base

### Workflow 1: Upload vidéo → Transcription automatique

**Cas d'usage:** Dès qu'une vidéo est uploadée sur MinIO, lancer automatiquement la transcription.

#### Configuration dans n8n:

1. **Trigger: Webhook**
   - Method: POST
   - Path: `video-uploaded`
   - Response: Return immediately

2. **Node: Extract Data**
   - Type: Function
   ```javascript
   // Extraire les infos de la vidéo
   const videoUrl = $input.item.json.videoUrl;
   const projectId = $input.item.json.projectId;
   const userId = $input.item.json.userId;

   return {
     videoUrl,
     projectId,
     userId,
     timestamp: new Date().toISOString()
   };
   ```

3. **Node: HTTP Request - Validate Format**
   - Method: GET
   - URL: `{{ $json.videoUrl }}`
   - Response: Binary

4. **Node: Function - Check Video Duration**
   ```javascript
   // Utiliser FFprobe (simulé ici)
   const maxDuration = 7200; // 2 heures max
   const videoDuration = $input.item.binary.duration || 0;

   if (videoDuration > maxDuration) {
     throw new Error('Video too long');
   }

   return {
     videoUrl: $json.videoUrl,
     projectId: $json.projectId,
     duration: videoDuration
   };
   ```

5. **Node: Kafka Producer - Send to Queue**
   - Topic: `video.transcription.requested`
   - Message:
   ```json
   {
     "projectId": "{{ $json.projectId }}",
     "videoUrl": "{{ $json.videoUrl }}",
     "userId": "{{ $json.userId }}",
     "priority": "normal",
     "requestedAt": "{{ $json.timestamp }}"
   }
   ```

6. **Node: HTTP Request - Update Project Status**
   - Method: PATCH
   - URL: `http://projects-service:8080/api/projects/{{ $json.projectId }}/status`
   - Body:
   ```json
   {
     "status": "TRANSCRIPTION_QUEUED"
   }
   ```

7. **Node: Send Notification**
   - Email/Slack/Webhook selon configuration
   - Message: "Votre vidéo est en cours de traitement"

**Export du workflow:**
```json
{
  "name": "Video Upload → Auto Transcription",
  "nodes": [...],
  "connections": {...}
}
```

---

### Workflow 2: Compression intelligente avant transcription

**Cas d'usage:** Réduire automatiquement la taille des vidéos >1GB avant transcription.

#### Configuration:

1. **Trigger: Kafka Consumer**
   - Topic: `video.uploaded`
   - Group: `n8n-compression`

2. **Node: Get Video Info**
   - HTTP Request vers MinIO
   - Extraire la taille

3. **Node: IF - Size > 1GB**
   - Condition: `{{ $json.size > 1073741824 }}`

4. **Node: HTTP Request - Trigger FFmpeg Service**
   - Method: POST
   - URL: `http://compression-service:8080/compress`
   - Body:
   ```json
   {
     "inputUrl": "{{ $json.videoUrl }}",
     "outputBucket": "compressed-videos",
     "preset": "medium",
     "targetSize": 500000000
   }
   ```

5. **Node: Wait for Completion**
   - Poll endpoint every 30s
   - Max wait: 30 minutes

6. **Node: Update Video URL**
   - Replace original with compressed
   - Update database

7. **Node: Kafka Producer**
   - Topic: `video.ready.for.transcription`

---

### Workflow 3: Notifications multi-canal

**Cas d'usage:** Envoyer des notifications via Email, Slack, et Webhook quand la transcription est terminée.

#### Configuration:

1. **Trigger: Kafka Consumer**
   - Topic: `video.transcription.completed`

2. **Node: Get Project Details**
   - HTTP Request: `GET /api/projects/{{ $json.projectId }}`

3. **Node: Get User Preferences**
   - HTTP Request: `GET /api/users/{{ $json.userId }}/notifications`

4. **Node: Split In Batches**
   - Par canal de notification

5. **Branch Email:**
   - **IF**: Email enabled
   - **Send Email**:
     - To: `{{ $json.user.email }}`
     - Subject: "Transcription terminée: {{ $json.project.name }}"
     - Body: Template HTML

6. **Branch Slack:**
   - **IF**: Slack enabled
   - **Slack Message**:
     - Channel: `{{ $json.user.slackChannel }}`
     - Message: Blocks avec résumé

7. **Branch Webhook:**
   - **IF**: Webhook configured
   - **HTTP Request**:
     - Method: POST
     - URL: `{{ $json.user.webhookUrl }}`
     - Body: Full event data

8. **Node: Log Notification**
   - Insert dans PostgreSQL
   - Table: notification_history

---

### Workflow 4: Génération automatique de clips

**Cas d'usage:** Extraire automatiquement des clips de 30s basés sur les keywords de la transcription.

#### Configuration:

1. **Trigger: Kafka Consumer**
   - Topic: `transcription.nlp.completed`

2. **Node: Analyze Keywords**
   - HTTP Request vers NLP service
   - Extraire timestamps des keywords importants

3. **Node: Generate Clip Specs**
   ```javascript
   const keywords = $json.keywords;
   const clips = [];

   keywords.forEach((kw, index) => {
     if (kw.importance > 0.7) {
       clips.push({
         startTime: Math.max(0, kw.timestamp - 15),
         endTime: kw.timestamp + 15,
         duration: 30,
         title: `Clip ${index + 1}: ${kw.keyword}`,
         keywords: [kw.keyword]
       });
     }
   });

   return { clips };
   ```

4. **Node: Split Clips**
   - Item: `{{ $json.clips }}`

5. **Node: HTTP Request - Generate Clip**
   - Method: POST
   - URL: `http://clipper-service:8080/clips`
   - Body:
   ```json
   {
     "videoUrl": "{{ $json.videoUrl }}",
     "startTime": "{{ $item.startTime }}",
     "endTime": "{{ $item.endTime }}",
     "outputBucket": "generated-clips"
   }
   ```

6. **Node: Merge Results**
   - Aggregate tous les clips générés

7. **Node: Update Project**
   - PATCH `/api/projects/{{ $json.projectId }}/clips`

8. **Node: Notify User**
   - Email avec liens vers les clips

---

### Workflow 5: Monitoring et alertes

**Cas d'usage:** Surveiller les métriques et alerter en cas de problème.

#### Configuration:

1. **Trigger: Cron**
   - Schedule: `*/5 * * * *` (toutes les 5 min)

2. **Node: Query Prometheus**
   - HTTP Request: `GET http://prometheus:9090/api/v1/query`
   - Queries:
     - CPU usage
     - Memory usage
     - GPU utilization
     - Queue depth
     - Error rate

3. **Node: Check Thresholds**
   ```javascript
   const metrics = $json.data.result;
   const alerts = [];

   // CPU > 90%
   if (metrics.cpu > 90) {
     alerts.push({
       severity: 'warning',
       message: 'CPU usage high: ' + metrics.cpu + '%'
     });
   }

   // GPU Memory > 95%
   if (metrics.gpu_memory > 95) {
     alerts.push({
       severity: 'critical',
       message: 'GPU memory critical: ' + metrics.gpu_memory + '%'
     });
   }

   // Queue > 100
   if (metrics.queue_depth > 100) {
     alerts.push({
       severity: 'warning',
       message: 'Queue depth high: ' + metrics.queue_depth
     });
   }

   return { alerts };
   ```

4. **Node: IF - Has Alerts**
   - Condition: `{{ $json.alerts.length > 0 }}`

5. **Node: Send Slack Alert**
   - Channel: `#monitoring`
   - Message: Format alerts

6. **Node: Create Incident**
   - HTTP Request to incident management system

7. **Node: Log to Database**
   - Insert dans alerts_history

---

## 🔌 Étape 3: Intégrations tierces

### Intégration Google Drive

**Workflow: Upload résultats vers Google Drive**

1. **Credentials:**
   - Settings → Credentials → New
   - Type: Google OAuth2
   - Scopes: `https://www.googleapis.com/auth/drive.file`

2. **Node: Google Drive Upload**
   - Operation: Upload
   - Folder: `/Video AI Results/{{ $json.projectId }}`
   - File: `{{ $binary.data }}`

### Intégration Slack

**Workflow: Notifications Slack**

1. **Credentials:**
   - Create Slack App
   - Add Bot Token
   - Add to n8n credentials

2. **Node: Slack**
   - Operation: Send Message
   - Channel: `#video-processing`
   - Message: Blocks avec statut

### Intégration Dropbox

**Workflow: Backup automatique**

1. **Credentials:**
   - OAuth2 Dropbox

2. **Node: Dropbox Upload**
   - Folder: `/Video AI Backups/`
   - File: Transcriptions + Clips

---

## 📊 Étape 4: Monitoring des workflows

### Dashboard n8n

Dans n8n → Executions:
- Voir tous les workflows exécutés
- Temps d'exécution
- Taux de succès/échec
- Logs détaillés

### Métriques Prometheus

```yaml
# Exposer métriques n8n vers Prometheus
# n8n n'a pas d'export natif, utiliser un exporter custom

# Créer un workflow qui publie les métriques:
# - Nombre d'exécutions
# - Durée moyenne
# - Taux d'erreur
# - Workflows actifs
```

### Dashboard Grafana

Créer un dashboard avec:
- Exécutions par workflow
- Temps moyen d'exécution
- Taux de succès
- Erreurs récentes

---

## 💡 Workflows avancés

### Auto-scaling des workers

**Cas d'usage:** Démarrer des workers additionnels si la queue Kafka > 50

```javascript
// Node: Check Queue Depth
const queueDepth = $json.queueDepth;
const currentWorkers = $json.currentWorkers;
const maxWorkers = 10;

if (queueDepth > 50 && currentWorkers < maxWorkers) {
  // Scale up
  return {
    action: 'scale_up',
    targetWorkers: Math.min(currentWorkers + 2, maxWorkers)
  };
} else if (queueDepth < 10 && currentWorkers > 1) {
  // Scale down
  return {
    action: 'scale_down',
    targetWorkers: Math.max(currentWorkers - 1, 1)
  };
}

return { action: 'no_change' };
```

### A/B Testing automatique

**Cas d'usage:** Tester différents modèles Whisper et choisir le meilleur

```javascript
// Node: Split Traffic
const userId = $json.userId;
const hashCode = userId.split('').reduce((a,b) => {
  return ((a << 5) - a) + b.charCodeAt(0);
}, 0);

// 50/50 split
const variant = (hashCode % 2 === 0) ? 'base' : 'medium';

return {
  userId: userId,
  model: variant,
  videoUrl: $json.videoUrl
};
```

### Cost optimization

**Cas d'usage:** Router vers CPU ou GPU selon la durée

```javascript
// Node: Smart Routing
const videoDuration = $json.duration; // en secondes

// Vidéos courtes (<5 min) → CPU (plus économique)
// Vidéos longues (>5 min) → GPU (plus rapide)

const threshold = 300; // 5 minutes

if (videoDuration < threshold) {
  return {
    worker: 'cpu',
    model: 'tiny', // Modèle rapide suffisant
    priority: 'low'
  };
} else {
  return {
    worker: 'gpu',
    model: 'base',
    priority: 'normal'
  };
}
```

---

## 🔐 Sécurité

### Authentification

```yaml
# docker-compose.yml
n8n:
  environment:
    - N8N_BASIC_AUTH_ACTIVE=true
    - N8N_BASIC_AUTH_USER=admin
    - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}

    # Ou OAuth2
    - N8N_AUTH_OAUTH2_ENABLED=true
    - N8N_AUTH_OAUTH2_CLIENT_ID=${OAUTH_CLIENT_ID}
    - N8N_AUTH_OAUTH2_CLIENT_SECRET=${OAUTH_CLIENT_SECRET}
```

### Secrets Management

Ne jamais hardcoder les secrets dans les workflows:
- Utiliser les Credentials n8n
- Ou variables d'environnement
- Ou intégration avec Vault

---

## 📈 Optimisations

### Performances

1. **Async execution:**
   - Activer l'exécution asynchrone pour les workflows longs

2. **Caching:**
   - Cacher les résultats d'API fréquemment appelées

3. **Batch processing:**
   - Grouper les opérations similaires

### Coûts

**Économies avec n8n:**
- Temps de développement: -40%
- Maintenance: -30%
- Intégrations tierces: Gratuit (vs Zapier ~100€/mois)

**Investissement:**
- RAM additionnel: +2GB = +20€/mois (cloud) ou +0€ (on-premise)
- Temps de setup: ~8-16h
- **ROI: < 1 mois**

---

## ✅ Checklist de déploiement

- [ ] n8n déployé sur Proxmox
- [ ] Accessible via http://192.168.1.23:5678
- [ ] Authentification configurée
- [ ] Credentials créées (Kafka, PostgreSQL, MinIO)
- [ ] Workflow 1: Video Upload → Transcription (testé)
- [ ] Workflow 2: Compression intelligente (testé)
- [ ] Workflow 3: Notifications (testé)
- [ ] Monitoring Grafana configuré
- [ ] Backups n8n configurés

---

## 📞 Support

- [Documentation n8n](https://docs.n8n.io/)
- [Community Forum](https://community.n8n.io/)
- [Workflow Templates](https://n8n.io/workflows/)

**Prêt à automatiser vos workflows? 🚀**
