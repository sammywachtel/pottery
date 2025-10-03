# Build and Deploy Guide

Complete guide for building and deploying the Pottery Flutter app to different environments and platforms.

## Overview

The Pottery app supports three deployment environments, each with its own build configuration:

| Environment | App Name | Package ID | Backend URL | Script |
|-------------|----------|------------|-------------|---------|
| **Local** | Pottery Studio Local | `com.pottery.app.local` | Local Docker | `build_dev.sh` (option 1) |
| **Dev** | Pottery Studio Dev | `com.pottery.app.dev` | Cloud Run Dev | `build_dev.sh` (option 2) |
| **Production** | Pottery Studio | `com.pottery.app` | Cloud Run Prod | `build_prod.sh` |

---

## Development Builds

### Local Development Build

For testing with local Docker backend:

```bash
cd frontend/scripts
./build_dev.sh
# Select option 1: "Pottery Studio Local"
```

**What this does:**
- Builds with `local` flavor
- Configures API URL to your Mac's IP:8000
- Installs app with package ID `com.pottery.app.local`
- Enables debug features

**Environment variables detected:**
- `FLAVOR=local`
- `API_BASE_URL=http://<your-mac-ip>:8000`
- `ENVIRONMENT=development`
- `DEBUG_ENABLED=true`

### Dev Cloud Build

For testing with Google Cloud Run development backend:

```bash
cd frontend/scripts
./build_dev.sh
# Select option 2: "Pottery Studio Dev"
```

**What this does:**
- Builds with `dev` flavor
- Configures API URL to Cloud Run dev service
- Installs app with package ID `com.pottery.app.dev`
- Enables debug features

**Environment variables:**
- `FLAVOR=dev`
- `API_BASE_URL=https://pottery-api-dev.run.app`
- `ENVIRONMENT=development`
- `DEBUG_ENABLED=true`

### Advanced Development Options

**Custom API URL:**
```bash
FLAVOR=local API_BASE_URL=http://192.168.1.100:8000 ./build_dev.sh
```

**Clean Install (remove all previous versions):**
```bash
CLEAN_INSTALL=true ./build_dev.sh
```

**Non-interactive mode:**
```bash
FLAVOR=dev ./build_dev.sh
```

---

## Production Builds

### Android APK

```bash
cd frontend/scripts
./build_prod.sh
```

**What this does:**
- Builds with `prod` flavor
- Enables code obfuscation
- Splits debug symbols
- Configures production backend URL
- Creates release APK

**Output:** `build/app/outputs/flutter-apk/app-prod-release.apk`

**For Play Store deployment:** Use `./build_prod.sh appbundle` to build AAB instead. See [Play Store Deployment Guide](./deploy-play-store.md) for complete instructions.

#### Install APK via USB

To install the production APK directly to a USB-connected device:

```bash
# Build the APK (if not already built)
cd frontend/scripts
./build_prod.sh android

# Install to connected device
adb install -r ../build/app/outputs/flutter-apk/app-prod-release.apk
```

**What this does:**
- Builds production release APK with `com.pottery.app` package ID
- Connects to production backend: `https://pottery-api-prod-89677836881.us-central1.run.app`
- Installs directly to connected Android device via USB
- Uses `-r` flag to reinstall, keeping app data

**Prerequisites:**
- USB debugging enabled on Android device
- Device connected via USB cable
- ADB installed (comes with Android Studio)

**Verify device connection:**
```bash
adb devices  # Should show your device
```

### iOS App

```bash
cd frontend/scripts
./build_prod.sh ios
```

**What this does:**
- Builds for iOS release
- Requires Xcode for archiving
- Creates `build/ios/` output

**Next steps:**
1. Open in Xcode: `open ios/Runner.xcworkspace`
2. Archive for distribution
3. Upload to App Store Connect

### Web App

```bash
cd frontend/scripts
./build_prod.sh web
```

**What this does:**
- Builds optimized web bundle
- Output to `build/web/`
- Ready for static hosting

**Deployment options:**
- Cloud Run (with Docker)
- Firebase Hosting
- Cloud Storage + Cloud CDN
- Any static web host

### macOS App

```bash
cd frontend/scripts
./build_prod.sh macos
```

**What this does:**
- Builds native macOS app
- Creates `build/macos/` output

### All Platforms

```bash
cd frontend/scripts
./build_prod.sh all
```

Builds for Android, iOS, web, and macOS sequentially.

---

## Production Deployment

### Deploy Web to Cloud Run

The repository includes a Dockerfile for containerized web deployment:

```bash
cd frontend

# Set variables
PROJECT_ID="your-gcp-project"
REGION="us-central1"
IMAGE="gcr.io/$PROJECT_ID/pottery-frontend:latest"
API_BASE="https://pottery-api-prod.run.app"

# Build Docker image with baked-in API URL
docker build \
  --build-arg API_BASE_URL=$API_BASE \
  -t $IMAGE .

# Deploy to Cloud Run
gcloud run deploy pottery-frontend \
  --image $IMAGE \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated
```

**What the Dockerfile does:**
1. Builds Flutter web bundle with production API URL
2. Uses nginx to serve static files
3. Rewrites routes to `index.html` for Flutter routing
4. Serves on port 8080

### Deploy Web with Cloud Build

```bash
cd frontend

# Set API URL for production
export API_BASE_URL="https://pottery-api-prod.run.app"

# Trigger Cloud Build
gcloud builds submit . \
  --config=cloudbuild.yaml \
  --substitutions=_API_BASE_URL=$API_BASE_URL
```

