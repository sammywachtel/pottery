# Troubleshooting Guide

Common issues and solutions for the Pottery Catalog Application.

## 🚨 Quick Fixes

### Backend Issues

#### Docker Backend Won't Start

**Symptom**: `./run_docker_local.sh` fails or container exits immediately

**Solutions**:
```bash
# 1. Check Docker is running
docker --version
docker ps

# 2. Verify environment file exists
ls -la backend/.env.local

# 3. Check for port conflicts
lsof -i :8000

# 4. Rebuild container
cd backend
docker-compose down
docker-compose build --no-cache
./run_docker_local.sh

# 5. Check container logs
docker logs pottery-backend-container
```

#### API Returns 500 Errors

**Symptom**: Backend starts but API calls return "Internal Server Error"

**Solutions**:
```bash
# 1. Check environment variables
docker exec pottery-backend-container env | grep GCP

# 2. Verify service account key
ls -la /Users/$(whoami)/.gsutil/pottery-app-sa-*.json

# 3. Test Firebase connectivity
docker exec pottery-backend-container python -c "
from firebase_admin import credentials, initialize_app
print('Firebase test passed')
"

# 4. Check Firestore access
curl -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://firestore.googleapis.com/v1/projects/pottery-app-456522/databases/(default)/documents"
```

#### Authentication Errors

**Symptom**: "Failed to verify Firebase token" errors

**Solutions**:
```bash
# 1. Verify Firebase project ID
firebase projects:list

# 2. Check service account permissions
gcloud projects get-iam-policy pottery-app-456522 \
  --filter="bindings.members:*pottery-app-sa*"

# 3. Regenerate service account key
gcloud iam service-accounts keys create new-key.json \
  --iam-account=pottery-app-sa@pottery-app-456522.iam.gserviceaccount.com

# 4. Update environment file with new key path
vim backend/.env.local
```

### Frontend Issues

#### Flutter Build Fails

**Symptom**: `flutter run` shows compilation errors

**Solutions**:
```bash
# 1. Clean and rebuild
cd frontend
flutter clean
flutter pub get

# 2. Check Flutter version
flutter --version
flutter upgrade

# 3. Check for dependency conflicts
flutter pub deps

# 4. Clear web cache
flutter clean
rm -rf build/
flutter build web
```

#### Firebase Authentication Popup Blocked

**Symptom**: Google Sign-In doesn't open popup or shows popup blocked error

**Solutions**:
1. **Browser Settings**: Allow popups for `localhost:9100`
2. **Chrome**: Settings → Privacy and Security → Site Settings → Pop-ups and redirects
3. **Firefox**: Preferences → Privacy & Security → Permissions → Block pop-up windows
4. **Safari**: Preferences → Websites → Pop-up Windows

**Alternative**:
```bash
# Use different port if blocked
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --web-hostname localhost \
  --web-port 9101
```

#### OAuth redirect_uri_mismatch

**Symptom**: "Error 400: redirect_uri_mismatch" during Google Sign-In

**Solutions**:
1. **Check OAuth Client Configuration**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
   - Edit OAuth 2.0 Client ID
   - Add authorized redirect URIs:
     ```
     http://localhost:9100/__/auth/handler
     http://127.0.0.1:9100/__/auth/handler
     ```

2. **Verify Flutter port**:
   ```bash
   # Check which port Flutter is using
   flutter run -d chrome --verbose
   ```

3. **Update OAuth configuration** to match actual port

### Database Issues

#### Firestore Permission Denied

**Symptom**: "Missing or insufficient permissions" errors

**Solutions**:
```bash
# 1. Check Firestore security rules
firebase firestore:rules:get --project pottery-app-456522

# 2. Verify user authentication
# In browser console (F12):
firebase.auth().currentUser

# 3. Test with temporary open rules (development only)
firebase firestore:rules:set --project pottery-app-456522 \
  --source=<(echo 'rules_version = "2"; service cloud.firestore { match /databases/{database}/documents { match /{document=**} { allow read, write: if true; } } }')

# 4. Restore secure rules after testing
firebase firestore:rules:set --project pottery-app-456522 \
  --source=firestore.rules
```

#### Cloud Storage Access Denied

**Symptom**: Photo uploads fail with 403 errors

**Solutions**:
```bash
# 1. Check bucket permissions
gsutil iam get gs://pottery-app-456522-bucket

# 2. Verify service account has Storage Object Admin role
gcloud projects add-iam-policy-binding pottery-app-456522 \
  --member="serviceAccount:pottery-app-sa@pottery-app-456522.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# 3. Test bucket access
gsutil ls gs://pottery-app-456522-bucket

# 4. Check CORS configuration
gsutil cors get gs://pottery-app-456522-bucket
```

## 🔍 Diagnostic Commands

### Environment Validation

```bash
# Check all required tools
./scripts/check-prerequisites.sh

# Verify environment variables
cd backend && source .env.local && env | grep -E "(GCP|FIREBASE|JWT)"

# Test GCP authentication
gcloud auth list
gcloud projects list

# Test Firebase authentication
firebase login
firebase projects:list
```

### Service Health Checks

```bash
# Backend health
curl http://localhost:8000/
curl http://localhost:8000/api/docs

# Firebase connectivity
curl -X POST http://localhost:8000/api/test-token \
  -d "username=test&password=test" \
  -H "Content-Type: application/x-www-form-urlencoded"

# Database connectivity
docker exec pottery-backend-container python -c "
from services.firestore_service import FirestoreService
service = FirestoreService()
print('Firestore connection successful')
"
```

