#!/bin/bash

# ShopSphere Master Test Suite
# Runs all testing scripts and provides comprehensive overview

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Test tracking
declare -A test_results
declare -A test_durations

run_test_suite() {
    local script_name="$1"
    local description="$2"
    local script_path="./$script_name"
    
    if [[ ! -f "$script_path" ]]; then
        echo -e "${RED}❌ Script not found: $script_path${NC}"
        test_results["$script_name"]="MISSING"
        return 1
    fi
    
    echo -e "\n${CYAN}🚀 Running: $description${NC}"
    echo -e "${BLUE}Script: $script_name${NC}"
    echo "=================================================================="
    
    start_time=$(date +%s)
    
    if bash "$script_path"; then
        test_results["$script_name"]="PASSED"
        echo -e "\n${GREEN}✅ $description completed successfully${NC}"
    else
        test_results["$script_name"]="FAILED"
        echo -e "\n${RED}❌ $description failed${NC}"
    fi
    
    end_time=$(date +%s)
    test_durations["$script_name"]=$((end_time - start_time))
}

show_summary() {
    local total_passed=0
    local total_failed=0
    local total_missing=0
    local total_duration=0
    
    echo -e "\n${BOLD}${PURPLE}################################################################${NC}"
    echo -e "${BOLD}${PURPLE}                    🏁 MASTER TEST SUMMARY                     ${NC}"
    echo -e "${BOLD}${PURPLE}################################################################${NC}"
    
    echo -e "\n${BOLD}📋 Test Suite Results:${NC}"
    echo "=================================================================="
    
    for script in "${!test_results[@]}"; do
        result="${test_results[$script]}"
        duration="${test_durations[$script]:-0}"
        total_duration=$((total_duration + duration))
        
        case "$result" in
            "PASSED")
                echo -e "  ${GREEN}✅ $script${NC} (${duration}s)"
                ((total_passed++))
                ;;
            "FAILED")
                echo -e "  ${RED}❌ $script${NC} (${duration}s)"
                ((total_failed++))
                ;;
            "MISSING")
                echo -e "  ${YELLOW}❓ $script${NC} (script not found)"
                ((total_missing++))
                ;;
        esac
    done
    
    local total_tests=$((total_passed + total_failed + total_missing))
    
    echo -e "\n${BOLD}📊 Statistics:${NC}"
    echo "=================================================================="
    echo -e "🕒 Total execution time: ${total_duration} seconds"
    echo -e "📈 Total test suites: ${total_tests}"
    echo -e "${GREEN}✅ Passed: ${total_passed}${NC}"
    echo -e "${RED}❌ Failed: ${total_failed}${NC}"
    echo -e "${YELLOW}❓ Missing: ${total_missing}${NC}"
    
    if [[ $total_tests -gt 0 ]]; then
        local success_rate=$(( (total_passed * 100) / total_tests ))
        echo -e "📈 Success rate: ${success_rate}%"
    fi
    
    echo -e "\n${BOLD}🎯 Overall Assessment:${NC}"
    echo "=================================================================="
    
    if [[ $total_failed -eq 0 && $total_missing -eq 0 ]]; then
        echo -e "${GREEN}🏆 EXCELLENT! All test suites passed successfully!${NC}"
        echo -e "${GREEN}Your ShopSphere system is fully operational and healthy! 🎉${NC}"
    elif [[ $total_failed -eq 0 && $total_missing -gt 0 ]]; then
        echo -e "${YELLOW}👍 GOOD! All available tests passed, but some scripts are missing.${NC}"
    elif [[ $total_failed -eq 1 ]]; then
        echo -e "${YELLOW}⚠️  FAIR: One test suite failed. Review the failed components.${NC}"
    else
        echo -e "${RED}🚨 CRITICAL: Multiple test suites failed!${NC}"
        echo -e "${RED}Immediate attention required for system stability.${NC}"
    fi
}

