-- 002_core_projects.sql
CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,

    -- === Identification ===
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- === Ownership & Organization ===
    owner_id INT REFERENCES users(id) ON DELETE SET NULL,
    organization_id INT REFERENCES organizations(id) ON DELETE SET NULL,
    created_by INT REFERENCES users(id) ON DELETE SET NULL,

    -- === Source Tracking ===
    source_type VARCHAR(50) DEFAULT 'manual',   -- 'manual' | 'github' | 'api'
    repo_url TEXT,
    github_repo_id BIGINT,
    github_full_name TEXT,
    github_visibility VARCHAR(50),
    github_default_branch TEXT,
    github_language JSONB DEFAULT '[]',
    stargazers_count INT DEFAULT 0,
    forks_count INT DEFAULT 0,
    is_fork BOOLEAN DEFAULT FALSE,
    github_last_sync TIMESTAMPTZ,
    last_sync_error TEXT,

    -- === Scan and Risk Data ===
    import_status VARCHAR(50) DEFAULT 'completed',
    scan_status VARCHAR(50) DEFAULT 'idle',
    last_sbom_upload TIMESTAMPTZ,
    last_vuln_scan TIMESTAMPTZ,
    avg_risk_score NUMERIC(5,2) DEFAULT 0,
    total_vulnerabilities INT DEFAULT 0,

    -- === Timestamps ===
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_scanned BOOLEAN DEFAULT FALSE,

    UNIQUE (organization_id, name)
);

CREATE INDEX IF NOT EXISTS idx_projects_owner ON projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_org ON projects(organization_id);
CREATE INDEX IF NOT EXISTS idx_projects_source_type ON projects(source_type);
CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_projects_last_vuln_scan ON projects(last_vuln_scan DESC);
CREATE INDEX IF NOT EXISTS idx_projects_avg_risk_score ON projects(avg_risk_score);

CREATE UNIQUE INDEX IF NOT EXISTS idx_projects_github_repo_id
  ON projects (github_repo_id)
  WHERE github_repo_id IS NOT NULL;