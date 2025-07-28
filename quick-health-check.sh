#!/bin/bash

# ShopSphere Quick Health Check
# Fast test of essential services only

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 ShopSphere Quick Health Check${NC}"
echo "=================================="

# Essential services to check (including Jenkins)
services=(
    "Backend API:http://localhost:8001/health:healthy"
    "Frontend:http://localhost:3000:200"
    "Analytics:http://localhost:8002/health:healthy"
    "Notifications:http://localhost:8003/health:healthy"
    "Jenkins CI/CD:http://localhost:9040:200"
    "Prometheus:http://localhost:9090:200"
    "Grafana:http://localhost:3001:200"
    "Kafka UI:http://localhost:8080:200"
)

# Infrastructure services
infrastructure=(
    "PostgreSQL:5432"
    "Redis:6379"
    "Kafka:9092"
)

passed=0
failed=0

echo -e "${BLUE}🌐 Testing Web Services:${NC}"
echo "========================"

for service in "${services[@]}"; do
    IFS=':' read -r name url expected <<< "$service"
    
    echo -n "🔍 Testing $name... "
    
    if [[ "$expected" == "healthy" ]]; then
        # Health check endpoint
        if response=$(curl -s --max-time 5 "$url" 2>/dev/null) && echo "$response" | grep -q "healthy"; then
            echo -e "${GREEN}✅ Healthy${NC}"
            ((passed++))
        else
            echo -e "${RED}❌ Unhealthy${NC}"
            ((failed++))
        fi
    else
        # HTTP status check
        if status_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null) && [[ "$status_code" == "$expected" ]]; then
            echo -e "${GREEN}✅ Online (HTTP $status_code)${NC}"
            ((passed++))
        else
            echo -e "${RED}❌ Offline (HTTP $status_code)${NC}"
            ((failed++))
        fi
    fi
done

echo -e "\n${BLUE}🏗️ Testing Infrastructure Services:${NC}"
echo "===================================="

# Test PostgreSQL
echo -n "🗄️  Testing PostgreSQL... "
if docker exec shopsphere_postgres pg_isready -U user -d shopdb >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Connected${NC}"
    ((passed++))
else
    echo -e "${RED}❌ Not connected${NC}"
    ((failed++))
fi

# Test Redis
echo -n "🔴 Testing Redis... "
if docker exec shopsphere_redis redis-cli ping 2>/dev/null | grep -q PONG; then
    echo -e "${GREEN}✅ Connected${NC}"
    ((passed++))
else
    echo -e "${RED}❌ Not connected${NC}"
    ((failed++))
fi

# Test Kafka (basic port check)
echo -n "📨 Testing Kafka... "
if nc -z localhost 9092 2>/dev/null; then
    echo -e "${GREEN}✅ Port accessible${NC}"
    ((passed++))
else
    echo -e "${RED}❌ Port not accessible${NC}"
    ((failed++))
fi

echo ""
echo "========================================"
echo "Results: ${GREEN}$passed passed${NC}, ${RED}$failed failed${NC}"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}🎉 All essential services are healthy!${NC}"
    
    # Check if ngrok is running and show public URL
    NGROK_URL=""
    if [[ -f ".ngrok_url" ]]; then
        NGROK_URL=$(cat .ngrok_url)
        if pgrep -f ngrok >/dev/null; then
            echo -e "${GREEN}🌐 ngrok tunnel is active!${NC}"
        else
            echo -e "${YELLOW}⚠️  ngrok URL found but tunnel may be down${NC}"
        fi
    fi
    
    echo -e "\n${CYAN}🔗 Quick Access URLs:${NC}"
    echo "===================="
    echo "  🌐 Frontend:    http://localhost:3000"
    echo "  🔧 Backend:     http://localhost:8001"
    echo "  🏗️  Jenkins:     http://localhost:9040"
    echo "  📊 Grafana:     http://localhost:3001 (admin/admin)"
    echo "  📋 Kafka UI:    http://localhost:8080"
    
    if [[ -n "$NGROK_URL" ]]; then
        echo -e "\n${CYAN}🌐 Public Access (ngrok):${NC}"
        echo "========================="
        echo "  🏗️  Jenkins:     $NGROK_URL"
        echo "  📝 Webhook:     $NGROK_URL/github-webhook/"
    else
        echo -e "\n${YELLOW}💡 To expose Jenkins publicly, run: './start-ngrok.sh'${NC}"
    fi
    
    exit 0
else
    echo -e "${YELLOW}⚠️  Some services need attention.${NC}"
    echo -e "${BLUE}💡 Troubleshooting tips:${NC}"
    echo "  • Wait 30 seconds and run this script again"
    echo "  • Check logs: docker-compose logs [service-name]"
    echo "  • Restart failing service: docker-compose restart [service-name]"
    echo "  • Run comprehensive test: ./scripts/test-all-services.sh"
    echo "  • Start ngrok for Jenkins: ./start-ngrok.sh"
    exit 1
fi
