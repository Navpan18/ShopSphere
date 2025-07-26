#!/bin/bash

# Install Git Plugin in Jenkins
echo "🔧 Installing Git Plugin in Jenkins..."

JENKINS_URL="http://localhost:9040"
JENKINS_CLI="/tmp/jenkins-cli.jar"

# Download Jenkins CLI if not exists
if [ ! -f "$JENKINS_CLI" ]; then
    echo "📥 Downloading Jenkins CLI..."
    curl -s "$JENKINS_URL/jnlpJars/jenkins-cli.jar" -o "$JENKINS_CLI"
fi

# Wait for Jenkins to be fully ready
echo "⏳ Waiting for Jenkins to be fully ready..."
while ! curl -s "$JENKINS_URL/api/json" > /dev/null; do
    sleep 2
done

echo "✅ Jenkins is ready!"

# Install Git plugin and dependencies
echo "📦 Installing Git plugin..."
java -jar "$JENKINS_CLI" -s "$JENKINS_URL" install-plugin git:latest || echo "Git plugin installation attempted"
java -jar "$JENKINS_CLI" -s "$JENKINS_URL" install-plugin git-client:latest || echo "Git client plugin installation attempted"
java -jar "$JENKINS_CLI" -s "$JENKINS_URL" install-plugin scm-api:latest || echo "SCM API plugin installation attempted"
java -jar "$JENKINS_CLI" -s "$JENKINS_URL" install-plugin workflow-scm-step:latest || echo "Workflow SCM step plugin installation attempted"

echo "🔄 Restarting Jenkins to load plugins..."
java -jar "$JENKINS_CLI" -s "$JENKINS_URL" restart || echo "Restart command sent"

echo "⏳ Waiting for Jenkins to restart..."
sleep 30

# Wait for Jenkins to come back online
while ! curl -s "$JENKINS_URL/api/json" > /dev/null; do
    echo "   Still waiting for Jenkins..."
    sleep 5
done

echo "✅ Jenkins has restarted!"
echo "🔍 Checking installed plugins..."

# Check if git plugin is installed
curl -s "$JENKINS_URL/pluginManager/api/json?depth=1" | grep -q '"shortName":"git"' && echo "✅ Git plugin is installed" || echo "❌ Git plugin not found"

echo "🎯 Ready to test the pipeline again!"
