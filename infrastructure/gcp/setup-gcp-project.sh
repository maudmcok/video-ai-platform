#!/bin/bash

# Video AI Platform - GCP Project Setup Script
# This script initializes a new GCP project for GPU-accelerated transcription

set -e  # Exit on error

echo "=================================================="
echo "🚀 Video AI Platform - GCP Setup"
echo "=================================================="
echo ""

# Load environment variables
if [ -f .env ]; then
    echo "✓ Loading .env configuration..."
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ Error: .env file not found"
    echo "   Copy .env.example to .env and configure your values"
    exit 1
fi

# Validate required variables
required_vars=("GCP_PROJECT_ID" "GCP_REGION" "GCP_ZONE" "ALERT_EMAIL")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: $var is not set in .env"
        exit 1
    fi
done

echo "📋 Configuration:"
echo "   Project ID: $GCP_PROJECT_ID"
echo "   Region: $GCP_REGION"
echo "   Zone: $GCP_ZONE"
echo ""

# Check if gcloud CLI is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI is not installed"
    echo "   Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

echo "✓ gcloud CLI found"
echo ""

# Step 1: Set project
echo "📌 Step 1/7: Setting GCP project..."
gcloud config set project $GCP_PROJECT_ID
echo ""

# Step 2: Enable required APIs
echo "📌 Step 2/7: Enabling required APIs..."
apis=(
    "compute.googleapis.com"
    "container.googleapis.com"
    "cloudbuild.googleapis.com"
    "cloudscheduler.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "monitoring.googleapis.com"
    "logging.googleapis.com"
    "secretmanager.googleapis.com"
    "billingbudgets.googleapis.com"
)

for api in "${apis[@]}"; do
    echo "   Enabling $api..."
    gcloud services enable $api --quiet
done
echo "✓ All APIs enabled"
echo ""

# Step 3: Create service account
echo "📌 Step 3/7: Creating service account..."
SERVICE_ACCOUNT_NAME="videoai-gpu-worker"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL &>/dev/null; then
    echo "   Service account already exists"
else
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --display-name="Video AI GPU Worker" \
        --description="Service account for GPU transcription workers"
    echo "✓ Service account created: $SERVICE_ACCOUNT_EMAIL"
fi

# Grant necessary roles
echo "   Granting IAM roles..."
roles=(
    "roles/compute.instanceAdmin.v1"
    "roles/logging.logWriter"
    "roles/monitoring.metricWriter"
    "roles/storage.objectViewer"
)

for role in "${roles[@]}"; do
    gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="$role" \
        --quiet
done
echo "✓ IAM roles granted"
echo ""

# Step 4: Set up VPC network
echo "📌 Step 4/7: Setting up VPC network..."
NETWORK_NAME="videoai-network"

if gcloud compute networks describe $NETWORK_NAME &>/dev/null; then
    echo "   Network already exists"
else
    gcloud compute networks create $NETWORK_NAME \
        --subnet-mode=auto \
        --bgp-routing-mode=regional
    echo "✓ Network created: $NETWORK_NAME"
fi

# Create firewall rules
echo "   Creating firewall rules..."

# Allow SSH
gcloud compute firewall-rules create ${NETWORK_NAME}-allow-ssh \
    --network=$NETWORK_NAME \
    --allow=tcp:22 \
    --source-ranges=0.0.0.0/0 \
    --description="Allow SSH access" \
    --quiet 2>/dev/null || echo "   SSH rule already exists"

# Allow internal communication
gcloud compute firewall-rules create ${NETWORK_NAME}-allow-internal \
    --network=$NETWORK_NAME \
    --allow=tcp:0-65535,udp:0-65535,icmp \
    --source-ranges=10.128.0.0/9 \
    --description="Allow internal communication" \
    --quiet 2>/dev/null || echo "   Internal rule already exists"

# Allow WireGuard VPN
gcloud compute firewall-rules create ${NETWORK_NAME}-allow-wireguard \
    --network=$NETWORK_NAME \
    --allow=udp:51820 \
    --source-ranges=0.0.0.0/0 \
    --description="Allow WireGuard VPN" \
    --quiet 2>/dev/null || echo "   WireGuard rule already exists"

