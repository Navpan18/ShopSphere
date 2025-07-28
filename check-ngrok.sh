#!/bin/bash

# ngrok Status Checker
# Quick script to check ngrok tunnel status and show URLs

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🌐 ngrok Status Check${NC}"
echo "====================="

# Check if ngrok process is running
if pgrep -f ngrok >/dev/null; then
    echo -e "${GREEN}✅ ngrok process is running${NC}"
    
    # Check if we can reach ngrok API
    if curl -s http://localhost:4040/api/tunnels >/dev/null 2>&1; then
        echo -e "${GREEN}✅ ngrok API is accessible${NC}"
        
        # Get tunnel information
        ngrok_url=$(curl -s http://localhost:4040/api/tunnels | grep -o 'https://[^"]*\.ngrok-free\.app' | head -1)
        
        if [[ -n "$ngrok_url" ]]; then
            echo -e "${GREEN}✅ Tunnel is active${NC}"
            echo ""
            echo -e "${CYAN}🔗 Current URLs:${NC}"
            echo "================"
            echo -e "  🏗️  Jenkins Public:  $ngrok_url"
            echo -e "  📝 GitHub Webhook:   $ngrok_url/github-webhook/"
            echo -e "  🔍 ngrok Dashboard:  http://localhost:4040"
            echo -e "  🏠 Jenkins Local:    http://localhost:9040"
            
            # Save current URL
            echo "$ngrok_url" > .ngrok_url
            
            # Test if Jenkins is accessible via tunnel
            echo ""
            echo -e "${BLUE}🔍 Testing tunnel connectivity...${NC}"
            if curl -s --max-time 10 "$ngrok_url" >/dev/null 2>&1; then
                echo -e "${GREEN}✅ Jenkins is accessible via tunnel${NC}"
            else
                echo -e "${YELLOW}⚠️  Tunnel exists but Jenkins may not be responding${NC}"
            fi
            
        else
            echo -e "${RED}❌ No active tunnels found${NC}"
        fi
    else
        echo -e "${RED}❌ ngrok API not accessible (port 4040)${NC}"
    fi
else
    echo -e "${RED}❌ ngrok process not running${NC}"
    
    # Check if we have a saved URL
    if [[ -f ".ngrok_url" ]]; then
        echo -e "${YELLOW}ℹ️  Found previous ngrok URL: $(cat .ngrok_url)${NC}"
        echo -e "${BLUE}💡 To restart ngrok: './start-ngrok.sh'${NC}"
    fi
fi

echo ""
echo -e "${BLUE}📋 ngrok Commands:${NC}"
echo "=================="
echo -e "  • Start ngrok:           ${YELLOW}./start-ngrok.sh${NC}"
echo -e "  • Stop ngrok:            ${YELLOW}pkill -f ngrok${NC}"
echo -e "  • View ngrok dashboard:  ${YELLOW}open http://localhost:4040${NC}"
echo -e "  • Manual start:          ${YELLOW}ngrok http 9040${NC}"
echo -e "  • Check this status:     ${YELLOW}./check-ngrok.sh${NC}"

# Show Jenkins status
echo ""
echo -e "${BLUE}🏗️ Jenkins Status:${NC}"
echo "=================="
if curl -s http://localhost:9040 >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Jenkins is running locally${NC}"
else
    echo -e "${RED}❌ Jenkins is not running${NC}"
    echo -e "${BLUE}💡 Start Jenkins: 'docker-compose -f jenkins/docker-compose.jenkins.yml up -d'${NC}"
fi
