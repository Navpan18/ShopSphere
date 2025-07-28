#!/bin/bash

# ShopSphere Service Shutdown Script
# Stops all ShopSphere services including Jenkins in the correct order

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${CYAN}🛑 Stopping ShopSphere Complete Service Stack${NC}"
echo "=============================================="

# Function to show shutdown status
show_status() {
    echo -e "\n${BLUE}📊 Remaining containers:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(shopsphere|jenkins)" || echo "No ShopSphere containers running"
    echo ""
}

# Step 1: Stop Frontend and Application Services
echo -e "${PURPLE}🛑 Step 1: Stopping Frontend and Application Services...${NC}"
docker-compose stop frontend backend analytics notifications
echo -e "${GREEN}✅ Application services stopped${NC}"

# Step 2: Stop Monitoring Services  
echo -e "${PURPLE}🛑 Step 2: Stopping Monitoring Services...${NC}"
docker-compose stop prometheus grafana kafka-ui
echo -e "${GREEN}✅ Monitoring services stopped${NC}"

# Step 3: Stop Jenkins CI/CD and ngrok
echo -e "${PURPLE}🛑 Step 3: Stopping Jenkins CI/CD and ngrok...${NC}"

# Stop ngrok tunnel
echo -e "${YELLOW}🌐 Stopping ngrok tunnel...${NC}"
pkill -f ngrok || echo "No ngrok process found"

# Clean up ngrok files
rm -f .ngrok_url ngrok_info.txt ngrok.log || true

docker-compose -f jenkins/docker-compose.jenkins.yml stop
echo -e "${GREEN}✅ Jenkins and ngrok stopped${NC}"

# Step 4: Stop Infrastructure Services
echo -e "${PURPLE}🛑 Step 4: Stopping Infrastructure Services...${NC}"
docker-compose stop kafka zookeeper redis postgres
echo -e "${GREEN}✅ Infrastructure services stopped${NC}"

show_status

# Option to remove containers completely
echo -e "\n${YELLOW}🗑️  Do you want to remove containers completely? (y/N)${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo -e "${PURPLE}🗑️  Removing all containers and volumes...${NC}"
    
    # Remove application containers
    docker-compose down -v
    
    # Remove Jenkins containers  
    docker-compose -f jenkins/docker-compose.jenkins.yml down -v
    
    # Clean up networks
    docker network prune -f
    
    # Clean up volumes (optional)
    echo -e "${YELLOW}🗑️  Do you want to remove all volumes (this will delete all data)? (y/N)${NC}"
    read -r vol_response
    
    if [[ "$vol_response" =~ ^[Yy]$ ]]; then
        docker volume prune -f
        echo -e "${GREEN}✅ All volumes removed${NC}"
    fi
    
    echo -e "${GREEN}✅ All containers and networks removed${NC}"
else
    echo -e "${BLUE}ℹ️  Containers stopped but not removed. Use 'docker-compose down' to remove them.${NC}"
fi

show_status

echo -e "\n${GREEN}🎉 ShopSphere service shutdown complete!${NC}"
echo -e "${BLUE}💡 To start services again, run './start-services.sh'${NC}"
echo -e "${BLUE}💡 To check remaining containers, run 'docker ps'${NC}"
echo -e "${GREEN}🌐 ngrok tunnel has been stopped${NC}"

# Show cleanup commands
echo -e "\n${CYAN}🔧 Useful cleanup commands:${NC}"
echo "=========================="
echo -e "  • Remove all containers:     ${YELLOW}docker-compose down && docker-compose -f jenkins/docker-compose.jenkins.yml down${NC}"
echo -e "  • Remove with volumes:       ${YELLOW}docker-compose down -v && docker-compose -f jenkins/docker-compose.jenkins.yml down -v${NC}"
echo -e "  • Clean unused resources:    ${YELLOW}docker system prune -a${NC}"
echo -e "  • View container logs:       ${YELLOW}docker-compose logs [service-name]${NC}"
echo -e "  • Restart specific service:  ${YELLOW}docker-compose restart [service-name]${NC}"
echo -e "  • Start ngrok manually:      ${YELLOW}ngrok http 9040${NC}"
