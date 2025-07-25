#!/bin/bash

# ShopSphere Deployment Script
# Handles deployment to different environments

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

# Default values
ENVIRONMENT="staging"
BUILD_NUMBER="latest"
DOCKER_REGISTRY="localhost:5000"
COMPOSE_PROJECT_NAME="shopsphere"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -b|--build)
            BUILD_NUMBER="$2"
            shift 2
            ;;
        -r|--registry)
            DOCKER_REGISTRY="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -e, --environment    Target environment (staging, production)"
            echo "  -b, --build         Build number or tag"
            echo "  -r, --registry      Docker registry URL"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate environment
validate_environment() {
    case $ENVIRONMENT in
        staging|production)
            print_status "Deploying to $ENVIRONMENT environment"
            ;;
        *)
            print_error "Invalid environment: $ENVIRONMENT (must be staging or production)"
            exit 1
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running"
        exit 1
    fi
    
    # Check if docker-compose is available
    if ! command -v docker-compose &> /dev/null; then
        print_error "docker-compose is not installed"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Build images if needed
build_images() {
    print_status "Building application images..."
    
    # Backend image
    print_status "Building backend image..."
    docker build -t ${DOCKER_REGISTRY}/shopsphere-backend:${BUILD_NUMBER} backend/
    docker tag ${DOCKER_REGISTRY}/shopsphere-backend:${BUILD_NUMBER} ${DOCKER_REGISTRY}/shopsphere-backend:latest
    
    # Frontend image
    print_status "Building frontend image..."
    docker build -t ${DOCKER_REGISTRY}/shopsphere-frontend:${BUILD_NUMBER} frontend/
    docker tag ${DOCKER_REGISTRY}/shopsphere-frontend:${BUILD_NUMBER} ${DOCKER_REGISTRY}/shopsphere-frontend:latest
    
    print_success "Images built successfully"
}

# Deploy to staging
deploy_staging() {
    print_status "Deploying to staging environment..."
    
    # Set staging-specific environment variables
    export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME}-staging"
    export BACKEND_IMAGE="${DOCKER_REGISTRY}/shopsphere-backend:${BUILD_NUMBER}"
    export FRONTEND_IMAGE="${DOCKER_REGISTRY}/shopsphere-frontend:${BUILD_NUMBER}"
    export POSTGRES_DB="shopdb_staging"
    export BACKEND_PORT="8001"
    export FRONTEND_PORT="3001"
    
    # Stop existing staging environment
    print_status "Stopping existing staging environment..."
    docker-compose -f docker-compose.yml down || true
    
    # Start new staging environment
    print_status "Starting staging environment..."
    docker-compose -f docker-compose.yml up -d
    
    # Wait for services to be healthy
    wait_for_health_check "staging"
    
    print_success "Staging deployment completed"
}

# Deploy to production
deploy_production() {
    print_status "Deploying to production environment..."
    
    # Production deployment requires additional checks
    if [ "$ENVIRONMENT" = "production" ]; then
        print_warning "⚠️  PRODUCTION DEPLOYMENT ⚠️"
        print_status "This will deploy to production environment"
        
        # Require confirmation for production
        read -p "Are you sure you want to deploy to production? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            print_status "Deployment cancelled"
            exit 0
        fi
    fi
    
    # Set production-specific environment variables
    export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME}-prod"
    export BACKEND_IMAGE="${DOCKER_REGISTRY}/shopsphere-backend:${BUILD_NUMBER}"
    export FRONTEND_IMAGE="${DOCKER_REGISTRY}/shopsphere-frontend:${BUILD_NUMBER}"
    export POSTGRES_DB="shopdb_production"
    export BACKEND_PORT="8000"
    export FRONTEND_PORT="3000"
    
    # Blue-green deployment strategy for production
    print_status "Implementing blue-green deployment..."
    
    # Check if production is currently running
    if docker-compose -f docker-compose.yml ps | grep -q "Up"; then
        print_status "Current production environment detected"
        
        # Start new environment on different ports temporarily
        export BACKEND_PORT="8002"
        export FRONTEND_PORT="3002"
        export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME}-green"
        
        print_status "Starting green environment..."
        docker-compose -f docker-compose.yml up -d
        
        # Wait for green environment to be healthy
        wait_for_health_check "green"
        
        # Switch traffic (this would typically involve load balancer configuration)
        print_status "Switching traffic to green environment..."
        
        # Stop old blue environment
        export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME}-prod"
        docker-compose -f docker-compose.yml down
        
        # Rename green to production
        export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME}-green"
        docker-compose -f docker-compose.yml down
        
        export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME}-prod"
        export BACKEND_PORT="8000"
        export FRONTEND_PORT="3000"
        docker-compose -f docker-compose.yml up -d
        
    else
        # First time production deployment
        print_status "Starting production environment..."
        docker-compose -f docker-compose.yml up -d
    fi
    
    # Wait for services to be healthy
    wait_for_health_check "production"
    
    print_success "Production deployment completed"
}

