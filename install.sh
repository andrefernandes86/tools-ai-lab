#!/bin/bash

# Detect username dynamically
USER=$(whoami)
DATA_DIR="/home/$USER/data"

echo "🚀 Starting installation of Ollama + DeepSeek 14B + Open WebUI..."

# 1️⃣ Update System Packages
echo "🔄 Checking and updating system packages..."
sudo apt update && sudo apt upgrade -y

# 2️⃣ Install Required Dependencies
echo "🔄 Checking and installing missing dependencies..."
sudo apt install -y python3 python3-venv python3-pip nginx curl wget unzip

# Check and Install Docker
if ! command -v docker &> /dev/null; then
    echo "🔄 Installing Docker..."
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
fi

# Check and Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "🔄 Installing Docker Compose..."
    sudo apt install -y docker-compose
fi

# 3️⃣ Install Ollama
echo "🔄 Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh

# 4️⃣ Pull DeepSeek 14B Model
echo "🔄 Downloading DeepSeek LLM 14B..."
ollama pull deepseek-llm:14b

# 5️⃣ Install Open WebUI
echo "🔄 Installing Open WebUI..."
mkdir -p /home/$USER/open-webui
cd /home/$USER/open-webui
wget https://github.com/open-webui/open-webui/releases/latest/download/open-webui-linux.zip
unzip open-webui-linux.zip -d /home/$USER/open-webui/
chmod +x /home/$USER/open-webui/open-webui

# 6️⃣ Create Persistent Memory Directory
echo "🔄 Checking and creating memory storage directory..."
mkdir -p $DATA_DIR

echo "🔄 Creating custom model with memory..."
cat <<EOF > $DATA_DIR/memory_model.modelfile
FROM deepseek-llm:14b
PARAMETER memory=True
EOF

# Create the model with memory enabled
ollama create my-deepseek-memory -f $DATA_DIR/memory_model.modelfile

echo "✅ Custom model 'my-deepseek-memory' created with memory support at $DATA_DIR."

# 7️⃣ Configure Open WebUI
echo "🔄 Setting up Open WebUI to run on Port 80..."
cat <<EOF > /home/$USER/open-webui/docker-compose.yml
version: '3.8'
services:
  open-webui:
    image: openwebui/open-webui:latest
    container_name: open-webui
    restart: always
    ports:
      - "80:3000"
    environment:
      - OLLAMA_BASE_URL=http://127.0.0.1:11434
      - MODEL=my-deepseek-memory
    volumes:
      - ./data:/app/data
EOF

# 8️⃣ Start Open WebUI
echo "🚀 Starting Open WebUI..."
cd /home/$USER/open-webui
sudo docker-compose up -d

echo "✅ Installation complete! 🎉"
echo "🌐 Access your AI Assistant at: http://your-server-ip"
