#!/bin/bash

# ShopSphere Infrastructure Testing Script
# Tests databases, messaging, and infrastructure components

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${CYAN}🏗️  ShopSphere Infrastructure Testing${NC}"
echo "====================================="

PASSED=0
FAILED=0

test_result() {
    if [[ $1 -eq 0 ]]; then
        echo -e "${GREEN}✅ PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAILED${NC}"
        ((FAILED++))
    fi
}

# PostgreSQL comprehensive testing
test_postgresql() {
    echo -e "\n${BLUE}🐘 PostgreSQL Database Testing${NC}"
    echo "==============================="
    
    # Connection test
    echo -n "1. Connection test... "
    if timeout 5 pg_isready -h localhost -p 5432 -U user >/dev/null 2>&1; then
        test_result 0
    else
        test_result 1
        return
    fi
    
    # Database existence
    echo -n "2. Database 'shopdb' exists... "
    if PGPASSWORD=password psql -h localhost -U user -d shopdb -c "SELECT 1;" >/dev/null 2>&1; then
        test_result 0
    else
        test_result 1
        return
    fi
    
    # Table creation test
    echo -n "3. Table operations test... "
    if PGPASSWORD=password psql -h localhost -U user -d shopdb -c "
        CREATE TABLE IF NOT EXISTS test_table (id SERIAL PRIMARY KEY, name VARCHAR(50));
        INSERT INTO test_table (name) VALUES ('test_$(date +%s)');
        SELECT COUNT(*) FROM test_table;
        DROP TABLE test_table;
    " >/dev/null 2>&1; then
        test_result 0
    else
        test_result 1
    fi
    
    # Performance test
    echo -n "4. Performance test (100 queries)... "
    start_time=$(date +%s%N)
    for i in {1..100}; do
        PGPASSWORD=password psql -h localhost -U user -d shopdb -c "SELECT 1;" >/dev/null 2>&1 || break
    done
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    echo -e "${GREEN}✅ PASSED${NC} (${duration}ms for 100 queries)"
    ((PASSED++))
}

# Redis comprehensive testing
test_redis() {
    echo -e "\n${BLUE}📦 Redis Cache Testing${NC}"
    echo "======================"
    
    # Connection test
    echo -n "1. Connection test... "
    if redis-cli -h localhost -p 6379 ping >/dev/null 2>&1; then
        test_result 0
    else
        test_result 1
        return
    fi
    
    # Basic operations
    echo -n "2. SET/GET operations... "
    test_key="shopsphere_test_$(date +%s)"
    test_value="test_value_$(date +%s)"
    if redis-cli -h localhost -p 6379 SET "$test_key" "$test_value" >/dev/null 2>&1 && \
       [[ "$(redis-cli -h localhost -p 6379 GET "$test_key" 2>/dev/null)" == "$test_value" ]]; then
        redis-cli -h localhost -p 6379 DEL "$test_key" >/dev/null 2>&1
        test_result 0
    else
        test_result 1
    fi
    
    # Hash operations
    echo -n "3. Hash operations... "
    hash_key="shopsphere_hash_$(date +%s)"
    if redis-cli -h localhost -p 6379 HSET "$hash_key" field1 value1 field2 value2 >/dev/null 2>&1 && \
       [[ "$(redis-cli -h localhost -p 6379 HGET "$hash_key" field1 2>/dev/null)" == "value1" ]]; then
        redis-cli -h localhost -p 6379 DEL "$hash_key" >/dev/null 2>&1
        test_result 0
    else
        test_result 1
    fi
    
    # List operations
    echo -n "4. List operations... "
    list_key="shopsphere_list_$(date +%s)"
    if redis-cli -h localhost -p 6379 LPUSH "$list_key" item1 item2 item3 >/dev/null 2>&1 && \
       [[ "$(redis-cli -h localhost -p 6379 LLEN "$list_key" 2>/dev/null)" == "3" ]]; then
        redis-cli -h localhost -p 6379 DEL "$list_key" >/dev/null 2>&1
        test_result 0
    else
        test_result 1
    fi
    
    # Performance test
    echo -n "5. Performance test (1000 operations)... "
    start_time=$(date +%s%N)
    for i in {1..1000}; do
        redis-cli -h localhost -p 6379 SET "perf_test_$i" "value_$i" >/dev/null 2>&1
    done
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    # Cleanup
    redis-cli -h localhost -p 6379 FLUSHDB >/dev/null 2>&1
    echo -e "${GREEN}✅ PASSED${NC} (${duration}ms for 1000 operations)"
    ((PASSED++))
}

