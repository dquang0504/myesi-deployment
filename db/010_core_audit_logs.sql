CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id INT, -- who did the action
    action VARCHAR(255) NOT NULL, -- e.g 'LOGIN', 'CREATE_REPORT', 'DELETE_SBOM'
    resource_type VARCHAR(100), -- e.g 'sbom', 'vulnerability', 'report'
    resource_id TEXT, -- e.g 'sbom_id', 'vuln_id', 'report_id'
    details JSONB, -- detailed data (optional)
    ip_address INET, -- source IP
    user_agent TEXT, -- browser/client info
    created_at TIMESTAMPTZ DEFAULT NOW()
);

--Index to optimize audit queries
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id
    ON audit_logs (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_logs_action
    ON audit_logs (action);

CREATE INDEX IF NOT EXISTS idx_audit_logs_resource
    ON audit_logs (resource_type, resource_id);

ALTER TABLE audit_logs
ADD CONSTRAINT fk_audit_logs_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE SET NULL;