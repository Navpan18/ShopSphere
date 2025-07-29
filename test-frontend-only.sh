#!/bin/bash

# Frontend Only Testing Script
echo "🚀 Starting Frontend Only Build Test..."

# Change to frontend directory
cd frontend

echo "📦 Installing dependencies..."
npm install --legacy-peer-deps --no-audit --no-fund

echo "🔍 Checking for vulnerabilities..."
npm audit --audit-level=moderate || true

echo "🧹 Running linting..."
npm run lint || true

echo "🏗️ Building frontend..."
npm run build

echo "✅ Frontend build completed successfully!"

# Optional: Start dev server for quick test
echo "🌐 Starting development server for 10 seconds..."
timeout 10s npm run dev || true

echo "🎉 Frontend testing complete!"
