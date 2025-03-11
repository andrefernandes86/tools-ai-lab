#!/bin/bash

echo "🚀 Starting Ollama + Open WebUI..."

# Ensure Docker is running
if ! systemctl is-active --quiet docker; then
    echo "🔄 Starting Docker service..."
    sudo systemctl start docker
fi

# Ensure Docker service is properly initialized
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

# Check if containers are running
if [ "$(docker ps -q -f name=ollama)" ]; then
    echo "✅ Ollama is already running."
else
    echo "🔄 Starting Ollama..."
    docker start ollama || docker run -d --name ollama ollama/ollama:latest
fi

if [ "$(docker ps -q -f name=open-webui)" ]; then
    echo "✅ Open WebUI is already running."
else
    echo "🔄 Starting Open WebUI..."
    cd /home/$(whoami)/tools-ai-lab/
    docker-compose up -d
fi

echo "✅ All services are up and running!"
echo "🌐 Access Open WebUI at: http://$(hostname -I | awk '{print $1}')"
