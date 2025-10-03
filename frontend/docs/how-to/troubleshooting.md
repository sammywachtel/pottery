# Troubleshooting Guide

Common issues and solutions for the Pottery Flutter app.

---

## Debugging Production App

### View Live Logs via ADB

To debug a production app installed on a device:

```bash
# Clear previous logs and watch new ones
adb logcat -c && adb logcat | grep -i flutter

# More comprehensive filtering (errors + Flutter messages)
adb logcat -c && adb logcat *:E Flutter:V
```

**What this shows:**
- All Flutter debug messages
- Error messages from the app
- Unhandled exceptions
- Firebase initialization issues

### Build Debug Version with Production Settings

For better error messages, build a debug APK with production configuration:

```bash
cd frontend

# Build debug APK with prod flavor and backend URL
flutter build apk --debug \
  --flavor prod \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL=https://pottery-api-prod-89677836881.us-central1.run.app \
  --dart-define=DEBUG_ENABLED=true

# Install it
adb install -r build/app/outputs/flutter-apk/app-prod-debug.apk
```

**Why this helps:**
- No code obfuscation (readable stack traces)
- Full error messages
- Debug logging enabled
- Still connects to production backend

### Run with Debugger Attached

For interactive debugging:

```bash
# Find your device ID
flutter devices

# Launch with debugger
cd frontend
flutter run -d <device-id> \
  --flavor prod \
  --dart-define=API_BASE_URL=https://pottery-api-prod-89677836881.us-central1.run.app
```

**Debugger features:**
- Set breakpoints in code
- Inspect variables
- Hot reload changes
- Step through execution

---

## Common Issues

### App Stuck on Splash Screen

**Symptoms:** App opens but never leaves the loading screen

**Possible Causes:**
1. Firebase initialization failure
2. Network connectivity issues
3. Backend URL unreachable

**Solutions:**

**Check logs for Firebase errors:**
```bash
adb logcat -c && adb logcat | grep -i firebase
```

Common Firebase errors:
- `No matching client found for package name` - Missing `google-services.json` for this flavor
- `duplicate-app` - Firebase initialized twice (see fix below)

**Verify backend connectivity:**
```bash
# Test if backend is reachable
curl https://pottery-api-prod-89677836881.us-central1.run.app/

# Check SSL certificate
curl -v https://pottery-api-prod-89677836881.us-central1.run.app/ 2>&1 | grep -i ssl
```

### Firebase Duplicate App Error

**Error:** `[core/duplicate-app] A Firebase App named "[DEFAULT]" already exists`

**Cause:** Firebase is being initialized multiple times

**Solution:** This was fixed in the codebase by adding a check for existing Firebase apps before re-initialization. Update to the latest code and rebuild.

### Build Failures

**Clean build cache:**
```bash
cd frontend
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

### Can't Connect to Backend

**Check backend is running:**
```bash
# For local Docker backend
docker ps | grep pottery-backend

# For Cloud Run backend
curl https://pottery-api-prod-89677836881.us-central1.run.app/
```

**Verify your Mac's IP (for local development):**
```bash
ifconfig en0 | grep inet
```

**Check API URL in app:**
Look for this in logs when app starts:
```
🔗 API Base URL: https://...
```

### Authentication Issues

**Clear app data and retry:**
```bash
adb shell pm clear com.pottery.app
```

**Verify Firebase Auth is configured:**
```bash
# Check Firebase Console
# Ensure Authentication is enabled
# Verify authorized domains include your backend URL
```

### Multi-App Conflicts

**Remove all installed versions:**
```bash
adb uninstall com.pottery.app.local
adb uninstall com.pottery.app.dev
adb uninstall com.pottery.app
```

**Clean install:**
```bash
cd frontend/scripts
CLEAN_INSTALL=true ./build_dev.sh
```

---

## Platform-Specific Issues

### Android - Gradle Errors

```bash
cd frontend/android
./gradlew clean
cd ..
flutter build apk
```

### iOS - Signing Issues

```bash
# Open in Xcode
open ios/Runner.xcworkspace

# Check Signing & Capabilities tab
# Ensure provisioning profiles are valid
```

### Web - Build Optimization

```bash
# Better graphics performance
flutter build web --web-renderer canvaskit

# Smaller bundle size
flutter build web --web-renderer html
```

---

## Getting More Help

**Check logs with timestamps:**
```bash
adb logcat -v time | grep -i flutter
```

**Export logs to file:**
```bash
adb logcat -d > app_logs.txt
```

**Verify ADB connection:**
```bash
adb devices  # Should show your device
```

**Restart ADB server:**
```bash
adb kill-server
adb start-server
```

---

## Related Documentation

- [Build & Deploy Guide](./build-and-deploy.md)
- [Local Development](../getting-started/local-development.md)
- [Build Scripts Reference](../reference/build-scripts.md)
- [Flutter Debugging Documentation](https://flutter.dev/docs/testing/debugging)
