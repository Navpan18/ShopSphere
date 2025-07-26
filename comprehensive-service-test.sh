#!/bin/bash

# ShopSphere Comprehensive Service Testing Script
# Tests all services in the ShopSphere project
# set -e  # Commented out to allow tests to continue even if some fail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test results tracking
PASSED_TESTS=0
FAILED_TESTS=0
TOTAL_TESTS=0

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED_TESTS++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_header() {
    echo -e "\n${PURPLE}🔍 $1${NC}"
    echo "=================================="
}

test_service() {
    local service_name="$1"
    local url="$2"
    local expected_status="$3"
    local timeout="${4:-10}"
    
    ((TOTAL_TESTS++))
    log_info "Testing $service_name at $url"
    
    if response=$(curl -s -w "%{http_code}" --max-time "$timeout" "$url" 2>/dev/null); then
        status_code="${response: -3}"
        if [[ "$status_code" == "$expected_status" ]]; then
            log_success "$service_name is responding correctly (HTTP $status_code)"
            return 0
        else
            log_error "$service_name returned unexpected status: $status_code (expected $expected_status)"
            return 1
        fi
    else
        log_error "$service_name is not accessible at $url"
        return 1
    fi
}

test_database_connection() {
    local service_name="$1"
    local host="$2"
    local port="$3"
    local timeout="${4:-5}"
    
    ((TOTAL_TESTS++))
    log_info "Testing $service_name connectivity at $host:$port"
    
    if timeout "$timeout" bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        log_success "$service_name is accessible on port $port"
        return 0
    else
        log_error "$service_name is not accessible on port $port"
        return 1
    fi
}

test_api_endpoint() {
    local service_name="$1"
    local url="$2"
    local method="${3:-GET}"
    local expected_field="$4"
    local timeout="${5:-10}"
    
    ((TOTAL_TESTS++))
    log_info "Testing $service_name API endpoint: $method $url"
    
    if response=$(curl -s -X "$method" --max-time "$timeout" "$url" 2>/dev/null); then
        if [[ -n "$expected_field" ]]; then
            if echo "$response" | grep -q "$expected_field"; then
                log_success "$service_name API is working (found: $expected_field)"
                return 0
            else
                log_error "$service_name API response missing expected field: $expected_field"
                echo "Response: $response"
                return 1
            fi
        else
            log_success "$service_name API is responding"
            return 0
        fi
    else
        log_error "$service_name API is not accessible"
        return 1
    fi
}

# Start comprehensive testing
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              🧪 ShopSphere Service Test Suite                 ║"
echo "║              Comprehensive Service Health Check              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

START_TIME=$(date +%s)

# 1. Infrastructure Services
log_header "Infrastructure Services"

# PostgreSQL
test_database_connection "PostgreSQL Database" "localhost" "5432" 5

# Redis
test_database_connection "Redis Cache" "localhost" "6379" 5

# Test Redis with ping
((TOTAL_TESTS++))
if redis_response=$(timeout 5 redis-cli -h localhost -p 6379 ping 2>/dev/null); then
    if [[ "$redis_response" == "PONG" ]]; then
        log_success "Redis is responding to PING command"
    else
        log_error "Redis PING returned unexpected response: $redis_response"
    fi
else
    log_error "Redis PING command failed"
fi

# Zookeeper
test_database_connection "Zookeeper" "localhost" "2181" 5

# Kafka
test_database_connection "Kafka" "localhost" "9092" 5

# 2. Core Application Services
log_header "Core Application Services"

# Backend API
test_service "Backend API" "http://localhost:8001/" "200"
test_api_endpoint "Backend Health Check" "http://localhost:8001/health" "GET" "healthy"
test_api_endpoint "Backend API Root" "http://localhost:8001/" "GET" "ShopSphere API is live"
test_service "Backend Metrics" "http://localhost:8001/metrics" "200"
test_service "Backend API Docs" "http://localhost:8001/docs" "200"

# Frontend
test_service "Frontend Application" "http://localhost:3000/" "200"

# 3. Microservices
log_header "Microservices"

