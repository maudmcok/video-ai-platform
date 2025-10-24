"""
Worker de transcription audio utilisant Whisper
Expose une API FastAPI pour recevoir les jobs
"""

import logging
import os
from pathlib import Path
from typing import Dict, List, Optional
import whisper
import torch
from pydantic import BaseModel, Field
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
import boto3
import json
from datetime import datetime
import structlog

# Configuration logging structuré
structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.add_log_level,
        structlog.processors.JSONRenderer()
    ]
)
logger = structlog.get_logger()

app = FastAPI(
    title="Transcription Service",
    description="Service de transcription audio avec Whisper",
    version="1.0.0"
)

# Configuration
MODEL_SIZE = os.getenv("WHISPER_MODEL_SIZE", "base")  # base/small/medium/large-v3
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
S3_BUCKET = os.getenv("S3_BUCKET", "videoai-assets")
S3_ENDPOINT = os.getenv("S3_ENDPOINT", "http://localhost:9000")
TEMP_DIR = Path("/tmp/transcription")
TEMP_DIR.mkdir(exist_ok=True)

# Initialisation Whisper
logger.info("Loading Whisper model", model=MODEL_SIZE, device=DEVICE)
try:
    model = whisper.load_model(MODEL_SIZE, device=DEVICE)
    logger.info("Whisper model loaded successfully")
except Exception as e:
    logger.error("Failed to load Whisper model", error=str(e))
    raise

# Client S3
s3_client = boto3.client(
    's3',
    endpoint_url=S3_ENDPOINT,
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID", "minioadmin"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY", "minioadmin"),
    region_name=os.getenv("AWS_REGION", "us-east-1")
)

# Models
class Word(BaseModel):
    t0: float = Field(..., description="Start time in seconds")
    t1: float = Field(..., description="End time in seconds")
    word: str = Field(..., description="Transcribed word")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Confidence score")

class Segment(BaseModel):
    start: float = Field(..., description="Segment start time")
    end: float = Field(..., description="Segment end time")
    text: str = Field(..., description="Transcribed text")
    words: List[Word] = Field(default_factory=list)

class TranscriptionRequest(BaseModel):
    project_id: str = Field(..., description="Project ID")
    audio_url: str = Field(..., description="S3 URL of audio file")
    language: Optional[str] = Field("auto", description="Language code or 'auto'")

class TranscriptionResult(BaseModel):
    project_id: str
    language: str
    duration: float
    full_text: str
    segments: List[Segment]
    transcript_url: str

class JobStatus(BaseModel):
    job_id: str
    status: str
    message: Optional[str] = None
    result_url: Optional[str] = None

# Jobs storage (in-memory pour dev, utiliser Redis en prod)
jobs: Dict[str, dict] = {}

@app.post("/transcribe", response_model=Dict[str, str], tags=["Transcription"])
async def transcribe(request: TranscriptionRequest, background_tasks: BackgroundTasks):
    """
    Lance une tâche de transcription en arrière-plan.
    Retourne immédiatement un job_id pour polling.
    """
    logger.info("Received transcription request", project_id=request.project_id)

    # Validation entrée
    if not request.audio_url.startswith(("s3://", "http://", "https://")):
        raise HTTPException(status_code=400, detail="Invalid audio URL")

    job_id = f"{request.project_id}_{int(datetime.utcnow().timestamp() * 1000)}"
    jobs[job_id] = {
        "status": "PENDING",
        "created_at": datetime.utcnow().isoformat()
    }

    background_tasks.add_task(
        process_transcription,
        job_id,
        request
    )

    return {
        "job_id": job_id,
        "status": "PENDING",
        "status_url": f"/status/{job_id}"
    }

