# Local Development Quick Start

Get the Pottery Flutter app running locally in under 5 minutes.

## Prerequisites

- Flutter SDK >= 3.19 (3.22 recommended)
- Dart >= 3.3
- Android Studio / Xcode (for mobile testing)
- Chrome (for web testing)
- Backend API running (see [Backend Local Development](../../../backend/docs/getting-started/local-development.md))

## Quick Start (3 Steps)

### 1. Install Dependencies

```bash
cd frontend
flutter pub get
```

### 2. Run the App

**For web (easiest):**
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

**For Android:**
```bash
flutter run -d <device-id> --dart-define=API_BASE_URL=http://<your-mac-ip>:8000
```

**For iOS:**
```bash
flutter run -d <device-id> --dart-define=API_BASE_URL=http://<your-mac-ip>:8000
```

### 3. Use Development Build Scripts

For easier development with the multi-app system:

```bash
cd scripts
./build_dev.sh
# Select option 1: "Pottery Studio Local" for local Docker backend
# Select option 2: "Pottery Studio Dev" for Cloud Run dev backend
```

---

## Development Workflows

### Running Different Environments

**Local Backend (Docker):**
```bash
# Start backend first
cd ../scripts/backend
./run_docker_local.sh

# Run Flutter app pointing to local backend
cd ../../frontend/scripts
./build_dev.sh  # Choose option 1
```

**Dev Backend (Cloud Run):**
```bash
cd scripts
./build_dev.sh  # Choose option 2
```

### Testing & Analysis

```bash
cd frontend

# Run tests
flutter test

# Analyze code
flutter analyze

# Check Flutter installation
flutter doctor
```

### Hot Reload Development

For fastest development cycle:

```bash
cd frontend
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
# Make code changes - hot reload will update automatically
```

---

## Multi-App System

The build scripts support three independent app installations that can coexist on your device:

| App Name | Package ID | Backend |
|----------|------------|---------|
| **Pottery Studio Local** | `com.pottery.app.local` | Local Docker |
| **Pottery Studio Dev** | `com.pottery.app.dev` | Cloud Run Dev |
| **Pottery Studio** | `com.pottery.app` | Cloud Run Prod |

**Benefits:**
- Test different backends simultaneously
- No need to uninstall between builds
- Easy comparison of environments

See [Multi-App System Explanation](../explanation/multi-app-system.md) for details.

---

## Project Structure

```
frontend/
  lib/
    src/
      app.dart                     # Root MaterialApp
      config/app_config.dart       # Environment config (API base URL)
      core/app_exception.dart      # Domain exceptions
      data/                        # Models, repositories, API client
      features/
        auth/                      # Login state & view
        items/                     # Item listing, detail, forms
        photos/                    # Photo upload workflow
      widgets/                     # Shared widgets
  assets/stages.json               # Stage metadata for dropdowns
  scripts/                         # Build & deployment scripts
```

---

## Common Tasks

### Finding Your Mac's IP Address

For Android/iOS devices to connect to local Docker backend:

```bash
# macOS/Linux
ifconfig en0 | grep inet

# You'll see something like: inet 192.168.1.100
# Use this IP in --dart-define=API_BASE_URL=http://192.168.1.100:8000
```

### Listing Connected Devices

```bash
flutter devices
```

### Installing Multiple Versions

```bash
# Install local version
./build_dev.sh  # Choose option 1

# Install dev version (won't remove local)
./build_dev.sh  # Choose option 2

# Both apps now coexist on device!
```

### Clean Install

To remove all previous versions:

```bash
CLEAN_INSTALL=true ./build_dev.sh
```

---

## Configuration

### API Base URL

The app reads the backend URL from `--dart-define=API_BASE_URL`:

```bash
# Local development (default)
--dart-define=API_BASE_URL=http://localhost:8000

# Custom local backend
--dart-define=API_BASE_URL=http://192.168.1.100:8000

# Dev cloud backend
--dart-define=API_BASE_URL=https://pottery-api-dev.run.app

# Production backend
--dart-define=API_BASE_URL=https://pottery-api-prod.run.app
```

### Platform Folders

If `android/`, `ios/`, or `web/` folders are missing:

```bash
cd frontend
flutter create .
```

This regenerates platform folders without affecting your lib/ code.

---

## Troubleshooting

### Cannot Connect to Backend

**Web (CORS issues):**
```bash
# Ensure backend CORS is configured for localhost
cd ../scripts/backend
./setup-infrastructure.sh local
```

**Mobile (Network issues):**
```bash
# Verify Docker is running
docker ps | grep pottery-backend

# Check your Mac's IP
ifconfig en0 | grep inet

# Use correct IP in API_BASE_URL
```

### Build Failures

```bash
# Clean Flutter cache
flutter clean

# Reinstall dependencies
flutter pub get

# Retry
./build_dev.sh
```

### App Not Installing

```bash
# Clean install to remove conflicts
CLEAN_INSTALL=true ./build_dev.sh

# Or manually remove
adb uninstall com.pottery.app.local
adb uninstall com.pottery.app.dev
```

### Platform-Specific Issues

**iOS:**
```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace

# Check signing & capabilities
```

**Android:**
```bash
# Check installed packages
adb shell pm list packages | grep pottery

# View logs
adb logcat | grep pottery
```

---

## Next Steps

- **Learn Build Scripts:** [Build & Deploy Guide](../how-to/build-and-deploy.md)
- **Understand Multi-App System:** [Multi-App Explanation](../explanation/multi-app-system.md)
- **Script Reference:** [Build Scripts Reference](../reference/build-scripts.md)
- **Deploy to Production:** [How to Deploy](../how-to/build-and-deploy.md#production-deployment)

## Reference

- [Build Scripts Reference](../reference/build-scripts.md)
- [Backend Local Development](../../../backend/docs/getting-started/local-development.md)
- [Flutter Documentation](https://flutter.dev/docs)
