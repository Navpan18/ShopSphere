#!/bin/bash

# =============================================================================
# ShopSphere Test Environment Setup
# Prepares the environment for comprehensive testing
# =============================================================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$PROJECT_ROOT/test_environments"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "🔧 Setting up ShopSphere testing environment..."

# =============================================================================
# System Requirements Check
# =============================================================================

check_system_requirements() {
    log_info "Checking system requirements..."
    
    # Check OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_success "Linux OS detected"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log_success "macOS detected"
    else
        log_warning "Unsupported OS: $OSTYPE"
    fi
    
    # Check available memory
    if command -v free &> /dev/null; then
        MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
        if [ "$MEMORY_GB" -lt 4 ]; then
            log_warning "Low memory: ${MEMORY_GB}GB (recommend 8GB+)"
        else
            log_success "Memory: ${MEMORY_GB}GB"
        fi
    fi
    
    # Check disk space
    DISK_SPACE=$(df -h . | awk 'NR==2 {print $4}')
    log_info "Available disk space: $DISK_SPACE"
}

# =============================================================================
# Install Dependencies
# =============================================================================

install_python_dependencies() {
    log_info "Installing Python dependencies..."
    
    # Check Python version
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is required but not installed"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
    log_info "Python version: $PYTHON_VERSION"
    
    # Install pip if not available
    if ! command -v pip3 &> /dev/null; then
        log_info "Installing pip..."
        curl https://bootstrap.pypa.io/get-pip.py | python3
    fi
    
    # Upgrade pip
    python3 -m pip install --upgrade pip
    
    # Install testing tools
    log_info "Installing Python testing tools..."
    python3 -m pip install --user \
        pytest \
        pytest-cov \
        pytest-xdist \
        pytest-mock \
        pytest-asyncio \
        pytest-html \
        bandit \
        safety \
        semgrep \
        flake8 \
        black \
        isort \
        mypy
    
    log_success "Python dependencies installed"
}

install_node_dependencies() {
    log_info "Installing Node.js dependencies..."
    
    # Check Node.js version
    if ! command -v node &> /dev/null; then
        log_error "Node.js is required but not installed"
        log_info "Please install Node.js 18+ from https://nodejs.org/"
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    log_info "Node.js version: $NODE_VERSION"
    
    # Check npm version
    if ! command -v npm &> /dev/null; then
        log_error "npm is required but not installed"
        exit 1
    fi
    
    NPM_VERSION=$(npm --version)
    log_info "npm version: $NPM_VERSION"
    
    # Install global testing tools
    log_info "Installing Node.js testing tools..."
    npm install -g \
        jest \
        @playwright/test \
        lighthouse \
        @lhci/cli \
        eslint \
        prettier \
        audit-ci || log_warning "Some npm packages may require sudo"
    
    log_success "Node.js dependencies installed"
}

install_docker() {
    log_info "Checking Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        log_warning "Docker is not installed"
        log_info "Installing Docker..."
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux Docker installation
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh
            sudo usermod -aG docker $USER
            log_info "Please log out and back in to use Docker without sudo"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            log_info "Please install Docker Desktop from https://docker.com/products/docker-desktop"
            exit 1
        fi
    else
        DOCKER_VERSION=$(docker --version)
        log_success "Docker installed: $DOCKER_VERSION"
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_info "Installing Docker Compose..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        fi
    else
        COMPOSE_VERSION=$(docker-compose --version)
        log_success "Docker Compose installed: $COMPOSE_VERSION"
    fi
}

install_k6() {
    log_info "Installing K6 for performance testing..."
    
    if ! command -v k6 &> /dev/null; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl -s https://github.com/grafana/k6/releases/download/v0.47.0/k6-v0.47.0-linux-amd64.tar.gz | tar xz
            sudo mv k6-v0.47.0-linux-amd64/k6 /usr/local/bin/
            rm -rf k6-v0.47.0-linux-amd64
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew &> /dev/null; then
                brew install k6
            else
                curl -s https://github.com/grafana/k6/releases/download/v0.47.0/k6-v0.47.0-macos-amd64.zip -o k6.zip
                unzip k6.zip
                sudo mv k6-v0.47.0-macos-amd64/k6 /usr/local/bin/
                rm -rf k6-v0.47.0-macos-amd64 k6.zip
            fi
        fi
        log_success "K6 installed"
    else
        K6_VERSION=$(k6 version)
        log_success "K6 already installed: $K6_VERSION"
    fi
}

# =============================================================================
# Setup Virtual Environments
# =============================================================================

