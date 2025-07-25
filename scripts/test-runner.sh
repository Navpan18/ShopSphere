#!/bin/bash

# ShopSphere Test Runner Script
# Comprehensive testing script for CI/CD pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test configuration
TEST_DIR="test-results"
COVERAGE_DIR="coverage-reports"
BACKEND_DIR="backend"
FRONTEND_DIR="frontend"

# Create test directories
setup_test_environment() {
    print_status "Setting up test environment..."
    
    mkdir -p "$TEST_DIR"
    mkdir -p "$COVERAGE_DIR"
    
    print_success "Test environment ready"
}

# Backend tests
run_backend_tests() {
    print_status "Running backend tests..."
    
    cd "$BACKEND_DIR"
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "test_env" ]; then
        print_status "Creating Python virtual environment..."
        python3 -m venv test_env
    fi
    
    # Activate virtual environment
    source test_env/bin/activate
    
    # Install dependencies
    print_status "Installing backend dependencies..."
    pip install -q -r requirements.txt
    pip install -q pytest pytest-cov pytest-html pytest-xvfb
    
    # Set test environment variables
    export TESTING=true
    export DATABASE_URL="sqlite:///./test.db"
    
    # Run tests with coverage
    print_status "Executing backend tests with coverage..."
    python -m pytest \
        --verbose \
        --tb=short \
        --cov=app \
        --cov-report=html:../coverage-reports/backend-html \
        --cov-report=xml:../coverage-reports/backend-coverage.xml \
        --cov-report=term-missing \
        --junitxml=../test-results/backend-results.xml \
        tests/ || test_exit_code=$?
    
    # Deactivate virtual environment
    deactivate
    
    cd ..
    
    if [ ${test_exit_code:-0} -eq 0 ]; then
        print_success "Backend tests passed"
        return 0
    else
        print_error "Backend tests failed"
        return 1
    fi
}

# Frontend tests
run_frontend_tests() {
    print_status "Running frontend tests..."
    
    cd "$FRONTEND_DIR"
    
    # Install dependencies
    print_status "Installing frontend dependencies..."
    npm ci --silent
    
    # Run tests
    print_status "Executing frontend tests..."
    npm test -- --coverage --watchAll=false --testResultsProcessor=jest-junit || test_exit_code=$?
    
    # Move coverage reports
    if [ -d "coverage" ]; then
        cp -r coverage ../coverage-reports/frontend-html
        print_success "Frontend coverage report generated"
    fi
    
    cd ..
    
    if [ ${test_exit_code:-0} -eq 0 ]; then
        print_success "Frontend tests passed"
        return 0
    else
        print_error "Frontend tests failed"
        return 1
    fi
}

# Integration tests
run_integration_tests() {
    print_status "Running integration tests..."
    
    # Start test database
    print_status "Starting test database..."
    docker-compose -f docker-compose.yml up -d postgres redis
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 15
    
    # Run API endpoint tests
    if [ -f "test-endpoints.sh" ]; then
        print_status "Running API endpoint tests..."
        chmod +x test-endpoints.sh
        ./test-endpoints.sh || integration_exit_code=$?
    else
        print_warning "test-endpoints.sh not found, skipping API tests"
    fi
    
    # Run Kafka event tests
    if [ -f "test-kafka-events.sh" ]; then
        print_status "Running Kafka event tests..."
        chmod +x test-kafka-events.sh
        ./test-kafka-events.sh || kafka_exit_code=$?
    else
        print_warning "test-kafka-events.sh not found, skipping Kafka tests"
    fi
    
    # Cleanup
    print_status "Cleaning up test environment..."
    docker-compose -f docker-compose.yml down
    
    if [ ${integration_exit_code:-0} -eq 0 ] && [ ${kafka_exit_code:-0} -eq 0 ]; then
        print_success "Integration tests passed"
        return 0
    else
        print_error "Integration tests failed"
        return 1
    fi
}

# Security tests
run_security_tests() {
    print_status "Running security tests..."
    
    # Backend security scan
    cd "$BACKEND_DIR"
    
    print_status "Installing security tools..."
    pip install -q safety bandit
    
    print_status "Checking for known vulnerabilities..."
    safety check --json --output ../test-results/safety-report.json || true
    
    print_status "Running static security analysis..."
    bandit -r app/ -f json -o ../test-results/bandit-report.json || true
    
    cd ..
    
    # Frontend security scan
    cd "$FRONTEND_DIR"
    
    print_status "Auditing npm packages..."
    npm audit --json > ../test-results/npm-audit.json || true
    
    cd ..
    
    print_success "Security tests completed"
}

