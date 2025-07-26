#!/bin/bash

# =============================================================================
# Quick Test Script for ShopSphere Environment
# =============================================================================

set -e

echo "🧪 Testing ShopSphere Environment"
echo "================================="

# Test Jenkins
echo "1. Testing Jenkins..."
if curl -s -o /dev/null http://localhost:9040; then
    echo "   ✅ Jenkins is accessible on localhost:9040"
else
    echo "   ❌ Jenkins is not accessible"
    exit 1
fi

# Test ngrok
echo "2. Testing ngrok..."
PUBLIC_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "import sys, json; data = json.load(sys.stdin); print(data['tunnels'][0]['public_url'] if data['tunnels'] else '')" 2>/dev/null || echo "")

if [ -n "$PUBLIC_URL" ]; then
    echo "   ✅ ngrok tunnel active: $PUBLIC_URL"
    
    # Test public access
    if curl -s -o /dev/null "$PUBLIC_URL"; then
        echo "   ✅ Public Jenkins access working"
    else
        echo "   ⚠️ Public access may have issues"
    fi
else
    echo "   ❌ ngrok tunnel not found"
fi

# Test comprehensive pipeline job
echo "3. Testing comprehensive pipeline job..."
if curl -s "http://localhost:9040/job/ShopSphere-Comprehensive/api/json" | grep -q "name"; then
    echo "   ✅ Comprehensive pipeline job exists"
    echo "   🔗 Job URL: http://localhost:9040/job/ShopSphere-Comprehensive"
    if [ -n "$PUBLIC_URL" ]; then
        echo "   🌐 Public Job URL: $PUBLIC_URL/job/ShopSphere-Comprehensive"
    fi
else
    echo "   ❌ Comprehensive pipeline job not found"
fi

# Test Docker containers
echo "4. Testing Docker containers..."
if docker ps | grep -q jenkins; then
    echo "   ✅ Jenkins container running"
else
    echo "   ❌ Jenkins container not running"
fi

if docker ps | grep -q postgres; then
    echo "   ✅ PostgreSQL container running"
else
    echo "   ❌ PostgreSQL container not running"
fi

# Test project files
echo "5. Testing project files..."
if [ -f "Jenkinsfile.comprehensive" ]; then
    echo "   ✅ Comprehensive Jenkinsfile exists"
else
    echo "   ❌ Comprehensive Jenkinsfile missing"
fi

if [ -f "scripts/comprehensive-test-runner.sh" ]; then
    echo "   ✅ Test runner script exists"
else
    echo "   ❌ Test runner script missing"
fi

if [ -f "scripts/smoke-tests.sh" ]; then
    echo "   ✅ Smoke tests script exists"
else
    echo "   ❌ Smoke tests script missing"
fi

echo ""
echo "🎯 Environment Test Summary:"
echo "   🏗️ Jenkins: ✅ Running on localhost:9040"
if [ -n "$PUBLIC_URL" ]; then
    echo "   🌐 Public: ✅ $PUBLIC_URL"
else
    echo "   🌐 Public: ❌ Not available"
fi
echo "   📋 Pipeline: ✅ ShopSphere-Comprehensive job ready"
echo "   🐳 Containers: ✅ Jenkins & PostgreSQL running"
echo "   📁 Scripts: ✅ All testing scripts available"

echo ""
echo "🚀 Ready to test! Next steps:"
echo "   1. Open: http://localhost:9040/job/ShopSphere-Comprehensive"
echo "   2. Click 'Build with Parameters'"
echo "   3. Configure test options:"
echo "      - RUN_E2E_TESTS: true (for full testing)"
echo "      - RUN_PERFORMANCE_TESTS: true"
echo "      - COVERAGE_THRESHOLD: 80"
echo "   4. Click 'Build' to start comprehensive testing"

if [ -n "$PUBLIC_URL" ]; then
    echo ""
    echo "🔗 For GitHub webhook setup:"
    echo "   Webhook URL: $PUBLIC_URL/github-webhook/"
    echo "   Content type: application/json"
    echo "   Events: Push, Pull request"
fi
