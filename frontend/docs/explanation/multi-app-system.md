# Multi-App Build System

Understanding the Pottery app's multi-environment build architecture and why it enables efficient development.

## Overview

The Pottery Flutter app uses a **product flavor** system that creates three independent app installations, each with its own:
- Package ID (application ID)
- Display name
- Backend configuration
- App icon/branding (optional)

This allows all three versions to coexist on the same device without conflicts.

---

## The Three Apps

### 1. Pottery Studio Local

**Package ID:** `com.pottery.app.local`
**Display Name:** "Pottery Studio Local"
**Backend:** Local Docker (`http://<your-mac-ip>:8000`)
**Use Case:** Testing with local backend during development

**When to use:**
- Developing new backend features
- Testing API changes before deploying
- Debugging backend/frontend integration
- Working offline or without cloud access

### 2. Pottery Studio Dev

**Package ID:** `com.pottery.app.dev`
**Display Name:** "Pottery Studio Dev"
**Backend:** Google Cloud Run Dev (`https://pottery-api-dev.run.app`)
**Use Case:** Testing with cloud infrastructure in non-production environment

**When to use:**
- Testing cloud-specific features (GCS, Firestore)
- QA/staging testing
- Integration testing with deployed backend
- Validating before production release

### 3. Pottery Studio (Production)

**Package ID:** `com.pottery.app`
**Display Name:** "Pottery Studio"
**Backend:** Google Cloud Run Prod (`https://pottery-api-prod.run.app`)
**Use Case:** Production release for end users

**When to use:**
- Final production builds
- App store releases
- Live user access

---

## Why Multiple Apps?

### Problem: Traditional Single-App Development

**Before multi-app system:**
```
Developer workflow:
1. Build app with local backend
2. Test feature
3. Uninstall app
4. Build app with dev backend
5. Test again
6. Uninstall app
7. Build app with prod backend
8. Test one more time
```

**Issues:**
- Constant uninstall/reinstall cycles
- Lost app state between builds
- Can't compare environments side-by-side
- Slower development iteration

### Solution: Multi-App Coexistence

**With multi-app system:**
```
Developer workflow:
1. Install all three versions once
2. Test in Local app
3. Switch to Dev app (no uninstall)
4. Compare behaviors instantly
5. Check Prod app for reference
```

**Benefits:**
- No uninstall/reinstall needed
- Preserved app state per environment
- Side-by-side comparison
- Faster development cycles

---

## Technical Implementation

### Android Product Flavors

Defined in `android/app/build.gradle.kts`:

```kotlin
flavorDimensions += "environment"

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

**Key concepts:**

**Flavor Dimension:** Groups related flavors (all are "environment" variants)

**Application ID:** Unique package identifier
- Android uses this to distinguish apps
- Different IDs = different apps can coexist
- Same ID = apps conflict (can't install both)

**Resource Values:** Dynamic app name
- `resValue("string", "app_name", "...")` sets display name
- Shows different names in launcher
- Easy visual identification

### Build Configuration

**Dart Define Variables:**

The build scripts pass configuration via `--dart-define`:

```bash
flutter build apk \
  --dart-define=FLAVOR=local \
  --dart-define=API_BASE_URL=http://192.168.1.100:8000 \
  --dart-define=ENVIRONMENT=development \
  --dart-define=DEBUG_ENABLED=true \
  --flavor local
```

**Access in code:**

```dart
class AppConfig {
  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'local'
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000'
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development'
  );

  static const bool debugEnabled = bool.fromEnvironment(
    'DEBUG_ENABLED',
    defaultValue: true
  );
}
```

---

## Development Workflow Benefits

### 1. Parallel Testing

**Scenario:** Testing a photo upload feature

```bash
# Test with local backend
./build_dev.sh  # Choose option 1
# Upload photo, see it stored locally

# Without uninstalling, test with cloud storage
./build_dev.sh  # Choose option 2
# Upload photo, see it in Cloud Storage

# Compare behaviors side-by-side
# Both apps are installed, can switch between them
```

### 2. Environment Debugging

**Scenario:** Feature works locally but fails in cloud

```bash
# Install both versions
./build_dev.sh  # Option 1 (local)
./build_dev.sh  # Option 2 (dev)

# Test in local app - works ✓
# Test in dev app - fails ✗
# Conclusion: Issue is cloud-specific (GCS/Firestore)
```

### 3. Regression Testing

**Scenario:** New feature might break existing functionality

```bash
# Install production app first (baseline)
./build_prod.sh

# Install new dev build with feature
./build_dev.sh  # Option 2

# Compare:
# - Prod app: Existing feature works ✓
# - Dev app: New feature works, but existing feature broken ✗
# Caught regression before production!
```

### 4. User Simulation

**Scenario:** Test upgrade path from current production

```bash
# Install current production version
./build_prod.sh  # (from old branch)

# Use app, create data, establish state

# Install new dev version (different package)
./build_dev.sh  # Option 2