# Performance tests
run_performance_tests() {
    print_status "Running performance tests..."
    
    if [ -d "loadtest" ]; then
        cd loadtest
        
        # Install k6 if available
        if command -v k6 &> /dev/null; then
            print_status "Running load tests with k6..."
            k6 run simple-test.js || perf_exit_code=$?
        else
            print_warning "k6 not installed, skipping performance tests"
            print_status "Install k6 for performance testing: https://k6.io/docs/getting-started/installation/"
        fi
        
        cd ..
    else
        print_warning "loadtest directory not found, skipping performance tests"
    fi
    
    if [ ${perf_exit_code:-0} -eq 0 ]; then
        print_success "Performance tests passed"
    else
        print_warning "Performance tests had issues"
    fi
}

# Generate test report
generate_test_report() {
    print_status "Generating test report..."
    
    cat > "$TEST_DIR/test-summary.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>ShopSphere Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f4f4f4; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .success { background-color: #d4edda; border-color: #c3e6cb; }
        .error { background-color: #f8d7da; border-color: #f5c6cb; }
        .warning { background-color: #fff3cd; border-color: #ffeaa7; }
        .info { background-color: #d1ecf1; border-color: #bee5eb; }
        .status { font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 ShopSphere Test Report</h1>
        <p>Generated on: $(date)</p>
        <p>Build: ${BUILD_NUMBER:-"Local"}</p>
    </div>
EOF
    
    # Add test results
    if [ $backend_tests_passed ]; then
        echo '<div class="section success"><h3>✅ Backend Tests</h3><p class="status">PASSED</p></div>' >> "$TEST_DIR/test-summary.html"
    else
        echo '<div class="section error"><h3>❌ Backend Tests</h3><p class="status">FAILED</p></div>' >> "$TEST_DIR/test-summary.html"
    fi
    
    if [ $frontend_tests_passed ]; then
        echo '<div class="section success"><h3>✅ Frontend Tests</h3><p class="status">PASSED</p></div>' >> "$TEST_DIR/test-summary.html"
    else
        echo '<div class="section error"><h3>❌ Frontend Tests</h3><p class="status">FAILED</p></div>' >> "$TEST_DIR/test-summary.html"
    fi
    
    if [ $integration_tests_passed ]; then
        echo '<div class="section success"><h3>✅ Integration Tests</h3><p class="status">PASSED</p></div>' >> "$TEST_DIR/test-summary.html"
    else
        echo '<div class="section error"><h3>❌ Integration Tests</h3><p class="status">FAILED</p></div>' >> "$TEST_DIR/test-summary.html"
    fi
    
    echo '<div class="section info"><h3>📊 Coverage Reports</h3>' >> "$TEST_DIR/test-summary.html"
    echo '<p><a href="../coverage-reports/backend-html/index.html">Backend Coverage</a></p>' >> "$TEST_DIR/test-summary.html"
    echo '<p><a href="../coverage-reports/frontend-html/index.html">Frontend Coverage</a></p>' >> "$TEST_DIR/test-summary.html"
    echo '</div>' >> "$TEST_DIR/test-summary.html"
    
    echo '</body></html>' >> "$TEST_DIR/test-summary.html"
    
    print_success "Test report generated: $TEST_DIR/test-summary.html"
}

# Main execution
main() {
    echo "🧪 ShopSphere Test Runner"
    echo "========================"
    echo
    
    setup_test_environment
    
    # Initialize test status
    backend_tests_passed=false
    frontend_tests_passed=false
    integration_tests_passed=false
    
    # Run tests
    if run_backend_tests; then
        backend_tests_passed=true
    fi
    
    if run_frontend_tests; then
        frontend_tests_passed=true
    fi
    
    if run_integration_tests; then
        integration_tests_passed=true
    fi
    
    # Run additional tests
    run_security_tests
    run_performance_tests
    
    # Generate report
    generate_test_report
    
    # Final status
    echo
    echo "=== Test Summary ==="
    echo "Backend Tests: $([ $backend_tests_passed = true ] && echo "✅ PASSED" || echo "❌ FAILED")"
    echo "Frontend Tests: $([ $frontend_tests_passed = true ] && echo "✅ PASSED" || echo "❌ FAILED")"
    echo "Integration Tests: $([ $integration_tests_passed = true ] && echo "✅ PASSED" || echo "❌ FAILED")"
    echo
    
    # Exit with appropriate code
    if [ $backend_tests_passed = true ] && [ $frontend_tests_passed = true ] && [ $integration_tests_passed = true ]; then
        print_success "All tests passed! 🎉"
        exit 0
    else
        print_error "Some tests failed! 😞"
        exit 1
    fi
}

# Run main function
main "$@"
