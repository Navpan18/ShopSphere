#!/bin/bash

# 🚀 Complete ShopSphere Services Test with Health Checks
cd /Users/coder/Downloads/ShopSphere-main/ShopSphere

echo "🚀 COMPLETE SHOPSPHERE SERVICES TEST"
echo "===================================="
echo "Testing all 4 services with 1GB memory + health checks"
echo "Time: $(date)"
echo ""

# Use BUILD_NUMBER for unique naming (default to timestamp if not set)
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}"
echo "🆔 Build Number: $BUILD_NUMBER"

# Service configurations
SERVICES=(
    "backend:backend:8001:8011"
    "frontend:frontend:3000:3010" 
    "analytics:microservices/analytics-service:8002:8012"
    "notifications:microservices/notification-service:8003:8013"
)

LOG_FILE="all-services-test-${BUILD_NUMBER}.log"
echo "📝 Detailed logs: $LOG_FILE"

# Cleanup existing test containers
echo ""
echo "🧹 Cleaning up existing test containers..."

# Remove test containers gracefully (by BUILD_NUMBER)
for container in "test-backend-${BUILD_NUMBER}" "test-frontend-${BUILD_NUMBER}" "test-analytics-${BUILD_NUMBER}" "test-notifications-${BUILD_NUMBER}"; do
    if docker ps -a --format "{{.Names}}" | grep -q "^${container}$" 2>/dev/null; then
        echo "Removing existing container: ${container}"
        docker rm -f "${container}" 2>/dev/null || true
    else
        echo "Container ${container} not found, skipping"
    fi
done

# Remove test images gracefully (by BUILD_NUMBER)
for image in "test-backend-${BUILD_NUMBER}" "test-frontend-${BUILD_NUMBER}" "test-analytics-${BUILD_NUMBER}" "test-notifications-${BUILD_NUMBER}"; do
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}:" 2>/dev/null; then
        echo "Removing existing image: ${image}"
        docker rmi "${image}" 2>/dev/null || true
    else
        echo "Image ${image} not found, skipping"
    fi
done

# Create test network with BUILD_NUMBER
NETWORK_NAME="test-network-${BUILD_NUMBER}"
echo ""
echo "🌐 Creating test network: ${NETWORK_NAME}..."
if docker network ls --format "{{.Name}}" | grep -q "^${NETWORK_NAME}$" 2>/dev/null; then
    echo "✅ ${NETWORK_NAME} already exists"
else
    if docker network create "${NETWORK_NAME}" >/dev/null 2>&1; then
        echo "✅ Created ${NETWORK_NAME}"
    else
        echo "⚠️ Failed to create ${NETWORK_NAME}, it may already exist"
    fi
fi

# Build all services
echo ""
echo "🏗️ PHASE 1: Building All Services"
echo "================================="

for service_config in "${SERVICES[@]}"; do
    IFS=':' read -r name path internal_port external_port <<< "$service_config"
    
    echo ""
    echo "🔨 Building $name service..."
    echo "Path: $path"
    echo "Ports: $external_port:$internal_port"
    echo "Command: docker build --memory=1g --memory-swap=2g --shm-size=512m -t test-$name-${BUILD_NUMBER} . --no-cache --progress=plain"
    echo ""
    
    START_TIME=$(date +%s)
    
    # Show live Docker build logs with tee to both console and file
    echo "[$(date)] STARTING BUILD: $name service" >> "../../../$LOG_FILE"
    echo "========================================" >> "../../../$LOG_FILE"
    
    if cd "$path" && timeout 300 docker build --memory=1g --memory-swap=2g --shm-size=512m -t "test-$name-${BUILD_NUMBER}" . --no-cache --progress=plain 2>&1 | tee -a "../../../$LOG_FILE"; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo ""
        echo "✅ $name: Built successfully in ${DURATION}s"
        echo "[$(date)] ✅ $name: Built successfully in ${DURATION}s" >> "../../../$LOG_FILE"
    else
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo ""
        echo "❌ $name: Build failed after ${DURATION}s"
        echo "[$(date)] ❌ $name: Build failed after ${DURATION}s" >> "../../../$LOG_FILE"
        cd - >/dev/null
        continue
    fi
    
    # Check image size
    IMAGE_SIZE=$(docker images "test-$name-${BUILD_NUMBER}" --format "{{.Size}}")
    echo "📦 $name image size: $IMAGE_SIZE"
    
    cd - >/dev/null
