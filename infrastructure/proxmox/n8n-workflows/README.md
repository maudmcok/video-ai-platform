# n8n Workflows - Video AI Platform

This directory contains n8n workflow definitions for intelligent routing and automation.

## 📋 Available Workflows

### 1. Smart Transcription Router (`smart-transcription-router.json`)

**Purpose:** Intelligently routes transcription jobs between local CPU workers and GCP GPU workers based on video duration and configuration.

**Logic:**
```
Kafka Trigger (video.transcription.requested)
    ↓
Route Decision:
    If GCP_GPU_ENABLED=true AND videoDuration >= 5 min
        → Send to GCP GPU Worker (Kafka: transcription.gpu.requests)
    Else
        → Send to Local CPU Worker (Kafka: transcription.cpu.requests)
    ↓
Update Project Status API
    ↓
Cache Request in Redis (TTL: 24h)
    ↓
Log Metrics to Prometheus
```

**Benefits:**
- 🚀 Route long videos to fast GPU workers (10x faster)
- 💰 Route short videos to local CPU (save cloud costs)
- 📊 Automatic metrics collection
- 🔄 Redis caching for request tracking

---

## 🚀 Installation

### 1. Import Workflows

After deploying n8n (via `docker-compose up`), access the UI:

```
http://192.168.1.23:5678
Username: admin
Password: (from .env - N8N_BASIC_AUTH_PASSWORD)
```

Then import workflows:

1. Click **Workflows** → **Import from File**
2. Select `smart-transcription-router.json`
3. Click **Save**

### 2. Configure Credentials

#### Kafka Credential

1. Go to **Credentials** → **New**
2. Select **Kafka**
3. Name: `Video AI Kafka`
4. Configuration:
   ```
   Brokers: kafka:9092
   Client ID: n8n-video-ai
   SASL: None (internal network)
   ```

#### Redis Credential

1. Go to **Credentials** → **New**
2. Select **Redis**
3. Name: `Video AI Redis`
4. Configuration:
   ```
   Host: redis
   Port: 6379
   Database: 0
   ```

#### Keycloak OAuth2 (for API calls)

1. Go to **Credentials** → **New**
2. Select **OAuth2 API**
3. Name: `Video AI Keycloak`
4. Configuration:
   ```
   Grant Type: Client Credentials
   Authorization URL: http://keycloak:8080/realms/videoai/protocol/openid-connect/auth
   Access Token URL: http://keycloak:8080/realms/videoai/protocol/openid-connect/token
   Client ID: video-ai-platform
   Client Secret: (from Keycloak)
   ```

### 3. Activate Workflow

1. Open the imported workflow
2. Click **Activate** toggle (top-right)
3. Check logs: **Executions** tab

---

## 📊 Monitoring

### View Workflow Executions

```
http://192.168.1.23:5678/workflow/<workflow-id>/executions
```

### Kafka Topics

Monitor Kafka to see routing:

```bash
# SSH to Proxmox VM
ssh root@192.168.1.23

# Consumer GPU topic
docker exec -it videoai-kafka-proxmox kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic transcription.gpu.requests

# Consumer CPU topic
docker exec -it videoai-kafka-proxmox kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic transcription.cpu.requests
```

### Redis Cache

Check cached requests:

```bash
docker exec -it videoai-redis-proxmox redis-cli

# Get all transcription keys
KEYS transcription:*

# Get specific request
GET transcription:<project-id>
```

---

## 🔧 Configuration

### Environment Variables (set in `.env`)

```env
# Enable/disable GCP GPU routing
GCP_GPU_ENABLED=true

# Kafka topics
GCP_KAFKA_TOPIC=transcription.gpu.requests
LOCAL_KAFKA_TOPIC=transcription.cpu.requests
```

### Routing Thresholds

Edit `smart-transcription-router.json` to change thresholds:

```json
{
  "parameters": {
    "conditions": {
      "number": [
        {
          "value1": "={{$json.videoDuration}}",
          "operation": "largerEqual",
          "value2": 300  // 5 minutes - change this value
        }
      ]
    }
  }
}
```

**Recommended thresholds:**
- **Tiny videos (<1 min):** Always local CPU
- **Short videos (1-5 min):** Local CPU
- **Medium videos (5-30 min):** GCP GPU
- **Long videos (>30 min):** GCP GPU

---

## 💰 Cost Optimization

The smart router optimizes costs by:

1. **Short videos → CPU:** Videos <5 min transcribe in ~2-3 min on CPU (acceptable)
2. **Long videos → GPU:** Videos >5 min benefit from 10x speedup
3. **Auto-scaling:** GCP GPU workers can scale to 0 when idle

**Example savings (100 videos/month):**

| Scenario | Videos | Avg Duration | Route | Cost |
|----------|--------|--------------|-------|------|
| All videos → GCP GPU | 100 | 10 min | GPU | ~$50/month |
| All videos → CPU | 100 | 10 min | CPU | $0 (Proxmox) |
| **Smart routing** | **50 + 50** | **5 min + 20 min** | **Mixed** | **~$20/month** |

**Savings: 60%** vs all-GPU, with same performance!

---

## 🧪 Testing

### Test Routing Logic

Send a test Kafka message:

```bash
docker exec -it videoai-kafka-proxmox kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic video.transcription.requested

# Paste JSON and press Enter:
{
  "projectId": "test-123",
  "videoId": "vid-456",
  "videoDuration": 600,
  "videoUrl": "http://minio:9000/videos/test.mp4"
}
```

**Expected behavior:**
- If `GCP_GPU_ENABLED=true` and duration ≥ 300 → Routes to `transcription.gpu.requests`
- Otherwise → Routes to `transcription.cpu.requests`

Check n8n executions to verify routing.

---

## 📚 Creating Custom Workflows

### Example: Video Quality Check Before Transcription

```json
{
  "name": "Pre-Transcription Quality Check",
  "nodes": [
    {
      "type": "kafkaTrigger",
      "topic": "video.uploaded"
    },
    {
      "type": "httpRequest",
      "url": "{{$env.MINIO_ENDPOINT}}/{{$json.bucket}}/{{$json.key}}",
      "method": "HEAD"
    },
    {
      "type": "if",
      "condition": "{{$json.headers['content-length']}} < 10000000"
    },
    {
      "type": "kafka",
      "topic": "video.transcription.requested"
    }
  ]
}
```

---

## 🆘 Troubleshooting

### Workflow Not Triggering

1. **Check Kafka connection:**
```bash
docker exec -it videoai-n8n-proxmox ping kafka
```

2. **Check Kafka topic exists:**
```bash
docker exec -it videoai-kafka-proxmox kafka-topics --list --bootstrap-server localhost:9092
```

3. **Check n8n logs:**
```bash
docker logs -f videoai-n8n-proxmox
```

### Credentials Not Working

1. **Keycloak:** Ensure client has `service-accounts-enabled: true`
2. **Kafka:** Verify network connectivity from n8n container
3. **Redis:** Check Redis is running: `docker ps | grep redis`

### Execution Failing

1. Go to **Executions** tab
2. Click failed execution
3. Check error message in each node
4. Common issues:
   - Missing environment variables
   - Invalid JSON in Kafka message
   - API authentication failure

---

## 📞 Support

For more workflow examples, see:
- [n8n Documentation](https://docs.n8n.io/)
- [Kafka Integration Guide](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.kafka/)
- [Video AI Platform Docs](../../docs/N8N-INTEGRATION-GUIDE.md)

---

**🚀 Happy automating!**
