-- 020_seed_system.sql
-- Subscription plans
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