#!/bin/bash

# ShopSphere Service Names Reference
# Shows the correct names for all containers and services

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}🔍 ShopSphere Service Names Reference${NC}"
echo "====================================="

echo -e "\n${BLUE}📋 Docker Compose Service Names (used in docker-compose commands):${NC}"
echo "  Main App Services (docker-compose.yml):"
echo "    • postgres"
echo "    • redis" 
echo "    • zookeeper"
echo "    • kafka"
echo "    • backend"
echo "    • frontend"
echo "    • analytics"
echo "    • notifications"
echo "    • kafka-ui"
echo "    • prometheus"
echo "    • grafana"
echo ""
echo "  Jenkins Services (jenkins/docker-compose.jenkins.yml):"
echo "    • jenkins"
echo "    • jenkins-db"

echo -e "\n${BLUE}🐳 Container Names (used in docker exec commands):${NC}"
echo "  Main App Containers:"
echo "    • shopsphere_postgres"
echo "    • shopsphere_redis"
echo "    • shopsphere_zookeeper" 
echo "    • shopsphere_kafka"
echo "    • shopsphere_backend"
echo "    • shopsphere_frontend"
echo "    • shopsphere_analytics"
echo "    • shopsphere_notifications"
echo "    • shopsphere_kafka_ui"
echo "    • shopsphere_prometheus"
echo "    • shopsphere_grafana"
echo ""
echo "  Jenkins Containers:"
echo "    • shopsphere_jenkins"
echo "    • jenkins_postgres"

echo -e "\n${BLUE}🌐 Networks:${NC}"
echo "  Main App Network: shopsphere-network"
echo "  Docker Compose Network Name: shopsphere_shopsphere-network"
echo "  Jenkins Network: jenkins-network"
echo "  Jenkins also connects to: shopsphere-network (external)"

echo -e "\n${BLUE}🔌 Service Ports:${NC}"
echo "  Application Services:"
echo "    • Backend:        8001"
echo "    • Frontend:       3000"  
echo "    • Analytics:      8002"
echo "    • Notifications:  8003"
echo "    • Jenkins:        9040"
echo "  Infrastructure:"
echo "    • PostgreSQL:     5432"
echo "    • Redis:          6379"
echo "    • Kafka:          9092"
echo "    • Zookeeper:      2181"
echo "  Monitoring:"
echo "    • Kafka UI:       8080"
echo "    • Prometheus:     9090"
echo "    • Grafana:        3001"
echo "    • Jenkins DB:     5433"

echo -e "\n${BLUE}🔗 Internal Service URLs (within Docker network):${NC}"
echo "  • Backend:        http://backend:8001"
echo "  • Analytics:      http://analytics:8002"
echo "  • Notifications:  http://notifications:8003"
echo "  • PostgreSQL:     postgresql://user:password@postgres:5432/shopdb"
echo "  • Redis:          redis://redis:6379"
echo "  • Kafka:          kafka:9092"

echo -e "\n${BLUE}🌍 External Service URLs (from host):${NC}"
echo "  • Frontend:       http://localhost:3000"
echo "  • Backend:        http://localhost:8001"
echo "  • Analytics:      http://localhost:8002"
echo "  • Notifications:  http://localhost:8003"
echo "  • Jenkins:        http://localhost:9040"
echo "  • Kafka UI:       http://localhost:8080"
echo "  • Prometheus:     http://localhost:9090"
echo "  • Grafana:        http://localhost:3001"

echo -e "\n${YELLOW}💡 Usage Examples:${NC}"
echo "  Check PostgreSQL: docker exec shopsphere_postgres pg_isready -U user -d shopdb"
echo "  Check Redis:      docker exec shopsphere_redis redis-cli ping"
echo "  Restart service:  docker-compose restart backend"
echo "  View logs:        docker-compose logs -f backend"
echo "  Start services:   docker-compose up -d postgres redis backend"

echo -e "\n${GREEN}✅ All service names are now consistent across scripts and Jenkinsfile!${NC}"
