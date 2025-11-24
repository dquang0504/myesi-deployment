-- 030_seed_demo.sql
-- 🚫 Only for dev/demo environments, NOT for real production data

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
 'admin', TRUE, 1, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

INSERT INTO subscriptions (
    user_id, plan_id, stripe_customer_id, stripe_subscription_id, status,
    current_period_start, current_period_end, trial_end
)
VALUES
(2, 1, 'cus_mock_trial', 'sub_mock_trial', 'active',
 NOW(), NOW() + INTERVAL '14 days', NOW() + INTERVAL '14 days')
ON CONFLICT DO NOTHING;

UPDATE organizations SET subscription_id = 1 WHERE name = 'MyESI';

-- Demo projects
INSERT INTO projects (
    name,
    description,
    owner_id,
    organization_id,
    created_by,
    source_type,
    repo_url,
    github_repo_id,
    github_full_name,
    github_visibility,
    github_default_branch,
    github_language,
    stargazers_count,
    forks_count,
    is_fork,
    github_last_sync,
    last_sync_error,
    import_status,
    scan_status,
    last_sbom_upload,
    last_vuln_scan,
    avg_risk_score,
    total_vulnerabilities,
    created_at,
    updated_at
) VALUES
(
    'manual-demo',
    'A manually created sample project for testing SBOM upload and vulnerability scanning.',
    1,
    1,
    1,
    'manual',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    '["Python"]'::jsonb,
    0,
    0,
    FALSE,
    NULL,
    NULL,
    'completed',
    'completed',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '2 days',
    5.0,
    12,
    NOW() - INTERVAL '5 days',
    NOW()
),
(
    'backend',
    'Main backend service imported from GitHub for automated analysis and compliance.',
    1,
    1,
    1,
    'github',
    'https://github.com/myesi/backend',
    987654321,
    'myesi/backend',
    'private',
    'main',
    '["Python"]'::jsonb,
    42,
    10,
    FALSE,
    NOW() - INTERVAL '5 days',
    NULL,
    'completed',
    'completed',
    NOW() - INTERVAL '4 days',
    NOW() - INTERVAL '3 days',
    7.2,
    28,
    NOW() - INTERVAL '6 days',
    NOW()
)
ON CONFLICT (organization_id, name) DO NOTHING;