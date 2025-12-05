-- ============================================================
-- Notification Service schema
-- ============================================================

CREATE TABLE IF NOT EXISTS notification_templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    channel VARCHAR(50) NOT NULL,
    subject TEXT NOT NULL,
    body TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_notification_templates_event_channel
    ON notification_templates (event_type, channel);

CREATE TABLE IF NOT EXISTS notification_preferences (
    id SERIAL PRIMARY KEY,
    organization_id INT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id INT REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(255) NOT NULL,
    channel VARCHAR(50) NOT NULL,
    target TEXT,
    enabled BOOLEAN DEFAULT TRUE,
    severity_min VARCHAR(20) DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Unique across org + event + channel while treating NULL user_id as shared scope.
CREATE UNIQUE INDEX IF NOT EXISTS ux_notification_preferences_scope
    ON notification_preferences (organization_id, event_type, channel, COALESCE(user_id, 0));

CREATE TABLE IF NOT EXISTS notification_logs (
    id BIGSERIAL PRIMARY KEY,
    organization_id INT NOT NULL,
    user_id INT REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(255) NOT NULL,
    channel VARCHAR(50) NOT NULL,
    target TEXT,
    status VARCHAR(50) NOT NULL,
    error TEXT,
    payload JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notification_logs_org_event ON notification_logs (organization_id, event_type);
CREATE INDEX IF NOT EXISTS idx_notification_logs_channel_status ON notification_logs (channel, status);