echo "✓ Firewall rules configured"
echo ""

# Step 5: Set up budget alerts
echo "📌 Step 5/7: Setting up budget alerts..."
BILLING_ACCOUNT=$(gcloud beta billing projects describe $GCP_PROJECT_ID --format="value(billingAccountName)" | sed 's/.*\///')

if [ -n "$BILLING_ACCOUNT" ]; then
    cat > /tmp/budget-alert.json <<EOF
{
  "displayName": "Video AI Platform Monthly Budget",
  "budgetFilter": {
    "projects": ["projects/${GCP_PROJECT_ID}"]
  },
  "amount": {
    "specifiedAmount": {
      "currencyCode": "USD",
      "units": "${MONTHLY_BUDGET}"
    }
  },
  "thresholdRules": [
    {
      "thresholdPercent": 0.5,
      "spendBasis": "CURRENT_SPEND"
    },
    {
      "thresholdPercent": 0.9,
      "spendBasis": "CURRENT_SPEND"
    },
    {
      "thresholdPercent": 1.0,
      "spendBasis": "CURRENT_SPEND"
    }
  ],
  "notificationsRule": {
    "pubsubTopic": "projects/${GCP_PROJECT_ID}/topics/budget-alerts",
    "schemaVersion": "1.0",
    "monitoringNotificationChannels": []
  }
}
EOF

    # Create Pub/Sub topic for alerts
    gcloud pubsub topics create budget-alerts --quiet 2>/dev/null || echo "   Budget topic already exists"

    # Create budget
    gcloud billing budgets create \
        --billing-account=$BILLING_ACCOUNT \
        --display-name="Video AI Platform Monthly Budget" \
        --budget-amount=${MONTHLY_BUDGET}USD \
        --threshold-rule=percent=50 \
        --threshold-rule=percent=90 \
        --threshold-rule=percent=100 \
        --quiet 2>/dev/null || echo "   Budget already exists"

    echo "✓ Budget alert configured: $MONTHLY_BUDGET USD/month"
else
    echo "⚠️  Warning: No billing account linked - budget alerts skipped"
fi
echo ""

# Step 6: Create Cloud Storage bucket for Docker images
echo "📌 Step 6/7: Setting up Container Registry..."
BUCKET_NAME="artifacts.${GCP_PROJECT_ID}.appspot.com"

gsutil mb -p $GCP_PROJECT_ID -c STANDARD -l $GCP_REGION gs://$BUCKET_NAME 2>/dev/null || echo "   Bucket already exists"

echo "✓ Container Registry ready"
echo ""

# Step 7: Set default region and zone
echo "📌 Step 7/7: Setting default region and zone..."
gcloud config set compute/region $GCP_REGION
gcloud config set compute/zone $GCP_ZONE
echo "✓ Defaults configured"
echo ""

# Summary
echo "=================================================="
echo "✅ GCP Project Setup Complete!"
echo "=================================================="
echo ""
echo "📋 Summary:"
echo "   Project ID: $GCP_PROJECT_ID"
echo "   Region: $GCP_REGION"
echo "   Zone: $GCP_ZONE"
echo "   Network: $NETWORK_NAME"
echo "   Service Account: $SERVICE_ACCOUNT_EMAIL"
echo "   Budget: $MONTHLY_BUDGET USD/month"
echo ""
echo "🎯 Next Steps:"
echo "   1. Build and push Docker image: ./build-and-push-image.sh"
echo "   2. Deploy GPU worker: ./deploy-gpu-worker.sh"
echo "   3. Configure VPN: ./setup-vpn.sh"
echo ""
echo "📊 Estimated Monthly Cost:"
echo "   GPU Instance (Spot, 75h/month): ~$12 USD"
echo "   Network egress: ~$5 USD"
echo "   Storage: ~$3 USD"
echo "   Total: ~$20 USD/month"
echo ""
echo "💡 Tip: Use GCP Free Tier credits ($300) for the first 3 months"
echo ""
