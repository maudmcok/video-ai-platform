-- Initial schema for Video AI Platform

-- Users table (extended from Keycloak)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    keycloak_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    quota_minutes INT DEFAULT 60,
    subscription_tier VARCHAR(50) DEFAULT 'FREE',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_keycloak_id ON users(keycloak_id);
CREATE INDEX idx_users_email ON users(email);

-- Projects table (aggregate root)
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('ANALYZE_VIDEO', 'TEXT2VIDEO', 'FUSION')),
    status VARCHAR(50) NOT NULL DEFAULT 'CREATED' CHECK (status IN ('CREATED', 'INGESTED', 'PROCESSING', 'RENDERING', 'READY', 'FAILED')),
    progress DECIMAL(5,2) DEFAULT 0.0 CHECK (progress >= 0 AND progress <= 100),
    config JSONB NOT NULL,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    completed_at TIMESTAMPTZ
);

CREATE INDEX idx_projects_owner_status ON projects(owner_id, status);
CREATE INDEX idx_projects_created_at ON projects(created_at DESC);
CREATE INDEX idx_projects_status ON projects(status);

-- Media table (input videos)
CREATE TABLE media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
    role VARCHAR(20) CHECK (role IN ('PRIMARY', 'SECONDARY')),
    source_url TEXT NOT NULL,
    storage_url TEXT,
    duration_sec DECIMAL(10,2),
    format VARCHAR(20),
    resolution VARCHAR(20),
    file_size_bytes BIGINT,
    waveform_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_media_project ON media(project_id);

-- Clips table (output for ANALYZE_VIDEO)
CREATE TABLE clips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
    start_sec DECIMAL(10,2) NOT NULL,
    end_sec DECIMAL(10,2) NOT NULL,
    topic VARCHAR(255),
    saliency_score DECIMAL(3,2),
    video_url TEXT,
    subtitles_url TEXT,
    thumbnail_url TEXT,
    style_preset VARCHAR(50),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_clips_project_score ON clips(project_id, saliency_score DESC);

-- Scenes table (for TEXT2VIDEO)
CREATE TABLE scenes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
    order_index INT NOT NULL,
    script_text TEXT NOT NULL,
    duration_sec DECIMAL(6,2),
    tts_url TEXT,
    generated_video_url TEXT,
    visual_prompt TEXT,
    status VARCHAR(50) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED')),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_scenes_project_order ON scenes(project_id, order_index);

-- Transcripts table (ASR output)
CREATE TABLE transcripts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    media_id UUID REFERENCES media(id) ON DELETE CASCADE NOT NULL,
    language VARCHAR(10),
    full_text TEXT,
    words JSONB,
    segments JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_transcripts_media ON transcripts(media_id);

-- Outputs table (final renders)
CREATE TABLE outputs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
    type VARCHAR(50) CHECK (type IN ('CLIP', 'FULL_RENDER', 'SCENE')),
    url TEXT NOT NULL,
    format VARCHAR(20),
    resolution VARCHAR(20),
    duration_sec DECIMAL(10,2),
    file_size_bytes BIGINT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_outputs_project ON outputs(project_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for projects table
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for users table
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE projects IS 'Main projects table (aggregate root)';
COMMENT ON TABLE media IS 'Input media files';
COMMENT ON TABLE clips IS 'Generated clips from video analysis';
COMMENT ON TABLE scenes IS 'Generated scenes for text-to-video';
COMMENT ON TABLE transcripts IS 'ASR transcription results';
COMMENT ON TABLE outputs IS 'Final rendered outputs';