# Verify new version works independently
# Verify users can run both (transition period)
```

---

## Platform Support

### Android

**Fully Supported** ✓

- Product flavors in `build.gradle.kts`
- Different package IDs
- All three apps install independently

### iOS

**Requires Additional Configuration**

Product flavors work, but need:
```
1. Different Bundle IDs (like Android package IDs)
2. Separate provisioning profiles per flavor
3. Updated Info.plist per flavor
```

Current iOS setup:
- Uses schemes instead of flavors
- Manual configuration needed
- See: `ios/Runner.xcodeproj/project.pbxproj`

### Web

**Not Applicable**

Web doesn't install as separate apps. Instead:
- Build different versions to different domains
- Use different builds per deployment:
  ```bash
  # Local testing
  flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000

  # Dev deployment
  flutter build web --dart-define=API_BASE_URL=https://pottery-dev.example.com

  # Prod deployment
  flutter build web --dart-define=API_BASE_URL=https://pottery.example.com
  ```

### macOS

**Similar to iOS**

- Requires separate bundle IDs
- Uses schemes for configuration
- Can coexist with different IDs

---

## Trade-offs and Limitations

### Advantages

✅ **No uninstall/reinstall cycles**
✅ **Preserved app state per environment**
✅ **Side-by-side comparison**
✅ **Faster iteration**
✅ **Easier debugging**
✅ **Risk-free production comparison**

### Disadvantages

❌ **More storage space** (3x apps installed)
❌ **Initial setup complexity** (flavor configuration)
❌ **iOS requires additional config** (bundle IDs, profiles)
❌ **Must manage 3 builds** (can be automated)
❌ **User confusion if distributed** (avoid giving all 3 to users)

---

## Best Practices

### 1. Visual Differentiation

**App Icons:**
Add flavor-specific icons:
```
assets/icons/
  icon-local.png    # Blue tint
  icon-dev.png      # Orange tint
  icon-prod.png     # Original
```

**Color Schemes:**
Use different theme colors per flavor:
```dart
MaterialApp(
  theme: ThemeData(
    primaryColor: AppConfig.flavor == 'local'
      ? Colors.blue
      : AppConfig.flavor == 'dev'
        ? Colors.orange
        : Colors.purple,
  ),
)
```

### 2. Clear Naming

**In launcher:**
- "Pottery Studio Local" (with local icon)
- "Pottery Studio Dev" (with dev icon)
- "Pottery Studio" (production icon)

Users can instantly identify which app they're using.

### 3. Build Scripts

**Automate with scripts:**
```bash
# Interactive selection
./build_dev.sh

# Environment variable override
FLAVOR=local ./build_dev.sh

# Clean install
CLEAN_INSTALL=true ./build_dev.sh
```

### 4. Don't Distribute All Flavors

**To end users:**
- Only distribute production app (`com.pottery.app`)
- Local and dev are for internal testing only

**To testers:**
- May distribute dev app for beta testing
- Still avoid distributing local (requires Docker)

---

## Migration Guide

### From Single-App to Multi-App

If you have an existing single-app Flutter project:

**1. Add flavor dimension:**
```kotlin
// android/app/build.gradle.kts
flavorDimensions += "environment"
```

**2. Create flavors:**
```kotlin
productFlavors {
    create("dev") {
        dimension = "environment"
        applicationId = "com.yourapp.dev"
        resValue("string", "app_name", "Your App Dev")
    }
    create("prod") {
        dimension = "environment"
        applicationId = "com.yourapp"
        resValue("string", "app_name", "Your App")
    }
}
```

**3. Update build commands:**
```bash
flutter build apk --flavor dev
flutter build apk --flavor prod
```

**4. Pass configuration:**
```bash
flutter build apk \
  --dart-define=API_BASE_URL=https://api-dev.example.com \
  --flavor dev
```

---

## Related Concepts

### Environment Variables vs Flavors

**Flavors** (build-time):
- Different package IDs
- Different app names
- Baked into APK/IPA
- Can't change after build

**Environment Variables** (runtime):
- Can change after build (with rebuild)
- Configuration values
- API URLs, feature flags
- Passed via `--dart-define`

**Use both together:**
```bash
flutter build apk \
  --flavor dev \                     # Flavor: package ID
  --dart-define=API_BASE_URL=...     # Env var: runtime config
```

### Build Modes vs Flavors

**Build Modes:**
- Debug (development)
- Release (optimized)
- Profile (performance testing)

**Flavors:**
- Local (environment)
- Dev (environment)
- Prod (environment)

**They're independent:**
```bash
# Dev flavor, debug mode
flutter build apk --flavor dev --debug

# Dev flavor, release mode
flutter build apk --flavor dev --release

# Prod flavor, debug mode (for testing)
flutter build apk --flavor prod --debug
```

---

## Summary

The multi-app build system provides:

1. **Independent Apps** - Three separate installations with unique package IDs
2. **Coexistence** - All versions can run on same device
3. **Environment Isolation** - Each app targets different backend
4. **Development Efficiency** - No uninstall/reinstall cycles
5. **Easy Comparison** - Side-by-side testing across environments

**Key takeaway:** Multi-app system optimizes the development workflow by eliminating friction between environment changes, enabling faster iteration and more thorough testing.

---

## Further Reading

- [Build Scripts Reference](../reference/build-scripts.md)
- [Build & Deploy Guide](../how-to/build-and-deploy.md)
- [Local Development Guide](../getting-started/local-development.md)
- [Flutter Product Flavors](https://flutter.dev/docs/deployment/flavors)
- [Android Product Flavors](https://developer.android.com/studio/build/build-variants)
