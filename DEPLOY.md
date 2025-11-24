DEPLOY.md — MyESI Deployment Guide (Production Release)

Version: 1.0
Release Target: 25 Nov
Prepared by: MyESI Engineering Team

🚀 1. Overview

MyESI is a web-based SaaS platform built on top of a distributed microservice architecture.
This document explains how to deploy the production version of MyESI using Docker Compose, including:

Infrastructure components

Service configuration

Environment variables

HTTPS reverse proxy

Database initialization

Backups

Upgrade procedures

This guide is intended for:
DevOps engineers, Release managers, Infrastructure admins, On-premise deployment teams.

🏗️ 2. Architecture Summary
Component	Description
Frontend (React + Vite)	UI served via Nginx
API Gateway (FastAPI)	Authentication, routing, RBAC, audit logging
User Service	Accounts, RBAC
Billing Service	Subscription, Stripe integration, quotas
SBOM Service (Go)	SBOM scanning, repo handling
Vuln Service (Go)	OSV queries, CVE mapping, code scanning
Risk Service (FastAPI)	LLM remediation + risk scores
Redis	Cache & distributed locks
PostgreSQL	Main database
Kafka + Zookeeper	Async event backbone
Elasticsearch + Kibana	Audit logs, analytics
G4F AI Service	Local LLM inference
Nginx Reverse Proxy	TLS termination, frontend hosting, traffic routing
🛠️ 3. Deployment Model

MyESI uses a multi-repo development model, but production deployment uses a single deployment repo:

myesi-deployment/
 ├── docker-compose.prod.yml
 ├── .env                # Production secrets
 ├── .env.example        # Template (NO SECRETS)
 ├── config/
 │     └── nginx.conf
 ├── db/
 │     └── *.sql         # All schema creation files
 └── DEPLOY.md


Deployment is performed using Docker images already built by CI/CD, not source code.

📦 4. System Requirements (Minimum)
Component	Requirement
OS	Ubuntu 22.04 / Debian 12 / Amazon Linux
CPU	4–8 vCPUs
RAM	16–32 GB
Disk	100GB SSD
Network	Ports 80, 443
Docker	v24+
Docker Compose	v2.20+
📥 5. Install Docker & Compose
curl -fsSL https://get.docker.com | bash
sudo apt install docker-compose-plugin -y

📂 6. Get Deployment Repository
git clone https://github.com/your-org/myesi-deployment
cd myesi-deployment


The repository contains everything needed to deploy MyESI.

🔧 7. Configure Environment Variables

Duplicate the template:

cp .env.example .env


Fill in values for PostgreSQL, tokens, secret keys, API keys.

This protects against leaking secrets inside images and satisfies ISO 27001 controls (A.5.10, A.8.24).

🌐 8. Nginx Reverse Proxy (TLS & Routing)

Nginx handles:

Frontend delivery

API proxy

TLS termination (future production domain)

Secure headers

File: config/nginx.conf

HTTP reverse proxy is enabled by default.
TLS version is provided as a template for production.

🏗️ 9. Build & Push Docker Images (CI/CD)

Each microservice has its own CI workflow:

docker build

test

docker push → Registry

Recommended tagging:

ghcr.io/myesi/user-service:1.0.0
ghcr.io/myesi/vuln-service:1.0.0
ghcr.io/myesi/frontend:1.0.0


This ensures reproducible deployments.

🚀 10. Start the Production System
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d


All services (DB, Kafka, Redis, SBOM, Vuln, Gateway, Frontend) will start.

❤️‍🩹 11. Health Checks

Check container status:

docker ps
docker logs -f api-gateway


API health:

curl http://localhost/api/ping


Frontend:

http://localhost

🔄 12. Updating / Rolling Deployment
docker compose pull
docker compose up -d


Supports zero-downtime when scaling replicas (future option).

🔐 13. Security & Compliance

Deployment follows ISO 27001, OWASP, and PCI controls:

✔ Secrets in .env, not code
✔ Rootless containers (Go services)
✔ Kafka + DB isolated in internal network
✔ TLS available for production domain
✔ Audit logs → Elasticsearch
✔ Developer actions recorded
✔ SBOM generated on every scan
✔ No outbound traffic except OSV & GitHub

💾 14. Backup Strategy
Component	Backup method
PostgreSQL	Daily pg_dump (retention 7 days)
Elasticsearch	Volume snapshot
.env	Encrypted backup
Kafka	Back up log directories as needed

Automated backup container included in docker-compose.prod.yml.

🧪 15. Troubleshooting

API Gateway cannot contact backend services
→ Verify docker network: docker network inspect myesi-net

Frontend is blank
→ Ensure /dist was copied into image
→ Check Nginx config paths

Kafka fails to start
→ Ensure Zookeeper is running
→ Check port 2181 conflicts

📋 16. Final Release Checklist
Item	Status
CI/CD builds all services	✔️
Images pushed to registry	✔️
Deployment repo ready	✔️
docker-compose.prod.yml	✔️
Nginx config done	✔️
.env.example prepared	✔️
DEPLOY.md ready	✔️
Test deploy on a clean VPS	⬜ (remaining)
👉 17. Next Steps (for Instructor Handover)

To hand over deployment:

Push all production Dockerfiles

Finalize deployment repo

Provide .env.example

Deploy once on a clean VPS to validate

Instructor only needs to:

Provide domain

Enable HTTPS

Run Docker