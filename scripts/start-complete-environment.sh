#!/bin/bash

# =============================================================================
# ShopSphere Complete Environment Startup Script
# Starts Jenkins, ngrok, and sets up the comprehensive testing pipeline
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() { echo -e "${PURPLE}[HEADER]${NC} $1"; }

echo "🚀 ShopSphere Complete Environment Startup"
echo "=========================================="

# Check prerequisites
log_info "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed or not running"
    exit 1
fi

if ! command -v ngrok &> /dev/null; then
    log_error "ngrok is not installed"
    exit 1
fi

log_success "All prerequisites satisfied"

# Start Jenkins if not running
log_header "Starting Jenkins..."
cd jenkins

if ! curl -s -o /dev/null http://localhost:9090; then
    log_info "Jenkins not running, starting..."
    
    # Ensure network exists
    docker network create shopsphere-network 2>/dev/null || true
    
    # Start Jenkins stack
    docker-compose -f docker-compose.jenkins.yml down 2>/dev/null || true
    docker-compose -f docker-compose.jenkins.yml up -d
    
    log_info "Waiting for Jenkins to start..."
    for i in {1..30}; do
        if curl -s -o /dev/null http://localhost:9090; then
            log_success "Jenkins is running!"
            break
        fi
        sleep 5
        log_info "Waiting... ($i/30)"
    done
else
    log_success "Jenkins is already running"
fi

cd ..

# Start ngrok if not running
log_header "Starting ngrok..."

if ! pgrep -f "ngrok.*9090" > /dev/null; then
    log_info "Starting ngrok tunnel for Jenkins..."
    
    # Kill any existing ngrok processes
    pkill -f ngrok || true
    sleep 2
    
    # Start ngrok in background
    nohup ngrok http 9090 --log stdout > ngrok.log 2>&1 &
    
    log_info "Waiting for ngrok to establish tunnel..."
    sleep 10
    
    # Get public URL
    for i in {1..10}; do
        PUBLIC_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "import sys, json; data = json.load(sys.stdin); print(data['tunnels'][0]['public_url'] if data['tunnels'] else '')" 2>/dev/null || echo "")
        
        if [ -n "$PUBLIC_URL" ]; then
            log_success "ngrok tunnel established!"
            break
        fi
        
        sleep 5
        log_info "Waiting for ngrok... ($i/10)"
    done
else
    log_success "ngrok is already running"
    PUBLIC_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "import sys, json; data = json.load(sys.stdin); print(data['tunnels'][0]['public_url'] if data['tunnels'] else '')" 2>/dev/null || echo "")
fi

# Setup comprehensive pipeline
log_header "Setting up Comprehensive Testing Pipeline..."

# Download Jenkins CLI if not exists
if [ ! -f "jenkins-cli.jar" ]; then
    log_info "Downloading Jenkins CLI..."
    curl -s http://localhost:9090/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar
fi

# Wait for Jenkins to be fully ready
log_info "Ensuring Jenkins is fully ready..."
sleep 15

# Check if comprehensive pipeline job exists
JOB_NAME="ShopSphere-Comprehensive"
if curl -s "http://localhost:9090/job/$JOB_NAME/api/json" | grep -q "name"; then
    log_warning "Job '$JOB_NAME' already exists, updating..."
    java -jar jenkins-cli.jar -s http://localhost:9090 update-job "$JOB_NAME" < jenkins-comprehensive-job-config.xml || log_warning "Failed to update job"
else
    log_info "Creating comprehensive pipeline job..."
    java -jar jenkins-cli.jar -s http://localhost:9090 create-job "$JOB_NAME" < jenkins-comprehensive-job-config.xml || log_error "Failed to create job"
fi

# Generate summary
log_header "Environment Status Summary"

echo ""
echo "🎯 ${CYAN}SHOPSPHERE TESTING ENVIRONMENT READY${NC}"
echo "============================================"
echo ""

