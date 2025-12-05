CREATE TABLE IF NOT EXISTS control_mappings (
    id BIGSERIAL PRIMARY KEY,
    sbom_id UUID NOT NULL,
    component_name TEXT NOT NULL,
    component_version TEXT NOT NULL,
    control_id VARCHAR(64) NOT NULL,        -- e.g. 'A.8.24'
    control_title TEXT,                     -- 'Authentication information'
    category TEXT,                          -- 'Technological', 'Organizational' etc.
    source VARCHAR(128) DEFAULT 'auto',     -- 'auto' or 'manual'
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_control_mappings_component 
    ON control_mappings(component_name, component_version);

CREATE INDEX IF NOT EXISTS idx_control_mappings_control
    ON control_mappings(control_id);
