# Pottery Catalog Application

A full-stack pottery catalog application with photo management, built with Flutter and FastAPI on Google Cloud Platform.

## 🎯 Overview

The Pottery App allows users to create, manage, and browse pottery items with photo uploads. It features secure authentication, cloud storage, and a responsive web interface.

### ✨ Key Features

- **🔐 Secure Authentication**: Google OAuth via Firebase Authentication
- **📱 Responsive Design**: Flutter web application with mobile-first design
- **📸 Photo Management**: Upload, store, and display pottery photos
- **☁️ Cloud-Native**: Built on Google Cloud Platform with Firestore and Cloud Storage
- **🚀 Serverless Backend**: FastAPI on Cloud Run with automatic scaling
- **📊 Real-time Data**: Live updates with Firestore integration

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter Web   │────│   FastAPI       │────│  Google Cloud   │
│   Frontend      │    │   Backend       │    │   Platform      │
│                 │    │                 │    │                 │
│ • Authentication│    │ • REST API      │    │ • Firestore     │
│ • Photo Gallery │    │ • JWT Validation│    │ • Cloud Storage │
│ • Item CRUD     │    │ • Photo Upload  │    │ • Firebase Auth │
│ • Responsive UI │    │ • Business Logic│    │ • Cloud Run     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Docker** (for backend)
- **Flutter SDK** (latest stable)
- **Google Cloud CLI** (`gcloud`)
- **Firebase CLI** (`npm install -g firebase-tools`)

### Local Development

```bash
# 1. Clone the repository
git clone <repository-url>
cd pottery-backend

# 2. Start the backend
cd backend
./run_docker_local.sh

# 3. Start the frontend (new terminal)
cd frontend
./scripts/run_web_local.sh
```

**Access the application:**
- 🌐 **Frontend**: http://localhost:9102
- 🔧 **Backend API**: http://localhost:8000
- 📚 **API Docs**: http://localhost:8000/api/docs

**Note:** Port 9102 is used for the frontend to ensure Google Sign-In works properly. This port is pre-authorized in Firebase OAuth configuration.

### Mobile App Development

For Android/iOS development:

```bash
# Run on Android device
cd frontend
./scripts/build_dev.sh

# Monitor app logs (separate terminal)
adb logcat | grep -E "(pottery|google|auth)"
```

