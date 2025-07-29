#!/bin/bash

echo "🐳 Simple Frontend Docker Build Test"

cd frontend

echo "🧹 Cleaning previous builds..."
docker rmi frontend-simple:latest 2>/dev/null || true

echo "🏗️ Building simple frontend image..."
docker build -f Dockerfile.simple -t frontend-simple:latest . --progress=plain

echo "🚀 Testing container startup..."
docker run --rm -d --name frontend-test -p 3001:3000 frontend-simple:latest

echo "⏰ Waiting 15 seconds for startup..."
sleep 15

echo "🔍 Testing health endpoint..."
curl -f http://localhost:3001/ || echo "❌ Health check failed"

echo "🛑 Stopping test container..."
docker stop frontend-test 2>/dev/null || true

echo "✅ Frontend Docker test completed!"