show_recommendations() {
    echo -e "\n${BOLD}💡 Recommendations:${NC}"
    echo "=================================================================="
    
    if [[ "${test_results['quick-health-check.sh']}" == "FAILED" ]]; then
        echo -e "${RED}🔧 Quick Health Check Failed:${NC}"
        echo "  - Check if all Docker containers are running"
        echo "  - Verify service dependencies"
        echo "  - Review Docker logs for errors"
    fi
    
    if [[ "${test_results['infrastructure-test.sh']}" == "FAILED" ]]; then
        echo -e "${RED}🏗️  Infrastructure Issues:${NC}"
        echo "  - Check database connections"
        echo "  - Verify Redis and Kafka connectivity"
        echo "  - Review Docker volumes and networking"
    fi
    
    if [[ "${test_results['comprehensive-service-test.sh']}" == "FAILED" ]]; then
        echo -e "${RED}🔍 Service Issues:${NC}"
        echo "  - Review individual service logs"
        echo "  - Check API endpoints manually"
        echo "  - Verify service configurations"
    fi
    
    if [[ "${test_results['load-test.sh']}" == "FAILED" ]]; then
        echo -e "${YELLOW}⚡ Performance Issues:${NC}"
        echo "  - Consider scaling resources"
        echo "  - Optimize database queries"
        echo "  - Review caching strategies"
    fi
    
    # General recommendations
    echo -e "\n${BLUE}📈 General Recommendations:${NC}"
    echo "  1. Set up monitoring dashboards in Grafana"
    echo "  2. Configure alerting for critical services"
    echo "  3. Implement proper logging and tracing"
    echo "  4. Regular backup procedures for databases"
    echo "  5. Performance monitoring and optimization"
}

show_service_urls() {
    echo -e "\n${BOLD}🔗 Service URLs:${NC}"
    echo "=================================================================="
    echo -e "${CYAN}Web Services:${NC}"
    echo "  🌐 Frontend:        http://localhost:3000"
    echo "  🔧 Backend API:     http://localhost:8001"
    echo "  📖 API Docs:       http://localhost:8001/docs"
    echo "  📊 Analytics:       http://localhost:8002"
    echo "  📬 Notifications:   http://localhost:8003"
    
    echo -e "\n${CYAN}Management & Monitoring:${NC}"
    echo "  🏗️  Jenkins:         http://localhost:9040"
    echo "  📈 Prometheus:      http://localhost:9090"
    echo "  📊 Grafana:         http://localhost:3001 (admin/admin)"
    echo "  📋 Kafka UI:        http://localhost:8080"
    
    echo -e "\n${CYAN}Databases:${NC}"
    echo "  🐘 PostgreSQL:      localhost:5432 (user/password/shopdb)"
    echo "  📦 Redis:           localhost:6379"
    echo "  🚀 Kafka:           localhost:9092"
    echo "  🐘 Zookeeper:       localhost:2181"
}

# Main execution
main() {
    echo -e "${BOLD}${CYAN}################################################################${NC}"
    echo -e "${BOLD}${CYAN}            🧪 ShopSphere Master Test Suite 🧪                 ${NC}"
    echo -e "${BOLD}${CYAN}          Comprehensive System Health Verification             ${NC}"
    echo -e "${BOLD}${CYAN}################################################################${NC}"
    
    echo -e "\n${YELLOW}🚀 Starting comprehensive testing of ShopSphere system...${NC}"
    echo -e "${BLUE}This will run all available test suites to verify system health.${NC}"
    
    START_TIME=$(date +%s)
    
    # Run all test suites
    run_test_suite "quick-health-check.sh" "Quick Health Check - Essential Services"
    run_test_suite "infrastructure-test.sh" "Infrastructure Testing - Databases & Messaging"
    run_test_suite "comprehensive-service-test.sh" "Comprehensive Service Testing - All APIs"
    run_test_suite "load-test.sh" "Load Testing - Performance & Stress Tests"
    
    END_TIME=$(date +%s)
    TOTAL_DURATION=$((END_TIME - START_TIME))
    
    # Show comprehensive results
    show_summary
    show_recommendations
    show_service_urls
    
    echo -e "\n${BOLD}⏱️  Total Master Test Duration: ${TOTAL_DURATION} seconds${NC}"
    echo -e "\n${PURPLE}🎯 Testing completed! Review results above for next steps.${NC}"
    
    # Return appropriate exit code
    if [[ "${test_results['quick-health-check.sh']}" == "FAILED" || "${test_results['infrastructure-test.sh']}" == "FAILED" ]]; then
        exit 1
    else
        exit 0
    fi
}

# Handle script arguments
case "${1:-}" in
    "-h"|"--help")
        echo "ShopSphere Master Test Suite"
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  -h, --help     Show this help message"
        echo "  --quick        Run only quick health check"
        echo "  --infra        Run only infrastructure tests"
        echo "  --services     Run only service tests"
        echo "  --load         Run only load tests"
        echo ""
        echo "By default, runs all test suites."
        exit 0
        ;;
    "--quick")
        run_test_suite "quick-health-check.sh" "Quick Health Check"
        ;;
    "--infra")
        run_test_suite "infrastructure-test.sh" "Infrastructure Testing"
        ;;
    "--services")
        run_test_suite "comprehensive-service-test.sh" "Service Testing"
        ;;
    "--load")
        run_test_suite "load-test.sh" "Load Testing"
        ;;
    *)
        main
        ;;
esac