async def process_transcription(job_id: str, request: TranscriptionRequest):
    """
    Traitement asynchrone avec gestion d'erreur robuste.
    """
    try:
        jobs[job_id]["status"] = "PROCESSING"
        logger.info("Starting transcription", job_id=job_id, project_id=request.project_id)

        # 1. Téléchargement audio depuis S3
        local_audio = await download_from_s3(request.audio_url)

        # 2. Transcription Whisper
        logger.info("Running Whisper inference", job_id=job_id)

        result = model.transcribe(
            str(local_audio),
            language=None if request.language == "auto" else request.language,
            word_timestamps=True,
            verbose=False
        )

        # 3. Formatage résultat
        segments = []
        for seg in result["segments"]:
            words = [
                Word(
                    t0=w.get("start", 0.0),
                    t1=w.get("end", 0.0),
                    word=w.get("word", ""),
                    confidence=w.get("probability", 0.0)
                )
                for w in seg.get("words", [])
            ]

            segments.append(Segment(
                start=seg["start"],
                end=seg["end"],
                text=seg["text"].strip(),
                words=words
            ))

        transcript_data = TranscriptionResult(
            project_id=request.project_id,
            language=result["language"],
            duration=result.get("duration", 0.0),
            full_text=result["text"],
            segments=segments,
            transcript_url=""  # sera rempli après upload
        )

        # 4. Upload résultat vers S3
        transcript_url = await upload_to_s3(
            request.project_id,
            transcript_data.model_dump(),
            "transcript.json"
        )

        transcript_data.transcript_url = transcript_url

        # 5. Mise à jour statut
        jobs[job_id]["status"] = "COMPLETED"
        jobs[job_id]["result_url"] = transcript_url
        jobs[job_id]["completed_at"] = datetime.utcnow().isoformat()

        logger.info(
            "Transcription completed",
            job_id=job_id,
            project_id=request.project_id,
            language=result["language"],
            duration=result.get("duration")
        )

        # Nettoyage fichier local
        local_audio.unlink(missing_ok=True)

    except Exception as e:
        logger.error("Transcription failed", job_id=job_id, error=str(e), exc_info=True)
        jobs[job_id]["status"] = "FAILED"
        jobs[job_id]["error"] = str(e)
        jobs[job_id]["failed_at"] = datetime.utcnow().isoformat()

async def download_from_s3(url: str) -> Path:
    """Télécharge un fichier depuis S3 vers /tmp."""
    if url.startswith("s3://"):
        parts = url.replace("s3://", "").split("/", 1)
        bucket, key = parts[0], parts[1]
    elif url.startswith("http"):
        # Parse MinIO URL
        parts = url.split("/")
        bucket = parts[3]
        key = "/".join(parts[4:])
    else:
        raise ValueError(f"Unsupported URL: {url}")

    local_path = TEMP_DIR / Path(key).name

    logger.info("Downloading from S3", bucket=bucket, key=key)
    s3_client.download_file(bucket, key, str(local_path))

    return local_path

async def upload_to_s3(project_id: str, data: dict, filename: str) -> str:
    """Upload résultat JSON vers S3."""
    key = f"projects/{project_id}/transcripts/{filename}"

    logger.info("Uploading to S3", bucket=S3_BUCKET, key=key)

    s3_client.put_object(
        Bucket=S3_BUCKET,
        Key=key,
        Body=json.dumps(data, indent=2),
        ContentType="application/json"
    )

    return f"s3://{S3_BUCKET}/{key}"

@app.get("/status/{job_id}", response_model=JobStatus, tags=["Status"])
async def get_status(job_id: str):
    """Polling du statut du job."""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found")

    job_data = jobs[job_id]
    return JobStatus(
        job_id=job_id,
        status=job_data["status"],
        message=job_data.get("error"),
        result_url=job_data.get("result_url")
    )

@app.get("/health", tags=["Health"])
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "model": MODEL_SIZE,
        "device": DEVICE,
        "gpu_available": torch.cuda.is_available()
    }

@app.get("/", tags=["Info"])
async def root():
    """Service information"""
    return {
        "service": "Transcription Service",
        "version": "1.0.0",
        "model": MODEL_SIZE,
        "device": DEVICE
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8001,
        log_config=None  # Utilise notre configuration structlog
    )
