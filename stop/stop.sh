#!/bin/bash

echo "🚨 Stopping all AI services..."

# Stop Open WebUI
echo "🔴 Stopping Open WebUI..."
cd /home/$USER/open-webui
sudo docker-compose down

# Stop Ollama
if pgrep -x "ollama" > /dev/null; then
    echo "🔴 Stopping Ollama..."
    pkill -f "ollama serve"
else
    echo "✅ Ollama is already stopped."
fi

echo "✅ AI Assistant services have been stopped."