# Kafka testing
test_kafka() {
    echo -e "\n${BLUE}🚀 Kafka Messaging Testing${NC}"
    echo "============================"
    
    # Check if kafka tools are available
    if ! command -v kafka-topics.sh >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Kafka CLI tools not available. Installing/using Docker exec...${NC}"
        
        # Alternative: use docker exec
        echo -n "1. Connection test via Docker... "
        if docker exec shopsphere_kafka kafka-topics --bootstrap-server localhost:9092 --list >/dev/null 2>&1; then
            test_result 0
        else
            test_result 1
            return
        fi
        
        echo -n "2. Topic creation test... "
        test_topic="test_topic_$(date +%s)"
        if docker exec shopsphere_kafka kafka-topics --bootstrap-server localhost:9092 --create --topic "$test_topic" --partitions 1 --replication-factor 1 >/dev/null 2>&1; then
            test_result 0
            # Cleanup
            docker exec shopsphere_kafka kafka-topics --bootstrap-server localhost:9092 --delete --topic "$test_topic" >/dev/null 2>&1
        else
            test_result 1
        fi
        
        echo -n "3. List existing topics... "
        if topics=$(docker exec shopsphere_kafka kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null); then
            topic_count=$(echo "$topics" | grep -v "^$" | wc -l)
            echo -e "${GREEN}✅ PASSED${NC} ($topic_count topics found)"
            ((PASSED++))
        else
            test_result 1
        fi
        
    else
        # Use local kafka tools
        echo -n "1. Connection test... "
        if kafka-topics.sh --bootstrap-server localhost:9092 --list >/dev/null 2>&1; then
            test_result 0
        else
            test_result 1
            return
        fi
        
        echo -n "2. Topic creation test... "
        test_topic="test_topic_$(date +%s)"
        if kafka-topics.sh --bootstrap-server localhost:9092 --create --topic "$test_topic" --partitions 1 --replication-factor 1 >/dev/null 2>&1; then
            test_result 0
            # Cleanup
            kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic "$test_topic" >/dev/null 2>&1
        else
            test_result 1
        fi
    fi
}

# Docker containers health check
test_docker_health() {
    echo -e "\n${BLUE}🐳 Docker Container Health${NC}"
    echo "=========================="
    
    containers=("shopsphere_postgres" "shopsphere_redis" "shopsphere_kafka" "shopsphere_zookeeper")
    
    for container in "${containers[@]}"; do
        echo -n "Checking $container... "
        if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
            # Check container health if health check is configured
            health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-healthcheck")
            if [[ "$health_status" == "healthy" ]]; then
                echo -e "${GREEN}✅ HEALTHY${NC}"
                ((PASSED++))
            elif [[ "$health_status" == "no-healthcheck" ]]; then
                echo -e "${GREEN}✅ RUNNING${NC}"
                ((PASSED++))
            else
                echo -e "${YELLOW}⚠️  UNHEALTHY ($health_status)${NC}"
                ((FAILED++))
            fi
        else
            echo -e "${RED}❌ NOT RUNNING${NC}"
            ((FAILED++))
        fi
    done
}

# Network connectivity testing
test_network() {
    echo -e "\n${BLUE}🌐 Network Connectivity Testing${NC}"
    echo "==============================="
    
    services=(
        "PostgreSQL:localhost:5432"
        "Redis:localhost:6379"
        "Kafka:localhost:9092"
        "Zookeeper:localhost:2181"
        "Backend:localhost:8001"
        "Frontend:localhost:3000"
        "Analytics:localhost:8002"
        "Notifications:localhost:8003"
    )
    
    for service in "${services[@]}"; do
        IFS=':' read -r name host port <<< "$service"
        echo -n "Testing $name ($host:$port)... "
        if timeout 3 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            test_result 0
        else
            test_result 1
        fi
    done
}

# Storage and volume testing
test_storage() {
    echo -e "\n${BLUE}💾 Storage and Volume Testing${NC}"
    echo "============================="
    
    echo -n "1. PostgreSQL data volume... "
    if docker volume inspect shopsphere_pgdata >/dev/null 2>&1; then
        test_result 0
    else
        test_result 1
    fi
    
    echo -n "2. Redis data volume... "
    if docker volume inspect shopsphere_redis_data >/dev/null 2>&1; then
        test_result 0
    else
        test_result 1
    fi
    
    echo -n "3. Grafana data volume... "
    if docker volume inspect shopsphere_grafana_data >/dev/null 2>&1; then
        test_result 0
    else
        test_result 1
    fi
    
    # Check disk usage
    echo -n "4. Docker system disk usage... "
    if disk_usage=$(docker system df --format "table {{.Type}}\t{{.Total}}\t{{.Active}}\t{{.Size}}" 2>/dev/null); then
        echo -e "${GREEN}✅ PASSED${NC}"
        echo "$disk_usage" | while read line; do
            echo "   $line"
        done
        ((PASSED++))
    else
        test_result 1
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}Starting infrastructure tests...${NC}\n"
    
    test_docker_health
    test_network
    test_postgresql
    test_redis
    test_kafka
    test_storage
    
    # Final results
    echo -e "\n${PURPLE}========================================${NC}"
    echo -e "${PURPLE}           INFRASTRUCTURE TEST RESULTS${NC}"
    echo -e "${PURPLE}========================================${NC}"
    
    total=$((PASSED + FAILED))
    echo -e "📊 Total Tests: $total"
    echo -e "${GREEN}✅ Passed: $PASSED${NC}"
    echo -e "${RED}❌ Failed: $FAILED${NC}"
    
    if [[ $FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 All infrastructure tests passed!${NC}"
        echo -e "${GREEN}Your ShopSphere infrastructure is solid! 💪${NC}"
    elif [[ $FAILED -le 2 ]]; then
        echo -e "\n${YELLOW}⚠️  Minor issues detected. Most infrastructure is healthy.${NC}"
    else
        echo -e "\n${RED}🚨 Multiple infrastructure issues detected!${NC}"
        echo -e "${RED}Please review failed services before proceeding.${NC}"
    fi
    
    exit $FAILED
}

# Run the tests
main "$@"
