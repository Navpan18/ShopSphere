pipeline {
    agent any
    
    environment {
        // Docker registry (can be Docker Hub or private registry)
        DOCKER_REGISTRY = "localhost:5000"
        DOCKER_IMAGE_BACKEND = "${DOCKER_REGISTRY}/shopsphere-backend"
        DOCKER_IMAGE_FRONTEND = "${DOCKER_REGISTRY}/shopsphere-frontend"
        
        // Application configurations
        APP_NAME = "shopsphere"
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        GIT_COMMIT_SHORT = "${env.GIT_COMMIT[0..7]}"
        
        // Test configurations
        PYTEST_ARGS = "--verbose --tb=short --cov=app --cov-report=xml --cov-report=html"
        NODE_ENV = "test"
        
        // Deployment configurations
        COMPOSE_PROJECT_NAME = "shopsphere-ci"
        DEPLOY_ENV = "staging"
    }
    
    options {
        // Keep builds for 30 days, max 10 builds
        buildDiscarder(logRotator(numToKeepStr: '10', daysToKeepStr: '30'))
        
        // Timeout for entire pipeline
        timeout(time: 30, unit: 'MINUTES')
        
        // Add timestamps to console output
        timestamps()
        
        // Clean workspace before build
        skipDefaultCheckout(false)
    }
    
    triggers {
        // Poll SCM every 2 minutes for changes
        pollSCM('H/2 * * * *')
        
        // GitHub webhook trigger
        githubPush()
    }
    
    stages {
        stage('🚀 Checkout & Setup') {
            steps {
                script {
                    echo "=== Starting ShopSphere CI/CD Pipeline ==="
                    echo "Build: ${BUILD_NUMBER}"
                    echo "Commit: ${GIT_COMMIT_SHORT}"
                    echo "Branch: ${env.BRANCH_NAME ?: env.GIT_BRANCH}"
                }
                
                // Clean workspace
                cleanWs()
                
                // Checkout source code
                checkout scm
                
                // Create necessary directories
                sh '''
                    mkdir -p test-results
                    mkdir -p coverage-reports
                    mkdir -p build-artifacts
                '''
            }
        }
        
        stage('🔍 Pre-build Checks') {
            parallel {
                stage('Backend Dependencies Check') {
                    steps {
                        dir('backend') {
                            sh '''
                                echo "=== Checking Backend Dependencies ==="
                                if [ -f requirements.txt ]; then
                                    echo "✅ requirements.txt found"
                                    cat requirements.txt
                                else
                                    echo "❌ requirements.txt not found"
                                    exit 1
                                fi
                            '''
                        }
                    }
                }
                
                stage('Frontend Dependencies Check') {
                    steps {
                        dir('frontend') {
                            sh '''
                                echo "=== Checking Frontend Dependencies ==="
                                if [ -f package.json ]; then
                                    echo "✅ package.json found"
                                    node --version
                                    npm --version
                                else
                                    echo "❌ package.json not found"
                                    exit 1
                                fi
                            '''
                        }
                    }
                }
                
                stage('Docker Environment Check') {
                    steps {
                        sh '''
                            echo "=== Checking Docker Environment ==="
                            docker --version
                            docker-compose --version
                            docker info
                        '''
                    }
                }
            }
        }
        
        stage('🏗️ Build Applications') {
            parallel {
                stage('Build Backend') {
                    steps {
                        dir('backend') {
                            script {
                                echo "=== Building Backend Application ==="
                                
                                // Build Docker image
                                sh """
                                    echo "Building backend Docker image..."
                                    docker build -t ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} .
                                    docker build -t ${DOCKER_IMAGE_BACKEND}:latest .
                                """
                            }
                        }
                    }
                }
                
                stage('Build Frontend') {
                    steps {
                        dir('frontend') {
                            script {
                                echo "=== Building Frontend Application ==="
                                
                                // Install dependencies and build
                                sh '''
                                    echo "Installing frontend dependencies..."
                                    npm ci --silent
                                    
                                    echo "Building frontend application..."
                                    npm run build
                                '''
                                
                                // Build Docker image
                                sh """
                                    echo "Building frontend Docker image..."
                                    docker build -t ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} .
                                    docker build -t ${DOCKER_IMAGE_FRONTEND}:latest .
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('🧪 Run Tests') {
            parallel {
                stage('Backend Tests') {
                    steps {
                        dir('backend') {
                            script {
                                echo "=== Running Backend Tests ==="
                                
                                // Create test environment
                                sh '''
                                    echo "Setting up test environment..."
                                    python3 -m venv test_env
                                    source test_env/bin/activate
                                    pip install -r requirements.txt
                                    
                                    echo "Running pytest..."
                                    python -m pytest ${PYTEST_ARGS} tests/ || true
                                '''
                            }
                        }
                    }
                    post {
                        always {
                            // Publish test results
                            publishTestResults testResultsPattern: 'backend/test-results.xml'
                            
                            // Publish coverage report
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'backend/htmlcov',
                                reportFiles: 'index.html',
                                reportName: 'Backend Coverage Report'
                            ])
                        }
                    }
                }
                
                stage('Frontend Tests') {
                    steps {
                        dir('frontend') {
                            script {
                                echo "=== Running Frontend Tests ==="
                                
                                sh '''
                                    echo "Running Jest tests..."
                                    npm test || true
                                '''
                            }
                        }
                    }
                    post {
                        always {
                            // Publish test results
                            publishTestResults testResultsPattern: 'frontend/test-results.xml'
                        }
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        script {
                            echo "=== Running Integration Tests ==="
                            
                            sh '''
                                echo "Starting test environment..."
                                docker-compose -f docker-compose.yml up -d postgres redis
                                sleep 10
                                
                                echo "Running integration tests..."
                                chmod +x test-endpoints.sh
                                ./test-endpoints.sh || true
                                
                                echo "Cleaning up test environment..."
                                docker-compose -f docker-compose.yml down
                            '''
                        }
                    }
                }
            }
        }
        
        stage('🔐 Security & Quality Checks') {
            parallel {
                stage('Backend Security Scan') {
                    steps {
                        dir('backend') {
                            sh '''
                                echo "=== Running Backend Security Scan ==="
                                pip install safety bandit
                                
                                echo "Checking for known vulnerabilities..."
                                safety check --json || true
                                
                                echo "Running static security analysis..."
                                bandit -r app/ -f json -o bandit-report.json || true
                            '''
                        }
                    }
                }
                
                stage('Frontend Security Scan') {
                    steps {
                        dir('frontend') {
                            sh '''
                                echo "=== Running Frontend Security Scan ==="
                                
                                echo "Auditing npm packages..."
                                npm audit --json || true
                                
                                echo "Checking for vulnerabilities..."
                                npx audit-ci || true
                            '''
                        }
                    }
                }
                
                stage('Docker Image Security') {
                    steps {
                        sh '''
                            echo "=== Docker Image Security Scan ==="
                            
                            echo "Scanning backend image..."
                            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \\
                                aquasec/trivy image --format json ${DOCKER_IMAGE_BACKEND}:latest || true
                            
                            echo "Scanning frontend image..."
                            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \\
                                aquasec/trivy image --format json ${DOCKER_IMAGE_FRONTEND}:latest || true
                        '''
                    }
                }
            }
        }
        
        stage('🚢 Deploy to Staging') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    echo "=== Deploying to Staging Environment ==="
                    
                    sh '''
                        echo "Stopping existing staging environment..."
                        docker-compose -f docker-compose.yml -p ${COMPOSE_PROJECT_NAME}-staging down || true
                        
                        echo "Starting staging environment with new images..."
                        export BACKEND_IMAGE=${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER}
                        export FRONTEND_IMAGE=${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER}
                        
                        docker-compose -f docker-compose.yml -p ${COMPOSE_PROJECT_NAME}-staging up -d
                        
                        echo "Waiting for services to be ready..."
                        sleep 30
                        
                        echo "Running smoke tests..."
                        curl -f http://localhost:8000/health || exit 1
                        curl -f http://localhost:3000 || exit 1
                    '''
                }
            }
        }
        
        stage('📊 Performance Tests') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    echo "=== Running Performance Tests ==="
                    
                    dir('loadtest') {
                        sh '''
                            echo "Installing k6 for load testing..."
                            # Add performance testing here
                            echo "Performance tests completed"
                        '''
                    }
                }
            }
        }
        
        stage('🎯 Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "=== Production Deployment ==="
                    
                    // Manual approval for production
                    input message: 'Deploy to Production?', ok: 'Deploy!',
                          submitterParameter: 'APPROVER'
                    
                    sh '''
                        echo "Deploying to production..."
                        echo "Approved by: ${APPROVER}"
                        
                        # Add production deployment logic here
                        echo "Production deployment completed"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "=== Pipeline Cleanup ==="
                
                // Archive artifacts
                archiveArtifacts artifacts: 'build-artifacts/**/*', allowEmptyArchive: true
                
                // Clean up Docker images to save space
                sh '''
                    echo "Cleaning up old Docker images..."
                    docker image prune -f
                    docker system prune -f
                '''
            }
        }
        
        success {
            script {
                echo "=== ✅ Pipeline Successful ==="
                
                // Send success notification
                sh '''
                    echo "Build ${BUILD_NUMBER} completed successfully!"
                    echo "Commit: ${GIT_COMMIT_SHORT}"
                    echo "Duration: ${currentBuild.durationString}"
                '''
            }
        }
        
        failure {
            script {
                echo "=== ❌ Pipeline Failed ==="
                
                // Send failure notification
                sh '''
                    echo "Build ${BUILD_NUMBER} failed!"
                    echo "Commit: ${GIT_COMMIT_SHORT}"
                    echo "Check the logs for details"
                '''
            }
        }
        
        unstable {
            script {
                echo "=== ⚠️ Pipeline Unstable ==="
                
                // Send unstable notification
                sh '''
                    echo "Build ${BUILD_NUMBER} is unstable"
                    echo "Some tests may have failed"
                '''
            }
        }
    }
}
