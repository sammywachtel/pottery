# Flutter Mobile App Debugging Guide

This guide covers debugging the Flutter mobile app during development and testing.

## Quick Reference

### Essential Commands
```bash
# Always run from frontend directory
cd pottery-backend/frontend

# Run app in debug mode
./scripts/build_dev.sh

# Monitor all Android logs (recommended)
adb logcat | grep -E "(pottery|google|auth|gms)"

# Monitor Flutter-specific logs only
flutter logs --verbose
```

## Android Testing Options

### Option 1: Android Emulator (Recommended for Development)

**Setup on macOS:**

1. **Install Android Studio**:
   ```bash
   # Download from https://developer.android.com/studio
   # Or via Homebrew:
   brew install --cask android-studio
   ```

2. **Create Virtual Device**:
   - Open Android Studio
   - Tools → AVD Manager → "Create Virtual Device"
   - Choose **Pixel 7** or **Pixel 8** (excellent Google Services support)
   - Select **API 34 (Android 14)** with Google Play Services
   - Download system image if needed

3. **Start Emulator**:
   ```bash
   # Command line (faster):
   ~/Library/Android/sdk/emulator/emulator @Pixel_7_API_34

   # Or use AVD Manager in Android Studio
   ```

4. **Verify Flutter Detection**:
   ```bash
   flutter devices
   # Should show: Pixel 7 API 34 (mobile) • emulator-5554 • android-x64
   ```

**Emulator Benefits:**
- ✅ Clean Google Play Services (no device-specific auth issues)
- ✅ Easy to reset and test different scenarios
- ✅ Better debugging experience
- ✅ Can sign in with test Google accounts safely
- ✅ Root access for advanced debugging

### Option 2: Physical Android Device

**Prerequisites:**
1. **Enable Developer Options**:
   - Settings → About Phone → Tap "Build Number" 7 times

2. **Enable USB Debugging**:
   - Settings → Developer Options → USB Debugging

3. **Connect Device**:
   - USB cable (fastest) or Wireless Debugging (Android 11+)

**Verify Connection:**
```bash
# Check device is detected
adb devices

# Should show something like:
# R5CR81F5D0J    device
```

**Note**: Physical devices may have device-specific Google Play Services authentication issues. If you encounter persistent Google Sign-In errors despite correct Firebase configuration, try the emulator instead.

## Logging and Debugging

### Real-time Log Monitoring

**Option 1: ADB Logcat (Recommended)**
```bash
# All relevant logs (works for both emulator and device)
adb logcat | grep -E "(pottery|google|auth|gms|GoogleAuth|GoogleSignIn)"

# Authentication-focused
adb logcat | grep -i "sign.*in\|auth\|google.*error\|gms.*error"

# App-specific only
adb logcat | grep "com.pottery.app"

# Save logs to file
adb logcat | grep -E "(pottery|google|auth)" | tee debug_logs.txt

# For emulator: cleaner logs (less system noise)
adb -s emulator-5554 logcat | grep -E "(pottery|google|auth)"
```

**Option 2: Flutter Logs**
```bash
# Basic Flutter logs
flutter logs

# Verbose with timestamps
flutter logs --verbose

# Filtered output
flutter logs | grep -E "(error|exception|auth|google)"

# Target specific device/emulator
flutter logs -d emulator-5554
```

### Debug Session Setup

**For Android Emulator (Recommended):**
```bash
# Terminal 1: Start emulator
~/Library/Android/sdk/emulator/emulator @Pixel_7_API_34

# Terminal 2: Start app (once emulator is ready)
cd pottery-backend/frontend
./scripts/build_dev.sh

# Terminal 3: Monitor emulator logs (cleaner output)
cd pottery-backend/frontend
adb -s emulator-5554 logcat | grep -E "(pottery|google|auth|GoogleAuth)"

# Terminal 4: Backend (if testing local API)
cd pottery-backend/backend
./run_docker_local.sh
```

**For Physical Device:**
```bash
# Terminal 1: Start app
cd pottery-backend/frontend
./scripts/build_dev.sh

# Terminal 2: Monitor logs
cd pottery-backend/frontend
adb logcat | grep -E "(pottery|google|auth|GoogleAuth)"

# Terminal 3: Backend (if testing local API)
cd pottery-backend/backend
./run_docker_local.sh
```

**Note**: If you have both emulator and device connected, specify the target:
```bash
# Run on specific emulator
flutter run -d emulator-5554

# Run on specific device
flutter run -d R5CR81F5D0J
```

## Common Issues & Solutions

### Google Sign-In Errors

#### Error Code 10: Configuration Mismatch
**Symptom**: `PlatformException(sign_in_failed, ...ApiException: 10)`

**Cause**: SHA-1 fingerprint not configured in Firebase

