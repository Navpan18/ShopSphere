#!/bin/bash

# Restart Jenkins and ngrok on port 9040
echo "🔄 Restarting Jenkins on port 9040..."

# Stop existing Jenkins and ngrok
echo "🛑 Stopping existing Jenkins and ngrok..."
cd /Users/coder/Downloads/ShopSphere-main/ShopSphere/jenkins && docker-compose -f docker-compose.jenkins.yml down
pkill -f "ngrok.*90"

# Wait a moment
sleep 5

# Start Jenkins on new port
echo "🚀 Starting Jenkins on port 9040..."
cd /Users/coder/Downloads/ShopSphere-main/ShopSphere/jenkins && docker-compose -f docker-compose.jenkins.yml up -d

# Wait for Jenkins to be ready
echo "⏳ Waiting for Jenkins to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:9040 > /dev/null; then
        echo "✅ Jenkins is ready on port 9040!"
        break
    fi
    echo "   Waiting... ($i/30)"
    sleep 5
done

# Start ngrok on new port
echo "🌐 Starting ngrok on port 9040..."
nohup ngrok http 9040 --log stdout > ngrok.log 2>&1 &

# Wait for ngrok to be ready
sleep 10

# Get ngrok URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*' | grep -o 'https://[^"]*' | head -1)

echo ""
echo "✅ Jenkins and ngrok restarted successfully!"
echo "📍 Local Jenkins:  http://localhost:9040"
echo "🌐 Public ngrok:   $NGROK_URL"
echo ""
echo "🔧 Update your GitHub webhook to use: $NGROK_URL/github-webhook/"
echo ""