done

# Start all containers
echo ""
echo "🚀 PHASE 2: Starting All Containers"
echo "==================================="

for service_config in "${SERVICES[@]}"; do
    IFS=':' read -r name path internal_port external_port <<< "$service_config"
    
    echo ""
    echo "🐳 Starting $name container..."
    echo "Command: docker run -d --name test-$name-${BUILD_NUMBER} --network ${NETWORK_NAME} -p $external_port:$internal_port test-$name-${BUILD_NUMBER}"
    
    if docker run -d \
        --name "test-$name-${BUILD_NUMBER}" \
        --network "${NETWORK_NAME}" \
        -p "$external_port:$internal_port" \
        "test-$name-${BUILD_NUMBER}" 2>&1 | tee -a "$LOG_FILE"; then
        echo "✅ $name: Container started successfully"
        echo "[$(date)] ✅ $name: Container started on port $external_port" >> "$LOG_FILE"
    else
        echo "❌ $name: Failed to start container"
        echo "[$(date)] ❌ $name: Container startup failed" >> "$LOG_FILE"
        continue
    fi
    
    # Show container status immediately
    echo "📊 Container status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "test-$name-${BUILD_NUMBER}" || echo "Container not found in ps output"
done

# Wait for initialization
echo ""
echo "⏰ Waiting 30 seconds for services to initialize..."
sleep 30

# Health checks
echo ""
echo "🔍 PHASE 3: Health Checks"
echo "========================="

echo "📋 Container status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "test-.*-${BUILD_NUMBER}"

echo ""
echo "🩺 Localhost health checks (using mapped ports):"

# Test backend health via localhost
echo "🔍 Testing Backend health (localhost:8011)..."
echo "Command: curl -f http://localhost:8011/health"
if curl -f http://localhost:8011/health 2>&1 | tee -a "$LOG_FILE"; then
    echo "✅ Backend: Healthy via localhost:8011"
    echo "[$(date)] ✅ Backend: Health check passed (localhost:8011)" >> "$LOG_FILE"
else
    echo "❌ Backend: Not responding on localhost:8011"
    echo "[$(date)] ❌ Backend: Health check failed (localhost:8011)" >> "$LOG_FILE"
    echo "📋 Backend container logs (last 10 lines):"
    docker logs "test-backend-${BUILD_NUMBER}" 2>&1 | tail -10 | tee -a "$LOG_FILE"
fi

echo ""
# Test frontend health via localhost
echo "🔍 Testing Frontend health (localhost:3010)..."
echo "Command: curl -f http://localhost:3010/"
if curl -f http://localhost:3010/ 2>&1 | tee -a "$LOG_FILE"; then
    echo "✅ Frontend: Healthy via localhost:3010"
    echo "[$(date)] ✅ Frontend: Health check passed (localhost:3010)" >> "$LOG_FILE"
else
    echo "❌ Frontend: Not responding on localhost:3010"
    echo "[$(date)] ❌ Frontend: Health check failed (localhost:3010)" >> "$LOG_FILE"
    echo "📋 Frontend container logs (last 10 lines):"
    docker logs "test-frontend-${BUILD_NUMBER}" 2>&1 | tail -10 | tee -a "$LOG_FILE"
fi

echo ""
# Test analytics health via localhost
echo "🔍 Testing Analytics health (localhost:8012)..."
echo "Command: curl -f http://localhost:8012/"
if curl -f http://localhost:8012/ 2>&1 | tee -a "$LOG_FILE"; then
    echo "✅ Analytics: Responding on localhost:8012"
    echo "[$(date)] ✅ Analytics: Health check passed (localhost:8012)" >> "$LOG_FILE"
