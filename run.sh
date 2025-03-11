#!/bin/bash

echo "🔄 Updating Ollama, DeepSeek 7B, and Open WebUI..."

# Ensure Docker is running
if ! systemctl is-active --quiet docker; then
    echo "🔄 Starting Docker service..."
    sudo systemctl start docker
fi

# Pull latest images
echo "🔄 Pulling latest Ollama version..."
docker pull ollama/ollama:latest

echo "🔄 Pulling latest Open WebUI..."
cd /home/$(whoami)/tools-ai-lab/
git pull origin main

# Restart services without losing memory
echo "🔄 Restarting Open WebUI..."
docker-compose down
docker-compose up -d

echo "✅ Update complete!"
echo "🌐 Access Open WebUI at: http://$(hostname -I | awk '{print $1}')"
