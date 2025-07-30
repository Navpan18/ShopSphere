#!/bin/bash

# 🧹 Frontend Memory Testing Script with Full Docker Logs & Cleanup
cd /Users/coder/Downloads/ShopSphere-main/ShopSphere/frontend

echo "🧹 STEP 1: Cleaning up old Docker builds..."
echo "============================================="

# Remove old test images
echo "📋 Current Docker images:"
docker images | grep -E "(test-frontend|shopsphere-frontend)" || echo "No existing test images found"

echo -e "\n🗑️ Removing old test images..."
docker rmi $(docker images | grep "test-frontend" | awk '{print $3}') 2>/dev/null || echo "No test-frontend images to remove"
docker rmi $(docker images | grep "shopsphere-frontend" | awk '{print $3}') 2>/dev/null || echo "No shopsphere-frontend images to remove"

echo -e "\n🧹 Cleaning Docker system..."
docker system prune -f
docker builder prune -f

echo -e "\n🚀 STEP 2: Testing Frontend Build with Different Memory Levels..."
echo "================================================================"

# Array of memory configurations to test (in GB)
MEMORY_LEVELS=(6 5 4 3 2 1)
LOG_FILE="frontend-memory-test-$(date +%Y%m%d_%H%M%S).log"

echo "📝 Detailed logs will be saved to: $LOG_FILE"
echo "🕐 Starting tests at: $(date)"
echo ""

for MEMORY in "${MEMORY_LEVELS[@]}"; do
    SWAP=$((MEMORY * 2))
    echo "🔬 TESTING: ${MEMORY}GB Memory + ${SWAP}GB Swap"
    echo "Time: $(date)"
    echo "=========================================="
    
    # Create unique tag for this test
    TAG="test-frontend-${MEMORY}gb"
    
    echo "🏗️ Building with ${MEMORY}GB memory (FULL DOCKER LOGS)..."
    echo "Command: docker build --memory=${MEMORY}g --memory-swap=${SWAP}g --shm-size=1g -t $TAG . --no-cache --progress=plain"
    echo ""
    
    # Log the start time and command
    echo "[$(date)] STARTING BUILD: ${MEMORY}GB memory" >> $LOG_FILE
    echo "[$(date)] Command: docker build --memory=${MEMORY}g --memory-swap=${SWAP}g --shm-size=1g -t $TAG . --no-cache --progress=plain" >> $LOG_FILE
    echo "========================================" >> $LOG_FILE
    
    # Run the build and capture both stdout and stderr, showing full logs
    START_TIME=$(date +%s)
    if timeout 900 docker build --memory=${MEMORY}g --memory-swap=${SWAP}g --shm-size=1g -t $TAG . --no-cache --progress=plain 2>&1 | tee -a $LOG_FILE; then
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
        if docker run --rm -d --name ${TAG}-test -p $((3000 + MEMORY)):3000 $TAG >/dev/null 2>&1; then
            sleep 10
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
