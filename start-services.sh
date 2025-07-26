#!/bin/bash

# ShopSphere Service Startup Script
# Starts all ShopSphere services in the correct order

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 Starting ShopSphere Services${NC}"
echo "================================"

# Check if docker-compose.yml exists
if [[ ! -f "docker-compose.yml" ]]; then
    echo -e "${RED}❌ docker-compose.yml not found in current directory${NC}"
    exit 1
fi

# Stop any existing services (except Jenkins)
echo -e "${YELLOW}🛑 Stopping existing services...${NC}"
docker-compose down

# Start all services
echo -e "${BLUE}🏗️  Starting all ShopSphere services...${NC}"
docker-compose up -d

# Wait for services to start
echo -e "${YELLOW}⏳ Waiting for services to initialize...${NC}"
sleep 30

# Check service status
echo -e "\n${BLUE}📊 Checking service status...${NC}"
docker-compose ps

# Test basic connectivity
echo -e "\n${BLUE}🔍 Testing basic connectivity...${NC}"

services=(
    "Backend:http://localhost:8001/health"
    "Analytics:http://localhost:8002/health"
    "Notifications:http://localhost:8003/health"
    "Frontend:http://localhost:3000"
    "Kafka UI:http://localhost:8080"
    "Prometheus:http://localhost:9090"
    "Grafana:http://localhost:3001"
)

for service in "${services[@]}"; do
    IFS=':' read -r name url <<< "$service"
    echo -n "Testing $name... "
    
    if curl -s --max-time 10 "$url" >/dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
    fi
done

echo -e "\n${GREEN}🎉 ShopSphere services startup complete!${NC}"
echo -e "${BLUE}💡 Run './quick-health-check.sh' to verify all services${NC}"
echo -e "${BLUE}💡 Run './test-all.sh' for comprehensive testing${NC}"

# Show service URLs
echo -e "\n${CYAN}🔗 Service URLs:${NC}"
echo "  🌐 Frontend:      http://localhost:3000"
echo "  🔧 Backend API:   http://localhost:8001"
echo "  📖 API Docs:     http://localhost:8001/docs"
echo "  📊 Analytics:     http://localhost:8002"
echo "  📬 Notifications: http://localhost:8003"
echo "  📋 Kafka UI:      http://localhost:8080"
echo "  📈 Prometheus:    http://localhost:9090"
echo "  📊 Grafana:       http://localhost:3001 (admin/admin)"
echo "  🏗️  Jenkins:       http://localhost:9040"