# Jenkins info
echo "🏗️  ${YELLOW}Jenkins Information:${NC}"
echo "   📍 Local URL:  http://localhost:9090"
if [ -n "$PUBLIC_URL" ]; then
    echo "   🌐 Public URL: $PUBLIC_URL"
    echo "   📱 ngrok Web:  http://localhost:4040"
else
    echo "   ⚠️  Public URL: Not available (ngrok tunnel failed)"
fi
echo ""

# Container status
echo "🐳 ${YELLOW}Container Status:${NC}"
docker ps --format "   📦 {{.Names}}: {{.Status}}" | grep -E "(jenkins|postgres)" || echo "   ⚠️  No containers found"
echo ""

# Pipeline info
echo "🧪 ${YELLOW}Comprehensive Testing Pipeline:${NC}"
echo "   📛 Job Name: $JOB_NAME"
echo "   🔗 Pipeline URL: http://localhost:9090/job/$JOB_NAME"
if [ -n "$PUBLIC_URL" ]; then
    echo "   🌐 Public Pipeline: $PUBLIC_URL/job/$JOB_NAME"
fi
echo ""

# Features overview
echo "⚡ ${YELLOW}Pipeline Features:${NC}"
echo "   ✅ Unit Testing (Backend, Frontend, Microservices)"
echo "   ✅ Integration Testing (API, Database, Kafka, Redis)"
echo "   ✅ End-to-End Testing (Playwright)"
echo "   ✅ Security Testing (SAST, DAST, Container)"
echo "   ✅ Performance Testing (K6, Lighthouse)"
echo "   ✅ Quality Gates & Coverage Analysis"
echo "   ✅ Staging & Production Deployment"
echo ""

# Next steps
echo "🚀 ${YELLOW}Ready to Test:${NC}"
echo "   1. Open Jenkins: ${CYAN}http://localhost:9090${NC}"
echo "   2. Navigate to: ${CYAN}http://localhost:9090/job/$JOB_NAME${NC}"
echo "   3. Click 'Build with Parameters'"
echo "   4. Configure test options and run"
echo ""

if [ -n "$PUBLIC_URL" ]; then
    echo "🌍 ${YELLOW}Public Access (for webhooks):${NC}"
    echo "   🔗 Public Jenkins: ${CYAN}$PUBLIC_URL${NC}"
    echo "   🪝 Webhook URL: ${CYAN}$PUBLIC_URL/github-webhook/${NC}"
    echo ""
fi

# Useful commands
echo "🔧 ${YELLOW}Useful Commands:${NC}"
echo "   📋 View logs: ${CYAN}docker logs shopsphere_jenkins${NC}"
echo "   📋 Stop all: ${CYAN}docker-compose -f jenkins/docker-compose.jenkins.yml down && pkill ngrok${NC}"
echo "   🔄 Restart: ${CYAN}$0${NC}"
echo ""

# Save URLs to file for later reference
cat > environment-urls.txt << EOF
# ShopSphere Environment URLs
# Generated: $(date)

Jenkins Local: http://localhost:9090
Jenkins Public: $PUBLIC_URL
ngrok Dashboard: http://localhost:4040
Pipeline Job: http://localhost:9090/job/$JOB_NAME
Public Pipeline: $PUBLIC_URL/job/$JOB_NAME
Webhook URL: $PUBLIC_URL/github-webhook/

# Test Scripts
Comprehensive Tests: ./scripts/comprehensive-test-runner.sh
Smoke Tests: ./scripts/smoke-tests.sh
Setup Environment: ./scripts/setup-test-environment.sh
EOF

log_success "Environment URLs saved to environment-urls.txt"

echo ""
log_success "🎉 Complete environment is ready for comprehensive testing!"
echo ""

# Optional: Open browser
if command -v open &> /dev/null; then
    read -p "Open Jenkins in browser? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "http://localhost:9090/job/$JOB_NAME"
    fi
fi
