#!/bin/bash

# Video AI Platform - Proxmox Deployment Script
# Target: Docker VM at 192.168.1.23

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROXMOX_DOCKER_IP="192.168.1.23"
DEPLOY_USER="${DEPLOY_USER:-root}"
PROJECT_NAME="video-ai-platform"
REMOTE_DIR="/opt/${PROJECT_NAME}"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Video AI Platform - Proxmox Deployment${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found!${NC}"
    echo -e "${YELLOW}Creating .env from .env.example...${NC}"
    cp .env.example .env
    echo -e "${RED}❌ Please edit .env file with your production values before deploying!${NC}"
    exit 1
fi

# Function to run command on remote server
remote_exec() {
    ssh ${DEPLOY_USER}@${PROXMOX_DOCKER_IP} "$@"
}

# Function to copy files to remote server
remote_copy() {
    scp -r "$1" ${DEPLOY_USER}@${PROXMOX_DOCKER_IP}:"$2"
}

echo -e "${BLUE}Step 1: Testing SSH connection to ${PROXMOX_DOCKER_IP}...${NC}"
if ssh -o BatchMode=yes -o ConnectTimeout=5 ${DEPLOY_USER}@${PROXMOX_DOCKER_IP} exit 2>/dev/null; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "${RED}❌ Cannot connect to ${PROXMOX_DOCKER_IP}${NC}"
    echo -e "${YELLOW}Please ensure:${NC}"
    echo -e "${YELLOW}  1. SSH is enabled on the Docker VM${NC}"
    echo -e "${YELLOW}  2. SSH key is configured (or use password)${NC}"
    echo -e "${YELLOW}  3. The IP address is correct${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 2: Creating remote directory...${NC}"
remote_exec "mkdir -p ${REMOTE_DIR}/{infrastructure,services}"
echo -e "${GREEN}✓ Remote directory created${NC}"

echo ""
echo -e "${BLUE}Step 3: Copying deployment files...${NC}"
echo -e "  → Copying docker-compose.proxmox.yml..."
remote_copy "docker-compose.proxmox.yml" "${REMOTE_DIR}/docker-compose.yml"

echo -e "  → Copying .env file..."
remote_copy ".env" "${REMOTE_DIR}/.env"

echo -e "  → Copying infrastructure files..."
remote_copy "../docker/init-db.sql" "${REMOTE_DIR}/infrastructure/"
remote_copy "../prometheus/prometheus.yml" "${REMOTE_DIR}/infrastructure/"

echo -e "${GREEN}✓ Files copied successfully${NC}"

echo ""
echo -e "${BLUE}Step 4: Building Docker images (this may take a while)...${NC}"

# Build projects-service image
echo -e "  → Building projects-service image..."
cd ../../services/projects
docker build -t videoai/projects-service:latest -f ../../infrastructure/docker/Dockerfile.projects .
docker save videoai/projects-service:latest | ssh ${DEPLOY_USER}@${PROXMOX_DOCKER_IP} docker load

# Build transcription-worker image
echo -e "  → Building transcription-worker image..."
cd ../transcription
docker build -t videoai/transcription-worker:latest .
docker save videoai/transcription-worker:latest | ssh ${DEPLOY_USER}@${PROXMOX_DOCKER_IP} docker load

cd ../../infrastructure/proxmox
echo -e "${GREEN}✓ Images built and transferred${NC}"

echo ""
echo -e "${BLUE}Step 5: Deploying services on Proxmox...${NC}"
remote_exec "cd ${REMOTE_DIR} && docker-compose down --remove-orphans"
remote_exec "cd ${REMOTE_DIR} && docker-compose up -d"

echo -e "${GREEN}✓ Services deployed${NC}"

echo ""
echo -e "${BLUE}Step 6: Waiting for services to be healthy...${NC}"
sleep 10

# Check service health
echo -e "  → Checking service status..."
remote_exec "cd ${REMOTE_DIR} && docker-compose ps"

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${BLUE}Access your services at:${NC}"
echo -e "  📊 Grafana:        http://${PROXMOX_DOCKER_IP}:3000"
echo -e "  📈 Prometheus:     http://${PROXMOX_DOCKER_IP}:9090"
echo -e "  🔐 Keycloak:       http://${PROXMOX_DOCKER_IP}:8180"
echo -e "  💾 MinIO Console:  http://${PROXMOX_DOCKER_IP}:9001"
echo -e "  ⏱️  Temporal UI:    http://${PROXMOX_DOCKER_IP}:8088"
echo -e "  🚀 API (Swagger):  http://${PROXMOX_DOCKER_IP}:8080/swagger-ui"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Configure Keycloak realm and clients"
echo -e "  2. Create MinIO buckets for video storage"
echo -e "  3. Configure Grafana dashboards"
echo -e "  4. Test the API endpoints"
echo ""
