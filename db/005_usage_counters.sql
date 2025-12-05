CREATE TABLE IF NOT EXISTS usage_counters (
    id SERIAL PRIMARY KEY,
    organization_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    usage_key TEXT NOT NULL,        -- e.g. 'sbom_upload', 'project_scan'
    used INT DEFAULT 0,
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (organization_id, usage_key)
);

CREATE INDEX IF NOT EXISTS idx_usage_org_key ON usage_counters (organization_id, usage_key);

-- Helper function: compute midnight boundaries (server timezone)
-- Returns next midnight and last midnight relative to current_timestamp
CREATE OR REPLACE FUNCTION get_midnight_bounds()
RETURNS TABLE(period_start TIMESTAMPTZ, period_end TIMESTAMPTZ) AS $$
BEGIN
    -- midnight today
    period_start := date_trunc('day', now())::timestamptz;
    -- next midnight
    period_end := (date_trunc('day', now()) + interval '1 day')::timestamptz;
    RETURN;
END;
$$ LANGUAGE plpgsql STABLE;

-- Upsert helper to ensure a usage counter exists for org / key with today's window
CREATE OR REPLACE FUNCTION ensure_usage_counter(org INT, key TEXT)
RETURNS TABLE(id INT, organization_id INT, usage_key TEXT, used INT, period_start TIMESTAMPTZ, period_end TIMESTAMPTZ) AS $$
DECLARE
    ps TIMESTAMPTZ;
    pe TIMESTAMPTZ;
BEGIN
    SELECT period_start, period_end INTO ps, pe FROM get_midnight_bounds();

    LOOP
        -- try update: if row exists but period differs (old window), reset used and set new window
        UPDATE usage_counters
        SET used = CASE WHEN period_end <= now() THEN 0 ELSE used END,
            period_start = ps,
            period_end = pe,
            updated_at = now()
        WHERE organization_id = org AND usage_key = key
        RETURNING id, organization_id, usage_key, used, period_start, period_end INTO id, organization_id, usage_key, used, period_start, period_end;

        IF FOUND THEN
            RETURN NEXT;
            RETURN;
        END IF;

        -- insert if not exists (concurrent safe)
        BEGIN
            INSERT INTO usage_counters (organization_id, usage_key, used, period_start, period_end)
            VALUES (org, key, 0, ps, pe)
            RETURNING id, organization_id, usage_key, used, period_start, period_end INTO id, organization_id, usage_key, used, period_start, period_end;
            RETURN NEXT;
            RETURN;
        EXCEPTION WHEN unique_violation THEN
            -- race, loop and try again
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Optional: a function to reset all usage counters to zero and move window to today (for pg_cron)
CREATE OR REPLACE FUNCTION reset_all_usage_counters()
RETURNS void AS $$
DECLARE
    ps TIMESTAMPTZ;
    pe TIMESTAMPTZ;
BEGIN
    SELECT period_start, period_end INTO ps, pe FROM get_midnight_bounds();
    UPDATE usage_counters
    SET used = 0,
        period_start = ps,
        period_end = pe,
        updated_at = now();
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_and_consume_usage(
    p_org_id INT,
    p_usage_key TEXT,
    p_amount INT
)
RETURNS TABLE(
    allowed BOOLEAN,
    message TEXT,
    next_reset TIMESTAMPTZ
) AS $$
DECLARE
    v_plan_limit INT;
    v_used INT;
    v_ps TIMESTAMPTZ;
    v_pe TIMESTAMPTZ;
