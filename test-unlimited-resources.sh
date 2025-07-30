#!/bin/bash

echo "🚀 Testing Frontend with UNLIMITED Resources"

cd frontend

echo "📊 System Resources Check:"
echo "Available Memory: $(free -h 2>/dev/null || echo 'macOS - using vm_stat')"
echo "Available CPU: $(nproc 2>/dev/null || sysctl -n hw.ncpu) cores"
echo "Node Version: $(node --version)"
echo "NPM Version: $(npm --version)"

echo "🏗️ Setting UNLIMITED Memory for Node.js..."
export NODE_OPTIONS="--max-old-space-size=8192"
export NEXT_TELEMETRY_DISABLED=1
export NODE_ENV=production

echo "📦 Installing dependencies with unlimited resources..."
npm install --legacy-peer-deps --no-audit --no-fund --verbose

if [ $? -ne 0 ]; then
    echo "❌ NPM install failed!"
    exit 1
fi

echo "🧹 Cleaning cache..."
npm cache clean --force

echo "🔨 Building application with 8GB memory limit..."
time npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend build SUCCESSFUL with unlimited resources!"
    echo "📊 Build completed at: $(date)"
    
    # Show build artifacts
    echo "📁 Build artifacts:"
    ls -la .next/ 2>/dev/null || echo "No .next directory found"
    
else
    echo "❌ Frontend build FAILED even with unlimited resources!"
    echo "🔍 Checking for common issues..."
    
    # Check disk space
    echo "💾 Disk space:"
    df -h .
    
    # Check for specific errors
    echo "🔍 Last few lines of npm output:"
    npm run build 2>&1 | tail -10
fi