**Solution**:
1. Get debug SHA-1 fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
   ```

2. Add to Firebase:
   - Go to [Firebase Console](https://console.firebase.google.com/project/pottery-app-456522/settings/general)
   - Find "PotteryStudio" Android app
   - Click "Add fingerprint"
   - Paste SHA-1 and save

3. Download updated config:
   - Download new `google-services.json`
   - Replace `android/app/google-services.json`

4. Clean and rebuild:
   ```bash
   flutter clean
   ./scripts/build_dev.sh
   ```

#### Error Code 12: Network/Backend Issues
**Symptom**: `PlatformException(sign_in_failed, ...ApiException: 12)`

**Cause**: Backend not running or network connectivity issues

**Solution**:
```bash
# Start backend
cd pottery-backend/backend
./run_docker_local.sh

# Check backend health
curl http://localhost:8000/
```

### Build Errors

#### Gradle Build Timeout
**Symptom**: Build takes extremely long or times out

**Expected**: First build can take 10-20 minutes
**Solutions**:
- Be patient on first build
- Ensure stable internet for dependency downloads
- Close other memory-intensive applications

#### Missing Android SDK Components
**Symptom**: Build errors mentioning missing SDK components

**Solution**:
```bash
# Open Android Studio and install missing components
# Or use command line:
sdkmanager "platforms;android-34"
sdkmanager "build-tools;34.0.0"
```

#### Package Name Mismatch
**Symptom**: Firebase authentication fails despite correct SHA-1

**Solution**: Verify package name consistency:
- Check `android/app/build.gradle`: `applicationId "com.pottery.app"`
- Check Firebase console: Android app should show `com.pottery.app`
- Check `google-services.json`: Should contain `"package_name": "com.pottery.app"`

### Runtime Issues

#### Firebase Configuration Missing
**Symptom**: App crashes on startup or Firebase features don't work

**Solution**:
```bash
# Verify config file exists
ls -la android/app/google-services.json

# Check file contents
cat android/app/google-services.json | grep "package_name"
```

#### Network Connection Issues
**Symptom**: API calls fail or timeout

**Solutions**:
- Verify backend is running: `curl http://localhost:8000/`
- Check device/emulator network connectivity
- Verify API_BASE_URL in environment config

#### App Permissions
**Symptom**: Features don't work despite proper configuration

**Solution**: Check Android app permissions:
- Settings → Apps → PotteryStudio → Permissions
- Ensure required permissions are granted

## Advanced Debugging

### Hot Reload/Restart
When app is running in debug mode:
- **Hot Reload**: Press `r` in terminal (preserves app state)
- **Hot Restart**: Press `R` in terminal (resets app state)
- **Quit**: Press `q` in terminal

### Environment Configuration
Debug builds automatically use:
- **Firebase Project**: pottery-app-456522 (development)
- **API Base URL**: http://localhost:8000
- **Debug Logging**: Enabled
- **Development Features**: Enabled

### Performance Monitoring
```bash
# Monitor CPU/Memory usage
adb shell top | grep com.pottery.app

# Monitor network requests
adb logcat | grep -i "http\|network\|request"

# Flutter performance overlay
# Add to app: flutter run --verbose
```

### Firebase Debug Logging
Add to your Flutter app for enhanced Firebase debugging:
```dart
// In main.dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Firebase debug logging
  if (kDebugMode) {
    FirebaseApp.configure(
      options: const FirebaseOptions(/* your config */),
    );
  }
}
```

## Troubleshooting Checklist

When debugging issues:

1. **Device Connection**:
   - [ ] Device shows in `adb devices`
   - [ ] USB debugging enabled
   - [ ] Developer options enabled

2. **Build Environment**:
   - [ ] Running from `pottery-backend/frontend` directory
   - [ ] Flutter SDK properly installed
   - [ ] Android SDK components installed

3. **Firebase Configuration**:
   - [ ] `google-services.json` exists and is valid
   - [ ] Package name matches (`com.pottery.app`)
   - [ ] SHA-1 fingerprint added to Firebase console

4. **Backend Connection** (if testing local API):
   - [ ] Backend running: `./run_docker_local.sh`
   - [ ] Backend health check: `curl http://localhost:8000/`
   - [ ] Correct API_BASE_URL in app config

5. **Logging Setup**:
   - [ ] ADB logcat monitoring active
   - [ ] Appropriate log filters applied
   - [ ] App running in debug mode

## Getting Help

If issues persist:
1. Capture logs with timestamps: `adb logcat -v time | grep pottery`
2. Note exact error messages and stack traces
3. Verify configuration matches this guide
4. Check Flutter and Firebase documentation for version-specific issues

## Useful Resources

- [Flutter Debugging Documentation](https://docs.flutter.dev/testing/debugging)
- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)
- [Android Debug Bridge (ADB)](https://developer.android.com/studio/command-line/adb)
- [Google Sign-In for Android](https://developers.google.com/identity/sign-in/android)
