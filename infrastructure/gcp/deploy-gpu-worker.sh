#!/bin/bash

# Video AI Platform - Deploy GPU Worker on GCP
# Creates a GPU-accelerated VM instance for Whisper transcription

set -e  # Exit on error

echo "=================================================="
echo "🚀 Deploying GPU Worker on GCP"
echo "=================================================="
echo ""

# Load environment variables
if [ -f .env ]; then
    echo "✓ Loading .env configuration..."
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ Error: .env file not found"
    exit 1
fi

# Validate required variables
required_vars=("GCP_PROJECT_ID" "GCP_ZONE" "INSTANCE_NAME" "INSTANCE_TYPE" "GPU_TYPE" "PRICING_MODEL")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: $var is not set in .env"
        exit 1
    fi
done

echo "📋 Configuration:"
echo "   Instance Name: $INSTANCE_NAME"
echo "   Instance Type: $INSTANCE_TYPE"
echo "   GPU Type: $GPU_TYPE (x${GPU_COUNT})"
echo "   Pricing: $PRICING_MODEL"
echo "   Zone: $GCP_ZONE"
echo ""

# Check if instance already exists
if gcloud compute instances describe $INSTANCE_NAME --zone=$GCP_ZONE &>/dev/null; then
    echo "⚠️  Instance '$INSTANCE_NAME' already exists"
    read -p "Delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "   Deleting existing instance..."
        gcloud compute instances delete $INSTANCE_NAME --zone=$GCP_ZONE --quiet
    else
        echo "   Aborting..."
        exit 0
    fi
fi

# Determine pricing flags
PRICING_FLAGS=""
if [ "$PRICING_MODEL" = "preemptible" ]; then
    PRICING_FLAGS="--preemptible"
    echo "💡 Using preemptible instance (up to 80% cheaper)"
elif [ "$PRICING_MODEL" = "spot" ]; then
    PRICING_FLAGS="--provisioning-model=SPOT --instance-termination-action=DELETE"
    echo "💡 Using spot instance (up to 90% cheaper)"
else
    echo "💡 Using standard instance"
fi

# Create startup script
echo "📝 Creating startup script..."
cat > /tmp/startup-script.sh <<'EOF'
#!/bin/bash

# Startup script for GCP GPU Worker
set -e

echo "=================================================="
echo "🚀 GPU Worker Initialization"
echo "=================================================="

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
fi

# Install NVIDIA drivers and CUDA
echo "🎮 Installing NVIDIA drivers..."
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

apt-get update
apt-get install -y nvidia-driver-535 nvidia-container-toolkit

# Configure Docker for GPU
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

# Test GPU
nvidia-smi

# Pull Docker image
echo "📥 Pulling transcription worker image..."
docker pull ${TRANSCRIPTION_IMAGE}

# Start worker container
echo "🚀 Starting worker container..."
docker run -d \
    --name videoai-transcription-worker \
    --restart unless-stopped \
    --gpus all \
    -e CUDA_VISIBLE_DEVICES=0 \
    -e WHISPER_MODEL=base \
    -e WHISPER_DEVICE=cuda \
    -e KAFKA_BOOTSTRAP_SERVERS=${KAFKA_BOOTSTRAP_SERVERS} \
    -e MINIO_ENDPOINT=${MINIO_ENDPOINT} \
    -e MINIO_ACCESS_KEY=${MINIO_ACCESS_KEY} \
    -e MINIO_SECRET_KEY=${MINIO_SECRET_KEY} \
    ${TRANSCRIPTION_IMAGE}

echo "✅ GPU Worker initialized successfully"

# Setup monitoring
echo "📊 Setting up monitoring..."
docker run -d \
    --name dcgm-exporter \
    --gpus all \
    --restart unless-stopped \
    -p 9400:9400 \
    nvidia/dcgm-exporter:latest

# Install Stackdriver agent
curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
bash add-logging-agent-repo.sh --also-install

echo "✅ Monitoring configured"
echo "=================================================="
EOF

