# Jenkins Pipeline Configuration Guide for ShopSphere

## 📋 Overview

This guide walks you through setting up Jenkins pipeline jobs for the ShopSphere project after the initial Jenkins installation.

## 🎯 Prerequisites

- Jenkins is running on http://localhost:9090
- You have admin access to Jenkins
- GitHub webhook is configured (see webhook-setup.md)

## 🔧 Step 1: Initial Jenkins Setup

### 1.1 First Time Login

1. Open http://localhost:9090 in your browser
2. Enter the initial admin password:
   ```bash
   # Get the password from the file created during setup
   cat jenkins-admin-password.txt
   ```
3. Choose "Install suggested plugins"
4. Create your admin user account
5. Confirm Jenkins URL (http://localhost:9090)

### 1.2 Install Additional Plugins

Go to **Manage Jenkins → Manage Plugins → Available** and install:

- GitHub Integration Plugin
- Pipeline: GitHub Groovy Libraries
- Blue Ocean (optional, for better UI)
- Slack Notification Plugin (if using Slack)
- HTML Publisher Plugin (for test reports)

## 🚀 Step 2: Create Pipeline Jobs

### 2.1 Main CI/CD Pipeline Job

1. **Create New Job**:

   - Click "New Item"
   - Enter name: `ShopSphere-CI-CD`
   - Select "Pipeline"
   - Click "OK"

2. **Configure General Settings**:

   - ✅ GitHub project
   - Project url: `https://github.com/yourusername/ShopSphere`
   - ✅ Build Triggers → GitHub hook trigger for GITScm polling

3. **Configure Pipeline**:

   - Definition: "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: `https://github.com/yourusername/ShopSphere.git`
   - Credentials: Add your GitHub credentials
   - Branch Specifier: `*/main`
   - Script Path: `Jenkinsfile`

4. **Save the configuration**

### 2.2 Feature Branch Testing Job

1. **Create New Job**:

   - Name: `ShopSphere-Feature-Tests`
   - Type: Pipeline

2. **Configure**:
   - GitHub project URL
   - Build Triggers: GitHub hook trigger
   - Pipeline from SCM
   - Branch Specifier: `*/feature/*`
   - Script Path: `Jenkinsfile.feature` (create simplified version)

### 2.3 Pull Request Testing Job

1. **Create New Job**:

   - Name: `ShopSphere-PR-Tests`
   - Type: Pipeline

2. **Configure**:
   - Use GitHub Pull Request Builder plugin
   - Trigger on PR open/update
   - Run tests only, no deployment

## 🔧 Step 3: Configure Credentials

### 3.1 GitHub Credentials

1. Go to **Manage Jenkins → Manage Credentials**
2. Click "global" domain
3. Click "Add Credentials"
4. Select "Username with password"
5. Enter your GitHub username and personal access token
6. ID: `github-credentials`

### 3.2 Docker Registry Credentials (if using private registry)

1. Add new credentials
2. Type: "Username with password"
3. Enter registry credentials
4. ID: `docker-registry-credentials`

### 3.3 Slack Webhook (Optional)

1. Add new credentials
2. Type: "Secret text"
3. Secret: Your Slack webhook URL
4. ID: `slack-webhook`

## 🔧 Step 4: Environment Configuration

### 4.1 Global Environment Variables

Go to **Manage Jenkins → Configure System** and add:

```
DOCKER_REGISTRY=localhost:5000
APP_NAME=shopsphere
DEFAULT_BRANCH=main
STAGING_URL=http://localhost:8001
PRODUCTION_URL=http://localhost:8000
```

### 4.2 Pipeline-Specific Variables

In your pipeline job configuration, add:

```groovy
environment {
    COMPOSE_PROJECT_NAME = "shopsphere-ci"
    BUILD_TIMEOUT = "30"
    TEST_TIMEOUT = "15"
}
```

## 🔧 Step 5: Configure Build Tools

### 5.1 Docker Configuration

Ensure Jenkins can access Docker:

```bash
# Check if Jenkins can run Docker
docker exec shopsphere_jenkins docker version
```

### 5.2 Node.js Configuration

1. Go to **Manage Jenkins → Global Tool Configuration**
2. Find "NodeJS" section
3. Add NodeJS installation:
   - Name: `Node 18`
   - Version: `18.x`
   - ✅ Install automatically

### 5.3 Python Configuration

Python should already be available in the Jenkins container.

## 📊 Step 6: Configure Test Results Publishing

### 6.1 JUnit Test Results

Add to your pipeline post actions:

```groovy
post {
    always {
        publishTestResults testResultsPattern: '**/test-results.xml'
    }
}
```

### 6.2 Coverage Reports

Add HTML Publisher for coverage:

```groovy
publishHTML([
    allowMissing: false,
    alwaysLinkToLastBuild: true,
    keepAll: true,
    reportDir: 'coverage-reports',
    reportFiles: 'index.html',
    reportName: 'Coverage Report'
])
```

## 🔔 Step 7: Configure Notifications

### 7.1 Email Notifications

1. Go to **Manage Jenkins → Configure System**
2. Find "E-mail Notification" section
3. Configure SMTP server settings
4. Test configuration

### 7.2 Slack Notifications

Add to pipeline:

```groovy
post {
    success {
        slackSend(
            channel: '#ci-cd',
            color: 'good',
            message: "✅ Build ${env.BUILD_NUMBER} succeeded!"
        )
    }
    failure {
        slackSend(
            channel: '#ci-cd',
            color: 'danger',
            message: "❌ Build ${env.BUILD_NUMBER} failed!"
        )
    }
}
```

## 🔧 Step 8: Security Configuration

### 8.1 GitHub Webhook Security

1. Go to **Manage Jenkins → Configure System**
2. Find "GitHub" section
3. Add webhook secret (same as configured in GitHub)

### 8.2 User Permissions

1. Go to **Manage Jenkins → Configure Global Security**
2. Authorization Strategy: "Matrix-based security"
3. Configure user permissions

## 🧪 Step 9: Test Your Pipeline

### 9.1 Manual Build Test

1. Go to your pipeline job
2. Click "Build Now"
3. Monitor the build in "Console Output"

### 9.2 Webhook Test

1. Make a small change to your repository
2. Commit and push:
   ```bash
   echo "# Test" >> README.md
   git add README.md
   git commit -m "Test Jenkins webhook"
   git push origin main
   ```
3. Check Jenkins dashboard for triggered build

### 9.3 Build Status Check

Monitor these key areas:

- Build duration
- Test results
- Coverage reports
- Deployment status

## 📈 Step 10: Pipeline Optimization

### 10.1 Parallel Execution

Utilize parallel stages for faster builds:

```groovy
stage('Parallel Tests') {
    parallel {
        stage('Backend Tests') { /* ... */ }
        stage('Frontend Tests') { /* ... */ }
        stage('Security Scan') { /* ... */ }
    }
}
```

### 10.2 Build Caching

Cache dependencies to speed up builds:

- Use Docker layer caching
- Cache npm/pip dependencies
- Use pipeline caching plugins

### 10.3 Resource Management

Configure resource limits:

```groovy
options {
    timeout(time: 30, unit: 'MINUTES')
    retry(3)
    skipDefaultCheckout()
}
```

## 🔍 Step 11: Monitoring and Maintenance

### 11.1 Build Metrics

Track important metrics:

- Build success rate
- Average build time
- Test coverage trends
- Deployment frequency

### 11.2 Log Management

Configure log rotation:

1. Go to job configuration
2. Set "Discard old builds"
3. Keep last 10 builds or 30 days

### 11.3 Regular Maintenance

Schedule regular tasks:

- Update Jenkins plugins
- Clean old Docker images
- Review and optimize pipelines
- Update security configurations

## 🚀 Advanced Features

### Blue-Green Deployment

Configure automated blue-green deployments for production:

```groovy
stage('Blue-Green Deploy') {
    when { branch 'main' }
    steps {
        script {
            // Deploy to green environment
            // Run health checks
            // Switch traffic
            // Cleanup blue environment
        }
    }
}
```

### Multi-Branch Pipeline

Create a multi-branch pipeline for automatic job creation:

1. New Item → Multibranch Pipeline
2. Configure branch sources
3. Automatic job creation for feature branches

### Pipeline Libraries

Create shared pipeline libraries for reusable code:

1. Go to **Manage Jenkins → Configure System**
2. Add "Global Pipeline Libraries"
3. Create reusable pipeline functions

## 🆘 Troubleshooting

### Common Issues

1. **Build fails with Docker permission denied**:

   ```bash
   # Fix Docker permissions
   docker exec -u root shopsphere_jenkins usermod -aG docker jenkins
   docker restart shopsphere_jenkins
   ```

2. **GitHub webhook not triggering builds**:

   - Check webhook delivery in GitHub
   - Verify Jenkins GitHub plugin configuration
   - Check firewall/network settings

3. **Pipeline script errors**:

   - Use Pipeline Syntax helper
   - Check Jenkinsfile syntax
   - Review Jenkins logs

4. **Out of disk space**:
   ```bash
   # Clean up Docker
   docker system prune -a
   # Clean up Jenkins workspace
   docker exec shopsphere_jenkins find /var/jenkins_home/workspace -type f -name "*.log" -delete
   ```

## ✅ Best Practices

1. **Version Control**: Keep Jenkinsfiles in version control
2. **Parameterization**: Use parameters for flexible pipelines
3. **Error Handling**: Add proper error handling and notifications
4. **Security**: Use credentials plugin, don't hardcode secrets
5. **Documentation**: Document pipeline stages and decisions
6. **Testing**: Test pipeline changes in feature branches
7. **Monitoring**: Set up monitoring for build health
8. **Backup**: Regular backup of Jenkins configuration

## 🎯 Next Steps

After successful pipeline setup:

1. **Add more sophisticated testing**: Integration tests, E2E tests
2. **Implement infrastructure as code**: Terraform integration
3. **Add performance testing**: Automated load testing
4. **Set up monitoring**: Application performance monitoring
5. **Implement GitOps**: ArgoCD or Flux for Kubernetes deployments
