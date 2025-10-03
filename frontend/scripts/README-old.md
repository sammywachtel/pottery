# Flutter Build Scripts

This directory contains scripts for building and deploying the Pottery Studio Flutter application with support for multiple environment configurations and parallel app installations.

## 🎯 Multi-App Build System

The build system supports **three independent app installations** on your device, each with its own package ID and backend configuration:

| App Name | Package ID | Script | Backend | Use Case |
|----------|------------|--------|---------|----------|
| **Pottery Studio Local** | `com.pottery.app.local` | `build_dev.sh` (option 1) | Local Docker | Testing with local backend |
| **Pottery Studio Dev** | `com.pottery.app.dev` | `build_dev.sh` (option 2) | Cloud Run Dev | Testing dev cloud features |
| **Pottery Studio** | `com.pottery.app` | `build_prod.sh` | Cloud Run Prod | Production app |

## 📁 Available Scripts

### build_dev.sh
Development build script with interactive environment selection.

**Features:**
- Interactive selection between Local and Dev flavors
- Auto-detects local IP for Docker backend connection
- Supports custom backend URLs
- Optional clean install to remove old app versions

**Usage:**
```bash
# Interactive mode (recommended)
./build_dev.sh

# With environment variables
FLAVOR=local API_BASE_URL=http://192.168.1.100:8000 ./build_dev.sh

# Clean install (removes old versions)
CLEAN_INSTALL=true ./build_dev.sh

# Build specific platform
./build_dev.sh release  # Build APK
./build_dev.sh ios      # Build for iOS
./build_dev.sh web      # Build for web
```

### build_prod.sh
Production build script with security checks and optimizations.

**Features:**
- Fixed production flavor and backend
- Code obfuscation enabled
- Debug symbols split for security
- Warns if localhost URLs detected
- Supports multiple platforms

**Usage:**
```bash
# Build Android APK (default)
./build_prod.sh

# Build for specific platforms
./build_prod.sh android  # Android APK
./build_prod.sh ios      # iOS app
./build_prod.sh web      # Web app
./build_prod.sh macos    # macOS app
./build_prod.sh all      # All platforms

# With custom API URL (not recommended)
API_BASE_URL=https://custom-prod-api.com ./build_prod.sh
```

### setup_firebase.sh
Configures Firebase services for the Flutter app.

**Features:**
- Initializes FlutterFire configuration
- Sets up Firebase Auth
- Configures Firestore Database
- Enables Cloud Storage

**Usage:**
```bash
./setup_firebase.sh
```

## 🚀 Quick Start

### 1. Local Development
Test with local Docker backend:
```bash
cd scripts
./build_dev.sh
# Select option 1: "Pottery Studio Local"
```

### 2. Dev Cloud Testing
Test with Google Cloud Run dev environment:
```bash
cd scripts
./build_dev.sh
# Select option 2: "Pottery Studio Dev"
```

### 3. Production Build
Build the production app:
```bash
cd scripts
./build_prod.sh
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FLAVOR` | App flavor (local/dev/prod) | Interactive selection |
| `API_BASE_URL` | Backend API URL | Based on flavor |
| `ENVIRONMENT` | Environment name | development/production |
| `DEBUG_ENABLED` | Enable debug features | true (dev) / false (prod) |
| `CLEAN_INSTALL` | Uninstall before install | false |

### Backend URLs

- **Local Docker**: `http://<your-mac-ip>:8000`
- **Dev Cloud Run**: `https://pottery-api-dev.run.app`
- **Prod Cloud Run**: `https://pottery-api-prod.run.app`

## 📱 Device Management

### Installing Multiple Versions
All three app versions can coexist on the same device:
```bash
# Install local version
./build_dev.sh  # Choose option 1

# Install dev version (without removing local)
./build_dev.sh  # Choose option 2

# Install production version
./build_prod.sh
```

### Removing Old Versions
```bash
# Remove all old versions during install
CLEAN_INSTALL=true ./build_dev.sh

# Manual removal
adb uninstall com.pottery.app.local
adb uninstall com.pottery.app.dev
adb uninstall com.pottery.app
```

## 🏗️ Technical Details

### Android Flavors
The multi-app system uses Android product flavors defined in `android/app/build.gradle.kts`:

```kotlin
productFlavors {
    create("local") {
        applicationId = "com.pottery.app.local"
        resValue("string", "app_name", "Pottery Studio Local")
    }
    create("dev") {
        applicationId = "com.pottery.app.dev"
        resValue("string", "app_name", "Pottery Studio Dev")
    }
    create("prod") {
        applicationId = "com.pottery.app"
        resValue("string", "app_name", "Pottery Studio")
    }
}
```

### Build Outputs

| Build Type | Output Location |
|------------|----------------|
| Debug APK | Installed directly on device |
| Release APK | `build/app/outputs/flutter-apk/app-<flavor>-release.apk` |
| iOS | `build/ios/` (requires Xcode archiving) |
| Web | `build/web/` |

## 🔒 Security Notes

### Development Builds
- Debug mode enabled for easier testing
- No code obfuscation
- Full error messages and stack traces

### Production Builds
- Debug mode disabled
- Code obfuscation enabled
- Debug symbols split and stored separately
- Localhost URLs trigger security warnings

## 🐛 Troubleshooting

### Common Issues

**App not installing:**
```bash
# Clean install to remove conflicting versions
CLEAN_INSTALL=true ./build_dev.sh
```

**Cannot connect to local backend:**
```bash
# Ensure Docker is running
docker ps | grep pottery-backend

# Check your Mac's IP address
ifconfig en0 | grep inet
```

**Build failures:**
```bash
# Clean Flutter build cache
flutter clean

# Get dependencies
flutter pub get

# Retry build
./build_dev.sh
```

### Debug Commands

```bash
# List installed pottery apps
adb shell pm list packages | grep pottery

# View device logs
adb logcat | grep pottery

# Check Flutter installation
flutter doctor
```

## 📚 Additional Documentation

- [Multi-App System Details](README-multi-app.md)
- [Backend Setup](../../backend/README.md)
- [Flutter Documentation](https://flutter.dev/docs)

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review backend logs: `docker logs pottery-backend`
3. Check Flutter logs: `flutter logs`
4. See main project README for more details
