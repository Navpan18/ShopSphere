#!/bin/bash

# 🚀 Complete ShopSphere Services Test with Health Checks
cd /Users/coder/Downloads/ShopSphere-main/ShopSphere

echo "🚀 COMPLETE SHOPSPHERE SERVICES TEST"
echo "===================================="
echo "Testing all 4 services with 1GB memory + health checks"
echo "Time: $(date)"
echo ""

# Service configurations
SERVICES=(
    "backend:backend:8001:8011"
    "frontend:frontend:3000:3010" 
    "analytics:microservices/analytics-service:8002:8012"
    "notifications:microservices/notification-service:8003:8013"
)

LOG_FILE="all-services-test-$(date +%Y%m%d_%H%M%S).log"
echo "📝 Detailed logs: $LOG_FILE"

# Cleanup existing test containers
echo ""
echo "🧹 Cleaning up existing test containers..."
docker rm -f test-backend test-frontend test-analytics test-notifications 2>/dev/null || true

# Create test network
echo ""
echo "🌐 Creating test network..."
if ! docker network ls | grep -q test-network; then
    docker network create test-network
    echo "✅ Created test-network"
else
    echo "✅ test-network already exists"
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
    echo "Command: docker build --memory=1g --memory-swap=2g --shm-size=512m -t test-$name . --no-cache --progress=plain"
    echo ""
    
    START_TIME=$(date +%s)
    
    # Show live Docker build logs with tee to both console and file
    echo "[$(date)] STARTING BUILD: $name service" >> "../../../$LOG_FILE"
    echo "========================================" >> "../../../$LOG_FILE"
    
    if cd "$path" && timeout 300 docker build --memory=1g --memory-swap=2g --shm-size=512m -t "test-$name" . --no-cache --progress=plain 2>&1 | tee -a "../../../$LOG_FILE"; then
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
    IMAGE_SIZE=$(docker images "test-$name" --format "{{.Size}}")
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
    echo "Command: docker run -d --name test-$name --network test-network -p $external_port:$internal_port test-$name"
    
    if docker run -d \
        --name "test-$name" \
        --network test-network \
        -p "$external_port:$internal_port" \
        "test-$name" 2>&1 | tee -a "$LOG_FILE"; then
        echo "✅ $name: Container started successfully"
        echo "[$(date)] ✅ $name: Container started on port $external_port" >> "$LOG_FILE"
    else
        echo "❌ $name: Failed to start container"
        echo "[$(date)] ❌ $name: Container startup failed" >> "$LOG_FILE"
        continue
    fi
    
    # Show container status immediately
    echo "📊 Container status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "test-$name" || echo "Container not found in ps output"
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
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep test-

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
    docker logs test-backend 2>&1 | tail -10 | tee -a "$LOG_FILE"
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
    docker logs test-frontend 2>&1 | tail -10 | tee -a "$LOG_FILE"
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
    docker logs test-analytics 2>&1 | tail -5 | tee -a "$LOG_FILE"
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
    docker logs test-notifications 2>&1 | tail -5 | tee -a "$LOG_FILE"
fi

# Resource usage
echo ""
echo "📊 PHASE 4: Resource Usage"
echo "=========================="
echo "🔋 Container resource usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep test-

# Final summary
echo ""
echo "📋 FINAL SUMMARY"
echo "================"
RUNNING_COUNT=$(docker ps | grep test- | wc -l)
TOTAL_COUNT=${#SERVICES[@]}

echo "🐳 Containers running: $RUNNING_COUNT/$TOTAL_COUNT"
echo "🌐 Network: test-network"
echo "📊 Log file: $LOG_FILE"
echo "🕐 Test completed: $(date)"

# Cleanup option
echo ""
read -p "🧹 Clean up all test containers? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 Cleaning up..."
    docker rm -f $(docker ps -aq --filter "name=test-") 2>/dev/null
    docker network rm test-network 2>/dev/null
    docker rmi $(docker images | grep "test-" | awk '{print $3}') 2>/dev/null
    echo "✅ Cleanup completed"
else
    echo "⚠️ Test containers left running for inspection"
    echo "   To clean up later: docker rm -f \$(docker ps -aq --filter \"name=test-\")"
fi