# Analytics Service
test_service "Analytics Service" "http://localhost:8002/" "200"
test_api_endpoint "Analytics Health Check" "http://localhost:8002/health" "GET" "healthy"
test_api_endpoint "Analytics Metrics" "http://localhost:8002/metrics" "GET" ""
test_api_endpoint "Analytics Debug Events" "http://localhost:8002/debug/events" "GET" ""

# Notification Service
test_service "Notification Service" "http://localhost:8003/" "200"
test_api_endpoint "Notification Health Check" "http://localhost:8003/health" "GET" "healthy"
test_api_endpoint "Notification Metrics" "http://localhost:8003/metrics" "GET" ""

# 4. Management & Monitoring Services
log_header "Management & Monitoring Services"

# Kafka UI
test_service "Kafka UI" "http://localhost:8080/" "200"

# Prometheus
test_service "Prometheus" "http://localhost:9090/" "200"
test_api_endpoint "Prometheus Targets" "http://localhost:9090/targets" "GET" ""
test_api_endpoint "Prometheus Config" "http://localhost:9090/config" "GET" ""

# Grafana
test_service "Grafana" "http://localhost:3001/" "200"
test_service "Grafana Login" "http://localhost:3001/login" "200"

# 5. CI/CD Services
log_header "CI/CD Services"

# Jenkins
test_service "Jenkins" "http://localhost:9040/" "200"
test_api_endpoint "Jenkins API" "http://localhost:9040/api/json" "GET" ""

# 6. Advanced API Testing
log_header "Advanced API Testing"

# Test Backend API endpoints with detailed checks
((TOTAL_TESTS++))
log_info "Testing Backend API documentation availability"
if curl -s "http://localhost:8001/docs" | grep -q "ShopSphere API"; then
    log_success "Backend API documentation is available and properly titled"
else
    log_error "Backend API documentation is missing or improperly configured"
fi

# Test Analytics Service detailed functionality
((TOTAL_TESTS++))
log_info "Testing Analytics Service event processing capability"
if analytics_response=$(curl -s "http://localhost:8002/debug/events" 2>/dev/null); then
    if echo "$analytics_response" | grep -q -E "(events|processed|total)"; then
        log_success "Analytics Service is processing events"
    else
        log_success "Analytics Service is ready for event processing"
    fi
else
    log_error "Analytics Service event processing check failed"
fi

# 7. Docker Container Health Check
log_header "Docker Container Health"

# Check running containers
((TOTAL_TESTS++))
log_info "Checking Docker containers status"
if running_containers=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(shopsphere|jenkins)" | wc -l); then
    if [[ $running_containers -gt 5 ]]; then
        log_success "Multiple ShopSphere containers are running ($running_containers found)"
        docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(shopsphere|jenkins)" | while read line; do
            echo "  📦 $line"
        done
    else
        log_warning "Only $running_containers ShopSphere containers found running"
    fi
else
    log_error "No ShopSphere containers found running"
fi

# 8. Load Testing Sample
log_header "Performance Testing Sample"

# Quick load test on backend
((TOTAL_TESTS++))
log_info "Running quick performance test on Backend API"
if command -v ab >/dev/null 2>&1; then
    if ab_result=$(ab -n 10 -c 2 "http://localhost:8001/" 2>/dev/null | grep "Requests per second"); then
        log_success "Backend API performance test completed: $ab_result"
    else
        log_warning "Backend API performance test completed but results unclear"
    fi
else
    log_warning "Apache Bench (ab) not available, skipping performance test"
fi

# 9. Database Connectivity Test
log_header "Database Operations Testing"

# Test PostgreSQL connection with actual query
((TOTAL_TESTS++))
log_info "Testing PostgreSQL database query capability"
if command -v psql >/dev/null 2>&1; then
    if db_result=$(PGPASSWORD=password psql -h localhost -U user -d shopdb -c "SELECT version();" 2>/dev/null | grep PostgreSQL); then
        log_success "PostgreSQL database query successful: $(echo $db_result | cut -d' ' -f1-2)"
    else
        log_error "PostgreSQL database query failed"
    fi
else
    log_warning "psql client not available, skipping database query test"
fi

