CREATE TABLE IF NOT EXISTS checkout_records (
    id BIGSERIAL PRIMARY KEY,
    actor_id INT REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR(255) NOT NULL UNIQUE,
    customer_email VARCHAR(255) NOT NULL,
    amount INTEGER NOT NULL,
    currency VARCHAR(10) DEFAULT 'usd',
    status VARCHAR(50) DEFAULT 'created', -- 'created', 'completed', 'failed', 'refunded'
    idempotency_key UUID NOT NULL,
    raw_session JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_checkout_records_email
    ON checkout_records (customer_email, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_checkout_records_status
    ON checkout_records (status);