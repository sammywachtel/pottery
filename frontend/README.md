# Pottery Catalog Flutter App

A Flutter application providing a full-featured interface for the pottery inventory backend. Supports web, iOS, and Android with a multi-app build system for efficient development.

## 🚀 Quick Start

Choose your path:

### I Want To...

**→ Develop Locally** (5 minutes)
Follow: [Local Development Guide](docs/getting-started/local-development.md)

**→ Build for Production** (10 minutes)
Follow: [Build & Deploy Guide](docs/how-to/build-and-deploy.md)

**→ Deploy to Google Play Store** (30 minutes)
Follow: [Play Store Deployment Guide](docs/how-to/deploy-play-store.md)

**→ Install Production App via USB** (2 minutes)
See: [Build & Deploy Guide - Install APK via USB](docs/how-to/build-and-deploy.md#install-apk-via-usb)

**→ Debug Production App** (5 minutes)
See: [Troubleshooting Guide](docs/how-to/troubleshooting.md)

**→ Understand the Multi-App System**
Read: [Multi-App Explanation](docs/explanation/multi-app-system.md)

**→ Look Up Build Scripts**
See: [Build Scripts Reference](docs/reference/build-scripts.md)

---

## Architecture Overview

```
┌─────────────────────────────────────┐
│    Flutter App (Multi-Platform)     │
│    ▸ Web (Chrome, Safari, Firefox)  │
│    ▸ Android (Mobile, Tablet)       │
│    ▸ iOS (iPhone, iPad)             │
│    ▸ macOS (Desktop)                │
└──────┬──────────────────────────────┘
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
- Multi-environment build system (local/dev/prod)
- Firebase Authentication
- Real-time data sync with Firestore
- Photo management with Cloud Storage
- Responsive design for all platforms
- Hot reload for rapid development

---

## Multi-App Build System

**Three independent app installations** for efficient development:

| App Name | Package ID | Backend | Build Script |
|----------|------------|---------|--------------|
| **Pottery Studio Local** | `com.pottery.app.local` | Local Docker | `./build_dev.sh` (option 1) |
| **Pottery Studio Dev** | `com.pottery.app.dev` | Cloud Run Dev | `./build_dev.sh` (option 2) |
| **Pottery Studio** | `com.pottery.app` | Cloud Run Prod | `./build_prod.sh` |

**Benefits:**
- All three apps coexist on same device
- No uninstall/reinstall cycles
- Easy environment comparison
- Preserved app state per environment

Learn more: [Multi-App System Explanation](docs/explanation/multi-app-system.md)

---

## Documentation

### 📘 Getting Started

- **[Local Development](docs/getting-started/local-development.md)** - Run the app locally in 5 minutes

### 📗 How-To Guides

- **[Build & Deploy](docs/how-to/build-and-deploy.md)** - Build and deploy for all platforms and environments
- **[Deploy to Play Store](docs/how-to/deploy-play-store.md)** - Complete Google Play Store deployment guide
- **[Troubleshooting](docs/how-to/troubleshooting.md)** - Debug and fix common issues

### 📕 Reference

- **[Build Scripts](docs/reference/build-scripts.md)** - Complete build script documentation

### 📙 Explanation

- **[Multi-App System](docs/explanation/multi-app-system.md)** - How and why the multi-app system works

---

## Project Structure

```
frontend/
├── lib/
│   └── src/
│       ├── app.dart                 # Root MaterialApp
│       ├── config/
│       │   └── app_config.dart      # Environment configuration
│       ├── core/
│       │   └── app_exception.dart   # Domain exceptions
│       ├── data/                    # Models, repositories, API client
│       ├── features/
│       │   ├── auth/                # Authentication
│       │   ├── items/               # Item management
│       │   └── photos/              # Photo upload
│       └── widgets/                 # Shared widgets
├── assets/
│   └── stages.json                  # Pottery stages data
├── scripts/
│   ├── build_dev.sh                 # Development builds
│   ├── build_prod.sh                # Production builds
│   └── setup_firebase.sh            # Firebase configuration
├── docs/                            # Documentation
├── Dockerfile                       # Web deployment
└── cloudbuild.yaml                  # Cloud Build pipeline
```

---

## Key Technologies

- **Framework:** Flutter 3.22+ (Dart 3.3+)
- **State Management:** Provider / Riverpod
- **Authentication:** Firebase Auth
- **Backend:** FastAPI on Cloud Run
- **Database:** Firestore
- **Storage:** Cloud Storage
- **Platforms:** Web, Android, iOS, macOS

---

## Common Commands

### Development

```bash
# Run locally with backend
cd scripts
./build_dev.sh

# Hot reload development (web)
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Production

```bash
# Build Android APK
cd scripts
./build_prod.sh

# Build for iOS
./build_prod.sh ios

# Build for web
./build_prod.sh web

# Build all platforms
./build_prod.sh all
```

---

## Prerequisites

- Flutter SDK >= 3.19 (3.22 recommended)
- Dart >= 3.3
- Android Studio / Xcode (for mobile)
- Chrome (for web development)
- Docker (for local backend)
- Google Cloud SDK (for deployment)

**Check installation:**
```bash
flutter doctor
```

---

## Quick Links

**For Developers:**
- [Local Development Setup](docs/getting-started/local-development.md)
- [Build Scripts Reference](docs/reference/build-scripts.md)
- [Multi-App System](docs/explanation/multi-app-system.md)

**For DevOps:**
- [Build & Deploy Guide](docs/how-to/build-and-deploy.md)
- [Play Store Deployment](docs/how-to/deploy-play-store.md)
- [Production Deployment](docs/how-to/build-and-deploy.md#production-deployment)

**Backend:**
- [Backend Documentation](../backend/README.md)
- [Backend API Docs](../backend/docs/reference/api-endpoints.md)

---

## Environment Configuration

The app uses `--dart-define` for configuration:

```bash
# Local development
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=ENVIRONMENT=development

# Production
flutter build apk \
  --dart-define=API_BASE_URL=https://pottery-api-prod.run.app \
  --dart-define=ENVIRONMENT=production \
  --flavor prod
```

**Available variables:**
- `API_BASE_URL` - Backend API endpoint
- `ENVIRONMENT` - Environment name (development/production)
- `DEBUG_ENABLED` - Enable debug features (true/false)
- `FLAVOR` - App flavor (local/dev/prod)

---

## Development Workflow

### 1. Local Development

```bash
# Start backend
cd ../scripts/backend
./run_docker_local.sh

# Run Flutter app
cd ../../frontend/scripts
./build_dev.sh  # Choose option 1: Local
```

### 2. Cloud Testing

```bash
# Test with Cloud Run dev backend
cd scripts
./build_dev.sh  # Choose option 2: Dev
```

### 3. Production Build

```bash
# Build production app
cd scripts
./build_prod.sh
```

---

## Platform Support

### Web ✅
- Chrome, Safari, Firefox
- Responsive design
- PWA capabilities
- Deploy to Cloud Run, Firebase Hosting, or static host

### Android ✅
- Phone and tablet support
- Material Design 3
- Multi-app system (3 flavors)

### iOS ✅
- iPhone and iPad support
- Cupertino widgets
- Requires provisioning profiles per flavor

### macOS ✅
- Desktop support
- Native performance
- Similar configuration to iOS

---

## Troubleshooting

### Common Issues

**App won't install:**
```bash
# Clean install
CLEAN_INSTALL=true ./build_dev.sh
```

**Build failures:**
```bash
flutter clean
flutter pub get
./build_dev.sh
```

**Can't connect to backend:**
```bash
# Check backend is running
docker ps | grep pottery-backend

# Verify your Mac's IP
ifconfig en0 | grep inet
```

See [Troubleshooting Guide](docs/getting-started/local-development.md#troubleshooting) for more.

---

## Support

- **Documentation:** See [docs/](docs/) directory
- **Backend Issues:** See [Backend README](../backend/README.md)
- **Build Issues:** See [Build Scripts Reference](docs/reference/build-scripts.md)
- **Flutter Docs:** https://flutter.dev/docs

---

## Legacy Documentation

Previous documentation has been archived:
- [README-old.md](README-old.md) - Original comprehensive README

This is kept for reference but may contain outdated information. Please use the new documentation structure in [docs/](docs/).
