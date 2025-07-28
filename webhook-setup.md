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

