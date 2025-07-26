#!/bin/bash

# Update Jenkins Pipeline Configuration Script
# This script updates the ShopSphere Comprehensive Pipeline with the correct GitHub repository

set -e

echo "🔄 Updating ShopSphere Jenkins Pipeline Configuration..."

# Configuration
JENKINS_URL="http://localhost:9040"
JOB_NAME="ShopSphere-Comprehensive-Pipeline"
CONFIG_FILE="jenkins-comprehensive-job-config.xml"

# Wait for Jenkins to be ready
echo "⏳ Waiting for Jenkins to be ready..."
while ! curl -s "$JENKINS_URL/api/json" > /dev/null; do
    echo "   Jenkins not ready, waiting 5 seconds..."
    sleep 5
done

echo "✅ Jenkins is ready!"

# Check if job exists and delete it
echo "🗑️ Removing existing job if it exists..."
if curl -s -f "$JENKINS_URL/job/$JOB_NAME/api/json" > /dev/null 2>&1; then
    echo "   Job exists, deleting..."
    curl -X POST "$JENKINS_URL/job/$JOB_NAME/doDelete" || echo "   Failed to delete job (might not exist)"
    sleep 2
else
    echo "   Job doesn't exist, nothing to delete"
fi

# Create the job with updated configuration
echo "🚀 Creating job with updated configuration..."
if curl -s -X POST "$JENKINS_URL/createItem?name=$JOB_NAME" \
    --header "Content-Type: application/xml" \
    --data @"$CONFIG_FILE"; then
    echo "✅ Job created successfully!"
else
    echo "❌ Failed to create job"
    exit 1
fi

# Wait a moment for job to be available
sleep 3

# Trigger a build to test the configuration
echo "🔄 Triggering initial build to test configuration..."
if curl -s -X POST "$JENKINS_URL/job/$JOB_NAME/build"; then
    echo "✅ Build triggered successfully!"
    echo ""
    echo "🎯 Job Status:"
    echo "   📊 Job Dashboard: $JENKINS_URL/job/$JOB_NAME/"
    echo "   🔍 Build Console: $JENKINS_URL/job/$JOB_NAME/lastBuild/console"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Monitor the build progress at: $JENKINS_URL/job/$JOB_NAME/"
    echo "   2. Check build console output for any issues"
    echo "   3. Verify all pipeline stages complete successfully"
    echo ""
else
    echo "⚠️ Failed to trigger build, but job was created"
    echo "   You can manually trigger it at: $JENKINS_URL/job/$JOB_NAME/"
fi

echo "✅ Pipeline configuration update complete!"
