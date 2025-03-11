#!/bin/bash

# Detect username dynamically
USER=$(whoami)
DATA_DIR="/home/$USER/data"
WEBUI_DIR="/home/$USER/open-webui"

echo "🚀 Starting installation of Ollama + DeepSeek 7B + Open WebUI..."

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

# 3️⃣ Fix Docker Startup Issues
echo "🔄 Ensuring Docker is running correctly..."
sudo systemctl stop docker
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl start docker

# Verify Docker is working
if ! sudo systemctl is-active --quiet docker; then
    echo "❌ Docker failed to start! Attempting manual recovery..."
    sudo systemctl restart docker
    sleep 5
    if ! sudo systemctl is-active --quiet docker; then
        echo "🚨 ERROR: Docker could not be started. Check system logs!"
        exit 1
    fi
fi

echo "✅ Docker is running."

# 4️⃣ Install Ollama
echo "🔄 Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama Service
echo "🔄 Starting Ollama service..."
sudo systemctl start ollama
sleep 5

# 5️⃣ Pull DeepSeek 7B Model
echo "🔄 Downloading DeepSeek LLM 7B..."
ollama pull deepseek-llm:7b
if [ $? -ne 0 ]; then
    echo "❌ Failed to download DeepSeek 7B. Retrying..."
    sleep 5
    ollama pull deepseek-llm:7b
fi

# 6️⃣ Install Open WebUI (Using Docker)
echo "🔄 Installing Open WebUI..."
mkdir -p $WEBUI_DIR
cd $WEBUI_DIR
echo "🔄 Pulling latest Open WebUI Docker image..."
sudo docker pull openwebui/open-webui:latest

# 7️⃣ Create Persistent Memory Directory
echo "🔄 Checking and creating memory storage directory..."
mkdir -p $DATA_DIR

echo "🔄 Creating custom model with memory..."
cat <<EOF > $DATA_DIR/memory_model.modelfile
FROM deepseek-llm:7b
PARAMETER memory=True
EOF

# Ensure the file is properly written before using it
if [ ! -s "$DATA_DIR/memory_model.modelfile" ]; then
    echo "❌ Error: Memory model file was not created correctly."
    exit 1
fi

# Create the model with memory enabled
ollama create my-deepseek-memory -f $DATA_DIR/memory_model.modelfile
if [ $? -ne 0 ]; then
    echo "❌ Failed to create the custom memory model. Retrying..."
    sleep 5
    ollama create my-deepseek-memory -f $DATA_DIR/memory_model.modelfile
fi

echo "✅ Custom model 'my-deepseek-memory' created with memory support at $DATA_DIR."

# 8️⃣ Configure Open WebUI
echo "🔄 Setting up Open WebUI to run on Port 80..."
cat <<EOF > $WEBUI_DIR/docker-compose.yml
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

# 9️⃣ Start Open WebUI
echo "🚀 Starting Open WebUI..."
cd $WEBUI_DIR
sudo docker-compose up -d

if [ $? -ne 0 ]; then
    echo "❌ Failed to start Open WebUI. Retrying..."
    sleep 5
    sudo docker-compose up -d
fi

echo "✅ Installation complete! 🎉"
echo "🌐 Access your AI Assistant at: http://your-server-ip"