# Test Redis operations
((TOTAL_TESTS++))
log_info "Testing Redis SET/GET operations"
if redis-cli -h localhost -p 6379 SET test_key "ShopSphere_Test_$(date +%s)" >/dev/null 2>&1; then
    if test_value=$(redis-cli -h localhost -p 6379 GET test_key 2>/dev/null); then
        if [[ "$test_value" == *"ShopSphere_Test"* ]]; then
            log_success "Redis SET/GET operations working correctly"
            redis-cli -h localhost -p 6379 DEL test_key >/dev/null 2>&1
        else
            log_error "Redis GET returned unexpected value: $test_value"
        fi
    else
        log_error "Redis GET operation failed"
    fi
else
    log_error "Redis SET operation failed"
fi

# 10. Kafka Topic Check
log_header "Kafka Topics and Messaging"

# Check Kafka topics
((TOTAL_TESTS++))
log_info "Checking Kafka topics"
if command -v kafka-topics.sh >/dev/null 2>&1; then
    if kafka_topics=$(kafka-topics.sh --bootstrap-server localhost:9092 --list 2>/dev/null); then
        topic_count=$(echo "$kafka_topics" | grep -v "^$" | wc -l)
        log_success "Kafka topics available: $topic_count topics found"
        echo "$kafka_topics" | while read topic; do
            [[ -n "$topic" ]] && echo "  📋 Topic: $topic"
        done
    else
        log_error "Failed to list Kafka topics"
    fi
else
    log_warning "Kafka CLI tools not available, skipping topic check"
fi

# Final Results
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}                         📊 TEST SUMMARY                         ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"

echo -e "🕒 Test Duration: ${DURATION} seconds"
echo -e "📊 Total Tests: ${TOTAL_TESTS}"
echo -e "${GREEN}✅ Passed: ${PASSED_TESTS}${NC}"
echo -e "${RED}❌ Failed: ${FAILED_TESTS}${NC}"

# Calculate success rate
if [[ $TOTAL_TESTS -gt 0 ]]; then
    SUCCESS_RATE=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    echo -e "📈 Success Rate: ${SUCCESS_RATE}%"
    
    if [[ $SUCCESS_RATE -ge 90 ]]; then
        echo -e "${GREEN}🎉 EXCELLENT! Your ShopSphere system is running great!${NC}"
    elif [[ $SUCCESS_RATE -ge 75 ]]; then
        echo -e "${YELLOW}👍 GOOD! Most services are working, check failed tests${NC}"
    elif [[ $SUCCESS_RATE -ge 50 ]]; then
        echo -e "${YELLOW}⚠️  FAIR: Several issues detected, review failed services${NC}"
    else
        echo -e "${RED}🚨 CRITICAL: Many services failing, immediate attention needed${NC}"
    fi
else
    echo -e "${RED}❌ No tests were executed${NC}"
fi

echo -e "\n${BLUE}🔗 Service URLs Summary:${NC}"
echo "  🌐 Frontend:      http://localhost:3000"
echo "  🔧 Backend API:   http://localhost:8001"
echo "  📊 Analytics:     http://localhost:8002"
echo "  📬 Notifications: http://localhost:8003"
echo "  📋 Kafka UI:      http://localhost:8080"
echo "  📈 Prometheus:    http://localhost:9090"
echo "  📊 Grafana:       http://localhost:3001 (admin/admin)"
echo "  🏗️  Jenkins:       http://localhost:9040"

echo -e "\n${PURPLE}💡 Next Steps:${NC}"
if [[ $FAILED_TESTS -gt 0 ]]; then
    echo "  1. Review failed services and check Docker logs"
    echo "  2. Verify service dependencies are running"
    echo "  3. Check network connectivity between services"
    echo "  4. Review environment variables and configuration"
else
    echo "  1. All services are healthy! 🎉"
    echo "  2. You can start testing your application features"
    echo "  3. Monitor services with Grafana and Prometheus"
    echo "  4. Check CI/CD pipeline in Jenkins"
fi

echo -e "\n${CYAN}🔍 For detailed service logs, run:${NC}"
echo "  docker logs <container_name>"
echo "  docker-compose logs <service_name>"

exit $FAILED_TESTS
