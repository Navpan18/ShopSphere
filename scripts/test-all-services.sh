#!/bin/bash

# Comprehensive Service Testing Script for ShopSphere
# Tests all services: backend, frontend, analytics, notifications

set -e

BACKEND_URL=${BACKEND_URL:-"http://localhost:8001"}
FRONTEND_URL=${FRONTEND_URL:-"http://localhost:3000"}
ANALYTICS_URL=${ANALYTICS_URL:-"http://localhost:8002"}
NOTIFICATIONS_URL=${NOTIFICATIONS_URL:-"http://localhost:8003"}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEALTH_CHECK_SCRIPT="$SCRIPT_DIR/service-health-check.sh"

echo "🚀 Starting comprehensive service testing..."
echo "Services to test:"
echo "  Backend: $BACKEND_URL"
echo "  Frontend: $FRONTEND_URL"
echo "  Analytics: $ANALYTICS_URL"
echo "  Notifications: $NOTIFICATIONS_URL"

# Test Backend Service
echo ""
echo "🐍 Testing Backend Service..."
$HEALTH_CHECK_SCRIPT "Backend API" "$BACKEND_URL/health"

# Test additional backend endpoints
echo "Testing backend API endpoints..."
curl -f "$BACKEND_URL/api/products" >/dev/null 2>&1 && echo "✅ Products API working" || echo "❌ Products API failed"
curl -f "$BACKEND_URL/api/users" >/dev/null 2>&1 && echo "✅ Users API working" || echo "❌ Users API failed"

# Test Frontend Service
echo ""
echo "⚛️ Testing Frontend Service..."
$HEALTH_CHECK_SCRIPT "Frontend" "$FRONTEND_URL"

# Test Analytics Service
echo ""
echo "📊 Testing Analytics Service..."
$HEALTH_CHECK_SCRIPT "Analytics Service" "$ANALYTICS_URL/health"

# Test analytics functionality
echo "Testing analytics event submission..."
curl -X POST "$ANALYTICS_URL/api/events" \
  -H "Content-Type: application/json" \
  -d '{"event_type": "test", "data": {"test": true}}' \
  >/dev/null 2>&1 && echo "✅ Analytics event submission working" || echo "❌ Analytics event submission failed"

# Test Notifications Service
echo ""
echo "📧 Testing Notifications Service..."
$HEALTH_CHECK_SCRIPT "Notifications Service" "$NOTIFICATIONS_URL/health"

# Test notifications functionality
echo "Testing notification sending..."
curl -X POST "$NOTIFICATIONS_URL/api/notifications" \
  -H "Content-Type: application/json" \
  -d '{"type": "test", "message": "Test notification", "recipient": "test@example.com"}' \
  >/dev/null 2>&1 && echo "✅ Notification sending working" || echo "❌ Notification sending failed"

# Test Cross-Service Communication
echo ""
echo "🔗 Testing Cross-Service Communication..."

# Test backend to analytics communication
echo "Testing backend → analytics communication..."
curl -X POST "$BACKEND_URL/api/analytics/track" \
  -H "Content-Type: application/json" \
  -d '{"event": "test_integration", "user_id": "test"}' \
  >/dev/null 2>&1 && echo "✅ Backend → Analytics communication working" || echo "❌ Backend → Analytics communication failed"

# Test backend to notifications communication
echo "Testing backend → notifications communication..."
curl -X POST "$BACKEND_URL/api/notify" \
  -H "Content-Type: application/json" \
  -d '{"message": "Test integration", "type": "info"}' \
  >/dev/null 2>&1 && echo "✅ Backend → Notifications communication working" || echo "❌ Backend → Notifications communication failed"

# Performance Testing
echo ""
echo "⚡ Running Quick Performance Tests..."

# Test response times
echo "Measuring response times..."
BACKEND_TIME=$(curl -w "%{time_total}" -o /dev/null -s "$BACKEND_URL/health")
FRONTEND_TIME=$(curl -w "%{time_total}" -o /dev/null -s "$FRONTEND_URL")
ANALYTICS_TIME=$(curl -w "%{time_total}" -o /dev/null -s "$ANALYTICS_URL/health")
NOTIFICATIONS_TIME=$(curl -w "%{time_total}" -o /dev/null -s "$NOTIFICATIONS_URL/health")

echo "Response times:"
echo "  Backend: ${BACKEND_TIME}s"
echo "  Frontend: ${FRONTEND_TIME}s"
echo "  Analytics: ${ANALYTICS_TIME}s"
echo "  Notifications: ${NOTIFICATIONS_TIME}s"

# Check if any service is too slow
if (( $(echo "$BACKEND_TIME > 2.0" | bc -l) )); then
    echo "⚠️ Backend response time is high: ${BACKEND_TIME}s"
fi

# Database Connectivity Test
echo ""
echo "🗄️ Testing Database Connectivity..."
curl -f "$BACKEND_URL/api/health/database" >/dev/null 2>&1 && echo "✅ Database connectivity working" || echo "❌ Database connectivity failed"

# Redis Connectivity Test
echo "Testing Redis Connectivity..."
curl -f "$BACKEND_URL/api/health/redis" >/dev/null 2>&1 && echo "✅ Redis connectivity working" || echo "❌ Redis connectivity failed"

echo ""
echo "🎉 Comprehensive service testing completed!"
