# Pottery Catalog API Backend

FastAPI-based backend for managing pottery items with photos. Uses Google Cloud services (Firestore, Cloud Storage, Firebase Authentication).

## 🚀 Quick Start

Choose your path:

### I Want To...

**→ Develop Locally** (5 minutes)
Follow: [Local Development Guide](docs/getting-started/local-development.md)

**→ Deploy to Production** (30-45 minutes)
Follow: [Production Setup Guide](docs/how-to/setup-production.md)

**→ Understand the Architecture**
Read: [Architecture Overview](docs/explanation/architecture.md)

**→ Look Up a Script or Command**
See: [Scripts Reference](docs/reference/scripts.md)

---

## Architecture Overview

```
┌─────────────┐
│ Flutter App │  (Mobile/Web Client)
└──────┬──────┘
       │ Firebase Auth Token
       ▼
┌─────────────────────────────────────┐
│    Pottery API (FastAPI)            │
│    ▸ Cloud Run (Serverless)         │
│    ▸ Firebase Auth Verification     │
└──────┬─────────────────┬────────────┘
       │                 │
       ▼                 ▼
┌──────────────┐  ┌────────────────┐
│  Firestore   │  │ Cloud Storage  │
│  (Metadata)  │  │ (Photo Files)  │
└──────────────┘  └────────────────┘
```

**Key Features:**
- RESTful API with automatic OpenAPI documentation
- Firebase Authentication with JWT tokens
- Firestore for metadata storage
- Google Cloud Storage for photos with signed URLs
- Multi-environment support (dev/prod)
- Comprehensive testing with pytest
- Docker-based local development

---

## Documentation

### 📘 Getting Started

- **[Local Development](docs/getting-started/local-development.md)** - Set up your development environment
- **[Quick Deploy](docs/getting-started/quick-deploy.md)** - Deploy to dev environment quickly

### 📗 How-To Guides

- **[Production Setup](docs/how-to/setup-production.md)** - Complete production environment setup
- **[Deploy to Environments](docs/how-to/deploy-environments.md)** - Deploy to dev/prod
- **[Manage Service Accounts](docs/how-to/setup-service-accounts.md)** - Create and configure service accounts
- **[Troubleshooting](docs/how-to/troubleshoot-common-issues.md)** - Fix common problems

### 📕 Reference

- **[Environment Variables](docs/reference/environment-variables.md)** - All configuration options
- **[Scripts](docs/reference/scripts.md)** - Complete scripts documentation
- **[API Endpoints](docs/reference/api-endpoints.md)** - API reference

### 📙 Explanation

- **[Architecture](docs/explanation/architecture.md)** - System design and decisions
- **[Multi-Environment](docs/explanation/multi-environment.md)** - Environment separation strategy
- **[Authentication](docs/explanation/authentication.md)** - How authentication works

---

## Project Structure

```
backend/
├── routers/              # API route handlers
│   ├── items.py         # Pottery items endpoints
│   ├── photos.py        # Photo management
│   └── account.py       # Account management
├── services/            # Business logic
│   ├── firestore_service.py
│   └── gcs_service.py
├── tests/               # Test suite
│   ├── integration/    # Integration tests
│   └── images/        # Test fixtures
├── infrastructure/      # CORS and infrastructure config
├── docs/               # Documentation (this site)
├── main.py            # Application entry point
├── models.py          # Pydantic data models
├── auth.py           # Authentication logic
├── config.py         # Configuration
└── Dockerfile        # Container definition
```

---

## Key Technologies

- **Framework:** FastAPI 0.100+
- **Database:** Google Cloud Firestore
- **Storage:** Google Cloud Storage
- **Auth:** Firebase Authentication
- **Deployment:** Google Cloud Run
- **Testing:** pytest
- **Quality:** Black, flake8, mypy, pre-commit

---

## Common Commands

### Local Development
```bash
# Run locally with Docker
cd ../scripts/backend
./run_docker_local.sh

# Run tests
cd backend
pytest -m "not integration"
```

### Deployment
```bash
# Deploy to development
cd ../scripts/backend
./build_and_deploy.sh --env=dev

# Deploy to production
./build_and_deploy.sh --env=prod
```

### API Documentation
- **Swagger UI:** `http://localhost:8000/api/docs` (local)
- **ReDoc:** `http://localhost:8000/api/redoc` (local)

---

## Support

- **Issues:** Report bugs and request features in GitHub Issues
- **Documentation:** See [docs/](docs/) directory
- **Architecture Questions:** See [Architecture Overview](docs/explanation/architecture.md)

---

## Quick Links

**For Developers:**
- [Local Development Setup](docs/getting-started/local-development.md)
- [Running Tests](docs/getting-started/local-development.md#running-tests)
- [Code Quality](docs/getting-started/local-development.md#code-quality)

**For DevOps:**
- [Production Setup](docs/how-to/setup-production.md)
- [Service Account Setup](docs/how-to/setup-service-accounts.md)
- [Scripts Reference](docs/reference/scripts.md)

**For Architects:**
- [Architecture Overview](docs/explanation/architecture.md)
- [Multi-Environment Strategy](docs/explanation/multi-environment.md)
- [Authentication Flow](docs/explanation/authentication.md)

---

## Legacy Documentation

Previous documentation has been archived:
- [README-old.md](README-old.md) - Original comprehensive README
- [README-environments-old.md](README-environments-old.md) - Multi-environment guide

These are kept for reference but may contain outdated information. Please use the new documentation structure in [docs/](docs/).
