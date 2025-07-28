#!/bin/bash

# Standalone ngrok starter for Jenkins
# Use this if you need to restart ngrok without restarting all services

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${CYAN}🌐 Starting ngrok for Jenkins${NC}"
echo "================================"

# Check if Jenkins is running
if ! curl -s http://localhost:9040 >/dev/null 2>&1; then
    echo -e "${RED}❌ Jenkins is not running on port 9040${NC}"
    echo -e "${YELLOW}💡 Start Jenkins first with './start-services.sh' or 'docker-compose -f jenkins/docker-compose.jenkins.yml up -d'${NC}"
    exit 1
fi

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo -e "${YELLOW}⚠️  ngrok not found. Installing ngrok...${NC}"
    # Install ngrok on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install ngrok/ngrok/ngrok
        else
            echo -e "${RED}❌ Please install ngrok manually from https://ngrok.com/download${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Please install ngrok manually from https://ngrok.com/download${NC}"
        exit 1
    fi
fi

# Kill any existing ngrok processes
echo -e "${YELLOW}🛑 Stopping any existing ngrok processes...${NC}"
pkill -f ngrok || true
sleep 2

# Clean up old files
rm -f .ngrok_url ngrok_info.txt ngrok.log || true

# Start ngrok in background
echo -e "${YELLOW}⏳ Starting ngrok tunnel for Jenkins (port 9040)...${NC}"
ngrok http 9040 --log=stdout > ngrok.log 2>&1 &

# Wait for ngrok to start
echo -e "${YELLOW}⏳ Waiting for ngrok to establish tunnel...${NC}"
sleep 5

# Get the public URL
ngrok_url=""
for i in {1..15}; do
    ngrok_url=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o 'https://[^"]*\.ngrok-free\.app' | head -1)
    if [[ -n "$ngrok_url" ]]; then
        break
    fi
    echo -n "."
    sleep 2
done

if [[ -n "$ngrok_url" ]]; then
    echo -e "\n${GREEN}✅ ngrok tunnel established successfully!${NC}"
    echo ""
    echo -e "${CYAN}🌐 Jenkins Public URL: ${ngrok_url}${NC}"
    echo -e "${YELLOW}📝 GitHub Webhook URL: ${ngrok_url}/github-webhook/${NC}"
    echo -e "${BLUE}🔍 ngrok Dashboard: http://localhost:4040${NC}"
    
    # Save to files for later reference
    echo "$ngrok_url" > .ngrok_url
    cat > ngrok_info.txt << EOF
Jenkins Public URL: $ngrok_url
GitHub Webhook URL: $ngrok_url/github-webhook/
ngrok Web Interface: http://localhost:4040
Jenkins Local URL: http://localhost:9040

GitHub Webhook Setup:
1. Go to your GitHub repository settings
2. Navigate to Webhooks → Add webhook
3. Payload URL: $ngrok_url/github-webhook/
4. Content type: application/json
5. Select 'Just the push event'
6. Set Active: ✅
7. Click 'Add webhook'
EOF
    
    echo -e "\n${CYAN}📝 URLs saved to 'ngrok_info.txt'${NC}"
    
    echo -e "\n${YELLOW}💡 GitHub Webhook Setup Instructions:${NC}"
    echo "====================================="
    echo -e "  1. Go to your GitHub repository settings"
    echo -e "  2. Navigate to Webhooks → Add webhook"
    echo -e "  3. Payload URL: ${CYAN}${ngrok_url}/github-webhook/${NC}"
    echo -e "  4. Content type: application/json"
    echo -e "  5. Select 'Just the push event'"
    echo -e "  6. Set Active: ✅"
    echo -e "  7. Click 'Add webhook'"
    
    echo -e "\n${GREEN}🎉 ngrok is now running! Jenkins is accessible worldwide.${NC}"
    echo -e "${BLUE}💡 Keep this terminal open or ngrok will stop.${NC}"
    echo -e "${BLUE}💡 To stop ngrok: Press Ctrl+C or run 'pkill -f ngrok'${NC}"
    
else
    echo -e "\n${RED}❌ Failed to get ngrok public URL${NC}"
    echo -e "${YELLOW}💡 Troubleshooting:${NC}"
    echo "  • Check if ngrok is properly installed"
    echo "  • Verify Jenkins is running: curl http://localhost:9040"
    echo "  • Check ngrok logs: cat ngrok.log"
    echo "  • Try running: ngrok http 9040 --log=stdout"
    exit 1
fi
