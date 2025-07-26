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

# Essential services to check
services=(
    "Backend API:http://localhost:8001/health:healthy"
    "Frontend:http://localhost:3000:200"
    "Analytics:http://localhost:8002/health:healthy"
    "Notifications:http://localhost:8003/health:healthy"
    "Jenkins:http://localhost:9040:200"
    "Prometheus:http://localhost:9090:200"
    "Grafana:http://localhost:3001:200"
    "Kafka UI:http://localhost:8080:200"
)

passed=0
failed=0

for service in "${services[@]}"; do
    IFS=':' read -r name url expected <<< "$service"
    
    echo -n "Testing $name... "
    
    if [[ "$expected" == "healthy" ]]; then
        # Health check endpoint
        if response=$(curl -s --max-time 5 "$url" 2>/dev/null) && echo "$response" | grep -q "healthy"; then
            echo -e "${GREEN}✅${NC}"
            ((passed++))
        else
            echo -e "${RED}❌${NC}"
            ((failed++))
        fi
    else
        # HTTP status check
        if status_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null) && [[ "$status_code" == "$expected" ]]; then
            echo -e "${GREEN}✅${NC}"
            ((passed++))
        else
            echo -e "${RED}❌ (HTTP $status_code)${NC}"
            ((failed++))
        fi
    fi
done

echo
echo "Results: ${GREEN}$passed passed${NC}, ${RED}$failed failed${NC}"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}🎉 All essential services are healthy!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some services need attention. Run ./comprehensive-service-test.sh for details.${NC}"
    exit 1
fi
