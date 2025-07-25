# GitHub Webhook Setup Guide for ShopSphere Jenkins CI/CD

## 📋 Overview

This guide explains how to set up GitHub webhooks to automatically trigger Jenkins builds when code is pushed to your repository.

## 🔧 Setting Up GitHub Webhook

### Step 1: Access Repository Settings

1. Go to your ShopSphere repository on GitHub
2. Click on **Settings** tab
3. Click on **Webhooks** in the left sidebar
4. Click **Add webhook**

### Step 2: Configure Webhook

Fill in the following details:

- **Payload URL**: `http://your-server-ip:9090/github-webhook/`
  - For local development: `http://localhost:9090/github-webhook/`
  - For public access: Use ngrok or your public IP
- **Content type**: `application/json`
- **Secret**: (Optional) Add a secret for security
- **SSL verification**: Enable if using HTTPS

### Step 3: Select Events

Choose which events should trigger the webhook:

- ✅ **Just the push event** (recommended for basic CI/CD)
- Or select **Let me select individual events** and choose:
  - Push events
  - Pull request events
  - Release events (optional)

### Step 4: Activate Webhook

- ✅ Check **Active**
- Click **Add webhook**

## 🌐 Local Development with ngrok

If you're running Jenkins locally and want to test webhooks:

### Install ngrok

```bash
# macOS with Homebrew
brew install ngrok

# Or download from https://ngrok.com/download
```

### Expose Jenkins

```bash
# Start ngrok tunnel to Jenkins
ngrok http 9090

# Note the https URL (e.g., https://abc123.ngrok.io)
```

### Update Webhook URL

Use the ngrok HTTPS URL in your GitHub webhook:
`https://abc123.ngrok.io/github-webhook/`

## 🔐 Security Configuration

### Option 1: Using Secret Token

1. Generate a secret token:

```bash
openssl rand -hex 20
```

2. Add the token to GitHub webhook secret field

3. Configure Jenkins to validate the secret:
   - Go to Jenkins → Manage Jenkins → Configure System
   - Find "GitHub" section
   - Add your secret token

### Option 2: IP Whitelist

If you have a static IP, you can restrict webhook access:

- Configure firewall to only allow GitHub IPs
- GitHub webhook IPs: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/about-githubs-ip-addresses

## 🧪 Testing the Webhook

### Manual Test

1. Go to your webhook settings on GitHub
2. Click on the webhook you created
3. Scroll down to "Recent Deliveries"
4. Click "Redeliver" to test

### Automatic Test

1. Make a small change to your repository
2. Commit and push:

```bash
git add .
git commit -m "Test webhook trigger"
git push origin main
```

3. Check Jenkins dashboard for new build

## 🔍 Troubleshooting

### Common Issues

#### 1. Webhook Returns 404

- **Problem**: Jenkins returns 404 for webhook URL
- **Solution**: Ensure GitHub plugin is installed and enabled
- **Check**: Jenkins → Manage Jenkins → Manage Plugins → Installed → GitHub Plugin

#### 2. Webhook Returns 403/500

- **Problem**: Authentication or server error
- **Solution**:
  - Check Jenkins logs: `docker logs shopsphere_jenkins`
  - Verify webhook secret configuration
  - Ensure Jenkins is accessible from GitHub

#### 3. Jenkins Build Not Triggered

- **Problem**: Webhook received but build not started
- **Solution**:
  - Check job configuration for GitHub trigger
  - Verify branch configuration
  - Check SCM polling logs

#### 4. ngrok Connection Issues

- **Problem**: ngrok tunnel not working
- **Solution**:
  - Restart ngrok: `ngrok http 9090`
  - Use HTTPS URL from ngrok
  - Check ngrok web interface: `http://localhost:4040`

### Debug Commands

```bash
# Check Jenkins logs
docker logs shopsphere_jenkins -f

# Check webhook deliveries on GitHub
curl -H "Authorization: token YOUR_GITHUB_TOKEN" \
     https://api.github.com/repos/USERNAME/REPO/hooks/HOOK_ID/deliveries

# Test webhook manually
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -d '{"ref":"refs/heads/main","commits":[{"id":"test"}]}' \
  http://localhost:9090/github-webhook/
```

## 📊 Webhook Payload Example

When GitHub sends a webhook, it includes payload data like this:

```json
{
  "ref": "refs/heads/main",
  "before": "0000000000000000000000000000000000000000",
  "after": "1234567890abcdef1234567890abcdef12345678",
  "repository": {
    "name": "ShopSphere",
    "full_name": "username/ShopSphere",
    "html_url": "https://github.com/username/ShopSphere",
    "clone_url": "https://github.com/username/ShopSphere.git"
  },
  "pusher": {
    "name": "username",
    "email": "user@example.com"
  },
  "commits": [
    {
      "id": "1234567890abcdef1234567890abcdef12345678",
      "message": "Fix bug in payment processing",
      "author": {
        "name": "Developer Name",
        "email": "dev@example.com"
      }
    }
  ]
}
```

## 🎯 Advanced Configuration

### Multiple Branch Triggers

Configure different Jenkins jobs for different branches:

1. **Main Branch Job**: Production deployment

   - Trigger: Push to `main`
   - Actions: Full CI/CD pipeline + production deploy

2. **Develop Branch Job**: Staging deployment

   - Trigger: Push to `develop`
   - Actions: Full CI/CD pipeline + staging deploy

3. **Feature Branch Job**: Testing only
   - Trigger: Push to `feature/*`
   - Actions: Tests only, no deployment

### Pull Request Triggers

Set up Jenkins to run tests on pull requests:

1. Install "GitHub Pull Request Builder" plugin
2. Configure job to trigger on PR events
3. Set status updates back to GitHub

## 📈 Monitoring Webhooks

### GitHub Webhook Logs

- Go to repository Settings → Webhooks
- Click on your webhook
- View "Recent Deliveries" section
- Check response codes and timing

### Jenkins Webhook Logs

```bash
# View Jenkins webhook logs
docker exec shopsphere_jenkins tail -f /var/log/jenkins/jenkins.log | grep webhook

# View all Jenkins logs
docker logs shopsphere_jenkins --tail 100 -f
```

## ✅ Best Practices

1. **Use HTTPS**: Always use HTTPS for webhook URLs in production
2. **Validate Signatures**: Use webhook secrets to validate requests
3. **Monitor Deliveries**: Regularly check webhook delivery status
4. **Test Changes**: Test webhook configuration in staging first
5. **Use Branch Protection**: Require successful builds before merging
6. **Rate Limiting**: Be aware of GitHub webhook rate limits
7. **Backup Configuration**: Document webhook settings for disaster recovery

## 🚀 Next Steps

After setting up webhooks:

1. **Test the complete flow**: Make a test commit and verify build triggers
2. **Configure notifications**: Set up Slack/email notifications for build results
3. **Add status badges**: Display build status in your README
4. **Set up branch protection**: Require passing builds for pull requests
5. **Monitor performance**: Track build times and success rates
