#!/bin/bash

# ShopSphere Jenkins CI/CD Setup Script
# This script sets up Jenkins with all necessary configurations

set -e

echo "🚀 Setting up Jenkins CI/CD for ShopSphere..."

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

# Check if Docker is installed and running
check_docker() {
    print_status "Checking Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker."
        exit 1
    fi
    
    print_success "Docker is installed and running"
}

# Check if docker-compose is installed
check_docker_compose() {
    print_status "Checking Docker Compose installation..."
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Docker Compose is installed"
}    # Check if ports are available
check_ports() {
    print_status "Checking if required ports are available..."
    
    ports=(9040 50000 5433)
    
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
            print_warning "Port $port is already in use"
            if [ "$port" = "9040" ]; then
                print_warning "Jenkins port 9040 is occupied. Stopping existing Jenkins..."
                docker-compose -f jenkins/docker-compose.jenkins.yml down 2>/dev/null || true
                sleep 2
            fi
        else
            print_success "Port $port is available"
        fi
    done
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    directories=(
        "jenkins/workspace"
        "jenkins/jenkins-config"
        "build-artifacts"
        "test-results"
        "coverage-reports"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        print_success "Created directory: $dir"
    done
}

# Set up environment file
setup_environment() {
    print_status "Setting up environment configuration..."
    
    if [ ! -f ".jenkins.env" ]; then
        print_warning ".jenkins.env not found, using default configuration"
    else
        print_success "Environment configuration loaded"
    fi
}

# Build Jenkins image
build_jenkins() {
    print_status "Building custom Jenkins image..."
    
    cd jenkins
    docker build -t shopsphere-jenkins:latest -f Dockerfile.jenkins .
    cd ..
    
    print_success "Jenkins image built successfully"
}

# Start Jenkins services
start_jenkins() {
    print_status "Starting Jenkins services..."
    
    # Create external network if it doesn't exist
    docker network create shopsphere-network 2>/dev/null || true
    
    # Start Jenkins
    docker-compose -f jenkins/docker-compose.jenkins.yml up -d
    
    print_success "Jenkins services started"
    print_status "Jenkins will be available at: http://localhost:9040"
}

# Wait for Jenkins to be ready
wait_for_jenkins() {
    print_status "Waiting for Jenkins to be ready..."
    
    max_attempts=30
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f http://localhost:9040 > /dev/null 2>&1; then
            print_success "Jenkins is ready!"
            break
        fi
        
        echo -n "."
        sleep 3
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "Jenkins failed to start within expected time"
        print_status "Checking Jenkins logs..."
        docker logs shopsphere_jenkins --tail 20
        exit 1
    fi
}

# Get initial admin password
get_admin_password() {
    print_status "Getting Jenkins initial admin password..."
    
    # Wait a bit more for the password file to be created
    sleep 5
    
    password=$(docker exec shopsphere_jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "")
    
    if [ -n "$password" ]; then
        print_success "Jenkins initial admin password: $password"
        echo "$password" > jenkins-admin-password.txt
        print_status "Password saved to: jenkins-admin-password.txt"
    else
        print_warning "Could not retrieve admin password. Check Jenkins logs."
    fi
}

# Setup webhook configuration
setup_webhook() {
    print_status "Setting up GitHub webhook configuration..."
    
    cat > webhook-setup.md << EOF
# GitHub Webhook Setup

To enable automatic builds on git commits, follow these steps:

1. Go to your GitHub repository
2. Navigate to Settings > Webhooks
3. Click "Add webhook"
4. Set Payload URL to: http://your-server-ip:9040/github-webhook/
5. Set Content type to: application/json
6. Select "Just the push event"
7. Check "Active"
8. Click "Add webhook"

## Local Development Webhook (using ngrok)

If you're running locally and want to test webhooks:

1. Install ngrok: brew install ngrok (on macOS)
2. Run: ngrok http 9040
3. Use the https URL provided by ngrok as your webhook URL
4. Example: https://abc123.ngrok.io/github-webhook/

EOF
    
    print_success "Webhook setup guide created: webhook-setup.md"
}

# Create sample pipeline job
create_sample_job() {
    print_status "Creating sample pipeline job configuration..."
    
    cat > jenkins/sample-job-config.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>ShopSphere CI/CD Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.34.3">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.87">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.2">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/yourusername/ShopSphere.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
    
    print_success "Sample job configuration created"
}

# Display final instructions
show_final_instructions() {
    print_success "🎉 Jenkins CI/CD setup completed successfully!"
    
    echo
    echo "=== Next Steps ==="
    echo "1. Open Jenkins: http://localhost:9040"
    echo "2. Login with initial admin password (check jenkins-admin-password.txt)"
    echo "3. Install suggested plugins"
    echo "4. Create admin user"
    echo "5. Create new pipeline job using the Jenkinsfile"
    echo "6. Configure GitHub webhook (see webhook-setup.md)"
    echo
    echo "=== Useful Commands ==="
    echo "• View Jenkins logs: docker logs shopsphere_jenkins"
    echo "• Stop Jenkins: docker-compose -f jenkins/docker-compose.jenkins.yml down"
    echo "• Start Jenkins: docker-compose -f jenkins/docker-compose.jenkins.yml up -d"
    echo "• View running containers: docker ps"
    echo
    echo "=== Troubleshooting ==="
    echo "• If Jenkins fails to start, check: docker logs shopsphere_jenkins"
    echo "• If port conflicts occur, update docker-compose.jenkins.yml"
    echo "• For webhook testing locally, use ngrok: ngrok http 9040"
    echo
}

# Main execution
main() {
    echo "🚀 ShopSphere Jenkins CI/CD Setup"
    echo "=================================="
    echo
    
    check_docker
    check_docker_compose
    check_ports
    create_directories
    setup_environment
    build_jenkins
    start_jenkins
    wait_for_jenkins
    get_admin_password
    setup_webhook
    create_sample_job
    show_final_instructions
}

# Run main function
main "$@"
