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

INSERT INTO subscription_plans 
(name, description, stripe_price_id_monthly, stripe_price_id_yearly, stripe_product_id,
 sbom_limit, user_limit, project_scan_limit, scan_rate_limit, monthly_price_cents, annual_price_cents, currency)
VALUES
('Free Trial', 'For new users — limited to 2 SBOMs and 2 team members, expires after 14 days',
 'price_free_trial_monthly', 'price_free_trial_yearly', 'prod_free_trial', 2, 3, 2, 30, 0, 0, 'usd'),
('Basic', 'For small teams — up to 10 SBOMs',
 'price_1SPis3Fd0pLm7dcHtqE6n9ff', 'price_1SPizzFd0pLm7dcHJw1yxo1q', 'prod_TMRlmkBALD3Oar', 10, 5, 10, 60, 1999, 19990, 'usd'),
('Professional', 'For growing orgs — up to 50 SBOMs',
 'price_1SPiteFd0pLm7dcHhRefwIvg', 'price_1SPizVFd0pLm7dcHKXsY07dZ', 'prod_TMRnNdKBfdw5PA', 50, 20, 50, 120, 5999, 59990, 'usd'),
('Enterprise', 'Unlimited SBOMs, dedicated support',
 'price_1SPiyZFd0pLm7dcH3iOnxqYl', 'price_1SPiujFd0pLm7dcH76WqiWiP', 'prod_TMRolSbh2HRgTP', -1, 1000, -1, -1, 14999, 149990, 'usd')
ON CONFLICT (name) DO NOTHING;


-- ============================================================
-- 2. Subscriptions (không FK tới users để tránh vòng)
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
    require_two_factor BOOLEAN DEFAULT FALSE,
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
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_login TIMESTAMPTZ,
    github_username VARCHAR(255),
    github_token VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS ix_users_email ON users(email);

CREATE TABLE IF NOT EXISTS organization_settings (
    organization_id INT PRIMARY KEY REFERENCES organizations(id) ON DELETE CASCADE,
    admin_email VARCHAR(255),
    support_email VARCHAR(255),
    require_two_factor BOOLEAN DEFAULT FALSE,
    password_expiry BOOLEAN DEFAULT TRUE,
    session_timeout BOOLEAN DEFAULT TRUE,
    ip_whitelisting BOOLEAN DEFAULT FALSE,
    email_notifications BOOLEAN DEFAULT TRUE,
    vulnerability_alerts BOOLEAN DEFAULT TRUE,
    weekly_reports BOOLEAN DEFAULT TRUE,
    user_activity_alerts BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_two_factors (
    user_id INT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    secret VARCHAR(255) NOT NULL,
    is_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================================
-- 5. Add FK subscriptions.user_id → users.id (sau khi bảng đã tồn tại)
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
-- 8. Seed Data (ĐƠN GIẢN – KHÔNG dynamic ID)
-- ============================================================

INSERT INTO organizations (name)
VALUES ('MyESI'), ('Acme Inc.')
ON CONFLICT (name) DO NOTHING;

INSERT INTO users (
    name, email, hashed_password, role, is_active, organization_id, created_at, last_login
)
VALUES
('Developer User', 'dev@myesi.local.dev',
 '$2a$12$.Qo/RImHj2Ltgd.Ia5SWKuw91WluYoU5NVA.Gq1BZeu0z4FzYO6FS',
 'developer', TRUE, 1, NOW(), NOW()),
('Admin User', 'admin@myesi.local.dev',
 '$2a$12$.Qo/RImHj2Ltgd.Ia5SWKuw91WluYoU5NVA.Gq1BZeu0z4FzYO6FS',
 'admin', TRUE, 1, NOW(), NOW()),
('Owner User', 'owner@myesi.local.dev',
 '$2a$12$.Qo/RImHj2Ltgd.Ia5SWKuw91WluYoU5NVA.Gq1BZeu0z4FzYO6FS',
 'owner', TRUE, 1, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

INSERT INTO organization_members (user_id, organization_id, role)
SELECT id, 1, 'owner'
FROM users
WHERE email = 'owner@myesi.local.dev'
ON CONFLICT (user_id, organization_id) DO NOTHING;

INSERT INTO subscriptions (
    user_id, plan_id, stripe_customer_id, stripe_subscription_id, status,
    current_period_start, current_period_end, trial_end
)
VALUES
(2, 1, 'cus_mock_trial', 'sub_mock_trial', 'active',
 NOW(), NOW() + INTERVAL '14 days', NOW() + INTERVAL '14 days')
ON CONFLICT DO NOTHING;


UPDATE organizations SET subscription_id = 1 WHERE name = 'MyESI';

INSERT INTO organization_settings (organization_id, admin_email, support_email, require_two_factor)
SELECT id, 'admin@myesi.local.dev', 'support@myesi.com', TRUE
FROM organizations
WHERE name = 'MyESI'
ON CONFLICT (organization_id) DO NOTHING;


-- ============================================================
-- 9. Trigger: Enforce User Limit
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
