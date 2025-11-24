CREATE TABLE IF NOT EXISTS compliance_weights (
    id BIGSERIAL PRIMARY KEY,
    standard VARCHAR(128) NOT NULL,          -- e.g. 'ISO_27001:2022', 'NIST_SP_800_53'
    scope_key TEXT NOT NULL,                 -- control_id e.g. 'A.5.1'
    title TEXT,                              -- optional short name
    category TEXT,                           -- e.g. 'Organizational', 'People', 'Physical', 'Technological'
    weight NUMERIC(8,6) NOT NULL,            -- fractional weight (sum per standard = 1.0)
    applicable BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_compliance_weights_std
  ON compliance_weights(standard, scope_key);

-- === ISO/IEC 27001:2022 ===
INSERT INTO compliance_weights (standard, scope_key, title, category, weight) VALUES
('ISO_27001:2022','A.5.1','Policies for information security','Organizational',0.010),
('ISO_27001:2022','A.5.7','Threat intelligence','Organizational',0.010),
('ISO_27001:2022','A.5.10','Acceptable use of information','Organizational',0.010),
('ISO_27001:2022','A.6.1','Screening','People',0.010),
('ISO_27001:2022','A.6.3','Termination or change of employment','People',0.010),
('ISO_27001:2022','A.7.1','Physical security perimeters','Physical',0.010),
('ISO_27001:2022','A.7.3','Secure disposal or reuse of equipment','Physical',0.010),
('ISO_27001:2022','A.8.1','User endpoint devices','Technological',0.010),
('ISO_27001:2022','A.8.7','Protection against malware','Technological',0.020),
('ISO_27001:2022','A.8.9','Configuration management','Technological',0.020),
('ISO_27001:2022','A.8.10','Information deletion','Technological',0.010),
('ISO_27001:2022','A.8.11','Data masking','Technological',0.010),
('ISO_27001:2022','A.8.18','Use of cryptography','Technological',0.020),
('ISO_27001:2022','A.8.20','Network security','Technological',0.020),
('ISO_27001:2022','A.8.21','Security of network services','Technological',0.015),
('ISO_27001:2022','A.8.23','Information transfer','Technological',0.010),
('ISO_27001:2022','A.8.24','Access control','Technological',0.025),
('ISO_27001:2022','A.8.25','Identity management','Technological',0.025),
('ISO_27001:2022','A.8.26','Authentication information','Technological',0.025),
('ISO_27001:2022','A.8.28','Secure coding','Technological',0.020);

-- === NIST SP 800-53 Core Families ===
INSERT INTO compliance_weights (standard, scope_key, title, category, weight) VALUES
('NIST_SP_800_53','AC','Access Control','Technological',0.10),
('NIST_SP_800_53','AU','Audit and Accountability','Technological',0.10),
('NIST_SP_800_53','CM','Configuration Management','Technological',0.10),
('NIST_SP_800_53','CP','Contingency Planning','Organizational',0.10),
('NIST_SP_800_53','IA','Identification and Authentication','Technological',0.10),
('NIST_SP_800_53','IR','Incident Response','Organizational',0.10),
('NIST_SP_800_53','MA','Maintenance','Operational',0.10),
('NIST_SP_800_53','PE','Physical and Environmental Protection','Physical',0.10),
('NIST_SP_800_53','PL','Planning','Organizational',0.10),
('NIST_SP_800_53','RA','Risk Assessment','Organizational',0.10);

-- === OWASP Top 10 (2021) ===
INSERT INTO compliance_weights (standard, scope_key, title, category, weight) VALUES
('OWASP','A01','Broken Access Control','Application',0.10),
('OWASP','A02','Cryptographic Failures','Application',0.10),
('OWASP','A03','Injection','Application',0.10),
('OWASP','A04','Insecure Design','Application',0.10),
('OWASP','A05','Security Misconfiguration','Application',0.10),
('OWASP','A06','Vulnerable and Outdated Components','Application',0.10),
('OWASP','A07','Identification and Authentication Failures','Application',0.10),
('OWASP','A08','Software and Data Integrity Failures','Application',0.10),
('OWASP','A09','Security Logging and Monitoring Failures','Application',0.10),
('OWASP','A10','Server-Side Request Forgery','Application',0.10);

