#!/bin/bash

# Install required Jenkins plugins for Git/GitHub integration
set -e

echo "🔧 Installing required Jenkins plugins for Git/GitHub integration..."

JENKINS_URL="http://localhost:9090"
JENKINS_CLI="java -jar jenkins-cli.jar -s $JENKINS_URL"

# Download Jenkins CLI if not present
if [ ! -f jenkins-cli.jar ]; then
    echo "📥 Downloading Jenkins CLI..."
    curl -s $JENKINS_URL/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar
fi

echo "🔍 Checking current plugins..."
$JENKINS_CLI list-plugins | grep -E 'git|github|scm|workflow' || echo "No Git plugins found"

echo ""
echo "📦 Installing essential plugins..."

# Install required plugins
REQUIRED_PLUGINS=(
    "git"
    "github"
    "workflow-scm-step"
    "pipeline-stage-view"
    "build-timeout"
    "timestamper"
    "ws-cleanup"
    "ant"
    "gradle"
    "workflow-aggregator"
    "github-branch-source"
    "pipeline-github-lib"
    "ssh-slaves"
    "matrix-auth"
    "pam-auth"
    "ldap"
    "email-ext"
    "mailer"
    "matrix-project"
    "ssh"
    "ssh-agent"
    "publish-over-ssh"
)

for plugin in "${REQUIRED_PLUGINS[@]}"; do
    echo "Installing plugin: $plugin"
    $JENKINS_CLI install-plugin $plugin || echo "Failed to install $plugin or already installed"
done

echo ""
echo "🔄 Restarting Jenkins to activate plugins..."
$JENKINS_CLI restart

echo "⏳ Waiting for Jenkins to restart..."
sleep 30

# Wait for Jenkins to be ready
while ! curl -s "$JENKINS_URL/api/json" > /dev/null; do
    echo "   Jenkins not ready, waiting 5 seconds..."
    sleep 5
done

echo "✅ Jenkins restarted and ready!"
echo ""
echo "🔍 Checking installed plugins..."
$JENKINS_CLI list-plugins | grep -E 'git|github|scm|workflow' | head -10

echo "✅ Plugin installation complete!"
