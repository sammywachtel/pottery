# 🏺 Pottery App - Full Stack Project

A Flutter mobile app with FastAPI backend for managing pottery collections with photos.

## 🎯 Quick Start

**All deployment and setup scripts are centralized in the `scripts/` directory:**

```bash
# 📖 Read the comprehensive guide
cat scripts/README.md

# 🛠️ Initial setup (run once)
./scripts/setup/setup-dev-machine.sh
./scripts/setup/setup-firebase.sh

# 💻 Local development
./scripts/backend/deploy-local.sh      # Start backend locally
./scripts/frontend/build-local.sh     # Install "Pottery Studio Local" app

# 🧪 Development testing
./scripts/backend/deploy-dev.sh       # Deploy to Cloud Run dev
./scripts/frontend/build-dev.sh      # Install "Pottery Studio Dev" app

# 🚀 Production deployment
./scripts/backend/deploy-prod.sh      # Deploy to Cloud Run prod
./scripts/frontend/build-prod.sh     # Install "Pottery Studio" app
```

## 📱 Three-App System

This project supports **three independent app installations** on the same device:

| App Name | Package | Backend | Purpose |
|----------|---------|---------|---------|
| **Pottery Studio Local** | com.pottery.app.local | http://localhost:8000 | Local Docker testing |
| **Pottery Studio Dev** | com.pottery.app.dev | Google Cloud Run dev | Integration testing |
| **Pottery Studio** | com.pottery.app | Google Cloud Run prod | Production |

## 🗂️ Project Structure

```
pottery-backend/
├── scripts/              # 🎯 ALL deployment scripts (START HERE)
│   ├── README.md         # 📖 Comprehensive deployment guide
│   ├── backend/          # Backend deployment scripts
│   ├── frontend/         # Frontend build scripts
│   ├── config/           # Environment configurations
│   └── setup/            # Initial setup scripts
│
├── backend/              # FastAPI backend application
│   ├── main.py          # FastAPI app entry point
│   ├── routers/         # API endpoints
│   ├── services/        # Business logic
│   └── models.py        # Pydantic models
│
└── frontend/            # Flutter mobile application
    ├── lib/             # Dart source code
    ├── android/         # Android configuration
    └── scripts/         # Original build scripts (use central ones instead)
```

## 🔧 Key Features Implemented

### ✅ Multi-Environment Setup
- **Local Docker**: Fast development with hot reload
- **Cloud Run Dev**: Integration testing environment
- **Cloud Run Prod**: Production deployment

### ✅ Firebase Authentication
- Google Sign-In integration
- SHA-1 fingerprint configuration for all app flavors
- JWT token verification in backend

### ✅ Photo Management
- Cloud Storage integration with signed URLs
- Automatic photo upload and metadata storage
- Service account-based authentication for Cloud Run

### ✅ Development Experience
- Centralized deployment scripts
- Environment-specific configurations
- Comprehensive troubleshooting guide

## 🚨 Important Setup Notes

1. **SHA-1 Fingerprints**: Must be added to Firebase Console for all three apps
2. **Service Account Keys**: Required for signed URL generation in Cloud Run
3. **Environment Variables**: All centralized in `scripts/config/`
4. **Google Cloud Project**: Requires proper IAM permissions

## 📖 Documentation

- **🎯 [Main Deployment Guide](scripts/README.md)** - Start here for all deployments
- [Backend Details](backend/README.md) - FastAPI architecture and API docs
- [Frontend Details](frontend/README.md) - Flutter app structure
- [Environment Setup](scripts/setup/) - Initial configuration guides

## 🛟 Troubleshooting

Common issues and solutions are documented in [scripts/README.md](scripts/README.md#-troubleshooting):

- **Google Sign-In Error (ApiException: 10)** → SHA-1 fingerprint issue
- **Photos Not Loading** → Signed URL service account issue
- **Backend 501 Error** → Firebase configuration issue
- **Wrong Backend URL** → Build cache issue

## 🔗 Quick Links

- **Firebase Console**: https://console.firebase.google.com/project/pottery-app-456522
- **Google Cloud Console**: https://console.cloud.google.com/run?project=pottery-app-456522
- **API Documentation**: http://localhost:8000/api/docs (when running locally)
- **Development Backend**: https://pottery-api-dev-1073709451179.us-central1.run.app

---

**👉 Start with [`scripts/README.md`](scripts/README.md) for the complete deployment workflow.**
