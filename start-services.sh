#!/bin/bash

# ShopSphere Service Startup Script
# Starts all ShopSphere services in the correct order including Jenkins

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${CYAN}🚀 Starting ShopSphere Complete Service Stack${NC}"
echo "================================================"

# Function to check if service is ready
check_service() {
    local service_name=$1
    local service_url=$2
    local max_attempts=${3:-30}
    local sleep_time=${4:-2}
    
    echo -e "${YELLOW}⏳ Waiting for $service_name to be ready...${NC}"
    
    for i in $(seq 1 $max_attempts); do
        if curl -f -s --max-time 10 "$service_url" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name is ready! (attempt $i/$max_attempts)${NC}"
            return 0
        fi
        echo -n "."
        sleep $sleep_time
    done
    
    echo -e "${RED}❌ $service_name failed to start after $max_attempts attempts${NC}"
    return 1
}

# Function to start ngrok and get public URL
start_ngrok() {
    echo -e "${PURPLE}🌐 Starting ngrok for Jenkins public access...${NC}"
    
    # Check if ngrok is installed
    if ! command -v ngrok &> /dev/null; then
        echo -e "${YELLOW}⚠️  ngrok not found. Installing ngrok...${NC}"
        # Install ngrok on macOS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew &> /dev/null; then
                brew install ngrok/ngrok/ngrok
            else
                echo -e "${RED}❌ Please install ngrok manually from https://ngrok.com/download${NC}"
                return 1
            fi
        else
            echo -e "${RED}❌ Please install ngrok manually from https://ngrok.com/download${NC}"
            return 1
        fi
    fi
    
    # Kill any existing ngrok processes
    pkill -f ngrok || true
    
    # Start ngrok in background
    echo -e "${YELLOW}⏳ Starting ngrok tunnel for Jenkins (port 9040)...${NC}"
    ngrok http 9040 --log=stdout > ngrok.log 2>&1 &
    
    # Wait for ngrok to start
    sleep 5
    
    # Get the public URL
    local ngrok_url=""
    for i in {1..10}; do
        ngrok_url=$(curl -s http://localhost:4040/api/tunnels | grep -o 'https://[^"]*\.ngrok-free\.app' | head -1)
        if [[ -n "$ngrok_url" ]]; then
            break
        fi
        echo -n "."
        sleep 2
    done
    
    if [[ -n "$ngrok_url" ]]; then
        echo -e "${GREEN}✅ ngrok tunnel established!${NC}"
        echo -e "${CYAN}🌐 Jenkins Public URL: $ngrok_url${NC}"
        echo -e "${YELLOW}📝 GitHub Webhook URL: $ngrok_url/github-webhook/${NC}"
        
        # Save to file for later reference
        echo "$ngrok_url" > .ngrok_url
        echo "Jenkins Public URL: $ngrok_url" > ngrok_info.txt
        echo "GitHub Webhook URL: $ngrok_url/github-webhook/" >> ngrok_info.txt
        echo "ngrok Web Interface: http://localhost:4040" >> ngrok_info.txt
        
        return 0
    else
        echo -e "${RED}❌ Failed to get ngrok public URL${NC}"
        return 1
    fi
}

# Function to show startup status
show_status() {
    echo -e "\n${BLUE}📊 Current Docker containers status:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
}

# Check if required files exist
if [[ ! -f "docker-compose.yml" ]]; then
    echo -e "${RED}❌ docker-compose.yml not found in current directory${NC}"
    exit 1
fi

if [[ ! -f "jenkins/docker-compose.jenkins.yml" ]]; then
    echo -e "${RED}❌ Jenkins docker-compose file not found${NC}"
    exit 1
fi

# Stop any existing services
echo -e "${YELLOW}🛑 Stopping existing services...${NC}"
docker-compose down
docker-compose -f jenkins/docker-compose.jenkins.yml down
docker network prune -f

# Step 1: Start Infrastructure Services (Database, Redis, Kafka)
echo -e "${PURPLE}🏗️ Step 1: Starting Infrastructure Services...${NC}"
echo "Starting PostgreSQL, Redis, Kafka, and Zookeeper..."

docker-compose up -d postgres redis zookeeper kafka

echo -e "${YELLOW}⏳ Waiting for infrastructure services to initialize...${NC}"
sleep 15

# Check PostgreSQL
check_service "PostgreSQL" "postgresql://user:password@localhost:5432/shopdb" 30 2 || {
    echo "Checking PostgreSQL with alternative method..."
    docker exec shopsphere_postgres pg_isready -U user -d shopdb || echo "PostgreSQL not ready yet"
}

# Check Redis
check_service "Redis" "redis://localhost:6379" 20 2 || {
    echo "Checking Redis with ping..."
    docker exec shopsphere_redis redis-cli ping || echo "Redis not ready yet"
}

# Wait for Kafka to be ready
echo -e "${YELLOW}⏳ Waiting for Kafka to be ready...${NC}"
sleep 20

show_status

# Step 2: Start Jenkins CI/CD
echo -e "${PURPLE}🏗️ Step 2: Starting Jenkins CI/CD Server...${NC}"

docker-compose -f jenkins/docker-compose.jenkins.yml up -d

echo -e "${YELLOW}⏳ Jenkins startup takes longer (60-90 seconds)...${NC}"
sleep 30

check_service "Jenkins" "http://localhost:9040" 60 3

# Start ngrok after Jenkins is ready
start_ngrok

show_status

# Step 3: Start Application Services
echo -e "${PURPLE}🏗️ Step 3: Starting Application Services...${NC}"
echo "Starting Backend, Analytics, and Notifications microservices..."

docker-compose up -d backend analytics notifications

echo -e "${YELLOW}⏳ Waiting for application services to start...${NC}"
sleep 25

# Check each service individually
check_service "Backend API" "http://localhost:8001/health" 45 2
check_service "Analytics Service" "http://localhost:8002/health" 30 2  
check_service "Notifications Service" "http://localhost:8003/health" 30 2

show_status

# Step 4: Start Frontend
echo -e "${PURPLE}🏗️ Step 4: Starting Frontend Application...${NC}"

docker-compose up -d frontend

echo -e "${YELLOW}⏳ Waiting for frontend to build and start...${NC}"
sleep 20

check_service "Frontend" "http://localhost:3000" 45 3

# Step 5: Start Monitoring Services
echo -e "${PURPLE}🏗️ Step 5: Starting Monitoring Services...${NC}"
echo "Starting Prometheus, Grafana, and Kafka UI..."

docker-compose up -d prometheus grafana kafka-ui

echo -e "${YELLOW}⏳ Waiting for monitoring services...${NC}"
sleep 15

check_service "Prometheus" "http://localhost:9090" 30 2
check_service "Grafana" "http://localhost:3001" 30 2
check_service "Kafka UI" "http://localhost:8080" 30 2

# Final status check
show_status

# Final comprehensive health check
echo -e "\n${BLUE}🔍 Running comprehensive health checks...${NC}"

services=(
    "Backend API:http://localhost:8001/health"
    "Analytics Service:http://localhost:8002/health"
    "Notifications Service:http://localhost:8003/health"
    "Frontend:http://localhost:3000"
    "Jenkins:http://localhost:9040"
    "Kafka UI:http://localhost:8080"
    "Prometheus:http://localhost:9090"
    "Grafana:http://localhost:3001"
)

echo -e "${BLUE}📋 Service Health Check Results:${NC}"
echo "================================"

all_healthy=true

for service in "${services[@]}"; do
    IFS=':' read -r name url <<< "$service"
    echo -n "🔍 Testing $name... "
    
    if curl -f -s --max-time 10 "$url" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Healthy${NC}"
    else
        echo -e "${RED}❌ Unhealthy${NC}"
        all_healthy=false
    fi
done

# Database connectivity test
echo -n "🗄️  Testing Database connectivity... "
if docker exec shopsphere_postgres pg_isready -U user -d shopdb >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
    all_healthy=false
fi

# Redis connectivity test
echo -n "🔴 Testing Redis connectivity... "
if docker exec shopsphere_redis redis-cli ping | grep -q PONG; then
    echo -e "${GREEN}✅ Connected${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
    all_healthy=false
fi

echo ""

if $all_healthy; then
    echo -e "${GREEN}🎉 All ShopSphere services are healthy and running!${NC}"
else
    echo -e "${YELLOW}⚠️  Some services may need more time to start or have issues${NC}"
    echo -e "${BLUE}💡 Run './quick-health-check.sh' again in a few minutes${NC}"
fi

echo -e "\n${GREEN}🎉 ShopSphere Complete Service Stack Startup Complete!${NC}"
echo -e "${BLUE}💡 Run './quick-health-check.sh' to verify all services${NC}"
echo -e "${BLUE}💡 Run './test-all.sh' for comprehensive testing${NC}"
echo -e "${BLUE}💡 Run './test-endpoints.sh' to test API endpoints${NC}"

# Get ngrok URL if available
NGROK_URL=""
if [[ -f ".ngrok_url" ]]; then
    NGROK_URL=$(cat .ngrok_url)
fi

# Show service URLs with startup times
echo -e "\n${CYAN}🔗 Local Service URLs:${NC}"
echo "========================"
echo -e "  🌐 Frontend:         http://localhost:3000     ${GREEN}(~20-30s startup)${NC}"
echo -e "  🔧 Backend API:      http://localhost:8001     ${GREEN}(~25s startup)${NC}"
echo -e "  📖 API Docs:        http://localhost:8001/docs ${GREEN}(Same as Backend)${NC}"
echo -e "  📊 Analytics:        http://localhost:8002     ${GREEN}(~20s startup)${NC}"
echo -e "  📬 Notifications:    http://localhost:8003     ${GREEN}(~20s startup)${NC}"
echo -e "  🏗️  Jenkins (Local):  http://localhost:9040     ${YELLOW}(~60-90s startup)${NC}"
echo -e "  📋 Kafka UI:         http://localhost:8080     ${GREEN}(~15s startup)${NC}"
echo -e "  📈 Prometheus:       http://localhost:9090     ${GREEN}(~10s startup)${NC}"
echo -e "  📊 Grafana:          http://localhost:3001     ${GREEN}(admin/admin, ~15s startup)${NC}"

if [[ -n "$NGROK_URL" ]]; then
    echo -e "\n${CYAN}🌐 Public URLs (via ngrok):${NC}"
    echo "============================"
    echo -e "  🏗️  Jenkins Public:   ${NGROK_URL}     ${GREEN}(Accessible worldwide!)${NC}"
    echo -e "  � GitHub Webhook:    ${NGROK_URL}/github-webhook/     ${YELLOW}(For GitHub integration)${NC}"
    echo -e "  🔍 ngrok Dashboard:   http://localhost:4040     ${BLUE}(ngrok web interface)${NC}"
fi

echo -e "\n${PURPLE}�🔧 Infrastructure Services:${NC}"
echo "============================"
echo -e "  🗄️  PostgreSQL:       localhost:5432          ${GREEN}(~10s startup)${NC}"
echo -e "  🔴 Redis:            localhost:6379           ${GREEN}(~5s startup)${NC}"
echo -e "  📨 Kafka:            localhost:9092           ${GREEN}(~20s startup)${NC}"

echo -e "\n${CYAN}📋 Service Startup Summary:${NC}"
echo "==========================="
echo -e "  ✅ Infrastructure services: ~15s"
echo -e "  ✅ Jenkins CI/CD: ~60-90s" 
echo -e "  ✅ Application services: ~25s"
echo -e "  ✅ Frontend: ~20-30s"
echo -e "  ✅ Monitoring: ~15s"
echo -e "  🌐 ngrok tunnel: ~5s"
echo -e "  📊 Total startup time: ~2-3 minutes"

echo -e "\n${YELLOW}💡 GitHub Webhook Setup:${NC}"
echo "========================="
if [[ -n "$NGROK_URL" ]]; then
    echo -e "  1. Go to your GitHub repository settings"
    echo -e "  2. Navigate to Webhooks → Add webhook"
    echo -e "  3. Payload URL: ${CYAN}${NGROK_URL}/github-webhook/${NC}"
    echo -e "  4. Content type: application/json"
    echo -e "  5. Select 'Just the push event'"
    echo -e "  6. Set Active: ✅"
    echo -e "  7. Click 'Add webhook'"
else
    echo -e "  ${RED}❌ ngrok URL not available. Please check ngrok status.${NC}"
fi

echo -e "\n${YELLOW}💡 Pro Tips:${NC}"
echo "============"
echo -e "  • Jenkins takes the longest to start (60-90 seconds)"
echo -e "  • If a service shows as unhealthy, wait 30s and run './quick-health-check.sh'"
echo -e "  • GitHub webhooks are configured for Jenkins via ngrok"
if [[ -n "$NGROK_URL" ]]; then
    echo -e "  • Your Jenkins is publicly accessible at: ${CYAN}${NGROK_URL}${NC}"
fi
echo -e "  • Monitor logs with: 'docker-compose logs -f [service-name]'"
echo -e "  • ngrok session info saved to: ${BLUE}ngrok_info.txt${NC}"
echo -e "  • Stop all services with: './stop-services.sh'"

echo -e "\n${GREEN}🚀 Ready to develop and deploy with ShopSphere!${NC}"
if [[ -n "$NGROK_URL" ]]; then
    echo -e "${GREEN}🌐 Jenkins is now accessible worldwide via ngrok!${NC}"
fi