setup_python_environments() {
    log_info "Setting up Python virtual environments..."
    
    mkdir -p "$VENV_DIR"
    
    # Backend environment
    if [ ! -d "$VENV_DIR/backend" ]; then
        log_info "Creating backend virtual environment..."
        python3 -m venv "$VENV_DIR/backend"
        source "$VENV_DIR/backend/bin/activate"
        pip install --upgrade pip
        pip install -r "$PROJECT_ROOT/backend/requirements.txt"
        deactivate
        log_success "Backend environment created"
    else
        log_info "Backend environment already exists"
    fi
    
    # Microservices environments
    for service in analytics-service notification-service; do
        if [ ! -d "$VENV_DIR/$service" ]; then
            log_info "Creating $service virtual environment..."
            python3 -m venv "$VENV_DIR/$service"
            source "$VENV_DIR/$service/bin/activate"
            pip install --upgrade pip
            if [ -f "$PROJECT_ROOT/microservices/$service/requirements.txt" ]; then
                pip install -r "$PROJECT_ROOT/microservices/$service/requirements.txt"
            fi
            deactivate
            log_success "$service environment created"
        else
            log_info "$service environment already exists"
        fi
    done
}

setup_node_environments() {
    log_info "Setting up Node.js environments..."
    
    # Frontend environment
    if [ -f "$PROJECT_ROOT/frontend/package.json" ]; then
        cd "$PROJECT_ROOT/frontend"
        if [ ! -d "node_modules" ]; then
            log_info "Installing frontend dependencies..."
            npm ci
            log_success "Frontend dependencies installed"
        else
            log_info "Frontend dependencies already installed"
        fi
        cd "$PROJECT_ROOT"
    fi
    
    # Load test environment
    if [ -d "$PROJECT_ROOT/loadtest" ]; then
        cd "$PROJECT_ROOT/loadtest"
        if [ ! -f "package.json" ]; then
            log_info "Initializing load test environment..."
            npm init -y
            npm install k6
        fi
        cd "$PROJECT_ROOT"
    fi
}

# =============================================================================
# Setup Test Databases
# =============================================================================

setup_test_databases() {
    log_info "Setting up test databases..."
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        log_warning "Docker is not running, skipping database setup"
        return
    fi
    
    # PostgreSQL test database
    if ! docker ps | grep -q postgres-test; then
        log_info "Starting PostgreSQL test database..."
        docker run -d --name postgres-test \
            -e POSTGRES_DB=shopsphere_test \
            -e POSTGRES_USER=test_user \
            -e POSTGRES_PASSWORD=test_password \
            -p 5433:5432 \
            postgres:14
        
        log_info "Waiting for PostgreSQL to be ready..."
        sleep 10
        
        # Test connection
        if docker exec postgres-test pg_isready -U test_user; then
            log_success "PostgreSQL test database ready"
        else
            log_error "PostgreSQL test database failed to start"
        fi
    else
        log_info "PostgreSQL test database already running"
    fi
    
    # Redis test database
    if ! docker ps | grep -q redis-test; then
        log_info "Starting Redis test database..."
        docker run -d --name redis-test \
            -p 6380:6379 \
            redis:alpine
        
        sleep 5
        
        # Test connection
        if docker exec redis-test redis-cli ping; then
            log_success "Redis test database ready"
        else
            log_error "Redis test database failed to start"
        fi
    else
        log_info "Redis test database already running"
    fi
}

# =============================================================================
# Create Test Configuration Files
# =============================================================================

