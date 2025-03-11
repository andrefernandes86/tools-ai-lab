#!/bin/bash

echo "🚨 Starting full uninstallation of Ollama + DeepSeek 7B + Open WebUI..."

# Stop all services
echo "🔴 Stopping AI services..."
cd /home/$(whoami)/open-webui
sudo docker-compose down

if pgrep -x "ollama" > /dev/null; then
    echo "🔴 Stopping Ollama..."
    pkill -f "ollama serve"
else
    echo "✅ Ollama is already stopped."
fi

# Remove Open WebUI and Docker Containers
echo "🗑️ Removing Open WebUI..."
sudo rm -rf /home/$(whoami)/open-webui
sudo docker system prune -af

# Remove Ollama and DeepSeek Model
echo "🗑️ Removing DeepSeek model..."
ollama rm deepseek-llm:7b

echo "🗑️ Uninstalling Ollama..."
sudo rm -rf ~/.ollama
sudo rm -f /usr/local/bin/ollama

# Remove stored AI memory
echo "🗑️ Removing AI memory storage..."
sudo rm -rf /home/$(whoami)/data

# Uninstall Dependencies (Optional)
echo "🗑️ Removing installed dependencies..."
sudo apt remove --purge -y docker docker-compose nginx python3 python3-venv python3-pip curl wget unzip
sudo apt autoremove -y
sudo apt clean

# Reload System Daemon
echo "🔄 Reloading system daemon..."
sudo systemctl daemon-reload

echo "✅ Uninstallation complete! All components have been removed."
