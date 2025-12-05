-- ============================================================
-- PROJECTS
-- Supports both manual creation and GitHub integration.
-- ============================================================

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
    github_repo_id BIGINT,                      -- GitHub unique repo ID
    github_full_name TEXT,                      -- e.g. "org/repo"
    github_visibility VARCHAR(50),              -- 'public' | 'private'
    github_default_branch TEXT,
    github_language JSONB DEFAULT '[]',
    stargazers_count INT DEFAULT 0,
    forks_count INT DEFAULT 0,
    is_fork BOOLEAN DEFAULT FALSE,
    github_last_sync TIMESTAMPTZ,
    last_sync_error TEXT,

    -- === Scan and Risk Data ===
    import_status VARCHAR(50) DEFAULT 'completed',  -- 'pending' | 'completed' | 'failed'
    scan_status VARCHAR(50) DEFAULT 'idle',         -- 'idle' | 'queued' | 'running' | 'completed' | 'failed'
    last_sbom_upload TIMESTAMPTZ,
    last_vuln_scan TIMESTAMPTZ,
    avg_risk_score NUMERIC(5,2) DEFAULT 0,
    total_vulnerabilities INT DEFAULT 0,

    -- === Timestamps ===
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_scanned BOOLEAN DEFAULT FALSE,

    -- === Constraints ===
    UNIQUE (organization_id, name)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_projects_owner ON projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_org ON projects(organization_id);
CREATE INDEX IF NOT EXISTS idx_projects_source_type ON projects(source_type);
CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_projects_last_vuln_scan ON projects(last_vuln_scan DESC);
CREATE INDEX IF NOT EXISTS idx_projects_avg_risk_score ON projects(avg_risk_score);
CREATE UNIQUE INDEX IF NOT EXISTS idx_projects_github_repo_id
  ON projects (github_repo_id)
  WHERE github_repo_id IS NOT NULL;

--Insert to projects
INSERT INTO projects (
    name,
    description,
    owner_id,
    organization_id,
    created_by,
    source_type,
    repo_url,
    github_repo_id,
    github_full_name,
    github_visibility,
    github_default_branch,
    github_language,
    stargazers_count,
    forks_count,
    is_fork,
    github_last_sync,
    last_sync_error,
    import_status,
    scan_status,
    last_sbom_upload,
    last_vuln_scan,
    avg_risk_score,
    total_vulnerabilities,
    created_at,
    updated_at
) VALUES

-- 1️⃣ Manual project example
(
    'manual-demo',
    'A manually created sample project for testing SBOM upload and vulnerability scanning.',
    1,                -- owner_id (Developer User)
    1,                -- organization_id (MyESI)
    1,                -- created_by
    'manual',
    NULL,             -- repo_url
    NULL,             -- github_repo_id
    NULL,             -- github_full_name
    NULL,             -- github_visibility
    NULL,             -- github_default_branch
    '["Python"]'::jsonb,
    0,                -- stargazers_count
    0,                -- forks_count
    FALSE,            -- is_fork
    NULL,             -- github_last_sync
    NULL,             -- last_sync_error
    'completed',      -- import_status
    'completed',      -- scan_status
    NOW() - INTERVAL '3 days',   -- last_sbom_upload
    NOW() - INTERVAL '2 days',   -- last_vuln_scan
    5.0,              -- avg_risk_score
    12,               -- total_vulnerabilities
    NOW() - INTERVAL '5 days',
    NOW()
),

-- 2️⃣ GitHub project example (MyESI backend)
(
    'backend',
    'Main backend service imported from GitHub for automated analysis and compliance.',
    1,                -- owner_id (Developer User)
    1,                -- organization_id (MyESI)
    1,                -- created_by
    'github',
    'https://github.com/myesi/backend',
    987654321,        -- mock GitHub repo ID
    'myesi/backend',  -- full repo name
    'private',
    'main',
    '["Python"]'::jsonb,
    42,               -- stargazers_count
    10,               -- forks_count
    FALSE,            -- is_fork
    NOW() - INTERVAL '5 days',
    NULL,             -- last_sync_error
    'completed',      -- import_status
    'completed',      -- scan_status
    NOW() - INTERVAL '4 days',
    NOW() - INTERVAL '3 days',
    7.2,
    28,
    NOW() - INTERVAL '6 days',
    NOW()
)
ON CONFLICT (organization_id, name) DO NOTHING;