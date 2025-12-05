-- ============================================================
-- SBOMS
-- Stores Software Bill of Materials for each project
-- ============================================================
CREATE TABLE IF NOT EXISTS sboms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id INT REFERENCES projects(id) ON DELETE CASCADE,
    project_name VARCHAR(255) NOT NULL,
    manifest_name TEXT,
    source VARCHAR(50) NOT NULL,                -- 'manual' | 'auto-code-scan'
    sbom JSONB NOT NULL,                        -- full CycloneDX/SPDX JSON
    summary JSONB,                              -- summarized analysis
    object_url VARCHAR(1024),                   -- storage location (S3, GCS, etc.)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sboms_project ON sboms(project_id);
CREATE INDEX IF NOT EXISTS idx_sboms_created ON sboms(created_at DESC);

-- ============================================================
-- SCAN_JOBS
-- Track scanning tasks (GitHub or manual projects)
-- ============================================================
CREATE TABLE IF NOT EXISTS scan_jobs (
    id BIGSERIAL PRIMARY KEY,
    project_id INT REFERENCES projects(id) ON DELETE CASCADE,
    sbom_id UUID REFERENCES sboms(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'queued',       -- queued | running | completed | failed
    scan_type VARCHAR(50) DEFAULT 'full',       -- 'full' | 'vuln-only' | 'compliance-only'
    triggered_by INT REFERENCES users(id) ON DELETE SET NULL,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    error_log TEXT,
    meta JSONB,                                -- e.g. commit info, branch name
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scan_jobs_project ON scan_jobs(project_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scan_jobs_status ON scan_jobs(status);
CREATE INDEX IF NOT EXISTS idx_scan_jobs_triggered_by ON scan_jobs(triggered_by);
