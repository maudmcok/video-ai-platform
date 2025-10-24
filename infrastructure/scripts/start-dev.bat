@echo off
REM Script de démarrage de l'environnement de développement (Windows)

echo ========================================
echo   Video AI Platform - Demarrage Dev
echo ========================================
echo.

REM Vérification Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERREUR] Docker n'est pas installe ou pas demarre
    exit /b 1
)

echo [1/5] Demarrage de l'infrastructure Docker Compose...
cd ..\docker
docker-compose up -d

echo.
echo [2/5] Attente de l'initialisation des services (30s)...
timeout /t 30 /nobreak

echo.
echo [3/5] Verification de la sante des services...
docker-compose ps

echo.
echo [4/5] Execution des migrations de base de donnees...
cd ..\..\services\projects
call mvnw.cmd flyway:migrate

echo.
echo [5/5] Infrastructure prete!
echo.
echo ========================================
echo   Services disponibles:
echo ========================================
echo   - PostgreSQL:     localhost:5432
echo   - Redis:          localhost:6379
echo   - Kafka:          localhost:9092
echo   - MinIO:          http://localhost:9001
echo   - Keycloak:       http://localhost:8180
echo   - Temporal UI:    http://localhost:8088
echo   - Prometheus:     http://localhost:9090
echo   - Grafana:        http://localhost:3000
echo ========================================
echo.
echo Pour demarrer les services applicatifs:
echo   1. Projects Service:     cd services\projects ^&^& mvnw.cmd quarkus:dev
echo   2. Transcription Worker: cd services\transcription ^&^& python worker.py
echo.
pause
