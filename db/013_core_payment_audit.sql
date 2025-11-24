-- PCI-specific Audit Table
CREATE TABLE IF NOT EXISTS payment_audit (
    id BIGSERIAL PRIMARY KEY,
    actor_id INT REFERENCES users(id) ON DELETE SET NULL, -- user who initiated payment
    action VARCHAR(255) NOT NULL, -- e.g. 'CREATE_SESSION', 'REFUND', 'WEBHOOK_PROCESSED'
    session_id VARCHAR(255),
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_audit_actor
    ON payment_audit (actor_id, created_at DESC);