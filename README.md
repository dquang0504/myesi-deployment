# 🚀 **MyESI Deployment Repository**  
**Production-Ready Deployment for the MyESI SaaS Platform**

This repository contains everything required to deploy the **MyESI security analysis platform** into a production environment using **Docker Compose**.

MyESI is a distributed microservice architecture providing:

- SBOM analysis  
- Vulnerability scanning (OSV + Semgrep)  
- Risk scoring & AI remediation  
- Compliance reporting  
- User management & RBAC  
- Subscription & billing  
- Centralized API Gateway  
- Frontend UI

> ⚠️ This repository is **deployment-only**, containing no application code — all services run from published container images.

---

# 📁 **Repository Structure**

```text
myesi-deployment/
│
├── docker-compose.prod.yml        # Main production deployment file
├── .env                           # Actual secrets (DO NOT COMMIT)
├── .env.example                   # Template for environment variables
│
├── config/
│   └── nginx.conf                 # Reverse proxy + TLS template
│
├── db/
│   ├── 001_organization.sql
│   ├── 002_vulnerabilities.sql
│   ├── 003_projects.sql
│   ├── 004_sboms.sql
│   ├── 005_usage_counters.sql
│   ├── 006_risks.sql
│   ├── 007_compliance_reports.sql
│   ├── 008_audit_logs.sql
│   ├── 009_compliance_weights.sql
│   ├── 010_control_mapping.sql
│   ├── 011_checkout_records.sql
│   ├── 012_billing_events.sql
│   ├── 013_payment_audit.sql
│   └── 014_billing_service.schema.sql
│
└── DEPLOY.md                      # Detailed deployment documentation
```

---

# 🧱 **1. System Requirements**

## **Hardware**

| Component | Requirement |
|----------|-------------|
| CPU | 4–8 cores |
| RAM | 16–32 GB |
| Disk | 100 GB SSD |
| OS | Ubuntu 22.04 / Debian 12 / Amazon Linux |
| Network | Ports 80, 443 open |

## **Software**

- Docker 24+
- Docker Compose v2.20+
- Domain name (for HTTPS, optional)
- Optional: S3 bucket for backups

---

# 🔐 **2. Environment Configuration**

Copy the sample file:

```bash
cp .env.example .env
```

Edit `.env`:

```env
POSTGRES_USER=myesi
POSTGRES_PASSWORD=CHANGE_ME
POSTGRES_DB=myesi_db

USER_SERVICE_SECRET_KEY=CHANGE_ME
RISK_SERVICE_SECRET_KEY=CHANGE_ME

GITHUB_CLIENT_ID=CHANGE_ME
GITHUB_CLIENT_SECRET=CHANGE_ME
GITHUB_OAUTH_REDIRECT_URI=https://YOUR_DOMAIN/github/callback

GITHUB_TOKEN=CHANGE_ME
SEMGREP_APP_TOKEN=CHANGE_ME

HF_TOKEN=CHANGE_ME
OPENROUTER_API_KEY=CHANGE_ME
G4F_API_KEY=CHANGE_ME
```

> ⚠️ **Never commit `.env` to Git.**

---

# 🌐 **3. Nginx Reverse Proxy (Routing + HTTPS)**

Roles:

- Routes `/api/*` → API Gateway  
- Serves frontend  
- Terminates HTTPS  
- Applies security headers  

See configuration:

```text
config/nginx.conf
```

Contains:

- HTTP setup  
- HTTPS template (commented-out)  
- Ready for Let’s Encrypt TLS  

---

# 🐘 **4. Database Initialization (Automatic)**

PostgreSQL automatically loads all schema files in:

```text
/db/*.sql
```

This creates:

- Users & organizations  
- Projects & repositories  
- SBOM storage  
- Vulnerability tables  
- Risk scores  
- Billing  
- Compliance controls  
- Audit logs  

**No manual SQL execution required.**

---

# 🚀 **5. Deployment**

### **Pull service images**

```bash
docker compose -f docker-compose.prod.yml pull
```

### **Start the system**

```bash
docker compose -f docker-compose.prod.yml up -d
```

### **Verify containers**

```bash
docker ps
```

---

# ❤️‍🩹 **6. Health Checks**

### **API Health**

```bash
curl http://localhost/api/ping
```

### **Frontend**

Open:

```text
http://localhost
```

### **Logs**

```bash
docker logs -f api-gateway
```

---

# 🔄 **7. Updating Production (Rolling Update)**

```bash
docker compose pull
docker compose up -d
```

---

# 🔒 **8. Security Practices**

### ISO/IEC 27001
- Secrets in environment variables  
- TLS termination  
- Audit logging  
- Least-privilege containers  

### PCI-DSS
- Billing audit logs  
- HTTPS required  
- No sensitive data stored  

### OWASP
- Sanitized API Gateway  
- TLS-only mode  
- CORS protections  
- Rate limiting (extensible)  

---

# 💾 **9. Backup & Disaster Recovery**

Included:

- Daily PostgreSQL `pg_dump`  
- Automatic rotation (7 days)  
- Stored in persistent volume `/backup`

Optional:

- Switch to S3-based backup (template included)

---

# 📦 **10. Deployed Services**

### **Core**
- myesi-api-gateway  
- myesi-frontend  
- myesi-user-service  
- myesi-billing-service  
- myesi-sbom-service-golang  
- myesi-vuln-service-golang  
- myesi-risk-service  

### **Infrastructure**
- PostgreSQL  
- Redis  
- Kafka  
- Zookeeper  
- Elasticsearch  
- Kibana  

### **AI Engine**
- G4F Service (local inference)

Network:

```text
myesi-net
```

---

# 🧪 **11. Testing on a Clean VPS**

Run:

```bash
docker compose down -v
docker compose up -d
```

Verify:

- ✔ DB initialized  
- ✔ SBOM scans work  
- ✔ OSV queries succeed  
- ✔ Vulnerabilities processed  
- ✔ Risk scoring runs  
- ✔ Frontend loads  

---

# 📌 **12. Handover Notes (for Project Instructor)**

Steps to enable HTTPS:

1. Register a domain (example):

```text
app.myesi.com
```

2. Point DNS → VPS IP

3. Install Let’s Encrypt TLS:

```bash
sudo certbot --nginx -d app.myesi.com
```

4. Restart Docker/Nginx

---

# 📞 **13. Support**

| Contact | Info |
|---------|------|
| Email | support@myesi.security |
| Slack | #myesi-devops |
| Status Page | status.myesi.com *(placeholder)* |

---

# 🎉 Deployment Complete

Your MyESI production system is ready.
