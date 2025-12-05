CREATE TABLE risk_scores (
    id BIGSERIAL PRIMARY KEY,
    sbom_id UUID REFERENCES sboms(id),
    component_name TEXT NOT NULL,
    component_version TEXT NOT NULL,
    score INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- index to look records based on sbom_id faster
CREATE INDEX idx_risk_scores_sbom_id ON risk_scores(sbom_id);