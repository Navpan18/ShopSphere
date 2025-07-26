#!/bin/bash

# GitHub Webhook Setup Script for Jenkins
# This script helps set up GitHub webhooks for instant Jenkins triggering

echo "🚀 GitHub Webhook Setup for Jenkins"
echo "===================================="
echo ""

# Check current Jenkins status
echo "📊 Current Jenkins Status:"
if curl -s http://localhost:9040 > /dev/null; then
    echo "✅ Jenkins is running on http://localhost:9040"
else
    echo "❌ Jenkins is not accessible on http://localhost:9040"
    exit 1
fi

echo ""
echo "🔧 Webhook Setup Options:"
echo ""

echo "Option 1: ngrok (Recommended for Testing)"
echo "----------------------------------------"
echo "1. Install ngrok: brew install ngrok/ngrok/ngrok"
echo "2. Expose Jenkins: ngrok http 9040"
echo "3. Copy the https URL (e.g., https://abc123.ngrok.io)"
echo "4. In GitHub repo settings:"
echo "   - Go to Settings → Webhooks → Add webhook"
echo "   - Payload URL: https://abc123.ngrok.io/github-webhook/"
echo "   - Content type: application/json"
echo "   - Events: Just the push event"
echo "   - Active: ✅"
echo ""

echo "Option 2: Generic Webhook (Local Testing)"
echo "-----------------------------------------"
echo "Use this URL for local webhook testing:"
echo "http://localhost:9040/generic-webhook-trigger/invoke?token=shopsphere-webhook-token"
echo ""
echo "Test with curl:"
echo "curl -X POST http://localhost:9040/generic-webhook-trigger/invoke?token=shopsphere-webhook-token"
echo ""

echo "Option 3: Git Post-Commit Hook (Local Development)"
echo "---------------------------------------------------"
echo "Create a post-commit hook in your local git repository:"
echo ""
echo "# In your project's .git/hooks/post-commit file:"
echo "#!/bin/bash"
echo "curl -X POST http://localhost:9040/generic-webhook-trigger/invoke?token=shopsphere-webhook-token"
echo ""
echo "Make it executable: chmod +x .git/hooks/post-commit"
echo ""

echo "🎯 Verification Steps:"
echo "----------------------"
echo "1. Make a git commit and push"
echo "2. Check Jenkins dashboard for new build"
echo "3. Build should trigger automatically within seconds"
echo ""

echo "🔍 Troubleshooting:"
echo "-------------------"
echo "- Check Jenkins logs: docker logs shopsphere_jenkins"
echo "- Verify webhook URL is accessible"
echo "- Check GitHub webhook delivery status"
echo "- Ensure Jenkins generic webhook trigger plugin is installed"
