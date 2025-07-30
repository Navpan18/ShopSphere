#!/bin/bash

# Automated Backend Resource Testing Script
# Tests backend build with decreasing memory to find minimum requirements

echo "🔥 AUTOMATED BACKEND RESOURCE TESTING"
echo "======================================"

cd /Users/coder/Downloads/ShopSphere-main/ShopSphere/backend

# Memory levels to test (in GB)
MEMORY_LEVELS=(6 5 4 3 2 1)

for MEMORY in "${MEMORY_LEVELS[@]}"; do
    echo ""
    echo "🚀 Testing with ${MEMORY}GB memory..."
    echo "-----------------------------------"
    
    # Clean up previous test images
    docker rmi test-backend-${MEMORY}gb 2>/dev/null || true
    
    # Start timer
    START_TIME=$(date +%s)
    
    # Try building with current memory level
    if timeout 300 docker build \
        --memory=${MEMORY}g \
        --memory-swap=$((MEMORY * 2))g \
        --shm-size=${MEMORY}g \
        -t test-backend-${MEMORY}gb . \
        --no-cache > build-${MEMORY}gb.log 2>&1; then
        
        # Success - calculate time
        END_TIME=$(date +%s)
        BUILD_TIME=$((END_TIME - START_TIME))
        
        echo "✅ SUCCESS: ${MEMORY}GB memory works! (${BUILD_TIME}s)"
        
        # Check image size
        IMAGE_SIZE=$(docker images test-backend-${MEMORY}gb --format "{{.Size}}")
        echo "📦 Image size: ${IMAGE_SIZE}"
        
    else
        # Failed
        END_TIME=$(date +%s)
        BUILD_TIME=$((END_TIME - START_TIME))
        
        echo "❌ FAILED: ${MEMORY}GB memory insufficient (${BUILD_TIME}s)"
        echo "📋 Last 10 lines of error log:"
        tail -10 build-${MEMORY}gb.log | sed 's/^/   /'
        
        # If this fails, we found our minimum
        if [ $MEMORY -gt 1 ]; then
            PREV_MEMORY=$((MEMORY + 1))
            echo ""
            echo "🎯 MINIMUM MEMORY FOUND: ${PREV_MEMORY}GB"
            echo "💡 Recommendation: Use ${PREV_MEMORY}GB for reliable builds"
            break
        fi
    fi
    
    echo "⏰ Build time: ${BUILD_TIME} seconds"
    
    # Small delay between tests
    sleep 2
done

echo ""
echo "🏁 TESTING COMPLETE"
echo "=================="
echo "📁 Build logs saved as: build-XGB.log"
echo "🧹 Cleaning up test images..."

# Clean up all test images
for MEMORY in "${MEMORY_LEVELS[@]}"; do
    docker rmi test-backend-${MEMORY}gb 2>/dev/null || true
done

echo "✅ Done!"