## 📊 Performance Issues

### Slow API Responses

**Symptoms**: API calls take >2 seconds

**Diagnostics**:
```bash
# 1. Check container resources
docker stats pottery-backend-container

# 2. Monitor API response times
curl -w "Time: %{time_total}s\n" http://localhost:8000/api/items

# 3. Check database query performance
# Enable Firestore debug logging in backend
```

**Solutions**:
- Add database indexes for frequently queried fields
- Implement caching for read-heavy operations
- Optimize container resource allocation

### High Memory Usage

**Symptoms**: Container uses >1GB RAM

**Solutions**:
```bash
# 1. Monitor memory usage
docker exec pottery-backend-container free -h

# 2. Check for memory leaks
docker exec pottery-backend-container python -c "
import psutil
process = psutil.Process()
print(f'Memory: {process.memory_info().rss / 1024 / 1024:.2f} MB')
"

# 3. Restart container
docker restart pottery-backend-container
```

## 🌐 Network Issues

### CORS Errors

**Symptom**: "CORS policy" errors in browser console

**Solutions**:
```bash
# 1. Check CORS configuration in backend
grep -r "CORS" backend/

# 2. Verify allowed origins
curl -H "Origin: http://localhost:9100" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: X-Requested-With" \
  -X OPTIONS http://localhost:8000/api/items

# 3. Check if backend is accessible
curl -I http://localhost:8000/
```

### SSL/TLS Issues in Production

**Symptoms**: Mixed content errors, certificate warnings

**Solutions**:
1. **Verify HTTPS endpoints**: Ensure all API calls use HTTPS in production
2. **Check certificate validity**: Use browser dev tools to inspect certificate
3. **Update Firebase configuration**: Ensure `authDomain` uses HTTPS

## 🔐 Authentication & Authorization

### Token Expiration Issues

**Symptoms**: Intermittent authentication failures, "token expired" errors

**Solutions**:
```bash
# 1. Check token expiration time
# In browser console:
firebase.auth().currentUser.getIdTokenResult().then(result => {
  console.log('Token expires at:', new Date(result.expirationTime))
})

# 2. Implement automatic token refresh
# Check if Firebase Auth handles this automatically in your implementation

# 3. Add token refresh logic
# In your Flutter app authentication service
```

### Service Account Issues

**Symptoms**: "Service account not found" or "Invalid service account" errors

**Solutions**:
```bash
# 1. Verify service account exists
gcloud iam service-accounts list --project pottery-app-456522

# 2. Check service account key
gcloud iam service-accounts keys list \
  --iam-account=pottery-app-sa@pottery-app-456522.iam.gserviceaccount.com

# 3. Recreate service account if needed
gcloud iam service-accounts create pottery-app-sa \
  --display-name="Pottery App Service Account" \
  --project pottery-app-456522
```

## 🚨 Emergency Procedures

### Complete System Reset

```bash
# 1. Stop all services
docker-compose down
pkill -f "flutter run"

# 2. Clean Docker
docker system prune -a

# 3. Reset Flutter
cd frontend
flutter clean
rm -rf build/
flutter pub get

# 4. Reset backend
cd backend
rm -rf __pycache__/
pip install -r requirements.txt

# 5. Restart services
./run_docker_local.sh
# In new terminal:
cd frontend && flutter run -d chrome
```

### Data Recovery

```bash
# 1. Check Firestore backups
gcloud firestore backups list --location=us-central1

# 2. Check Cloud Storage object versions
gsutil ls -la gs://pottery-app-456522-bucket/

# 3. Restore from backup if needed
gcloud firestore import gs://pottery-app-456522-backup/latest
```

## 📝 Logging & Debugging

### Enable Debug Logging

**Backend**:
```python
# Add to main.py
import logging
logging.basicConfig(level=logging.DEBUG)
```

**Frontend**:
```dart
// Add to main.dart
import 'dart:developer' as developer;

void main() {
  // Enable detailed logging
  developer.log('App starting...', name: 'pottery_app');
  runApp(MyApp());
}
```

### Log Locations

- **Backend Container**: `docker logs pottery-backend-container`
- **Frontend Console**: Browser Developer Tools → Console
- **Firebase**: Firebase Console → Functions → Logs
- **Cloud Run**: GCP Console → Cloud Run → Service → Logs

## 📞 Getting Help

### Self-Service Resources

1. **Check Documentation**: [docs/](../README.md)
2. **Search Issues**: [GitHub Issues](../../issues)
3. **API Documentation**: http://localhost:8000/api/docs
4. **Firebase Console**: [Firebase Console](https://console.firebase.google.com)
5. **GCP Console**: [Google Cloud Console](https://console.cloud.google.com)

### Reporting Issues

When reporting issues, please include:

1. **Environment**: Development/Testing/Production
2. **Steps to Reproduce**: Exact commands or actions
3. **Expected vs Actual**: What should happen vs what actually happens
4. **Error Messages**: Complete error text and stack traces
5. **System Info**: OS, browser, Docker version, Flutter version
6. **Logs**: Relevant log entries from backend and frontend

### Common Log Patterns

**Look for these patterns in logs:**

```bash
# Authentication issues
grep -i "auth\|token\|firebase" logs.txt

# Database issues
grep -i "firestore\|permission\|denied" logs.txt

# Network issues
grep -i "cors\|connection\|timeout" logs.txt

# Performance issues
grep -i "slow\|timeout\|memory" logs.txt
```

---

*Next: [Monitoring Guide](./monitoring.md)*
