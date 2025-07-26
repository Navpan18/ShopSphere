#!/bin/bash

# =============================================================================
# ShopSphere Comprehensive Smoke Tests
# =============================================================================

set -e

ENVIRONMENT=${1:-staging}
BASE_URL_BACKEND="http://localhost:8000"
BASE_URL_FRONTEND="http://localhost:3000"

echo "🔍 Running comprehensive smoke tests for $ENVIRONMENT environment..."

# =============================================================================
# Helper Functions
# =============================================================================

log_success() {
    echo "✅ $1"
}

log_error() {
    echo "❌ $1"
    exit 1
}

log_info() {
    echo "ℹ️  $1"
}

check_service() {
    local service_name=$1
    local url=$2
    local expected_status=${3:-200}
    
    log_info "Checking $service_name at $url"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000")
    
    if [ "$response" = "$expected_status" ]; then
        log_success "$service_name is healthy (HTTP $response)"
    else
        log_error "$service_name failed health check (HTTP $response)"
    fi
}

# =============================================================================
# Backend Health Checks
# =============================================================================

echo "🐍 Testing Backend Services..."

# Health endpoint
check_service "Backend Health" "$BASE_URL_BACKEND/health"

# API documentation
check_service "API Documentation" "$BASE_URL_BACKEND/docs"

# Database connectivity
check_service "Database Health" "$BASE_URL_BACKEND/health/db"

# Redis connectivity
check_service "Redis Health" "$BASE_URL_BACKEND/health/redis"

# =============================================================================
# Frontend Health Checks
# =============================================================================

echo "⚛️ Testing Frontend Services..."

# Homepage
check_service "Frontend Homepage" "$BASE_URL_FRONTEND"

# Health check endpoint (if exists)
check_service "Frontend Health" "$BASE_URL_FRONTEND/api/health" "200"

# =============================================================================
# API Functionality Tests
# =============================================================================

echo "🔗 Testing API Functionality..."

# Test user registration
log_info "Testing user registration..."
registration_response=$(curl -s -X POST "$BASE_URL_BACKEND/auth/register" \
    -H "Content-Type: application/json" \
    -d '{
        "email": "smoke-test@example.com",
        "password": "smoketest123",
        "full_name": "Smoke Test User"
    }' \
    -w "%{http_code}" || echo "000")

if [[ "$registration_response" == *"201"* ]] || [[ "$registration_response" == *"400"* ]]; then
    log_success "User registration endpoint working"
else
    log_error "User registration failed (HTTP code in response: $registration_response)"
fi

# Test product listing
log_info "Testing product listing..."
products_response=$(curl -s -w "%{http_code}" "$BASE_URL_BACKEND/products" || echo "000")

if [[ "$products_response" == *"200"* ]]; then
    log_success "Product listing endpoint working"
else
    log_error "Product listing failed"
fi

# =============================================================================
# Database Tests
# =============================================================================

echo "🗃️ Testing Database Connectivity..."

# Test database migrations
log_info "Checking database schema..."
db_check=$(curl -s "$BASE_URL_BACKEND/health/db" | grep -o '"status":"healthy"' || echo "")

if [ -n "$db_check" ]; then
    log_success "Database schema is healthy"
else
    log_error "Database schema check failed"
fi

# =============================================================================
# Cache Tests
# =============================================================================

echo "⚡ Testing Cache Layer..."

# Test Redis connectivity
redis_check=$(curl -s "$BASE_URL_BACKEND/health/redis" | grep -o '"status":"healthy"' || echo "")

if [ -n "$redis_check" ]; then
    log_success "Redis cache is healthy"
else
    log_error "Redis cache check failed"
fi

# =============================================================================
# Microservices Tests
# =============================================================================

echo "🔧 Testing Microservices..."

# Test Analytics Service
if curl -s "http://localhost:8001/health" > /dev/null 2>&1; then
    log_success "Analytics service is running"
else
    log_info "Analytics service not accessible (may not be running)"
fi

# Test Notification Service
if curl -s "http://localhost:8002/health" > /dev/null 2>&1; then
    log_success "Notification service is running"
else
    log_info "Notification service not accessible (may not be running)"
fi

# =============================================================================
# Security Tests
# =============================================================================

echo "🔒 Running Security Smoke Tests..."

# Test HTTPS redirect (if applicable)
log_info "Testing security headers..."
security_headers=$(curl -s -I "$BASE_URL_BACKEND/health" | grep -E "(X-Frame-Options|X-Content-Type-Options|X-XSS-Protection)" || echo "")

if [ -n "$security_headers" ]; then
    log_success "Security headers detected"
else
    log_info "No security headers found (consider adding)"
fi

# Test CORS configuration
log_info "Testing CORS configuration..."
cors_response=$(curl -s -H "Origin: http://localhost:3000" -I "$BASE_URL_BACKEND/health" | grep -i "access-control" || echo "")

if [ -n "$cors_response" ]; then
    log_success "CORS headers configured"
else
    log_info "No CORS headers found"
fi

# =============================================================================
# Performance Tests
# =============================================================================

echo "🚀 Running Performance Smoke Tests..."

# Test response times
log_info "Testing API response time..."
start_time=$(date +%s%N)
curl -s "$BASE_URL_BACKEND/health" > /dev/null
end_time=$(date +%s%N)
response_time=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds

if [ $response_time -lt 1000 ]; then
    log_success "API response time: ${response_time}ms (good)"
elif [ $response_time -lt 3000 ]; then
    log_info "API response time: ${response_time}ms (acceptable)"
else
    log_error "API response time: ${response_time}ms (too slow)"
fi

# Test frontend loading time
log_info "Testing frontend loading time..."
start_time=$(date +%s%N)
curl -s "$BASE_URL_FRONTEND" > /dev/null
end_time=$(date +%s%N)
frontend_time=$(( (end_time - start_time) / 1000000 ))

if [ $frontend_time -lt 2000 ]; then
    log_success "Frontend response time: ${frontend_time}ms (good)"
elif [ $frontend_time -lt 5000 ]; then
    log_info "Frontend response time: ${frontend_time}ms (acceptable)"
else
    log_error "Frontend response time: ${frontend_time}ms (too slow)"
fi

# =============================================================================
# Final Summary
# =============================================================================

echo ""
echo "🎉 Smoke tests completed successfully!"
echo "📊 Environment: $ENVIRONMENT"
echo "⏱️  Backend response time: ${response_time}ms"
echo "⏱️  Frontend response time: ${frontend_time}ms"
echo "✅ All critical services are operational"
echo ""
