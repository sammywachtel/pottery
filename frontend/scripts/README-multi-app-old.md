# Multi-App Build System

This Flutter project now supports three separate app installations on your device:

## App Versions

| App Name | Package ID | Environment | Backend URL | Script |
|----------|------------|-------------|-------------|---------|
| **Pottery Studio Local** | `com.pottery.app.local` | Development | Local Docker (http://IP:8000) | `build_dev.sh` (option 1) |
| **Pottery Studio Dev** | `com.pottery.app.dev` | Development | Google Cloud Run dev | `build_dev.sh` (option 2) |
| **Pottery Studio** | `com.pottery.app` | Production | Google Cloud Run prod | `build_prod.sh` |

## Usage Examples

### Build Local Development Version
```bash
cd scripts
./build_dev.sh
# Select option 1: "Pottery Studio Local"
```

### Build Dev Cloud Version
```bash
cd scripts
./build_dev.sh
# Select option 2: "Pottery Studio Dev"
```

### Build Production Version
```bash
cd scripts
./build_prod.sh
```

### Clean Install (Remove All Previous Versions)
```bash
CLEAN_INSTALL=true ./build_dev.sh
```

### Environment Variable Override
```bash
# Build specific flavor with custom backend
FLAVOR=local API_BASE_URL=http://192.168.1.100:8000 ./build_dev.sh

# Build dev flavor with custom backend
FLAVOR=dev API_BASE_URL=https://custom-api.example.com ./build_dev.sh
```

## Benefits

- **Parallel Testing**: Test local, dev, and prod versions simultaneously
- **No Conflicts**: Each app has unique package ID and name
- **Easy Switching**: Quickly compare different backend environments
- **Clean Builds**: Option to remove old versions when needed

## Technical Details

- Uses Android Gradle product flavors for package separation
- Dynamic app names configured in `build.gradle.kts`
- Separate package IDs prevent installation conflicts
- All three apps can coexist on the same device

## Notes

- Local version connects to Docker backend on your Mac
- Dev version connects to Google Cloud Run development environment
- Prod version connects to production environment
- Each app maintains separate data and settings
