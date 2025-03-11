#!/bin/bash

echo "🚀 Ensuring all AI services are running..."

# Start Ollama
if ! pgrep -x "ollama" > /dev/null; then
    echo "🔄 Starting Ollama..."
    ollama serve &
else
    echo "✅ Ollama is already running."
fi

# Start Open WebUI
cd /home/$USER/open-webui
if ! sudo docker ps | grep -q "open-webui"; then
    echo "🔄 Starting Open WebUI..."
    sudo docker-compose up -d
else
    echo "✅ Open WebUI is already running."
fi

# Ensure Open WebUI starts on reboot
sudo systemctl enable docker

echo "✅ AI Assistant is fully operational. 🌐 Access at: http://your-server-ip"
