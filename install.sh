#!/bin/bash

echo "🚀 Starting installation of Ollama + DeepSeek 14B + Open WebUI..."

# 1️⃣ Update System Packages
echo "🔄 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# 2️⃣ Install Required Dependencies
echo "🔄 Installing dependencies..."
sudo apt install -y python3 python3-venv python3-pip nginx docker docker-compose unzip curl wget

# 3️⃣ Install Ollama
echo "🔄 Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh

# 4️⃣ Pull DeepSeek 14B Model
echo "🔄 Downloading DeepSeek LLM 14B..."
ollama pull deepseek-llm:14b

# 5️⃣ Install Open WebUI
echo "🔄 Installing Open WebUI..."
mkdir -p /home/skynet/open-webui
cd /home/skynet/open-webui
wget https://github.com/open-webui/open-webui/releases/latest/download/open-webui-linux.zip
unzip open-webui-linux.zip -d /home/skynet/open-webui/
chmod +x /home/skynet/open-webui/open-webui

# 6️⃣ Configure Persistent Memory (Custom Ollama Model)
echo "🔄 Creating custom model with memory..."
cat <<EOF > /home/skynet/open-webui/memory_model.modelfile
FROM deepseek-llm:14b
PARAMETER memory=True
EOF

# Create the model with memory enabled
ollama create my-deepseek-memory -f /home/skynet/open-webui/memory_model.modelfile

echo "✅ Custom model 'my-deepseek-memory' created with memory support."

# 7️⃣ Configure and Run Open WebUI
echo "🔄 Configuring Open WebUI..."
cat <<EOF > /home/skynet/open-webui/.env
OLLAMA_BASE_URL=http://127.0.0.1:11434
MODEL=my-deepseek-memory
EOF

echo "🔄 Setting up Open WebUI to run on Port 80..."
cat <<EOF > /home/skynet/open-webui/docker-compose.yml
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

# Start Open WebUI with Docker
echo "🚀 Starting Open WebUI..."
cd /home/skynet/open-webui
sudo docker-compose up -d

echo "✅ Installation complete! 🎉"
echo "🌐 Access your AI Assistant at: http://your-server-ip"
