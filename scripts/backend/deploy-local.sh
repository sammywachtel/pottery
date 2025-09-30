#!/bin/bash

# Backend Local Docker Deployment Script
# Deploys backend locally using Docker for development
# Points to: http://localhost:8000

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
CONFIG_DIR="$SCRIPT_DIR/../config"

echo "🚀 Deploying Backend Locally with Docker"
echo "========================================="

# Load environment configuration
source "$CONFIG_DIR/env.local.sh"

# Navigate to backend directory
cd "$BACKEND_DIR"

# Run the local Docker script
./run_docker_local.sh

echo "✅ Backend is running locally at http://localhost:8000"
echo "📋 API Documentation: http://localhost:8000/api/docs"
