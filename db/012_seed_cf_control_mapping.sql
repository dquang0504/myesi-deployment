-- Seed control mapping for existing code_findings based on category/rule keywords.
INSERT INTO code_finding_control_mappings (code_finding_id, project_id, sbom_id, control_id, control_title, category, source)
SELECT
    cf.id,
    cf.project_id,
    NULL::uuid,
    CASE
        WHEN LOWER(COALESCE(cf.category,'')) LIKE '%secret%' OR LOWER(COALESCE(cf.rule_title,'')) LIKE '%secret%' THEN 'CF_SECRETS'
        WHEN LOWER(COALESCE(cf.category,'')) LIKE '%docker%' OR LOWER(COALESCE(cf.category,'')) LIKE '%k8s%' OR LOWER(COALESCE(cf.rule_title,'')) LIKE '%docker%' THEN 'CF_DEPLOYMENT'
        WHEN LOWER(COALESCE(cf.category,'')) LIKE '%injection%' OR LOWER(COALESCE(cf.rule_title,'')) LIKE '%injection%' THEN 'CF_INJECTION'
        ELSE 'CF_CODE_SECURITY'
    END AS control_id,
    COALESCE(cf.category,'Code Security') AS control_title,
    COALESCE(cf.category,'Code Security') AS category,
    'auto'
FROM code_findings cf
ON CONFLICT DO NOTHING;
