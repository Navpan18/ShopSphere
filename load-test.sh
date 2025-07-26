#!/bin/bash

# ShopSphere Load Testing Script
# Performance testing for API endpoints

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 ShopSphere Load Testing Suite${NC}"
echo "=================================="

# Check if required tools are available
check_dependencies() {
    local deps=("curl" "ab")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing dependencies: ${missing[*]}${NC}"
        echo "Install with: brew install httpie"
        echo "Apache Bench (ab) is usually included with Apache"
        exit 1
    fi
}

# Load test function
load_test() {
    local name="$1"
    local url="$2"
    local requests="${3:-100}"
    local concurrency="${4:-10}"
    local timeout="${5:-30}"
    
    echo -e "\n${BLUE}🧪 Testing: $name${NC}"
    echo "URL: $url"
    echo "Requests: $requests, Concurrency: $concurrency"
    echo "----------------------------------------"
    
    if result=$(timeout "$timeout" ab -n "$requests" -c "$concurrency" "$url" 2>/dev/null); then
        # Extract key metrics
        rps=$(echo "$result" | grep "Requests per second" | awk '{print $4}')
        mean_time=$(echo "$result" | grep "Time per request" | head -1 | awk '{print $4}')
        failed_requests=$(echo "$result" | grep "Failed requests" | awk '{print $3}')
        
        echo -e "${GREEN}✅ Test completed${NC}"
        echo "  📊 Requests/sec: $rps"
        echo "  ⏱️  Mean time/request: ${mean_time}ms"
        echo "  ❌ Failed requests: $failed_requests"
        
        if [[ "$failed_requests" == "0" ]]; then
            echo -e "  ${GREEN}🎉 No failed requests!${NC}"
        else
            echo -e "  ${YELLOW}⚠️  Some requests failed${NC}"
        fi
    else
        echo -e "${RED}❌ Load test failed or timed out${NC}"
    fi
}

# Stress test function with gradual load increase
stress_test() {
    local name="$1"
    local url="$2"
    
    echo -e "\n${YELLOW}⚡ Stress Testing: $name${NC}"
    echo "Gradually increasing load..."
    echo "=================================="
    
    for concurrency in 1 5 10 20; do
        echo -e "\n${BLUE}🔄 Testing with $concurrency concurrent users${NC}"
        if result=$(timeout 20 ab -n 50 -c "$concurrency" "$url" 2>/dev/null); then
            rps=$(echo "$result" | grep "Requests per second" | awk '{print $4}')
            failed=$(echo "$result" | grep "Failed requests" | awk '{print $3}')
            echo "  📊 RPS: $rps, Failed: $failed"
        else
            echo -e "  ${RED}❌ Test failed at $concurrency concurrency${NC}"
            break
        fi
    done
}

# API endpoint testing with sample data
api_test() {
    local name="$1"
    local url="$2"
    local method="${3:-GET}"
    local data="$4"
    
    echo -e "\n${BLUE}🔗 API Test: $name${NC}"
    echo "Method: $method, URL: $url"
    
    if [[ "$method" == "GET" ]]; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" "$url")
    else
        response=$(curl -s -X "$method" -H "Content-Type: application/json" \
                       -d "$data" -w "\nHTTP_CODE:%{http_code}\nTIME:%{time_total}" "$url")
    fi
    
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    time_total=$(echo "$response" | grep "TIME:" | cut -d: -f2)
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        echo -e "${GREEN}✅ Success (HTTP $http_code)${NC}"
        echo "  ⏱️  Response time: ${time_total}s"
    else
        echo -e "${RED}❌ Failed (HTTP $http_code)${NC}"
    fi
}

# Main testing execution
main() {
    check_dependencies
    
    echo -e "${YELLOW}Starting performance tests...${NC}\n"
    
    # Basic load tests
    echo -e "${CYAN}📈 BASIC LOAD TESTING${NC}"
    load_test "Backend API Root" "http://localhost:8001/" 50 5
    load_test "Backend Health Check" "http://localhost:8001/health" 50 5
    load_test "Analytics Service" "http://localhost:8002/health" 30 3
    load_test "Notification Service" "http://localhost:8003/health" 30 3
    
    # Frontend testing (if available)
    if curl -s --max-time 5 "http://localhost:3000" >/dev/null 2>&1; then
        load_test "Frontend" "http://localhost:3000/" 30 3
    else
        echo -e "\n${YELLOW}⚠️  Frontend not available for testing${NC}"
    fi
    
    # Stress testing on main API
    stress_test "Backend API" "http://localhost:8001/"
    
    # API endpoint testing
    echo -e "\n${CYAN}🔌 API ENDPOINT TESTING${NC}"
    api_test "Backend Root" "http://localhost:8001/"
    api_test "Backend Health" "http://localhost:8001/health"
    api_test "Backend Metrics" "http://localhost:8001/metrics"
    api_test "Analytics Health" "http://localhost:8002/health"
    api_test "Analytics Metrics" "http://localhost:8002/metrics"
    api_test "Notification Health" "http://localhost:8003/health"
    
    # Monitoring services
    echo -e "\n${CYAN}📊 MONITORING SERVICES${NC}"
    api_test "Prometheus" "http://localhost:9090/"
    api_test "Grafana" "http://localhost:3001/"
    api_test "Kafka UI" "http://localhost:8080/"
    
    echo -e "\n${GREEN}🎉 Load testing complete!${NC}"
    echo -e "${BLUE}💡 Tips for production:${NC}"
    echo "  - Monitor response times under load"
    echo "  - Set up proper rate limiting"
    echo "  - Use caching for frequently accessed data"
    echo "  - Configure auto-scaling based on load"
    echo "  - Monitor error rates and set alerts"
}

# Run the tests
main "$@"