# Replace environment variables in startup script
sed -i "s|\${TRANSCRIPTION_IMAGE}|${TRANSCRIPTION_IMAGE}|g" /tmp/startup-script.sh
sed -i "s|\${KAFKA_BOOTSTRAP_SERVERS}|${KAFKA_BOOTSTRAP_SERVERS}|g" /tmp/startup-script.sh
sed -i "s|\${MINIO_ENDPOINT}|${MINIO_ENDPOINT}|g" /tmp/startup-script.sh
sed -i "s|\${MINIO_ACCESS_KEY}|${MINIO_ACCESS_KEY}|g" /tmp/startup-script.sh
sed -i "s|\${MINIO_SECRET_KEY}|${MINIO_SECRET_KEY}|g" /tmp/startup-script.sh

echo "✓ Startup script ready"
echo ""

# Create the instance
echo "🚀 Creating GPU instance..."
echo "   This may take 2-3 minutes..."
echo ""

gcloud compute instances create $INSTANCE_NAME \
    --zone=$GCP_ZONE \
    --machine-type=$INSTANCE_TYPE \
    --accelerator=type=$GPU_TYPE,count=$GPU_COUNT \
    --maintenance-policy=TERMINATE \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=50GB \
    --boot-disk-type=pd-standard \
    --network=videoai-network \
    --subnet=default \
    --metadata-from-file=startup-script=/tmp/startup-script.sh \
    --service-account=${SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com \
    --scopes=cloud-platform \
    --tags=gpu-worker,http-server \
    $PRICING_FLAGS \
    --quiet

echo ""
echo "✅ Instance created successfully!"
echo ""

# Get instance details
EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$GCP_ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
INTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$GCP_ZONE --format="get(networkInterfaces[0].networkIP)")

echo "=================================================="
echo "📊 Instance Details"
echo "=================================================="
echo "   Name: $INSTANCE_NAME"
echo "   Zone: $GCP_ZONE"
echo "   Type: $INSTANCE_TYPE"
echo "   GPU: $GPU_TYPE (x${GPU_COUNT})"
echo "   Pricing: $PRICING_MODEL"
echo ""
echo "   External IP: $EXTERNAL_IP"
echo "   Internal IP: $INTERNAL_IP"
echo ""
echo "=================================================="
echo "⏳ Initializing (this takes ~5-10 minutes)..."
echo "=================================================="
echo ""
echo "Monitor progress:"
echo "   gcloud compute instances get-serial-port-output $INSTANCE_NAME --zone=$GCP_ZONE"
echo ""
echo "SSH to instance:"
echo "   gcloud compute ssh $INSTANCE_NAME --zone=$GCP_ZONE"
echo ""
echo "View logs:"
echo "   gcloud compute ssh $INSTANCE_NAME --zone=$GCP_ZONE --command='sudo docker logs -f videoai-transcription-worker'"
echo ""
echo "Check GPU:"
echo "   gcloud compute ssh $INSTANCE_NAME --zone=$GCP_ZONE --command='nvidia-smi'"
echo ""

# Wait for startup to complete
echo "⏳ Waiting for instance to be ready..."
sleep 30

echo "Checking startup progress..."
gcloud compute instances get-serial-port-output $INSTANCE_NAME --zone=$GCP_ZONE 2>/dev/null | tail -20 || echo "Still initializing..."

echo ""
echo "=================================================="
echo "💰 Cost Estimate"
echo "=================================================="

if [ "$PRICING_MODEL" = "spot" ]; then
    HOURLY_COST="0.16"
    MONTHLY_COST="12"
elif [ "$PRICING_MODEL" = "preemptible" ]; then
    HOURLY_COST="0.22"
    MONTHLY_COST="16.50"
else
    HOURLY_COST="0.35"
    MONTHLY_COST="26.25"
fi

echo "   Hourly: ~$${HOURLY_COST} USD"
echo "   Monthly (75h): ~$${MONTHLY_COST} USD"
echo ""
echo "💡 Tip: Stop instance when not in use:"
echo "   gcloud compute instances stop $INSTANCE_NAME --zone=$GCP_ZONE"
echo ""
echo "✅ Deployment complete!"
echo ""
