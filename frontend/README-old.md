# Pottery Frontend (Flutter)

A Flutter application that provides a full-featured interface for the pottery inventory backend. The app targets web, iOS, and Android and is ready for deployment on Google Cloud Platform (GCP).

## Prerequisites

- Flutter SDK >= 3.19 (3.22 recommended) with Dart >= 3.3
- Run `flutter create .` inside `frontend/` once if platform folders (android/ios/web) are missing
- Android/iOS toolchains as required for mobile builds
- For web builds: Chrome (for `flutter run -d chrome`)
- Google Cloud SDK (for deployment)
- Backend API reachable via HTTPS (Cloud Run URL or local instance)

## Project structure

```
frontend/
  lib/
    src/
      app.dart                     # Root MaterialApp
      config/app_config.dart       # Environment config (API base URL)
      core/app_exception.dart      # Domain exceptions
      data/                        # Models, repositories, API client
      features/
        auth/                      # Login state & view
        items/                     # Item listing, detail, forms
        photos/                    # Photo upload workflow
      widgets/                     # Shared widgets (splash)
  assets/stages.json               # Stage metadata for dropdowns
  deployment/                      # Docker/nginx assets for web hosting
  Dockerfile                       # Multi-stage build for Cloud Run
  cloudbuild.yaml                  # Example Cloud Build pipeline
```

## Configuration

The app reads the API base URL from `API_BASE_URL` using `--dart-define`. Defaults to `http://localhost:8000` for local work. For production builds (web or mobile) override the value:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://pottery-api.yourcompany.dev
flutter build web --dart-define=API_BASE_URL=$PROD_API_URL
```

## Local development

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

For Android or iOS targets pick the appropriate device (`flutter devices`) and pass the same `--dart-define`.

### Testing & analysis

```bash
flutter analyze
flutter test
```

## Building for production (web)

```bash
flutter build web --release --dart-define=API_BASE_URL=https://pottery-api.example.com
```

The compiled assets are written to `build/web`. They can be served by any static host (e.g., Cloud Storage + Cloud CDN) or containerized via the provided Dockerfile.

## GCP deployment (Cloud Run)

The included `Dockerfile` builds the Flutter web bundle and serves it with nginx. An example Cloud Build pipeline is provided in `cloudbuild.yaml`.

### Build & deploy manually

```bash
cd frontend
PROJECT_ID="your-gcp-project"
REGION="us-central1"
IMAGE="gcr.io/$PROJECT_ID/pottery-frontend:latest"
API_BASE="https://pottery-api-1073709451179.us-central1.run.app"

docker build \
  --build-arg API_BASE_URL=$API_BASE \
  -t $IMAGE .

gcloud run deploy pottery-frontend \
  --image $IMAGE \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated
```

### Using Cloud Build

The `cloudbuild.yaml` expects two substitutions:

- `_API_BASE_URL` – backend endpoint for the production build
- `IMAGE` – Artifact Registry/Container Registry target (defaults provided)

Trigger Cloud Build with:

```bash
gcloud builds submit . --config=cloudbuild.yaml --substitutions=_API_BASE_URL=$API_BASE
```

Cloud Run will serve the compiled SPA on port 8080. The nginx configuration rewrites unknown routes to `index.html`, keeping Flutter routing functional.

## Environment variables for runtime

Because Flutter web apps bake the base URL at build time, ensure the `API_BASE_URL` passed during build points to the correct backend environment. For multi-environment support, build separate images (e.g., staging vs production) with the corresponding API value.

## Next steps

- Configure Google Cloud IAM/Secrets for storing API credentials if required.
- Set up HTTPS Load Balancer or Cloud CDN in front of Cloud Run for better performance.
- Integrate CI to run `flutter analyze` and `flutter test` before build triggers.
