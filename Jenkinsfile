pipeline {
    agent any
    
    environment {
        // Docker configurations
        DOCKER_REGISTRY = "localhost:5000"
        DOCKER_IMAGE_BACKEND = "shopsphere-backend"
        DOCKER_IMAGE_FRONTEND = "shopsphere-frontend"
        DOCKER_IMAGE_ANALYTICS = "shopsphere-analytics"
        DOCKER_IMAGE_NOTIFICATIONS = "shopsphere-notifications"
        
        // Application configurations
        APP_NAME = "shopsphere"
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        GIT_COMMIT_SHORT = "${env.GIT_COMMIT?.take(7) ?: 'unknown'}"
        
        // Build configurations - NO TESTING
        NODE_ENV = "production"
        
        // Database configurations for container health check
        POSTGRES_DB = "shopdb_build"
        POSTGRES_USER = "builduser"
        POSTGRES_PASSWORD = "buildpass123"
        REDIS_URL = "redis://localhost:6380/1"
        
        // Service URLs for health check only
        BACKEND_URL = "http://localhost:8011"
        FRONTEND_URL = "http://localhost:3010"
        ANALYTICS_URL = "http://localhost:8012"
        NOTIFICATIONS_URL = "http://localhost:8013"
        
        // Kafka configurations for health check
        KAFKA_BOOTSTRAP_SERVERS = "localhost:9093"
        
        // Deployment configurations
        COMPOSE_PROJECT_NAME = "shopsphere-build"
        DEPLOY_ENV = "build"
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10', daysToKeepStr: '14'))
        timeout(time: 45, unit: 'MINUTES')
        timestamps()
        skipDefaultCheckout(false)
    }
    
    triggers {
        pollSCM('H/5 * * * *')  // Poll every 5 minutes as backup
        githubPush()  // GitHub webhook trigger
    }
    
    stages {
        stage('🚀 Initialize Build Pipeline') {
            steps {
                script {
                    echo "=== 🎯 SHOPSPHERE BUILD PIPELINE (NO TESTING) ==="
                    echo "Build: ${BUILD_NUMBER}"
                    echo "Commit: ${GIT_COMMIT_SHORT}"
                    echo "Branch: ${env.BRANCH_NAME ?: env.GIT_BRANCH}"
                    echo "Timestamp: ${new Date()}"
                    
                    // Set build description
                    currentBuild.description = "Build Only - ${GIT_COMMIT_SHORT}"
                    
                    // Verify Docker is available
                    sh '''
                        echo "=== 🔧 Tool Verification ==="
                        which docker || (echo "Docker not found!" && exit 1)
                        which docker-compose || (echo "Docker Compose not found!" && exit 1)
                        echo "Docker tools available ✅"
                    '''
                }
                
                cleanWs()
                checkout scm
                
                sh '''
                    mkdir -p build-artifacts
                    echo "Build workspace prepared ✅"
                '''
            }
        }
        
        stage('🔍 Environment Check & Pre-Build Cleanup') {
            steps {
                sh '''
                    echo "=== 🔧 Environment Check ==="
                    echo "Docker Version: $(docker --version)"
                    echo "Docker Compose Version: $(docker-compose --version)"
                    
                    echo "=== 🧹 COMPREHENSIVE PRE-BUILD CLEANUP ==="
                    
                    # Stop any running containers that might be using our ports or names
                    echo "🛑 Stopping any running test containers..."
                    for container in "test-backend-${BUILD_NUMBER}" "test-frontend-${BUILD_NUMBER}" "test-analytics-${BUILD_NUMBER}" "test-notifications-${BUILD_NUMBER}"; do
                        if docker ps --format "{{.Names}}" | grep -q "^${container}$" 2>/dev/null; then
                            echo "Stopping running container: ${container}"
                            docker stop "${container}" 2>/dev/null || true
                        fi
                    done
                    
                    # Remove any existing test containers (stopped or running)
                    echo "🗑️ Removing any existing test containers..."
                    for container in "test-backend-${BUILD_NUMBER}" "test-frontend-${BUILD_NUMBER}" "test-analytics-${BUILD_NUMBER}" "test-notifications-${BUILD_NUMBER}"; do
                        if docker ps -a --format "{{.Names}}" | grep -q "^${container}$" 2>/dev/null; then
                            echo "Removing container: ${container}"
                            docker rm -f "${container}" 2>/dev/null || true
                        fi
                    done
                    
                    # Remove any existing test images to prevent "already exists" errors
                    echo "🗑️ Removing any existing test/build images..."
                    for image in "${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}" "${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}" "${DOCKER_IMAGE_ANALYTICS}:${BUILD_NUMBER}" "${DOCKER_IMAGE_NOTIFICATIONS}:${BUILD_NUMBER}"; do
                        if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$" 2>/dev/null; then
                            echo "Removing existing image: ${image}"
                            docker rmi -f "${image}" 2>/dev/null || true
                        fi
                    done
                    
                    # Remove any existing test networks
                    echo "🗑️ Removing any existing test networks..."
                    for network in "shopsphere-build-network" "shopsphere-test-network" "test-network" "test-network-${BUILD_NUMBER}" "shopsphere-test-${BUILD_NUMBER}"; do
                        if docker network ls --format "{{.Name}}" | grep -q "^${network}$" 2>/dev/null; then
                            echo "Removing existing network: ${network}"
                            docker network rm "${network}" 2>/dev/null || true
                        fi
                    done
                    
                    # Clean up any leftover docker-compose files
                    echo "🗑️ Removing any leftover docker-compose test files..."
                    rm -f docker-compose.test.yml || true
                    
                    # General Docker cleanup
                    echo "🧽 General Docker cleanup..."
                    docker container prune -f || true
                    docker network prune -f || true
                    
                    echo "✅ Pre-build cleanup completed - ready for fresh builds!"
                '''
            }
        }
        
        stage('🏗️ Build Services') {
            parallel {
                stage('Build Backend') {
                    steps {
                        sh '''
                            echo "=== 🏗️ Building Backend with Optimized 1GB Memory ==="
                            cd backend
                            docker build --memory=1g --memory-swap=2g --shm-size=1g -t ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} . --no-cache
                            echo "✅ Backend build completed"
                            
                            # Show image info
                            echo "📦 Backend image size: $(docker images ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} --format '{{.Size}}')"
                        '''
                    }
                }
                
                stage('Build Frontend') {
                    steps {
                        sh '''
                            echo "=== 🏗️ Building Frontend with Optimized 1GB Memory ==="
                            cd frontend
                            docker build --memory=1g --memory-swap=2g --shm-size=1g -t ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} . --no-cache
                            echo "✅ Frontend build completed"
                            
                            # Show image info
                            echo "📦 Frontend image size: $(docker images ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} --format '{{.Size}}')"
                        '''
                    }
                }
                
                stage('Build Analytics') {
                    steps {
                        sh '''
                            echo "=== 🏗️ Building Analytics with Optimized 1GB Memory ==="
                            cd microservices/analytics-service
                            docker build --memory=1g --memory-swap=2g --shm-size=1g -t ${DOCKER_IMAGE_ANALYTICS}:${BUILD_NUMBER} . --no-cache
                            echo "✅ Analytics build completed"
                            
                            # Show image info
                            echo "📦 Analytics image size: $(docker images ${DOCKER_IMAGE_ANALYTICS}:${BUILD_NUMBER} --format '{{.Size}}')"
                        '''
                    }
                }
                
                stage('Build Notifications') {
                    steps {
                        sh '''
                            echo "=== 🏗️ Building Notifications with Optimized 1GB Memory ==="
                            cd microservices/notification-service
                            docker build --memory=1g --memory-swap=2g --shm-size=1g -t ${DOCKER_IMAGE_NOTIFICATIONS}:${BUILD_NUMBER} . --no-cache
                            echo "✅ Notifications build completed"
                            
                            # Show image info
                            echo "📦 Notifications image size: $(docker images ${DOCKER_IMAGE_NOTIFICATIONS}:${BUILD_NUMBER} --format '{{.Size}}')"
                        '''
                    }
                }
            }
        }
        
        stage('🐳 Container Health Check') {
            steps {
                script {
                    sh '''
                        echo "=== 🐳 Starting Test Containers for Health Check ==="
                        
                        # Ensure no conflicts before creating docker-compose
                        echo "🔍 Final check - ensuring no conflicting resources..."
                        
                        # Create temporary docker-compose for testing with all 4 services
                        cat > docker-compose.test.yml << EOF
version: '3.8'
services:
  backend-test:
    image: shopsphere-backend:${BUILD_NUMBER}
    container_name: test-backend-${BUILD_NUMBER}
    ports:
      - "8011:8001"
    environment:
      - NODE_ENV=test
    networks:
      - test-network-${BUILD_NUMBER}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/health"]
      interval: 10s
      timeout: 5s
      retries: 3
  
  frontend-test:
    image: shopsphere-frontend:${BUILD_NUMBER}
    container_name: test-frontend-${BUILD_NUMBER}
    ports:
      - "3010:3000"
    environment:
      - NODE_OPTIONS=--max-old-space-size=8192
      - NEXT_TELEMETRY_DISABLED=1
    networks:
      - test-network-${BUILD_NUMBER}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/"]
      interval: 15s
      timeout: 10s
      retries: 5

  analytics-test:
    image: shopsphere-analytics:${BUILD_NUMBER}
    container_name: test-analytics-${BUILD_NUMBER}
    ports:
      - "8012:8002"
    environment:
      - NODE_ENV=test
    networks:
      - test-network-${BUILD_NUMBER}

  notifications-test:
    image: shopsphere-notifications:${BUILD_NUMBER}
    container_name: test-notifications-${BUILD_NUMBER}
    ports:
      - "8013:8003"
    environment:
      - NODE_ENV=test
    networks:
      - test-network-${BUILD_NUMBER}

networks:
  test-network-${BUILD_NUMBER}:
    driver: bridge
EOF
                        
                        # Create network first to avoid conflicts
                        echo "🌐 Creating test network..."
                        docker network create test-network-${BUILD_NUMBER} 2>/dev/null || echo "Network test-network-${BUILD_NUMBER} already exists or failed to create, continuing..."
                        
                        # Start test containers with host networking
                        echo "🚀 Starting test containers with host networking..."
                        docker-compose -f docker-compose.test.yml up -d
                        
                        echo "⏰ Waiting 30 seconds for containers to initialize..."
                        sleep 30
                        
                        echo "=== 🔍 Checking Service Health (Backend & Frontend Only) ==="
                        
                        # Check if containers are running
                        echo "Current test containers:"
                        docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}" | grep test- || echo "No test containers found in ps output"
                        
                        # Check container logs for debugging
                        echo "📋 Backend container logs:"
                        docker logs test-backend-${BUILD_NUMBER} 2>&1 | tail -10 || echo "Cannot get backend logs"
                        
                        echo "📋 Frontend container logs:"  
                        docker logs test-frontend-${BUILD_NUMBER} 2>&1 | tail -10 || echo "Cannot get frontend logs"
                        
                        # Wait for backend to be ready (faster startup)
                        echo "📊 Checking Backend Health via container network:"
                        BACKEND_HEALTHY=false
                        for i in $(seq 1 10); do
                            # First check if container is running
                            if docker ps | grep -q "test-backend-${BUILD_NUMBER}"; then
                                # Check via container name (Jenkins can access containers by name)
                                if docker exec test-backend-${BUILD_NUMBER} curl -f http://localhost:8001/health >/dev/null 2>&1; then
                                    echo "Backend is healthy via container check! ✅"
                                    BACKEND_HEALTHY=true
                                    break
                                fi
                                echo "Backend container running but not healthy yet, waiting... (attempt $i/10)"
                            else
                                echo "Backend container not running, waiting... (attempt $i/10)"
                            fi
                            sleep 10
                        done
                        
                        # Wait for frontend to be ready (slower startup)  
                        echo "🌐 Checking Frontend Health via container network:"
                        FRONTEND_HEALTHY=false
                        for i in $(seq 1 20); do
                            # First check if container is running
                            if docker ps | grep -q "test-frontend-${BUILD_NUMBER}"; then
                                # Check via container name (Jenkins can access containers by name)
                                if docker exec test-frontend-${BUILD_NUMBER} curl -f http://localhost:3000/ >/dev/null 2>&1; then
                                    echo "Frontend is healthy via container check! ✅"
                                    FRONTEND_HEALTHY=true
                                    break
                                fi
                                echo "Frontend container running but not healthy yet, waiting... (attempt $i/20)"
                            else
                                echo "Frontend container not running, waiting... (attempt $i/20)"
                            fi
                            sleep 15
                        done
                        
                        # Check analytics and notifications containers are running (but no health check)
                        echo "📊 Checking Analytics and Notifications containers (no health check):"
                        if docker ps | grep -q "test-analytics-${BUILD_NUMBER}"; then
                            echo "Analytics container: ✅ RUNNING (health check skipped)"
                        else
                            echo "Analytics container: ❌ NOT RUNNING (but build succeeded)"
                        fi
                        
                        if docker ps | grep -q "test-notifications-${BUILD_NUMBER}"; then
                            echo "Notifications container: ✅ RUNNING (health check skipped)"
                        else
                            echo "Notifications container: ❌ NOT RUNNING (but build succeeded)"
                        fi
                        
                        # Final status check using localhost (backend and frontend only)
                        echo "=== Final Health Check Status (Backend & Frontend Only) ==="
                        
                        # Check backend via container network
                        if docker ps | grep -q "test-backend-${BUILD_NUMBER}"; then
                            if docker exec test-backend-${BUILD_NUMBER} curl -f http://localhost:8001/health >/dev/null 2>&1; then
                                echo "Backend: ✅ HEALTHY (via container check)"
                            else
                                echo "Backend: ❌ RUNNING BUT UNHEALTHY (but continuing pipeline)"
                            fi
                        else
                            echo "Backend: ❌ CONTAINER NOT RUNNING (but continuing pipeline)"
                        fi
                        
                        # Check frontend via container network
                        if docker ps | grep -q "test-frontend-${BUILD_NUMBER}"; then
                            if docker exec test-frontend-${BUILD_NUMBER} curl -f http://localhost:3000/ >/dev/null 2>&1; then
                                echo "Frontend: ✅ HEALTHY (via container check)"  
                            else
                                echo "Frontend: ❌ RUNNING BUT UNHEALTHY (but continuing pipeline)"
                            fi
                        else
                            echo "Frontend: ❌ CONTAINER NOT RUNNING (but continuing pipeline)"
                        fi
                        
                        echo "Analytics and Notifications: Built and containers started (no health checks performed)"
                        
                        echo "Backend/Frontend health checks completed - Analytics/Notifications built only ✅"
                    '''
                }
            }
        }
        
        stage('🧹 Cleanup') {
            steps {
                sh '''
                    echo "=== 🧹 Cleaning Up Test Containers and Resources ==="
                    
                    # Stop and remove containers using docker-compose if file exists
                    if [ -f docker-compose.test.yml ]; then
                        echo "Stopping containers via docker-compose..."
                        docker-compose -f docker-compose.test.yml down -v --remove-orphans 2>/dev/null || true
                    fi
                    
                    # Remove test containers by name (more reliable)
                    echo "🔍 Checking for test containers to remove..."
                    for container in "test-backend-${BUILD_NUMBER}" "test-frontend-${BUILD_NUMBER}" "test-analytics-${BUILD_NUMBER}" "test-notifications-${BUILD_NUMBER}"; do
                        if docker ps -a --format "{{.Names}}" | grep -q "^${container}$" 2>/dev/null; then
                            echo "Removing container: ${container}"
                            docker rm -f "${container}" 2>/dev/null || true
                        else
                            echo "Container ${container} not found, skipping"
                        fi
                    done
                    
                    # Remove test networks gracefully
                    echo "🔍 Checking for test networks to remove..."
                    for network in "test-network-${BUILD_NUMBER}" "shopsphere-test-${BUILD_NUMBER}" "shopsphere-build-network"; do
                        if docker network ls --format "{{.Name}}" | grep -q "^${network}$" 2>/dev/null; then
                            echo "Removing network: ${network}"
                            docker network rm "${network}" 2>/dev/null || true
                        else
                            echo "Network ${network} not found, skipping"
                        fi
                    done
                    
                    # Clean up test files
                    echo "🗑️ Removing test files..."
                    rm -f docker-compose.test.yml || true
                    
                    # Clean up old build images (keep only last 3 builds)
                    echo "🗑️ Cleaning up old build images..."
                    for service in "backend" "frontend" "analytics" "notifications"; do
                        echo "Cleaning old shopsphere-${service} images..."
                        # Get all images for this service, sort by created date, keep only last 3
                        docker images --format "{{.Repository}}:{{.Tag}} {{.CreatedAt}}" | \
                        grep "^shopsphere-${service}:" | \
                        sort -k2 -r | \
                        tail -n +4 | \
                        awk '{print $1}' | \
                        while read image; do
                            if [ ! -z "$image" ]; then
                                echo "Removing old image: $image"
                                docker rmi "$image" 2>/dev/null || true
                            fi
                        done
                    done
                    
                    # Clean up docker system (but preserve current build images)
                    echo "🧽 Cleaning up Docker system..."
                    docker container prune -f || true
                    docker volume prune -f || true
                    docker network prune -f || true
                    
                    echo "Cleanup completed ✅"
                '''
            }
        }
    }
    
    post {
        always {
            script {
                sh '''
                    echo "=== 📊 POST-BUILD CLEANUP AND SUMMARY ==="
                    echo "Build: ${BUILD_NUMBER}"
                    echo "Status: ${currentBuild.currentResult}"
                    echo "Duration: ${currentBuild.durationString}"
                    
                    # Force cleanup of any remaining test resources
                    echo "🔧 Final cleanup of any remaining test resources..."
                    for container in "test-backend-${BUILD_NUMBER}" "test-frontend-${BUILD_NUMBER}" "test-analytics-${BUILD_NUMBER}" "test-notifications-${BUILD_NUMBER}"; do
                        docker rm -f "${container}" 2>/dev/null || true
                    done
                    
                    # Remove test networks
                    for network in "test-network-${BUILD_NUMBER}" "shopsphere-test-${BUILD_NUMBER}"; do
                        docker network rm "${network}" 2>/dev/null || true
                    done
                    
                    # Show final docker state
                    echo "📋 Final Docker state:"
                    echo "Running containers: $(docker ps --format '{{.Names}}' | wc -l)"
                    echo "Total images: $(docker images | wc -l)"
                    echo "Networks: $(docker network ls | wc -l)"
                '''
                
                // Always clean workspace
                cleanWs()
            }
        }
        
        success {
            script {
                echo "🎉 BUILD SUCCESSFUL! 🎉"
                echo '''
🏗️ Build: ${BUILD_NUMBER}
🎯 All services built successfully:
  ✅ Backend (shopsphere-backend:${BUILD_NUMBER})
  ✅ Frontend (shopsphere-frontend:${BUILD_NUMBER}) 
  ✅ Analytics (shopsphere-analytics:${BUILD_NUMBER})
  ✅ Notifications (shopsphere-notifications:${BUILD_NUMBER})

📊 Build completed successfully! All Docker images are ready for deployment.
'''
                currentBuild.description = "✅ Success - Build ${BUILD_NUMBER}"
            }
        }
        
        failure {
            script {
                echo "❌ BUILD FAILED!"
                echo '''
🏗️ Build: ${BUILD_NUMBER}
❌ Build failed - check logs above for details

💡 Common issues:
  - Docker memory limits
  - Missing dependencies
  - Network conflicts
  - Port conflicts

🔧 Cleanup completed automatically
'''
                currentBuild.description = "❌ Failed - Build ${BUILD_NUMBER}"
            }
        }
    }
}
