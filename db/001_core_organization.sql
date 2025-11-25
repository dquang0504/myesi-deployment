-- 001_core_organization.sql
-- ============================================================
-- 1. Subscription Plans
-- ============================================================
CREATE TABLE IF NOT EXISTS subscription_plans (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    stripe_price_id_monthly VARCHAR(255) NOT NULL,
    stripe_price_id_yearly VARCHAR(255) NOT NULL,
    stripe_product_id VARCHAR(255),
    sbom_limit INT DEFAULT 10,
    user_limit INT DEFAULT 5,
    project_scan_limit INT DEFAULT 10,
    scan_rate_limit INT DEFAULT 60,
    monthly_price_cents INT NOT NULL,
    annual_price_cents INT NOT NULL,
    currency VARCHAR(10) DEFAULT 'usd',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. Subscriptions
-- ============================================================
CREATE TABLE IF NOT EXISTS subscriptions (
    id BIGSERIAL PRIMARY KEY,
    user_id INT, -- FK added later
    plan_id INT REFERENCES subscription_plans(id),
    stripe_customer_id VARCHAR(255),
    stripe_subscription_id VARCHAR(255) UNIQUE,
    status VARCHAR(50) DEFAULT 'active',
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    trial_end TIMESTAMPTZ,
    quantity INT DEFAULT 1,
    interval VARCHAR(10) DEFAULT 'monthly',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 3. Organizations
-- ============================================================
CREATE TABLE IF NOT EXISTS organizations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    subscription_id BIGINT REFERENCES subscriptions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. Users
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    role VARCHAR(100) DEFAULT 'user',
    is_active BOOLEAN DEFAULT TRUE,
    organization_id INT REFERENCES organizations(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_login TIMESTAMPTZ,
    github_username VARCHAR(255),
    github_token VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS ix_users_email ON users(email);

-- ============================================================
-- 5. Add FK subscriptions.user_id → users.id
-- ============================================================
ALTER TABLE subscriptions
    ADD CONSTRAINT fk_subscriptions_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- ============================================================
-- 6. Organization Members
-- ============================================================
CREATE TABLE IF NOT EXISTS organization_members (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    organization_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, organization_id)
);

-- ============================================================
-- 7. User Integrations
-- ============================================================
CREATE TABLE IF NOT EXISTS user_integrations (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    access_token TEXT NOT NULL,
    refresh_token TEXT,
    expires_at TIMESTAMPTZ,
    scope TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, provider)
);

-- ============================================================
-- 8. Trigger: Enforce User Limit
-- ============================================================
CREATE OR REPLACE FUNCTION enforce_user_limit() RETURNS trigger AS $$
DECLARE
    plan_limit INT;
    current_count INT;
BEGIN
    SELECT sp.user_limit INTO plan_limit
    FROM organizations o
    JOIN subscriptions s ON s.id = o.subscription_id
    JOIN subscription_plans sp ON sp.id = s.plan_id
    WHERE o.id = NEW.organization_id;

    SELECT COUNT(*) INTO current_count
    FROM users WHERE organization_id = NEW.organization_id;

    IF current_count >= plan_limit THEN
        RAISE EXCEPTION 'User limit exceeded for organization %, max %', NEW.organization_id, plan_limit;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_limit
BEFORE INSERT ON users
FOR EACH ROW
WHEN (NEW.organization_id IS NOT NULL)
EXECUTE FUNCTION enforce_user_limit();