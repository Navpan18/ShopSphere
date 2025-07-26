#!/bin/bash

# GitHub Webhook Setup for Jenkins
echo "🔗 Setting up GitHub Webhook for Jenkins Pipeline"
echo "================================================"

JENKINS_LOCAL_URL="http://localhost:9090"
JENKINS_PUBLIC_URL="https://e77949f6bcb9.ngrok-free.app"
GITHUB_REPO="https://github.com/Navpan18/ShopSphere"
WEBHOOK_URL="${JENKINS_PUBLIC_URL}/github-webhook/"

echo "📋 Webhook Configuration Details:"
echo "   🌐 Jenkins Local URL: $JENKINS_LOCAL_URL"
echo "   🌍 Jenkins Public URL: $JENKINS_PUBLIC_URL"
echo "   📦 GitHub Repository: $GITHUB_REPO"
echo "   🔗 Webhook URL: $WEBHOOK_URL"
echo ""

echo "🔧 Manual Setup Instructions:"
echo "=============================================="
echo ""
echo "1. 🌐 Go to your GitHub repository:"
echo "   $GITHUB_REPO"
echo ""
echo "2. ⚙️ Navigate to Settings → Webhooks → Add webhook"
echo ""
echo "3. 📝 Configure the webhook:"
echo "   Payload URL: $WEBHOOK_URL"
echo "   Content type: application/json"
echo "   Secret: (leave empty for now)"
echo "   Events: Just the push event"
echo "   Active: ✅ Checked"
echo ""
echo "4. 💾 Click 'Add webhook'"
echo ""
echo "5. 🧪 Test the webhook:"
echo "   - Make a small change to your repository"
echo "   - Commit and push to GitHub"
echo "   - Jenkins should automatically trigger a build"
echo ""

echo "✅ Current Pipeline Triggers:"
echo "   🔄 GitHub Push Webhook (githubPush())"
echo "   🕒 SCM Polling every 5 minutes (pollSCM('H/5 * * * *'))"
echo "   📅 Daily scheduled build (cron('@daily'))"
echo ""

echo "🎯 What happens when you push to GitHub:"
echo "   1. GitHub sends webhook to Jenkins"
echo "   2. Jenkins receives the push notification"
echo "   3. Jenkins automatically starts a new build"
echo "   4. The comprehensive pipeline runs all tests"
echo "   5. Results are available in Jenkins dashboard"
echo ""

echo "📊 Monitor builds at:"
echo "   🌐 Local: $JENKINS_LOCAL_URL/job/ShopSphere-Comprehensive-Pipeline/"
echo "   🌍 Public: $JENKINS_PUBLIC_URL/job/ShopSphere-Comprehensive-Pipeline/"
echo ""

echo "💡 Pro Tip: The webhook URL must be accessible from the internet"
echo "   That's why we're using ngrok: $JENKINS_PUBLIC_URL"
echo ""

# Test if Jenkins is accessible
echo "🔍 Testing Jenkins accessibility..."
if curl -s "$JENKINS_LOCAL_URL/api/json" > /dev/null; then
    echo "   ✅ Jenkins local URL is accessible"
else
    echo "   ❌ Jenkins local URL not accessible"
fi

if curl -s "$JENKINS_PUBLIC_URL/api/json" > /dev/null; then
    echo "   ✅ Jenkins public URL is accessible"
else
    echo "   ❌ Jenkins public URL not accessible (check ngrok)"
fi

echo ""
echo "🚀 Ready for automatic builds via GitHub webhook!"
