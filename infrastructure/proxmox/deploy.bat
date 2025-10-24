@echo off
REM Video AI Platform - Proxmox Deployment Script (Windows)
REM Target: Docker VM at 192.168.1.23

setlocal EnableDelayedExpansion

echo =====================================
echo Video AI Platform - Proxmox Deployment
echo =====================================
echo.

REM Configuration
set PROXMOX_DOCKER_IP=192.168.1.23
set DEPLOY_USER=root
set PROJECT_NAME=video-ai-platform
set REMOTE_DIR=/opt/%PROJECT_NAME%

REM Check if .env file exists
if not exist ".env" (
    echo [WARNING] .env file not found!
    echo Creating .env from .env.example...
    copy .env.example .env
    echo.
    echo [ERROR] Please edit .env file with your production values before deploying!
    pause
    exit /b 1
)

echo Step 1: Testing SSH connection to %PROXMOX_DOCKER_IP%...
ssh -o BatchMode=yes -o ConnectTimeout=5 %DEPLOY_USER%@%PROXMOX_DOCKER_IP% exit >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Cannot connect to %PROXMOX_DOCKER_IP%
    echo.
    echo Please ensure:
    echo   1. SSH is enabled on the Docker VM
    echo   2. SSH key is configured ^(or use password^)
    echo   3. The IP address is correct
    echo.
    echo You can test connection with: ssh %DEPLOY_USER%@%PROXMOX_DOCKER_IP%
    pause
    exit /b 1
)
echo [OK] SSH connection successful
echo.

echo Step 2: Creating remote directory...
ssh %DEPLOY_USER%@%PROXMOX_DOCKER_IP% "mkdir -p %REMOTE_DIR%/{infrastructure,services}"
echo [OK] Remote directory created
echo.

echo Step 3: Copying deployment files...
echo   - Copying docker-compose.proxmox.yml...
scp docker-compose.proxmox.yml %DEPLOY_USER%@%PROXMOX_DOCKER_IP%:%REMOTE_DIR%/docker-compose.yml

echo   - Copying .env file...
scp .env %DEPLOY_USER%@%PROXMOX_DOCKER_IP%:%REMOTE_DIR%/.env

echo   - Copying infrastructure files...
scp ../docker/init-db.sql %DEPLOY_USER%@%PROXMOX_DOCKER_IP%:%REMOTE_DIR%/infrastructure/
scp ../prometheus/prometheus.yml %DEPLOY_USER%@%PROXMOX_DOCKER_IP%:%REMOTE_DIR%/infrastructure/

echo [OK] Files copied successfully
echo.

echo Step 4: Building Docker images...
echo   - Building projects-service image...
echo     (This may take a while, please be patient...)
cd ..\..\services\projects
docker build -t videoai/projects-service:latest -f ..\..\infrastructure\docker\Dockerfile.projects .
if errorlevel 1 (
    echo [ERROR] Failed to build projects-service image
    pause
    exit /b 1
)

echo   - Transferring projects-service image to Proxmox...
docker save videoai/projects-service:latest | ssh %DEPLOY_USER%@%PROXMOX_DOCKER_IP% docker load

echo   - Building transcription-worker image...
cd ..\transcription
docker build -t videoai/transcription-worker:latest .
if errorlevel 1 (
    echo [ERROR] Failed to build transcription-worker image
    pause
    exit /b 1
)

echo   - Transferring transcription-worker image to Proxmox...
docker save videoai/transcription-worker:latest | ssh %DEPLOY_USER%@%PROXMOX_DOCKER_IP% docker load

cd ..\..\infrastructure\proxmox
echo [OK] Images built and transferred
echo.

echo Step 5: Deploying services on Proxmox...
ssh %DEPLOY_USER%@%PROXMOX_DOCKER_IP% "cd %REMOTE_DIR% && docker-compose down --remove-orphans"
ssh %DEPLOY_USER%@%PROXMOX_DOCKER_IP% "cd %REMOTE_DIR% && docker-compose up -d"
echo [OK] Services deployed
echo.

echo Step 6: Waiting for services to be healthy...
timeout /t 10 /nobreak >nul

echo   - Checking service status...
ssh %DEPLOY_USER%@%PROXMOX_DOCKER_IP% "cd %REMOTE_DIR% && docker-compose ps"

echo.
echo =====================================
echo Deployment completed successfully!
echo =====================================
echo.
echo Access your services at:
echo   Grafana:        http://%PROXMOX_DOCKER_IP%:3000
echo   Prometheus:     http://%PROXMOX_DOCKER_IP%:9090
echo   Keycloak:       http://%PROXMOX_DOCKER_IP%:8180
echo   MinIO Console:  http://%PROXMOX_DOCKER_IP%:9001
echo   Temporal UI:    http://%PROXMOX_DOCKER_IP%:8088
echo   API (Swagger):  http://%PROXMOX_DOCKER_IP%:8080/swagger-ui
echo.
echo Next steps:
echo   1. Configure Keycloak realm and clients
echo   2. Create MinIO buckets for video storage
echo   3. Configure Grafana dashboards
echo   4. Test the API endpoints
echo.
pause
