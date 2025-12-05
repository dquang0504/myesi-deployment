CREATE TABLE IF NOT EXISTS code_finding_control_mappings (
    id BIGSERIAL PRIMARY KEY,
    code_finding_id BIGINT NOT NULL REFERENCES code_findings(id) ON DELETE CASCADE,
    project_id INT REFERENCES projects(id) ON DELETE CASCADE,
    sbom_id UUID NULL,
    control_id VARCHAR(64) NOT NULL,
    control_title TEXT,
    category TEXT,
    source VARCHAR(64) DEFAULT 'auto',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cf_ctrl_project ON code_finding_control_mappings(project_id);
CREATE INDEX IF NOT EXISTS idx_cf_ctrl_control ON code_finding_control_mappings(control_id);