create_test_configs() {
    log_info "Creating test configuration files..."
    
    # pytest.ini for backend
    cat > "$PROJECT_ROOT/pytest.ini" << 'EOF'
[tool:pytest]
minversion = 6.0
addopts = 
    -ra 
    -q 
    --strict-markers 
    --strict-config 
    --cov=app 
    --cov-report=term-missing 
    --cov-report=html 
    --cov-report=xml
    --cov-fail-under=80
testpaths = 
    backend/tests
    microservices/*/tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
markers =
    slow: marks tests as slow (deselect with '-m "not slow"')
    integration: marks tests as integration tests
    unit: marks tests as unit tests
    security: marks tests as security tests
    performance: marks tests as performance tests
EOF
    
    # Jest configuration update for frontend
    if [ -f "$PROJECT_ROOT/frontend/package.json" ]; then
        log_info "Updating Jest configuration..."
        # The configuration is already in package.json
    fi
    
    # ESLint security configuration
    cat > "$PROJECT_ROOT/frontend/.eslintrc.security.js" << 'EOF'
module.exports = {
  extends: ['plugin:security/recommended'],
  plugins: ['security'],
  rules: {
    'security/detect-object-injection': 'error',
    'security/detect-non-literal-fs-filename': 'error',
    'security/detect-unsafe-regex': 'error',
    'security/detect-buffer-noassert': 'error',
    'security/detect-child-process': 'error',
    'security/detect-disable-mustache-escape': 'error',
    'security/detect-eval-with-expression': 'error',
    'security/detect-no-csrf-before-method-override': 'error',
    'security/detect-non-literal-regexp': 'error',
    'security/detect-non-literal-require': 'error',
    'security/detect-possible-timing-attacks': 'error',
    'security/detect-pseudoRandomBytes': 'error'
  }
};
EOF
    
    log_success "Test configuration files created"
}

# =============================================================================
# Setup Monitoring and Reporting
# =============================================================================

setup_monitoring() {
    log_info "Setting up monitoring and reporting..."
    
    # Create directories for reports
    mkdir -p "$PROJECT_ROOT"/{test-results,coverage-reports,security-reports,performance-reports}
    mkdir -p "$PROJECT_ROOT"/coverage-reports/{backend,frontend,analytics,notifications}
    
    # Create monitoring script
    cat > "$PROJECT_ROOT/scripts/monitor-tests.sh" << 'EOF'
#!/bin/bash
# Test monitoring script
echo "🔍 Monitoring test execution..."

while true; do
    echo "$(date): Checking test processes..."
    
    # Check for running pytest processes
    if pgrep -f pytest > /dev/null; then
        echo "  - Backend tests running"
    fi
    
    # Check for running Jest processes
    if pgrep -f jest > /dev/null; then
        echo "  - Frontend tests running"
    fi
    
    # Check for running Docker containers
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(test|postgres|redis)"; then
        echo "  - Test containers running"
    fi
    
    sleep 30
done
EOF
    
    chmod +x "$PROJECT_ROOT/scripts/monitor-tests.sh"
    
    log_success "Monitoring setup completed"
}

# =============================================================================
# Validation
# =============================================================================

validate_setup() {
    log_info "Validating test environment setup..."
    
    local validation_failed=false
    
    # Check Python environment
    if source "$VENV_DIR/backend/bin/activate" 2>/dev/null; then
        if python -c "import pytest, coverage" 2>/dev/null; then
            log_success "Backend Python environment valid"
        else
            log_error "Backend Python environment missing dependencies"
            validation_failed=true
        fi
        deactivate
    else
        log_error "Backend Python environment not found"
        validation_failed=true
    fi
    
    # Check Node.js environment
    if [ -f "$PROJECT_ROOT/frontend/package.json" ]; then
        cd "$PROJECT_ROOT/frontend"
        if npm list jest >/dev/null 2>&1; then
            log_success "Frontend Node.js environment valid"
        else
            log_error "Frontend Node.js environment missing dependencies"
            validation_failed=true
        fi
        cd "$PROJECT_ROOT"
    fi
    
    # Check Docker
    if docker info >/dev/null 2>&1; then
        log_success "Docker is accessible"
    else
        log_error "Docker is not accessible"
        validation_failed=true
    fi
    
    # Check test databases
    if docker ps | grep -q postgres-test; then
        log_success "PostgreSQL test database running"
    else
        log_warning "PostgreSQL test database not running"
    fi
    
    if docker ps | grep -q redis-test; then
        log_success "Redis test database running"
    else
        log_warning "Redis test database not running"
    fi
    
    if $validation_failed; then
        log_error "Environment validation failed"
        exit 1
    else
        log_success "Environment validation passed"
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo "🔧 ShopSphere Test Environment Setup"
    echo "===================================="
    echo ""
    
    check_system_requirements
    install_python_dependencies
    install_node_dependencies
    install_docker
    install_k6
    setup_python_environments
    setup_node_environments
    setup_test_databases
    create_test_configs
    setup_monitoring
    validate_setup
    
    echo ""
    echo "✅ Test environment setup completed successfully!"
    echo ""
    echo "📋 Summary:"
    echo "  - Python testing tools installed"
    echo "  - Node.js testing tools installed"
    echo "  - Docker environment ready"
    echo "  - Test databases configured"
    echo "  - Virtual environments created"
    echo "  - Configuration files generated"
    echo "  - Monitoring tools setup"
    echo ""
    echo "🚀 Ready to run comprehensive tests!"
    echo "    Use: ./scripts/comprehensive-test-runner.sh"
    echo ""
}

# Execute main function
main "$@"
