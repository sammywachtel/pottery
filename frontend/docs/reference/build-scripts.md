# Build Scripts Reference

Complete reference for all frontend build scripts and their usage.

## Scripts Location

All build scripts are located in `/frontend/scripts/`

---

## build_dev.sh

Development build script with interactive environment selection.

**Location:** `/frontend/scripts/build_dev.sh`

**Usage:**
```bash
./build_dev.sh [platform]
```

**Options:**
- No args - Interactive selection between Local and Dev flavors, builds debug for connected device
- `release` - Build release APK
- `ios` - Build for iOS
- `web` - Build for web
- `macos` - Build for macOS
- `debug` - Explicitly build debug (default)

**Environment Variables:**
- `FLAVOR` - Set flavor (local/dev) to skip interactive selection
- `API_BASE_URL` - Override API URL
- `CLEAN_INSTALL` - Set to `true` to uninstall before installing
- `ENVIRONMENT` - Environment name (defaults based on flavor)
- `DEBUG_ENABLED` - Enable debug features (defaults based on flavor)

**Interactive Menu:**
```
Select the app flavor to build:
1) Pottery Studio Local (local Docker)
2) Pottery Studio Dev (Google Cloud Run dev)

Enter your choice (1 or 2):
```

**What it does:**

1. **Detects local IP** (for local flavor):
   ```bash
   # Automatically finds your Mac's IP address
   # Used for Android/iOS to connect to local Docker backend
   ```

2. **Interactive flavor selection** (if FLAVOR not set):
   - Option 1: Local flavor → `com.pottery.app.local` → local Docker backend
   - Option 2: Dev flavor → `com.pottery.app.dev` → Cloud Run dev backend

3. **Sets environment variables**:
   ```bash
   FLAVOR=local|dev
   API_BASE_URL=http://<ip>:8000|https://pottery-api-dev.run.app
   ENVIRONMENT=development
   DEBUG_ENABLED=true
   ```

4. **Builds and installs**:
   - Runs `flutter build` with `--dart-define` flags
   - Optionally runs `flutter clean` if CLEAN_INSTALL=true
   - Uninstalls previous app if CLEAN_INSTALL=true
   - Installs new build on connected device

**Examples:**

```bash
# Interactive mode (recommended)
./build_dev.sh

# Non-interactive with environment variable
FLAVOR=local ./build_dev.sh

# Custom API URL
FLAVOR=dev API_BASE_URL=https://custom-dev-api.com ./build_dev.sh

# Clean install (removes old versions)
CLEAN_INSTALL=true ./build_dev.sh

# Build for specific platform
./build_dev.sh ios
./build_dev.sh web
./build_dev.sh macos

# Build release APK for testing
./build_dev.sh release
```

**Output:**
- **Debug build (default)**: Installed directly on connected device
- **Release build**: `build/app/outputs/flutter-apk/app-<flavor>-release.apk`
- **iOS**: `build/ios/`
- **Web**: `build/web/`
- **macOS**: `build/macos/`

---

## build_prod.sh

Production build script with security checks and optimizations.

**Location:** `/frontend/scripts/build_prod.sh`

**Usage:**
```bash
./build_prod.sh [platform]
```

**Platform Options:**
- No args - Build Android APK (default)
- `android` - Build Android APK
- `ios` - Build for iOS
- `web` - Build for web
- `macos` - Build for macOS
- `all` - Build all platforms

**Environment Variables:**
- `API_BASE_URL` - Override production API URL (not recommended)

**What it does:**

1. **Sets production configuration**:
   ```bash
   FLAVOR=prod
   API_BASE_URL=https://pottery-api-prod.run.app (default)
   ENVIRONMENT=production
   DEBUG_ENABLED=false
   ```

2. **Security checks**:
   - Warns if `API_BASE_URL` contains `localhost`
   - Warns if using `http://` instead of `https://`

3. **Production optimizations**:
   - Enables code obfuscation: `--obfuscate`
   - Splits debug symbols: `--split-debug-info=build/debug-symbols`
   - Release mode: `--release`

4. **Builds for selected platform(s)**

**Examples:**

```bash
# Build Android APK (default)
./build_prod.sh

# Build for specific platforms
./build_prod.sh android
./build_prod.sh ios
./build_prod.sh web
./build_prod.sh macos

# Build all platforms
./build_prod.sh all

# Override API URL (not recommended)
API_BASE_URL=https://custom-prod-api.com ./build_prod.sh
```

**Security Warnings:**

```bash
⚠️ WARNING: Production build with localhost API URL detected!
   Current API_BASE_URL: http://localhost:8000
   This should only be used for local testing.

Press Enter to continue or Ctrl+C to cancel...
```

**Output:**
- **Android APK**: `build/app/outputs/flutter-apk/app-prod-release.apk`
- **Android App Bundle**: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`
- **iOS**: `build/ios/` (requires Xcode for archiving)
- **Web**: `build/web/`
- **macOS**: `build/macos/Build/Products/Release/pottery_app.app`
- **Debug Symbols**: `build/debug-symbols/`

---

## setup_firebase.sh

Configures Firebase services for the Flutter app.

**Location:** `/frontend/scripts/setup_firebase.sh`

**Usage:**
```bash
./setup_firebase.sh
```

**What it does:**

1. Checks FlutterFire CLI installation
2. Configures Firebase for Flutter:
   - Firebase Authentication
   - Firestore Database
   - Cloud Storage
3. Generates `lib/firebase_options.dart`
4. Updates platform configurations

**Prerequisites:**
- Firebase project created
- FlutterFire CLI installed: `dart pub global activate flutterfire_cli`
- Authenticated with Firebase: `firebase login`

**Example:**
```bash
cd frontend/scripts
./setup_firebase.sh
```

**Interactive prompts:**
1. Select Firebase project
2. Select platforms (iOS, Android, web, macOS)
3. Confirm Firebase services to enable

**Output:**
- `lib/firebase_options.dart` - Firebase configuration
- Updates to `ios/Runner/GoogleService-Info.plist`
- Updates to `android/app/google-services.json`

---

## Environment Variables Reference

### FLAVOR

**Values:** `local` | `dev` | `prod`

**Purpose:** Determines which app flavor to build

**Effects:**
- Sets Android application ID
- Sets app display name
- Configures default API URL
- Sets debug/release mode

### API_BASE_URL

**Format:** `http://[host]:[port]` or `https://[host]`

