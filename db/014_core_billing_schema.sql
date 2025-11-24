-- ================================================
-- Billing Service Core Schema Extension for MyESI
-- ================================================

-- === Invoices Table ===
CREATE TABLE IF NOT EXISTS invoices (
    id BIGSERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE SET NULL,
    stripe_invoice_id VARCHAR(255) UNIQUE NOT NULL,
    subscription_id BIGINT REFERENCES subscriptions(id) ON DELETE CASCADE,
    amount_due_cents INT NOT NULL,
    amount_paid_cents INT DEFAULT 0,
    currency VARCHAR(10) DEFAULT 'usd',
    invoice_pdf_url TEXT,
    status VARCHAR(50) DEFAULT 'draft',            -- draft, paid, open, void, uncollectible
    hosted_invoice_url TEXT,
    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_invoices_user
    ON invoices (user_id, created_at DESC);

-- === Payment Methods Table ===
CREATE TABLE IF NOT EXISTS payment_methods (
    id BIGSERIAL PRIMARY KEY,
    stripe_customer_id VARCHAR(255) NOT NULL,
    stripe_payment_method_id VARCHAR(255) UNIQUE NOT NULL,
    brand VARCHAR(50),                             -- e.g. 'visa', 'mastercard'
    last4 VARCHAR(4),
    exp_month INT,
    exp_year INT,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE scheduled_downgrades (
    id SERIAL PRIMARY KEY,
    subscription_id BIGINT REFERENCES subscriptions(id) ON DELETE CASCADE,
    organization_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    target_price_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);