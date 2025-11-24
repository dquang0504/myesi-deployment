CREATE TABLE IF NOT EXISTS compliance_reports (
    id BIGSERIAL PRIMARY KEY,
    sbom_id UUID,
    project_name VARCHAR(255),
    report_type VARCHAR(100) DEFAULT 'compliance', -- 'compliance' | 'vuln-summary' | 'custom'
    report_data JSONB, -- original data (summary JSON)
    report_url TEXT, -- URL to where the PDF is saved (S3 or local)
    generated_by INT, -- user id who generates the report
    status VARCHAR(50) DEFAULT 'completed', -- 'completed', 'failed', 'pending'
    created_at TIMESTAMPTZ  DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

--Indexes to optimize query by sboms and timestamps
CREATE INDEX IF NOT EXISTS idx_compliance_reports_sbom
    ON compliance_reports (sbom_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_compliance_reports_type
    ON compliance_reports (report_type);

--Basic constraints
ALTER TABLE compliance_reports
ADD CONSTRAINT fk_compliance_reports_sbom
    FOREIGN KEY (sbom_id) REFERENCES sboms (id)
    ON DELETE CASCADE;

ALTER TABLE compliance_reports
ADD CONSTRAINT fk_compliance_reports_user
    FOREIGN KEY (generated_by) REFERENCES users(id)
    ON DELETE SET NULL;