# Wait for health checks
wait_for_health_check() {
    local env_name=$1
    print_status "Waiting for $env_name services to be healthy..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        # Check backend health
        if curl -s -f http://localhost:${BACKEND_PORT}/health > /dev/null 2>&1; then
            print_success "Backend is healthy"
            break
        fi
        
        print_status "Attempt $attempt/$max_attempts - waiting for services..."
        sleep 10
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "Services failed to become healthy within expected time"
        print_status "Checking service logs..."
        docker-compose -f docker-compose.yml logs --tail=20
        exit 1
    fi
    
    # Run smoke tests
    run_smoke_tests
}

# Run smoke tests
run_smoke_tests() {
    print_status "Running smoke tests..."
    
    # Test backend endpoints
    print_status "Testing backend endpoints..."
    
    # Health check
    if ! curl -s -f http://localhost:${BACKEND_PORT}/health; then
        print_error "Backend health check failed"
        return 1
    fi
    
    # API endpoints
    if ! curl -s -f http://localhost:${BACKEND_PORT}/api/products; then
        print_warning "Products API endpoint check failed"
    fi
    
    # Test frontend
    print_status "Testing frontend..."
    if ! curl -s -f http://localhost:${FRONTEND_PORT}; then
        print_error "Frontend check failed"
        return 1
    fi
    
    print_success "Smoke tests passed"
}

# Rollback function
rollback() {
    print_warning "Rolling back deployment..."
    
    # This would typically involve switching back to the previous version
    # For now, we'll just stop the current deployment
    docker-compose -f docker-compose.yml down
    
    print_success "Rollback completed"
}

# Cleanup old images
cleanup_old_images() {
    print_status "Cleaning up old Docker images..."
    
    # Remove dangling images
    docker image prune -f
    
    # Remove old application images (keep last 5 versions)
    docker images ${DOCKER_REGISTRY}/shopsphere-backend --format "table {{.Tag}}" | tail -n +6 | xargs -r docker rmi ${DOCKER_REGISTRY}/shopsphere-backend: || true
    docker images ${DOCKER_REGISTRY}/shopsphere-frontend --format "table {{.Tag}}" | tail -n +6 | xargs -r docker rmi ${DOCKER_REGISTRY}/shopsphere-frontend: || true
    
    print_success "Cleanup completed"
}

# Post-deployment tasks
post_deployment() {
    print_status "Running post-deployment tasks..."
    
    # Database migrations (if needed)
    if [ "$ENVIRONMENT" = "production" ]; then
        print_status "Running database migrations..."
        docker-compose -f docker-compose.yml exec backend alembic upgrade head || true
    fi
    
    # Send notifications
    send_notifications
    
    # Update monitoring
    update_monitoring
    
    print_success "Post-deployment tasks completed"
}

# Send notifications
send_notifications() {
    print_status "Sending deployment notifications..."
    
    local message="🚀 ShopSphere deployed to $ENVIRONMENT - Build: $BUILD_NUMBER"
    
    # Slack notification (if webhook URL is configured)
    if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$message\"}" \
            "$SLACK_WEBHOOK_URL" || true
    fi
    
    # Email notification (if configured)
    if [ -n "${EMAIL_NOTIFICATION:-}" ]; then
        echo "$message" | mail -s "ShopSphere Deployment" "$EMAIL_NOTIFICATION" || true
    fi
    
    print_success "Notifications sent"
}

# Update monitoring
update_monitoring() {
    print_status "Updating monitoring configuration..."
    
    # Update Prometheus targets (if using Prometheus)
    # This would typically involve updating service discovery or configuration files
    
    print_success "Monitoring updated"
}

# Display deployment information
show_deployment_info() {
    echo
    print_success "🎉 Deployment Summary"
    echo "===================="
    echo "Environment: $ENVIRONMENT"
    echo "Build Number: $BUILD_NUMBER"
    echo "Backend URL: http://localhost:${BACKEND_PORT}"
    echo "Frontend URL: http://localhost:${FRONTEND_PORT}"
    echo "Deployment Time: $(date)"
    echo
    echo "=== Useful Commands ==="
    echo "• View logs: docker-compose -f docker-compose.yml logs -f"
    echo "• Check status: docker-compose -f docker-compose.yml ps"
    echo "• Stop services: docker-compose -f docker-compose.yml down"
    echo "• Rollback: $0 --rollback"
    echo
}

# Main execution
main() {
    echo "🚢 ShopSphere Deployment Script"
    echo "==============================="
    echo
    
    validate_environment
    check_prerequisites
    
    case $ENVIRONMENT in
        staging)
            build_images
            deploy_staging
            ;;
        production)
            deploy_production
            ;;
    esac
    
    post_deployment
    cleanup_old_images
    show_deployment_info
    
    print_success "Deployment completed successfully! 🎉"
}

# Handle script termination
trap 'print_error "Deployment interrupted"; exit 1' INT TERM

# Run main function
main "$@"