**Common Issues:**
- **Google Sign-In Error 10**: Add debug SHA-1 to Firebase ([Guide](./frontend/DEBUGGING.md#google-sign-in-debugging))
- **Build timeouts**: First Android build takes 10-20 minutes
- **No logs showing**: Use `adb logcat` instead of `flutter logs` for Android errors

📖 **Full debugging guide**: [frontend/DEBUGGING.md](./frontend/DEBUGGING.md)

## 📚 Documentation

Comprehensive documentation is available in the [`docs/`](./docs/) directory:

### 🚀 Getting Started
- [📖 Quick Start Guide](./docs/getting-started/quick-start.md) - Get running in 5 minutes
- [⚙️ Installation Guide](./docs/getting-started/installation.md) - Detailed setup instructions
- [🏗️ Environment Setup](./docs/getting-started/environment-setup.md) - Configure dev/prod environments

### 🏛️ Architecture & Design
- [🏗️ **Architecture & Security**](./docs/ARCHITECTURE_AND_SECURITY.md) - **Complete system architecture, security model, and service relationships**
- [📋 System Overview](./docs/architecture/system-overview.md) - High-level architecture
- [🔗 API Reference](./docs/architecture/api-reference.md) - REST API documentation
- [🗃️ Database Schema](./docs/architecture/database-schema.md) - Firestore structure
- [🔐 Authentication](./docs/architecture/authentication.md) - Auth flow details

### 💻 Development
- [🛠️ Development Guide](./docs/development/development-guide.md) - Local development workflow
- [🧪 Testing Guide](./docs/development/testing.md) - Testing strategies and setup
- [🐛 Mobile Debugging](./frontend/DEBUGGING.md) - Flutter app debugging guide
- [📝 Code Style Guide](./docs/development/code-style.md) - Coding standards
- [🤝 Contributing](./docs/development/contributing.md) - How to contribute

### 🚀 Deployment
- [📦 **Play Store Deployment**](./scripts/DEPLOYMENT_GUIDE.md) - **Complete guide for Google Play deployment**
- [🏗️ **Architecture & Security**](./docs/ARCHITECTURE_AND_SECURITY.md) - **Environment setup and graduation (dev to prod)**
- [📦 Deployment Guide](./docs/deployment/deployment-guide.md) - Production deployment
- [⚙️ Environment Config](./docs/deployment/environment-config.md) - Environment variables
- [🏗️ Infrastructure](./docs/deployment/infrastructure.md) - GCP setup
- [🔄 CI/CD Pipeline](./docs/deployment/ci-cd.md) - Automated deployment

### 🔧 Operations
- [📊 Monitoring](./docs/operations/monitoring.md) - Application monitoring
- [🆘 Troubleshooting](./docs/operations/troubleshooting.md) - Common issues
- [🔧 Maintenance](./docs/operations/maintenance.md) - Regular maintenance
- [💾 Backup & Recovery](./docs/operations/backup-recovery.md) - Data backup

### 📚 Reference
- [🛠️ Technology Stack](./docs/reference/tech-stack.md) - All technologies used
- [⚙️ Configuration](./docs/reference/configuration.md) - Complete config reference
- [📜 Scripts](./docs/reference/scripts.md) - Available scripts
- [❓ FAQ](./docs/reference/faq.md) - Frequently asked questions

## 🛠️ Technology Stack

### Backend
- **Framework**: FastAPI (Python 3.11+)
- **Database**: Cloud Firestore (NoSQL)
- **Storage**: Google Cloud Storage
- **Authentication**: Firebase Authentication
- **Deployment**: Docker + Google Cloud Run

### Frontend
- **Framework**: Flutter 3.x (Dart)
- **State Management**: Riverpod
- **HTTP Client**: Dio
- **Deployment**: Firebase Hosting

### Infrastructure
- **Cloud Platform**: Google Cloud Platform
- **Authentication**: Firebase Auth + Google OAuth
- **CI/CD**: Cloud Build + GitHub Actions
- **Monitoring**: Cloud Monitoring + Firebase Analytics

## 🌍 Environment Support

| Environment | Purpose | Status | URL |
|-------------|---------|--------|-----|
| **Development** | Local development | ✅ Active | `http://localhost:9100` |
| **Staging** | Pre-production testing | 📋 Planned | - |
| **Production** | Live application | 🚀 Ready for deploy | - |

## 🔑 Key Commands

### Development
```bash
# Start development environment
./scripts/dev-start.sh

# Run tests
cd backend && pytest
cd frontend && flutter test

# Format code
cd backend && black . && isort .
cd frontend && dart format .

# View logs
docker logs pottery-backend-container
```

### Deployment
```bash
# Deploy to production
cd backend && ./build_and_deploy.sh
cd frontend && firebase deploy

# Health check
./scripts/health-check.sh production
```

## 🧪 Testing

### Backend Testing
```bash
cd backend

# Unit tests only
pytest -m "not integration"

# Integration tests (uses development environment)
pytest -m integration

# All tests with coverage
pytest --cov=. --cov-report=html
```

### Frontend Testing
```bash
cd frontend

# Unit and widget tests
flutter test

# Integration tests
flutter drive --target=test_driver/app.dart
```

## 📊 Project Status

### Current Status: ✅ **Development Ready**

- ✅ Firebase Authentication integrated
- ✅ Backend API with FastAPI
- ✅ Frontend Flutter web app
- ✅ Local development environment
- ✅ Docker containerization
- ✅ Basic CRUD operations
- ✅ Photo upload functionality
- ✅ Comprehensive documentation

### Upcoming Features
- 🔄 Production deployment automation
- 📱 Mobile app (iOS/Android)
- 🔍 Advanced search and filtering
- 👥 Multi-user collaboration
- 📊 Analytics dashboard
- 🎨 Advanced photo editing

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](./docs/development/contributing.md) for details on:

- Code style guidelines
- Testing requirements
- Pull request process
- Development workflow

### Quick Contribution Steps

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## 🆘 Support

### Documentation
- 📖 **Full Documentation**: [docs/](./docs/)
- 🚀 **Quick Start**: [docs/getting-started/quick-start.md](./docs/getting-started/quick-start.md)
- 🆘 **Troubleshooting**: [docs/operations/troubleshooting.md](./docs/operations/troubleshooting.md)

### Help Resources
- **Issues**: Report bugs and feature requests in [GitHub Issues](../../issues)
- **Discussions**: Community discussions in [GitHub Discussions](../../discussions)
- **API Docs**: Interactive API documentation at `http://localhost:8000/api/docs`

### Common Issues
| Issue | Quick Fix | Documentation |
|-------|-----------|---------------|
| Backend won't start | Check Docker is running | [Troubleshooting](./docs/operations/troubleshooting.md) |
| Auth popup blocked | Enable browser popups | [Environment Setup](./docs/getting-started/environment-setup.md) |
| Flutter build fails | Run `flutter clean && flutter pub get` | [Development Guide](./docs/development/development-guide.md) |

## 🏗️ Project Structure

```
pottery-backend/
├── 📁 backend/              # FastAPI backend application
│   ├── routers/             # API route definitions
│   ├── services/            # Business logic services
│   ├── models/              # Data models and schemas
│   ├── auth/                # Authentication middleware
│   ├── config/              # Configuration management
│   ├── tests/               # Backend tests
│   └── scripts/             # Deployment and utility scripts
├── 📁 frontend/             # Flutter web application
│   ├── lib/src/             # Source code
│   │   ├── core/            # Shared utilities
│   │   ├── data/            # Data layer (services, repositories)
│   │   ├── domain/          # Business logic
│   │   └── presentation/    # UI layer (pages, widgets)
│   ├── test/                # Frontend tests
│   └── web/                 # Web-specific configurations
├── 📁 docs/                 # Comprehensive documentation
│   ├── getting-started/     # Setup and installation guides
│   ├── architecture/        # System design documentation
│   ├── development/         # Development workflow guides
│   ├── deployment/          # Deployment and infrastructure
│   ├── operations/          # Monitoring and maintenance
│   └── reference/           # Technical reference materials
├── 📄 README.md            # This file
└── 📄 LICENSE              # Project license
```

---

**Ready to start developing?** 🚀 Follow the [Quick Start Guide](./docs/getting-started/quick-start.md) to get your development environment running in minutes.

*For detailed information, explore the comprehensive documentation in the [`docs/`](./docs/) directory.*
