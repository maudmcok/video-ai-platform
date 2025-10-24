#!/bin/bash

# Script de démarrage de l'environnement de développement (Linux/Mac)

set -e

echo "========================================"
echo "  Video AI Platform - Démarrage Dev"
echo "========================================"
echo ""

# Vérification Docker
if ! command -v docker &> /dev/null; then
    echo "[ERREUR] Docker n'est pas installé"
    exit 1
fi

echo "[1/5] Démarrage de l'infrastructure Docker Compose..."
cd ../docker
docker-compose up -d

echo ""
echo "[2/5] Attente de l'initialisation des services (30s)..."
sleep 30

echo ""
echo "[3/5] Vérification de la santé des services..."
docker-compose ps

echo ""
echo "[4/5] Exécution des migrations de base de données..."
cd ../../services/projects
./mvnw flyway:migrate

echo ""
echo "[5/5] Infrastructure prête!"
echo ""
echo "========================================"
echo "  Services disponibles:"
echo "========================================"
echo "  - PostgreSQL:     localhost:5432"
echo "  - Redis:          localhost:6379"
echo "  - Kafka:          localhost:9092"
echo "  - MinIO:          http://localhost:9001"
echo "  - Keycloak:       http://localhost:8180"
echo "  - Temporal UI:    http://localhost:8088"
echo "  - Prometheus:     http://localhost:9090"
echo "  - Grafana:        http://localhost:3000"
echo "========================================"
echo ""
echo "Pour démarrer les services applicatifs:"
echo "  1. Projects Service:     cd services/projects && ./mvnw quarkus:dev"
echo "  2. Transcription Worker: cd services/transcription && python worker.py"
echo ""
