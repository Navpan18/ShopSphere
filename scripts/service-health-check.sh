#!/bin/bash

# Service Health Check Script for ShopSphere
# Replaces sleep commands with proper health checks

set -e

SERVICE_NAME=$1
SERVICE_URL=$2
MAX_ATTEMPTS=${3:-60}
SLEEP_TIME=${4:-2}

if [ -z "$SERVICE_NAME" ] || [ -z "$SERVICE_URL" ]; then
    echo "Usage: $0 <service_name> <service_url> [max_attempts] [sleep_time]"
    echo "Example: $0 'Backend API' 'http://localhost:8001/health' 60 2"
    exit 1
fi

echo "🔍 Checking $SERVICE_NAME readiness..."
echo "URL: $SERVICE_URL"
echo "Max attempts: $MAX_ATTEMPTS"

for i in $(seq 1 $MAX_ATTEMPTS); do
    if curl -f -s --max-time 10 "$SERVICE_URL" >/dev/null 2>&1; then
        echo "✅ $SERVICE_NAME is ready! (attempt $i/$MAX_ATTEMPTS)"
        
        # Additional health check - verify response content if it's a health endpoint
        if [[ "$SERVICE_URL" == *"/health"* ]]; then
            RESPONSE=$(curl -s --max-time 10 "$SERVICE_URL" || echo "")
            if [[ "$RESPONSE" == *"ok"* ]] || [[ "$RESPONSE" == *"healthy"* ]] || [[ "$RESPONSE" == *"200"* ]]; then
                echo "✅ $SERVICE_NAME health check passed"
            else
                echo "⚠️ $SERVICE_NAME responded but health check content unclear: $RESPONSE"
            fi
        fi
        
        exit 0
    fi
    
    echo "⏳ Waiting for $SERVICE_NAME... attempt $i/$MAX_ATTEMPTS"
    
    if [ $i -eq $MAX_ATTEMPTS ]; then
        echo "❌ $SERVICE_NAME failed to become ready after $MAX_ATTEMPTS attempts"
        echo "Last attempted URL: $SERVICE_URL"
        
        # Try to get more diagnostic information
        echo "🔍 Diagnostic information:"
        curl -v "$SERVICE_URL" || true
        
        exit 1
    fi
    
    sleep $SLEEP_TIME
done
