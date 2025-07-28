#!/bin/bash

echo "🚀 ShopSphere - Complete Service Status Summary"
echo "================================================"
echo

echo "📡 Jenkins CI/CD:"
echo "  Local:  http://localhost:9040"
echo "  ngrok:  https://0bea8d10028d.ngrok-free.app"
echo

echo "🌐 Application Services:"
echo "  Frontend:     http://localhost:3000"
echo "  Backend API:  http://localhost:8001"
echo "  Backend Alt:  http://localhost:8000"
echo

echo "🔧 Microservices:"
echo "  Analytics:      http://localhost:8002"
echo "  Notifications:  http://localhost:8003"
echo

echo "🗄️ Data & Infrastructure:"
echo "  PostgreSQL:   localhost:5432"
echo "  Redis:        localhost:6379"
echo "  ZooKeeper:    localhost:2181"
echo "  Kafka:        localhost:9092"
echo

echo "📊 Monitoring & UI:"
echo "  Prometheus:   http://localhost:9090"
echo "  Grafana:      http://localhost:3001"
echo "  Kafka UI:     http://localhost:8080"
echo

echo "🐳 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep shopsphere
echo

echo "💡 Quick Commands:"
echo "  Health Check:  ./quick-health-check.sh"
echo "  Stop All:      docker-compose down"
echo "  Start All:     docker-compose up -d"
echo "  View Logs:     docker-compose logs -f [service-name]"
echo

echo "🔗 External Access:"
echo "  Jenkins via ngrok is accessible globally at:"
echo "  https://0bea8d10028d.ngrok-free.app"
echo
