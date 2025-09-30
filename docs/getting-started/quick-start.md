# Quick Start Guide

Get the Pottery App running locally in 5 minutes.

## 🚀 Prerequisites

- **Docker** installed and running
- **Flutter SDK** (latest stable)
- **Google Cloud CLI** (`gcloud`) configured
- **Firebase CLI** (`npm install -g firebase-tools`)

## ⚡ Quick Setup

### 1. Clone and Navigate
```bash
git clone <your-repo-url>
cd pottery-backend
```

### 2. Start Backend (Docker)
```bash
cd backend
./run_docker_local.sh
```
✅ Backend running at `http://localhost:8000`

### 3. Start Frontend
```bash
cd frontend
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --web-hostname localhost \
  --web-port 9100
```
✅ Frontend running at `http://localhost:9100`

## 🧪 Test Authentication

1. Open `http://localhost:9100`
2. Click "Sign in with Google"
3. Complete OAuth flow
4. Verify authentication works

## 📱 What's Running

| Service | URL | Purpose |
|---------|-----|---------|
| Backend API | `http://localhost:8000` | FastAPI server |
| Frontend App | `http://localhost:9100` | Flutter web app |
| API Docs | `http://localhost:8000/api/docs` | Swagger UI |
| Alternative Docs | `http://localhost:8000/api/redoc` | ReDoc UI |

## 🔍 Quick Commands

```bash
# View API documentation
open http://localhost:8000/api/docs

# Run backend tests
cd backend && pytest

# Run frontend tests
cd frontend && flutter test

# Check backend logs
cd backend && docker logs pottery-backend-container

# Hot reload frontend
# In Flutter terminal, press 'r'
```

## 🎯 Default Credentials

**Test JWT Authentication:**
- Username: `test`
- Password: `test`
- Endpoint: `POST /api/test-token`

**Firebase Authentication:**
- Use your Google account
- Configured for localhost development

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| Backend won't start | Check Docker is running, verify `.env.local` exists |
| Frontend build fails | Run `flutter clean && flutter pub get` |
| Auth popup blocked | Check browser popup settings |
| API calls fail | Verify backend is running and CORS is configured |

## 📖 Next Steps

- **Full Setup**: [Installation Guide](./installation.md)
- **Development**: [Development Guide](../development/development-guide.md)
- **Environment Config**: [Environment Setup](./environment-setup.md)
- **API Reference**: [API Documentation](../architecture/api-reference.md)

---

*Need help? Check the [Troubleshooting Guide](../operations/troubleshooting.md)*
