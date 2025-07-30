#!/bin/bash

# 🧹 Backend Memory Testing Script - Fixed & Optimized
cd /Users/coder/Downloads/ShopSphere-main/ShopSphere/backend

echo "🧹 STEP 1: Smart Docker Cleanup..."
echo "=================================="

# Clean up in stages to prevent hanging
echo "🗑️ Removing old test images..."
docker images | grep "test-backend" | awk '{print $3}' | xargs -r docker rmi 2>/dev/null || echo "No test images to remove"

echo "🧹 Quick system cleanup..."
docker system prune -f --volumes
docker builder prune -f

echo -e "\n🚀 STEP 2: Testing Backend Build with Smart Memory Limits..."
echo "==========================================================="

# Reduced memory levels for faster testing
MEMORY_LEVELS=(4 3 2 1)
LOG_FILE="backend-memory-test-$(date +%Y%m%d_%H%M%S).log"

echo "📝 Detailed logs will be saved to: $LOG_FILE"
echo "🕐 Starting tests at: $(date)"
echo ""

for MEMORY in "${MEMORY_LEVELS[@]}"; do
    SWAP=$((MEMORY * 2))
    echo "🔬 TESTING: ${MEMORY}GB Memory + ${SWAP}GB Swap"
    echo "Time: $(date)"
    echo "=========================================="
    
    # Create unique tag for this test
    TAG="test-backend-${MEMORY}gb"
    
    echo "🏗️ Building with ${MEMORY}GB memory..."
    echo "Command: docker build --memory=${MEMORY}g --memory-swap=${SWAP}g --shm-size=512m -t $TAG . --no-cache"
    echo ""
    
    # Log the start time and command
    echo "[$(date)] STARTING BUILD: ${MEMORY}GB memory" >> $LOG_FILE
    echo "[$(date)] Command: docker build --memory=${MEMORY}g --memory-swap=${SWAP}g --shm-size=512m -t $TAG . --no-cache" >> $LOG_FILE
    echo "========================================" >> $LOG_FILE
    
    # Run the build with reduced timeout and simpler logging
    START_TIME=$(date +%s)
    if timeout 300 docker build --memory=${MEMORY}g --memory-swap=${SWAP}g --shm-size=512m -t $TAG . --no-cache >> $LOG_FILE 2>&1; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        
        echo ""
        echo "✅ SUCCESS: ${MEMORY}GB build completed in ${DURATION} seconds!"
        echo "[$(date)] ✅ SUCCESS: ${MEMORY}GB build completed in ${DURATION} seconds" >> $LOG_FILE
        
        # Check image size
        IMAGE_SIZE=$(docker images $TAG --format "{{.Size}}")
        echo "📦 Image size: $IMAGE_SIZE"
        echo "[$(date)] 📦 Image size: $IMAGE_SIZE" >> $LOG_FILE
        
        # Test if container can start
        echo "🧪 Testing container startup..."
        if docker run --rm -d --name ${TAG}-test -p $((8000 + MEMORY)):8001 $TAG >/dev/null 2>&1; then
            sleep 5
            if docker ps | grep -q "${TAG}-test"; then
                echo "✅ Container started successfully!"
                echo "[$(date)] ✅ Container startup: SUCCESS" >> $LOG_FILE
                docker stop ${TAG}-test >/dev/null 2>&1
            else
                echo "❌ Container failed to stay running"
                echo "[$(date)] ❌ Container startup: FAILED - container exited" >> $LOG_FILE
            fi
        else
            echo "❌ Container failed to start"
            echo "[$(date)] ❌ Container startup: FAILED - could not start" >> $LOG_FILE
        fi
        
        # Clean up the test image
        docker rmi $TAG >/dev/null 2>&1
        
    else
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        
        echo ""
        echo "❌ FAILED: ${MEMORY}GB build failed after ${DURATION} seconds"
        echo "[$(date)] ❌ FAILED: ${MEMORY}GB build failed after ${DURATION} seconds" >> $LOG_FILE
        
        # Clean up any partial builds
        docker rmi $TAG >/dev/null 2>&1
    fi
    
    echo "[$(date)] ========================================" >> $LOG_FILE
    echo ""
    echo "⏸️ Waiting 10 seconds before next test..."
    sleep 10
done

echo ""
echo "🏁 TESTING COMPLETED!"
echo "====================="
echo "📊 Summary saved in: $LOG_FILE"
echo "🕐 Finished at: $(date)"

# Show a quick summary
echo ""
echo "📋 QUICK SUMMARY:"
echo "=================="
grep -E "(SUCCESS|FAILED):" $LOG_FILE | tail -10

echo ""
echo "📖 To view full logs: cat $LOG_FILE"
echo "🧹 Final cleanup..."
docker system prune -f >/dev/null 2>&1
