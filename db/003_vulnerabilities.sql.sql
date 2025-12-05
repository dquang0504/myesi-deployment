CREATE TABLE IF NOT EXISTS vulnerabilities (
    id BIGSERIAL PRIMARY KEY,
    sbom_id UUID NOT NULL,
    project_id INT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    project_name TEXT,
    component_name TEXT NOT NULL,
    component_version TEXT NOT NULL,
    fix_available BOOLEAN DEFAULT FALSE,
    fixed_version TEXT,
    vuln_id TEXT, -- optional, may be NULL if 1 vuln per component
    severity TEXT,
    osv_metadata JSONB,
    cvss_vector VARCHAR(255),
    sbom_component_count INT DEFAULT 0,
    sbom_hash TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (sbom_id, component_name, component_version)
);

CREATE INDEX IF NOT EXISTS idx_vuln_sbom_component
ON vulnerabilities(sbom_id, component_name, component_version);

CREATE INDEX IF NOT EXISTS idx_vuln_sbom ON vulnerabilities(sbom_id);
CREATE INDEX IF NOT EXISTS idx_vuln_project ON vulnerabilities(project_id);

CREATE TABLE IF NOT EXISTS vulnerability_assignments (
    id BIGSERIAL PRIMARY KEY,
    vulnerability_id BIGINT NOT NULL REFERENCES vulnerabilities(id) ON DELETE CASCADE,
    assignee_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_by INT NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'open',
    -- open | in_progress | resolved | wont_fix | accepted_risk
    priority VARCHAR(16) DEFAULT 'medium',
    -- low | medium | high | critical
    note TEXT,
    due_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_vuln_assign_vuln
    ON vulnerability_assignments(vulnerability_id);

CREATE INDEX IF NOT EXISTS idx_vuln_assign_assignee
    ON vulnerability_assignments(assignee_id);

CREATE INDEX IF NOT EXISTS idx_vuln_assign_status
    ON vulnerability_assignments(status);

CREATE TABLE code_findings (
    id SERIAL PRIMARY KEY,
    project_id INT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    project_name TEXT NOT NULL,
    rule_id TEXT,
    rule_title TEXT,
    severity TEXT,
    confidence TEXT,
    category TEXT,
    message TEXT,
    file_path TEXT,
    start_line INTEGER,
    end_line INTEGER,
    code_snippet TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    recommendation TEXT,
    reference_links JSONB,
    ai_remediation JSONB, -- g4f output (markdown)
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_code_findings_project ON code_findings(project_name);
CREATE INDEX IF NOT EXISTS idx_cf_project ON code_findings(project_id);

CREATE TABLE IF NOT EXISTS code_finding_assignments (
    id BIGSERIAL PRIMARY KEY,
    code_finding_id BIGINT NOT NULL REFERENCES code_findings(id) ON DELETE CASCADE,
    assignee_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_by INT NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'open',
    -- open | in_progress | resolved | wont_fix | accepted_risk
    priority VARCHAR(16) DEFAULT 'medium',
    -- low | medium | high | critical
    note TEXT,
    due_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_cf_assign_finding
    ON code_finding_assignments(code_finding_id);

CREATE INDEX IF NOT EXISTS idx_cf_assign_assignee
    ON code_finding_assignments(assignee_id);

CREATE INDEX IF NOT EXISTS idx_cf_assign_status
    ON code_finding_assignments(status);
