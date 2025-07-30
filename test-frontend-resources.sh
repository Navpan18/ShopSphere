#!/bin/bash

echo "🚀 Testing Frontend with High Resources"

cd frontend

echo "📊 System Resources Check:"
echo "Available Memory: $(free -h | grep Mem | awk '{print $7}')"
echo "Available CPU: $(nproc) cores"

echo "🏗️ Building Frontend with High Memory..."
export NODE_OPTIONS="--max-old-space-size=4096"
export NEXT_TELEMETRY_DISABLED=1

echo "📦 Installing dependencies..."
npm install --legacy-peer-deps --no-audit --no-fund

echo "🔨 Building application..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend build successful with high resources!"
else
    echo "❌ Frontend build failed - need even more resources?"
fi
