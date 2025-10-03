# Interactive Deployment Script

Quick deployment tool for Pottery App across all environments.

## Quick Start

```bash
# From project root
./scripts/deploy.sh

# Or from scripts directory
cd scripts
./deploy.sh
```

## Current Features (Local/Docker Only)

### Deployment Options

1. **Backend Only** - Deploys local Docker backend
   - Starts Docker container with backend API
   - Accessible at `http://{YOUR_IP}:8000`
   - API docs at `http://{YOUR_IP}:8000/api/docs`

2. **Frontend Only** - Builds and deploys Flutter app
   - Auto-detects USB-connected Android device
   - Installs debug build to device if connected
   - Always builds AAB for Play Store upload
   - Configures app to connect to local Docker backend

3. **Both** - Full stack deployment
   - Deploys backend Docker container
   - Builds and installs frontend to USB device
   - Builds AAB for Play Store

### Features

✅ **Auto-detect USB device** - Finds connected Android phones via adb
✅ **Auto-build AAB** - Always creates app bundle for Play Store
✅ **Smart IP detection** - Automatically finds your local network IP
✅ **Post-deployment instructions** - Shows next steps after completion
✅ **Color-coded output** - Easy to read progress and status

### What Gets Built

**Backend:**
- Docker container: `pottery-backend-local`
- Port: 8000
- Environment: local

**Frontend:**
- Flavor: local
- App Name: "Pottery Studio Local"
- Package: com.pottery.app.local
- Backend URL: `http://{YOUR_LOCAL_IP}:8000`
- Outputs:
  - Debug APK (if USB device connected)
  - AAB: `frontend/build/app/outputs/bundle/localRelease/app-local-release.aab`

## Requirements

### Backend Deployment
- Docker installed and running
- Port 8000 available

### Frontend Deployment
- Flutter SDK installed
- Android SDK installed (for adb)
- USB device with USB debugging enabled (optional, for device installation)
  - **First time:** Device will prompt "Allow USB debugging?" - tap Allow
  - **After authorization:** Connection is automatic when plugged in
- Backend running (for testing)

## Post-Deployment

After successful deployment, the script shows:

1. **Backend info** - URL, API docs, health check endpoint
2. **Frontend info** - Installed app details, USB device name
3. **AAB location** - Where to find app bundle for Play Store upload
4. **Testing instructions** - How to verify deployment
5. **Documentation links** - Where to find more info

## Coming Soon

🚧 **Dev Environment Support**
- Deploy to Google Cloud Run (dev)
- Build with dev backend URL
- gcloud authentication check

🚧 **Prod Environment Support**
- Deploy to Google Cloud Run (prod)
- IAM role verification
- Production safety checks

🚧 **Enhanced Features**
- Custom app naming for sideloaded apps ("SL" suffix)
- Automatic version bumping
- Deployment history tracking

## Examples

### Backend Only
```bash
./scripts/deploy.sh
# Choose: 1 (Backend Only)
# Result: Docker container running on port 8000
```

### Frontend with USB Device
```bash
# Connect Android device via USB
./scripts/deploy.sh
# Choose: 2 (Frontend Only)
# Result: App installed on device + AAB built
```

### Full Stack
```bash
./scripts/deploy.sh
# Choose: 3 (Both)
# Result: Backend running + App on device + AAB built
```

## Troubleshooting

### "No USB device detected" or "Device unauthorized"
**First-time setup:**
1. Enable USB debugging on device:
   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable "USB Debugging"
2. Connect device via USB
3. Tap "Allow" on device when prompted "Allow USB debugging?"
4. Connection will be automatic on subsequent plugs

**If previously authorized:**
- Disconnect and reconnect USB cable
- Run `adb devices` to verify connection shows "device" (not "unauthorized")
- Try `adb kill-server && adb start-server`

**Script behavior:**
- Detects unauthorized devices and waits 10 seconds for authorization
- Shows helpful prompts to tap "Allow" on device
- Automatically retries after authorization

### "Port 8000 already in use"
- Stop existing backend: `docker stop pottery-backend-local`
- Or kill process: `lsof -ti:8000 | xargs kill`

### "Docker not found"
- Install Docker Desktop
- Start Docker daemon
- Verify with `docker ps`

### "Flutter not found"
- Install Flutter SDK
- Add to PATH
- Verify with `flutter doctor`

## Related Documentation

- [Main Scripts README](README.md)
- [Backend Deployment](../backend/docs/how-to/deploy-environments.md)
- [Frontend Build Scripts](../frontend/scripts/README.md)
- [Google Play Deployment](DEPLOYMENT_GUIDE.md)
