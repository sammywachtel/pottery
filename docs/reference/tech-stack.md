# Technology Stack Reference

Complete overview of all technologies, frameworks, and tools used in the Pottery Catalog Application.

## 🎯 Core Technologies

### Backend Stack

| Technology | Version | Purpose | Documentation |
|------------|---------|---------|---------------|
| **Python** | 3.11+ | Backend programming language | [Python.org](https://docs.python.org/3/) |
| **FastAPI** | Latest | Web framework for building APIs | [FastAPI Docs](https://fastapi.tiangolo.com/) |
| **Pydantic** | 2.x | Data validation and settings | [Pydantic Docs](https://docs.pydantic.dev/) |
| **Uvicorn** | Latest | ASGI server implementation | [Uvicorn Docs](https://www.uvicorn.org/) |

### Frontend Stack

| Technology | Version | Purpose | Documentation |
|------------|---------|---------|---------------|
| **Flutter** | 3.x | UI framework | [Flutter Docs](https://docs.flutter.dev/) |
| **Dart** | 3.x | Programming language | [Dart Docs](https://dart.dev/guides) |
| **Riverpod** | 2.x | State management | [Riverpod Docs](https://riverpod.dev/) |
| **Dio** | Latest | HTTP client | [Dio Pub](https://pub.dev/packages/dio) |

## ☁️ Google Cloud Platform

### Core Services

| Service | Purpose | Configuration |
|---------|---------|---------------|
| **Cloud Run** | Backend deployment | Serverless container platform |
| **Firestore** | NoSQL database | Document-based data storage |
| **Cloud Storage** | File storage | Photo and asset storage |
| **Firebase Auth** | Authentication | OAuth 2.0 + Google Sign-In |
| **Cloud Build** | CI/CD pipeline | Automated building and deployment |

### Supporting Services

| Service | Purpose | Usage |
|---------|---------|-------|
| **Cloud Monitoring** | Application monitoring | Performance and error tracking |
| **Cloud Logging** | Centralized logging | Application and system logs |
| **Identity & Access Management** | Security | Service accounts and permissions |
| **Cloud DNS** | Domain management | Production domain resolution |

## 🔧 Development Tools

### Local Development

| Tool | Purpose | Configuration |
|------|---------|---------------|
| **Docker** | Backend containerization | `backend/Dockerfile` |
| **Docker Compose** | Local orchestration | `backend/docker-compose.yml` |
| **Flutter SDK** | Frontend development | Local installation |
| **Firebase CLI** | Firebase management | Global npm package |
| **Google Cloud CLI** | GCP management | Local authentication |

### Code Quality

| Tool | Purpose | Configuration |
|------|---------|---------------|
| **pytest** | Python testing framework | `backend/pytest.ini` |
| **Black** | Python code formatting | `backend/pyproject.toml` |
| **isort** | Python import sorting | `backend/pyproject.toml` |
| **mypy** | Python static type checking | `backend/mypy.ini` |
| **dartfmt** | Dart code formatting | Built into Flutter |
| **dart analyze** | Dart static analysis | Built into Flutter |

## 🗃️ Data Technologies

### Database

| Technology | Type | Usage | Schema |
|------------|------|-------|--------|
| **Firestore** | NoSQL Document DB | Primary database | Collections: `pottery_items`, `users` |
| **Cloud Storage** | Object Storage | File storage | Buckets: `{project}-bucket` |

### Data Models

**Firestore Document Structure:**
```json
{
  "pottery_items/{item_id}": {
    "title": "string",
    "description": "string",
    "created_at": "timestamp",
    "updated_at": "timestamp",
    "user_id": "string",
    "photos": {
      "{photo_id}": {
        "filename": "string",
        "gcs_path": "string",
        "upload_date": "timestamp",
        "size_bytes": "number"
      }
    }
  }
}
```

## 🔐 Authentication & Security

### Authentication Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **OAuth Provider** | Google OAuth 2.0 | User authentication |
| **Identity Provider** | Firebase Authentication | Token management |
| **Backend Validation** | Firebase Admin SDK | ID token verification |
| **Session Management** | JWT tokens | Stateless authentication |

### Security Measures

| Feature | Implementation | Purpose |
|---------|----------------|---------|
| **CORS** | FastAPI CORS middleware | Cross-origin request security |
| **Input Validation** | Pydantic models | Data validation and sanitization |
| **File Upload Security** | Content-type validation | Prevent malicious uploads |
| **User Data Isolation** | User ID filtering | Data privacy and security |

## 📦 Package Management

### Backend Dependencies

**Core Dependencies** (`requirements.txt`):
```
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
pydantic>=2.0.0
firebase-admin>=6.2.0
google-cloud-firestore>=2.12.0
google-cloud-storage>=2.10.0
python-multipart>=0.0.6
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
```

**Development Dependencies** (`requirements-dev.txt`):
```
pytest>=7.4.0
pytest-asyncio>=0.21.0
pytest-cov>=4.1.0
black>=23.0.0
isort>=5.12.0
mypy>=1.5.0
httpx>=0.24.0
```

### Frontend Dependencies

**Core Dependencies** (`pubspec.yaml`):
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  google_sign_in: ^6.2.1
  riverpod: ^2.4.0
  flutter_riverpod: ^2.4.0
  dio: ^5.3.0
  image_picker: ^1.0.0
```

**Development Dependencies**:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

## 🚀 Deployment Technologies

### Production Infrastructure

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Container Runtime** | Cloud Run | Serverless container execution |
| **Container Registry** | Artifact Registry | Docker image storage |
| **Web Hosting** | Firebase Hosting | Static site hosting |
| **CDN** | Firebase CDN | Global content delivery |
| **Load Balancing** | Cloud Load Balancing | Traffic distribution |

### CI/CD Pipeline

| Stage | Technology | Purpose |
|-------|------------|---------|
| **Source Control** | Git + GitHub | Version control |
| **Build Automation** | Cloud Build | Automated builds |
| **Testing** | pytest + flutter test | Automated testing |
| **Deployment** | Cloud Build triggers | Automated deployment |
| **Monitoring** | Cloud Monitoring | Post-deployment verification |

## 🛠️ Development Environment

### Local Setup Requirements

**System Requirements:**
- macOS 10.15+ / Windows 10+ / Ubuntu 18.04+
- 8GB RAM minimum, 16GB recommended
- 10GB free disk space
- Internet connection for cloud services

**Required Software:**
```bash
# Core development tools
brew install docker
brew install --cask flutter
npm install -g firebase-tools
curl https://sdk.cloud.google.com | bash

# Optional but recommended
brew install git
brew install node
brew install python@3.11
```

### IDE Configuration

**VS Code Extensions:**
- Flutter
- Dart
- Python
- Docker
- Firebase
- GitLens
- Thunder Client (API testing)

**PyCharm/IntelliJ Plugins:**
- Python
- Docker
- Google Cloud Tools
- Database Navigator

## 📊 Monitoring & Analytics

### Application Monitoring

| Tool | Purpose | Metrics |
|------|---------|---------|
| **Cloud Monitoring** | Infrastructure monitoring | CPU, memory, latency |
| **Firebase Analytics** | User behavior tracking | Sessions, events, retention |
| **Firebase Performance** | Frontend performance | Load times, network requests |
| **Cloud Logging** | Centralized logging | Error logs, access logs |

### Key Performance Indicators

**Backend Metrics:**
- API response time (target: <200ms)
- Error rate (target: <1%)
- Container startup time (target: <10s)
- Memory usage (target: <80%)

**Frontend Metrics:**
- First contentful paint (target: <2s)
- Time to interactive (target: <3s)
- Authentication success rate (target: >99%)
- Photo upload success rate (target: >95%)

## 🔄 Version Management

### Versioning Strategy

| Component | Strategy | Format |
|-----------|----------|--------|
| **Backend API** | Semantic versioning | v1.2.3 |
| **Frontend App** | Build numbers + version | 1.0.0+1 |
| **Database Schema** | Migration-based | Sequential migrations |
| **Infrastructure** | Infrastructure as Code | Git-tracked configurations |

### Release Process

1. **Development**: Feature branches + pull requests
2. **Testing**: Automated test suite execution
3. **Staging**: Deploy to staging environment
4. **Production**: Automated deployment with rollback capability
5. **Monitoring**: Post-deployment health checks

---

*Last updated: September 2025*