The `cloudbuild.yaml` pipeline:
1. Builds Docker image with API URL
2. Pushes to Artifact Registry
3. Deploys to Cloud Run

### Deploy Web to Firebase Hosting

```bash
cd frontend

# Build web bundle
flutter build web --release \
  --dart-define=API_BASE_URL=https://pottery-api-prod.run.app

# Deploy to Firebase
firebase deploy --only hosting
```

**Prerequisites:**
- Firebase project initialized
- `firebase.json` configured

---

## Multi-Platform Build Strategy

### Android

**Development:**
```bash
./build_dev.sh  # Debug APK, installed directly
```

**Production:**
```bash
./build_prod.sh android  # Release APK
# Or for Play Store:
./build_prod.sh android --app-bundle
```

### iOS

**Development:**
```bash
flutter run -d <ios-device> --dart-define=API_BASE_URL=<url>
```

**Production:**
```bash
./build_prod.sh ios
# Then in Xcode:
# 1. Archive
# 2. Distribute to App Store
```

### Web

**Development:**
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

**Production:**
```bash
./build_prod.sh web
# Deploy build/web/ to hosting
```

### macOS

**Development:**
```bash
flutter run -d macos --dart-define=API_BASE_URL=http://localhost:8000
```

**Production:**
```bash
./build_prod.sh macos
# Notarize and distribute
```

---

## Build Configuration

### Environment Variables

The build scripts use these environment variables:

| Variable | Purpose | Default |
|----------|---------|---------|
| `FLAVOR` | App flavor (local/dev/prod) | Interactive selection |
| `API_BASE_URL` | Backend API URL | Based on flavor |
| `ENVIRONMENT` | Environment name | development/production |
| `DEBUG_ENABLED` | Enable debug features | true (dev) / false (prod) |
| `CLEAN_INSTALL` | Uninstall before install | false |

### Dart Define Variables

These are passed to Flutter at build time:

```bash
flutter build <platform> \
  --dart-define=FLAVOR=prod \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=ENVIRONMENT=production \
  --dart-define=DEBUG_ENABLED=false
```

Access in Dart code:
```dart
const apiUrl = String.fromEnvironment('API_BASE_URL',
  defaultValue: 'http://localhost:8000');
```

### Android Gradle Flavors

Defined in `android/app/build.gradle.kts`:

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

---

## Security Considerations

### Development Builds

- Debug mode enabled
- No code obfuscation
- Full error messages
- Debugging tools accessible

### Production Builds

- Debug mode disabled
- Code obfuscation enabled
- Debug symbols split and stored separately
- Minimal error information
- Security warnings for localhost URLs

### API URL Security

**Production builds warn if:**
- `API_BASE_URL` contains `localhost`
- `API_BASE_URL` uses `http://` instead of `https://`

```bash
⚠️ WARNING: Production build with localhost API URL detected!
   Current API_BASE_URL: http://localhost:8000
   This should only be used for local testing.
```

---

## Build Output Locations

| Platform | Output Path |
|----------|-------------|
| Android Debug | Installed directly on device |
| Android Release APK | `build/app/outputs/flutter-apk/app-<flavor>-release.apk` |
| Android App Bundle | `build/app/outputs/bundle/<flavor>Release/app-<flavor>-release.aab` |
| iOS | `build/ios/` (requires Xcode archiving) |
| Web | `build/web/` |
| macOS | `build/macos/Build/Products/Release/pottery_app.app` |

---

## Troubleshooting

### Build Failures

**Clean build cache:**
```bash
flutter clean
flutter pub get
```

**Check Flutter installation:**
```bash
flutter doctor
```

**Verify platform-specific setup:**
```bash
flutter doctor -v
```

### Platform-Specific Issues

**Android - Gradle errors:**
```bash
cd android
./gradlew clean
cd ..
flutter build apk
```

**iOS - Signing issues:**
```bash
# Open in Xcode
open ios/Runner.xcworkspace
# Check Signing & Capabilities
```

**Web - Build optimization:**
```bash
flutter build web --web-renderer canvaskit  # Better graphics
flutter build web --web-renderer html      # Smaller bundle
```

### Multi-App Conflicts

**Remove all versions:**
```bash
adb uninstall com.pottery.app.local
adb uninstall com.pottery.app.dev
adb uninstall com.pottery.app
```

**Clean install:**
```bash
CLEAN_INSTALL=true ./build_dev.sh
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'

      - name: Build APK
        run: |
          cd frontend
          flutter pub get
          flutter build apk --release \
            --dart-define=API_BASE_URL=${{ secrets.PROD_API_URL }}

      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: android-apk
          path: frontend/build/app/outputs/flutter-apk/
```

### Cloud Build for Web

See [Production Deployment](#deploy-web-with-cloud-build) section above.

---

## Next Steps

- **Deploy to Play Store:** [Play Store Deployment Guide](./deploy-play-store.md)
- **Understand Multi-App System:** [Multi-App Explanation](../explanation/multi-app-system.md)
- **Script Reference:** [Build Scripts Reference](../reference/build-scripts.md)
- **Local Development:** [Getting Started](../getting-started/local-development.md)
- **Backend Deployment:** [Backend Deployment Guide](../../../backend/docs/how-to/deploy-environments.md)

## Related Documentation

- [Play Store Deployment](./deploy-play-store.md) - Complete Google Play Store guide
- [Build Scripts Reference](../reference/build-scripts.md)
- [Multi-App System](../explanation/multi-app-system.md)
- [Flutter Build Documentation](https://flutter.dev/docs/deployment)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
