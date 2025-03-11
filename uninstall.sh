#!/bin/bash

echo "🚨 Starting full uninstallation of Ollama + DeepSeek 14B + Open WebUI..."

# Detect username dynamically
USER=$(whoami)
DATA_DIR="/home/$USER/data"
WEBUI_DIR="/home/$USER/open-webui"

# 1️⃣ Stop All Running Services
echo "🔴 Stopping AI services..."
cd $WEBUI_DIR
sudo docker-compose down

if pgrep -x "ollama" > /dev/null; then
    echo "🔴 Stopping Ollama..."
    pkill -f "ollama serve"
else
    echo "✅ Ollama is already stopped."
fi

# 2️⃣ Remove Open WebUI and Docker Containers
echo "🗑️ Removing Open WebUI..."
sudo rm -rf $WEBUI_DIR
sudo docker system prune -af

# 3️⃣ Uninstall Ollama and DeepSeek Model
echo "🗑️ Removing DeepSeek model..."
ollama rm deepseek-llm:14b

echo "🗑️ Uninstalling Ollama..."
sudo rm -rf ~/.ollama
sudo rm -f /usr/local/bin/ollama

# 4️⃣ Remove Stored Memory Data
echo "🗑️ Removing AI memory storage..."
sudo rm -rf $DATA_DIR

# 5️⃣ Uninstall Dependencies (Optional)
echo "🗑️ Removing installed dependencies..."
sudo apt remove --purge -y docker docker-compose nginx python3 python3-venv python3-pip curl wget unzip
sudo apt autoremove -y
sudo apt clean

# 6️⃣ Reload System Daemon
echo "🔄 Reloading system daemon..."
sudo systemctl daemon-reload

echo "✅ Uninstallation complete! All components have been removed."
