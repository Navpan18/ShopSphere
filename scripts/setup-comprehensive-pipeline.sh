#!/bin/bash

# =============================================================================
# Setup ShopSphere Comprehensive Pipeline in Jenkins
# =============================================================================

set -e

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

echo "🎯 Setting up ShopSphere Comprehensive Testing Pipeline"
echo "====================================================="

# Check if Jenkins is running
if ! curl -s -o /dev/null http://localhost:9090; then
    log_error "Jenkins is not accessible at http://localhost:9090"
    log_info "Please run: ./scripts/restart-jenkins.sh"
    exit 1
fi

log_success "Jenkins is accessible"

# Get Jenkins CLI jar if not exists
if [ ! -f "jenkins-cli.jar" ]; then
    log_info "Downloading Jenkins CLI..."
    wget -q http://localhost:9090/jnlpJars/jenkins-cli.jar
fi

# Check if comprehensive pipeline job exists
JOB_NAME="ShopSphere-Comprehensive"
if curl -s "http://localhost:9090/job/$JOB_NAME/api/json" | grep -q "name"; then
    log_warning "Job '$JOB_NAME' already exists"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Updating existing job..."
        java -jar jenkins-cli.jar -s http://localhost:9090 update-job "$JOB_NAME" < jenkins-comprehensive-job-config.xml
    else
        log_info "Skipping job creation"
        exit 0
    fi
else
    log_info "Creating comprehensive pipeline job..."
    java -jar jenkins-cli.jar -s http://localhost:9090 create-job "$JOB_NAME" < jenkins-comprehensive-job-config.xml
fi

log_success "Comprehensive pipeline job configured!"

echo ""
echo "🚀 Pipeline Setup Complete!"
echo ""
echo "📋 Job Details:"
echo "  📛 Job Name: $JOB_NAME"
echo "  🌐 Job URL: http://localhost:9090/job/$JOB_NAME"
echo "  📄 Pipeline File: Jenkinsfile.comprehensive"
echo ""
echo "⚙️ Pipeline Features:"
echo "  ✅ Unit Testing (Backend, Frontend, Microservices)"
echo "  ✅ Integration Testing (API, Database, Kafka, Redis)"
echo "  ✅ End-to-End Testing (Playwright)"
echo "  ✅ Security Testing (SAST, DAST, Container)"
echo "  ✅ Performance Testing (K6, Lighthouse)"
echo "  ✅ Quality Gates & Coverage Analysis"
echo "  ✅ Staging & Production Deployment"
echo ""
echo "🔧 Next Steps:"
echo "  1. Open Jenkins: http://localhost:9090"
echo "  2. Navigate to job: http://localhost:9090/job/$JOB_NAME"
echo "  3. Configure GitHub webhook (if needed)"
echo "  4. Run the comprehensive pipeline"
echo ""
echo "📚 Documentation:"
echo "  📖 Pipeline Guide: docs/comprehensive-pipeline-guide.md"
echo "  🧪 Test Runner: scripts/comprehensive-test-runner.sh"
echo "  💨 Smoke Tests: scripts/smoke-tests.sh"
echo ""

log_success "Ready to run comprehensive testing!"