else
    echo "⚠️ Analytics: No response on localhost:8012"
    echo "[$(date)] ⚠️ Analytics: No response (localhost:8012)" >> "$LOG_FILE"
    echo "📋 Analytics container logs (last 5 lines):"
    docker logs "test-analytics-${BUILD_NUMBER}" 2>&1 | tail -5 | tee -a "$LOG_FILE"
fi

echo ""
# Test notifications health via localhost
echo "🔍 Testing Notifications health (localhost:8013)..."
echo "Command: curl -f http://localhost:8013/"
if curl -f http://localhost:8013/ 2>&1 | tee -a "$LOG_FILE"; then
    echo "✅ Notifications: Responding on localhost:8013"
    echo "[$(date)] ✅ Notifications: Health check passed (localhost:8013)" >> "$LOG_FILE"
else
    echo "⚠️ Notifications: No response on localhost:8013"
    echo "[$(date)] ⚠️ Notifications: No response (localhost:8013)" >> "$LOG_FILE"
    echo "📋 Notifications container logs (last 5 lines):"
    docker logs "test-notifications-${BUILD_NUMBER}" 2>&1 | tail -5 | tee -a "$LOG_FILE"
fi

# Resource usage
echo ""
echo "📊 PHASE 4: Resource Usage"
echo "=========================="
echo "🔋 Container resource usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep "test-.*-${BUILD_NUMBER}"

# Final summary
echo ""
echo "📋 FINAL SUMMARY"
echo "================"
RUNNING_COUNT=$(docker ps | grep "test-.*-${BUILD_NUMBER}" | wc -l)
TOTAL_COUNT=${#SERVICES[@]}

echo "🐳 Containers running: $RUNNING_COUNT/$TOTAL_COUNT"
echo "🌐 Network: ${NETWORK_NAME}"
echo "📊 Log file: $LOG_FILE"
echo "🕐 Test completed: $(date)"

# Cleanup option
echo ""
read -p "🧹 Clean up all test containers? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 Cleaning up..."
    
    # Remove test containers gracefully (by BUILD_NUMBER)
    for container in "test-backend-${BUILD_NUMBER}" "test-frontend-${BUILD_NUMBER}" "test-analytics-${BUILD_NUMBER}" "test-notifications-${BUILD_NUMBER}"; do
        if docker ps -a --format "{{.Names}}" | grep -q "^${container}$" 2>/dev/null; then
            echo "Removing container: ${container}"
            docker rm -f "${container}" 2>/dev/null || true
        fi
    done
    
    # Remove test network gracefully (by BUILD_NUMBER)
    if docker network ls --format "{{.Name}}" | grep -q "^${NETWORK_NAME}$" 2>/dev/null; then
        echo "Removing ${NETWORK_NAME}"
        docker network rm "${NETWORK_NAME}" 2>/dev/null || true
    fi
    
    # Remove test images gracefully (by BUILD_NUMBER)
    for image in "test-backend-${BUILD_NUMBER}" "test-frontend-${BUILD_NUMBER}" "test-analytics-${BUILD_NUMBER}" "test-notifications-${BUILD_NUMBER}"; do
        if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}:" 2>/dev/null; then
            echo "Removing image: ${image}"
            docker rmi "${image}" 2>/dev/null || true
        fi
    done
    
    echo "✅ Cleanup completed"
else
    echo "⚠️ Test containers left running for inspection"
    echo "   To clean up later:"
    echo "   docker rm -f test-backend-${BUILD_NUMBER} test-frontend-${BUILD_NUMBER} test-analytics-${BUILD_NUMBER} test-notifications-${BUILD_NUMBER}"
    echo "   docker network rm ${NETWORK_NAME}"
    echo "   docker rmi test-backend-${BUILD_NUMBER} test-frontend-${BUILD_NUMBER} test-analytics-${BUILD_NUMBER} test-notifications-${BUILD_NUMBER}"
fi