BEGIN
    IF p_amount <= 0 THEN
        p_amount := 1;
    END IF;

    -- Load plan limit
    SELECT 
        CASE
            WHEN p_usage_key = 'project_scan' THEN sp.project_scan_limit
            WHEN p_usage_key = 'sbom_upload'  THEN sp.sbom_limit
            ELSE 0
        END
    INTO v_plan_limit
    FROM organizations o
    JOIN subscriptions s ON s.id = o.subscription_id
    JOIN subscription_plans sp ON sp.id = s.plan_id
    WHERE o.id = p_org_id;

    -- Unlimited
    IF v_plan_limit < 0 THEN
        RETURN QUERY SELECT TRUE, '', NULL::timestamptz;
        RETURN;
    END IF;

    v_ps := date_trunc('day', now());
    v_pe := v_ps + interval '1 day';

    -- Ensure row exists
    INSERT INTO usage_counters (organization_id, usage_key, used, period_start, period_end)
    VALUES (p_org_id, p_usage_key, 0, v_ps, v_pe)
    ON CONFLICT (organization_id, usage_key) DO NOTHING;

    -- Lock row for update
    SELECT uc.used, uc.period_start, uc.period_end
    INTO v_used, v_ps, v_pe
    FROM usage_counters uc
    WHERE uc.organization_id = p_org_id
      AND uc.usage_key = p_usage_key
    FOR UPDATE;

    -- If missing row, recreate
    IF NOT FOUND THEN
        INSERT INTO usage_counters (organization_id, usage_key, used, period_start, period_end)
        VALUES (p_org_id, p_usage_key, 0, v_ps, v_pe)
        ON CONFLICT DO NOTHING;

        SELECT uc.used, uc.period_start, uc.period_end
        INTO v_used, v_ps, v_pe
        FROM usage_counters uc
        WHERE uc.organization_id = p_org_id
          AND uc.usage_key = p_usage_key
        FOR UPDATE;
    END IF;

    -- Reset if expired
    IF now() >= v_pe THEN
        v_used := 0;
        v_ps := date_trunc('day', now());
        v_pe := v_ps + interval '1 day';

        UPDATE usage_counters uc
        SET used = 0,
            period_start = v_ps,
            period_end = v_pe,
            updated_at = NOW()
        WHERE uc.organization_id = p_org_id
          AND uc.usage_key = p_usage_key;
    END IF;

    -- Check limit
    IF v_used >= v_plan_limit THEN
        IF v_used > v_plan_limit THEN
            RETURN QUERY SELECT FALSE,
                format('Your current usage (%s) exceeds the new plan limit (%s). No new operations allowed until %s. Contact admin to adjust.', v_used, v_plan_limit, v_pe::text),
                v_pe;
            RETURN;
        ELSE
            RETURN QUERY SELECT FALSE,
                'Limit reached. Next reset at ' || v_pe::TEXT,
                v_pe;
            RETURN;
        END IF;
    END IF;

    IF v_used + p_amount > v_plan_limit THEN
        RETURN QUERY SELECT FALSE,
            'Limit reached. Next reset at ' || v_pe::TEXT,
            v_pe;
        RETURN;
    END IF;

    -- Consume usage
    UPDATE usage_counters uc
    SET used = v_used + p_amount,
        updated_at = NOW()
    WHERE uc.organization_id = p_org_id
      AND uc.usage_key = p_usage_key;

    RETURN QUERY SELECT TRUE, '', v_pe;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION revert_usage(
    p_org_id INT, 
    p_usage_key TEXT, 
    p_amount INT
)
RETURNS VOID AS $$
BEGIN
    UPDATE usage_counters
    SET used = GREATEST(used - p_amount, 0),
        updated_at = now()
    WHERE organization_id = p_org_id 
      AND usage_key = p_usage_key;
END;
$$ LANGUAGE plpgsql;

-- Create admin_adjust_usage(org_id, usage_key, new_used) for manual fixes (eg after downgrade or customer support credits).

CREATE OR REPLACE FUNCTION admin_adjust_usage(p_org INT, p_key TEXT, p_new_used INT)
RETURNS VOID AS $$
BEGIN
  UPDATE usage_counters
  SET used = GREATEST(p_new_used, 0), updated_at = now()
  WHERE organization_id = p_org AND usage_key = p_key;
END;
$$ LANGUAGE plpgsql;
