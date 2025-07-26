#!/bin/bash

# =============================================================================
# ShopSphere Jenkins Restart Script
# Quick script to restart Jenkins after system shutdown
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🔄 ShopSphere Jenkins Restart Script"
echo "===================================="

# Change to the project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

log_info "Project root: $PROJECT_ROOT"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    log_error "Docker is not running. Please start Docker first."
    exit 1
fi

log_success "Docker is running"

# Stop any existing Jenkins containers
log_info "Stopping existing Jenkins containers..."
cd jenkins
docker-compose -f docker-compose.jenkins.yml down 2>/dev/null || true

# Ensure the ShopSphere network exists
log_info "Ensuring ShopSphere network exists..."
docker network create shopsphere-network 2>/dev/null || log_info "Network already exists"

# Start Jenkins and database
log_info "Starting Jenkins and PostgreSQL..."
docker-compose -f docker-compose.jenkins.yml up -d

# Wait for Jenkins to start
log_info "Waiting for Jenkins to start..."
sleep 10

# Check if Jenkins is running
for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:9090 | grep -q "200"; then
        log_success "Jenkins is running and accessible!"
        break
    else
        log_info "Waiting for Jenkins to be ready... ($i/30)"
        sleep 5
    fi
    
    if [ $i -eq 30 ]; then
        log_error "Jenkins failed to start within 150 seconds"
        log_info "Check logs with: docker logs shopsphere_jenkins"
        exit 1
    fi
done

# Display status
echo ""
log_success "🎉 Jenkins has been successfully restarted!"
echo ""
echo "📋 Jenkins Information:"
echo "  🌐 Web Interface: http://localhost:9090"
echo "  🔌 Agent Port: 50000"
echo "  🗄️ Database: PostgreSQL on port 5433"
echo ""
echo "📊 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(jenkins|postgres)"

echo ""
echo "🔧 Useful Commands:"
echo "  📋 Check logs: docker logs shopsphere_jenkins"
echo "  📋 Check DB logs: docker logs jenkins_postgres"
echo "  🛑 Stop Jenkins: docker-compose -f jenkins/docker-compose.jenkins.yml down"
echo "  🔄 Restart Jenkins: $0"

echo ""
echo "🚀 Next Steps:"
echo "  1. Open http://localhost:9090 in your browser"
echo "  2. Import your comprehensive pipeline job configuration"
echo "  3. Set up GitHub webhook for automatic builds"
echo "  4. Run your comprehensive testing pipeline"

echo ""
log_success "Jenkins is ready for your comprehensive testing pipeline!"
