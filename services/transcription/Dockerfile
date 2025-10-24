FROM python:3.11-slim

# Install FFmpeg (requis par Whisper)
RUN apt-get update && apt-get install -y \
    ffmpeg \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copier les dépendances
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pré-télécharger le modèle Whisper
ARG WHISPER_MODEL_SIZE=base
RUN python -c "import whisper; whisper.load_model('${WHISPER_MODEL_SIZE}')"

# Copier le code
COPY worker.py .

# Créer le répertoire temporaire
RUN mkdir -p /tmp/transcription

EXPOSE 8001

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8001/health')"

CMD ["python", "worker.py"]
