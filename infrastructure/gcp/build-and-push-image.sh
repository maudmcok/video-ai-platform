#!/bin/bash

# Video AI Platform - Build and Push Docker Image to GCR
# Builds the CUDA-enabled transcription worker and pushes to Google Container Registry

set -e  # Exit on error

echo "=================================================="
echo "🐳 Building and Pushing Docker Image"
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
required_vars=("GCP_PROJECT_ID" "TRANSCRIPTION_IMAGE")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: $var is not set in .env"
        exit 1
    fi
done

echo "📋 Configuration:"
echo "   Project ID: $GCP_PROJECT_ID"
echo "   Image: $TRANSCRIPTION_IMAGE"
echo ""

# Check if Docker is running
if ! docker info &>/dev/null; then
    echo "❌ Error: Docker is not running"
    echo "   Please start Docker Desktop and try again"
    exit 1
fi
echo "✓ Docker is running"
echo ""

# Configure Docker authentication for GCR
echo "🔐 Configuring Docker authentication..."
gcloud auth configure-docker --quiet
echo "✓ Docker authentication configured"
echo ""

# Navigate to transcription service directory
TRANSCRIPTION_DIR="../../services/transcription"
if [ ! -d "$TRANSCRIPTION_DIR" ]; then
    echo "❌ Error: Transcription service directory not found"
    echo "   Expected: $TRANSCRIPTION_DIR"
    exit 1
fi

cd $TRANSCRIPTION_DIR
echo "✓ Changed to transcription service directory"
echo ""

# Build the Docker image with CUDA support
echo "🔨 Building Docker image..."
echo "   This may take 5-10 minutes (downloading CUDA base image)..."
echo ""

docker build \
    --platform linux/amd64 \
    --tag $TRANSCRIPTION_IMAGE \
    --file Dockerfile.cuda \
    .

echo ""
echo "✅ Image built successfully!"
echo ""

# Push to GCR
echo "📤 Pushing to Google Container Registry..."
echo "   This may take 2-5 minutes..."
echo ""

docker push $TRANSCRIPTION_IMAGE

echo ""
echo "✅ Image pushed successfully!"
echo ""

# Get image details
IMAGE_SIZE=$(docker images $TRANSCRIPTION_IMAGE --format "{{.Size}}")
IMAGE_ID=$(docker images $TRANSCRIPTION_IMAGE --format "{{.ID}}")

echo "=================================================="
echo "📦 Image Details"
echo "=================================================="
echo "   Image: $TRANSCRIPTION_IMAGE"
echo "   Image ID: $IMAGE_ID"
echo "   Size: $IMAGE_SIZE"
echo "   Registry: Google Container Registry (GCR)"
echo ""
echo "🔗 View in GCP Console:"
echo "   https://console.cloud.google.com/gcr/images/${GCP_PROJECT_ID}"
echo ""
echo "📝 Next Steps:"
echo "   1. Deploy GPU worker: cd ../../infrastructure/gcp && ./deploy-gpu-worker.sh"
echo "   2. Or update existing instance: ./update-gpu-worker.sh"
echo ""
echo "✅ Build and push complete!"
echo ""