**Purpose:** Backend API endpoint URL

**Examples:**
- Local: `http://192.168.1.100:8000`
- Dev: `https://pottery-api-dev.run.app`
- Prod: `https://pottery-api-prod.run.app`

**Accessed in Dart:**
```dart
const apiUrl = String.fromEnvironment('API_BASE_URL',
  defaultValue: 'http://localhost:8000');
```

### ENVIRONMENT

**Values:** `development` | `production`

**Purpose:** Runtime environment indicator

**Effects:**
- Enables/disables debug features
- Configures logging level
- Sets error reporting

### DEBUG_ENABLED

**Values:** `true` | `false`

**Purpose:** Enable debug features

**Effects:**
- Debug console
- Detailed error messages
- Development tools

### CLEAN_INSTALL

**Values:** `true` | `false`

**Purpose:** Uninstall app before installing new build

**Usage:**
```bash
CLEAN_INSTALL=true ./build_dev.sh
```

**Effects:**
- Runs `adb uninstall <package-id>` before install
- Ensures fresh app state
- Removes conflicting versions

---

## Build Configurations

### Flavor Configurations

Defined in `android/app/build.gradle.kts`:

```kotlin
productFlavors {
    create("local") {
        dimension = "environment"
        applicationId = "com.pottery.app.local"
        resValue("string", "app_name", "Pottery Studio Local")
    }
    create("dev") {
        dimension = "environment"
        applicationId = "com.pottery.app.dev"
        resValue("string", "app_name", "Pottery Studio Dev")
    }
    create("prod") {
        dimension = "environment"
        applicationId = "com.pottery.app"
        resValue("string", "app_name", "Pottery Studio")
    }
}
```

### Build Modes

**Debug:**
- Fast compilation
- Hot reload enabled
- No obfuscation
- Full debugging tools

**Release:**
- Optimized code
- Code obfuscation (production only)
- Smaller app size
- No debugging tools

**Profile:**
- Performance profiling enabled
- Some optimizations
- Used for performance testing

---

## Common Workflows

### Local Development Workflow

```bash
# 1. Start backend
cd ../scripts/backend
./run_docker_local.sh

# 2. Build and run Flutter app
cd ../../frontend/scripts
./build_dev.sh
# Select option 1: "Pottery Studio Local"
```

### Dev Cloud Testing Workflow

```bash
# Build and run against Cloud Run dev backend
cd frontend/scripts
./build_dev.sh
# Select option 2: "Pottery Studio Dev"
```

### Production Release Workflow

```bash
cd frontend/scripts

# Build Android
./build_prod.sh android

# Build iOS (requires macOS)
./build_prod.sh ios
# Then archive in Xcode

# Build Web
./build_prod.sh web
# Deploy build/web/ to hosting
```

### Multi-Platform Build Workflow

```bash
cd frontend/scripts

# Build everything
./build_prod.sh all

# Outputs:
# - build/app/outputs/flutter-apk/app-prod-release.apk
# - build/ios/
# - build/web/
# - build/macos/
```

---

## Troubleshooting

### Script Not Found

```bash
# Ensure you're in the correct directory
cd /path/to/pottery-backend/frontend/scripts
ls -la  # Should see build_dev.sh, build_prod.sh
```

### Permission Denied

```bash
# Make scripts executable
chmod +x build_dev.sh build_prod.sh setup_firebase.sh
```

### IP Detection Fails (build_dev.sh)

```bash
# Manually set IP address
FLAVOR=local API_BASE_URL=http://192.168.1.100:8000 ./build_dev.sh
```

### Build Failures

```bash
# Clean Flutter cache
flutter clean

# Get dependencies
flutter pub get

# Retry
./build_dev.sh
```

### Platform Not Found

```bash
# Ensure platform is set up
flutter create .  # Regenerates platform folders

# Check Flutter setup
flutter doctor
```

---

## Debug Commands

### List installed apps

```bash
adb shell pm list packages | grep pottery
```

**Output:**
```
package:com.pottery.app.local
package:com.pottery.app.dev
package:com.pottery.app
```

### Uninstall specific app

```bash
adb uninstall com.pottery.app.local
adb uninstall com.pottery.app.dev
adb uninstall com.pottery.app
```

### View app logs

```bash
adb logcat | grep pottery
```

### Check connected devices

```bash
flutter devices
adb devices
```

### Get current Flutter configuration

```bash
flutter config
```

---

## Related Documentation

- [Build & Deploy Guide](../how-to/build-and-deploy.md)
- [Local Development Guide](../getting-started/local-development.md)
- [Multi-App System Explanation](../explanation/multi-app-system.md)
- [Flutter Build Documentation](https://flutter.dev/docs/deployment)
