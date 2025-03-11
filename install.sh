#!/bin/bash

# -------------------------------
# 🚀 Ollama + DeepSeek 7B + Open WebUI Installer (Auto-Restart Enabled)
# -------------------------------

echo "🚀 Starting installation of Ollama + DeepSeek 7B + Open WebUI (GitHub Version)..."

# 🔄 Step 1: Check and Update System Packages
echo "🔄 Checking and updating system packages..."
sudo apt update -y && sudo apt upgrade -y

# 🔄 Step 2: Install Dependencies
echo "🔄 Checking and installing missing dependencies..."
sudo apt install -y python3 python3-venv python3-pip nginx curl wget unzip git lsof

# 🔄 Step 3: Ensure Docker and Docker-Compose are Installed
if ! command -v docker &> /dev/null; then
    echo "🔄 Installing Docker..."
    sudo apt install -y docker.io containerd
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "✅ Docker is already installed."
fi

# Ensure Docker is Running
if ! sudo systemctl is-active --quiet docker; then
    echo "⚠️ Docker is not running. Fixing..."
    sudo systemctl stop docker
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl start docker
fi

# 🔄 Step 4: Update Docker-Compose (Fixes 'ContainerConfig' Error)
echo "🔄 Checking Docker-Compose version..."
if ! command -v docker-compose &> /dev/null || [[ "$(docker-compose version --short)" < "2.20.0" ]]; then
    echo "⚠️ Outdated or missing Docker-Compose! Installing latest version..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "✅ Docker-Compose is up-to-date."
fi

# 🔄 Step 5: Check for Port 80 Conflicts
echo "🔄 Checking if port 80 is in use..."
if sudo lsof -i :80; then
    echo "⚠️ Port 80 is in use. Stopping Nginx..."
    sudo systemctl stop nginx
    sudo systemctl disable nginx
    PORT=80
else
    echo "✅ Port 80 is free."
    PORT=80
fi

# 🔄 Step 6: Install Ollama
echo "🔄 Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh
sudo systemctl enable ollama
sudo systemctl start ollama

# 🔄 Step 7: Download DeepSeek LLM 7B
echo "🔄 Downloading DeepSeek LLM 7B..."
ollama pull deepseek-llm:7b

# 🔄 Step 8: Configure Ollama to Auto-Load DeepSeek 7B
echo "🔄 Configuring Ollama systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/ollama.service
[Unit]
Description=Ollama Service
After=network.target

[Service]
ExecStart=/usr/local/bin/ollama serve
ExecStartPost=/bin/bash -c "sleep 10 && /usr/local/bin/ollama run deepseek-llm:7b"
Restart=always
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF

# Enable and restart Ollama service
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl restart ollama

# 🔄 Step 9: Remove Old Open WebUI Installations
WEBUI_DIR="/home/$(whoami)/open-webui"
if [ -d "$WEBUI_DIR" ]; then
    echo "⚠️ Open WebUI directory already exists. Cleaning up..."
    sudo rm -rf "$WEBUI_DIR"
fi

echo "🔄 Cloning Open WebUI from GitHub..."
git clone https://github.com/open-webui/open-webui.git "$WEBUI_DIR"
cd "$WEBUI_DIR"

# 🔄 Step 10: Remove Old Docker Containers & Volumes (Fixes 'ContainerConfig' Issue)
echo "🗑️ Removing old Docker containers and volumes..."
docker-compose down -v --remove-orphans
docker system prune -af

# 🔄 Step 11: Install Open WebUI Dependencies and Build
echo "🔄 Installing Open WebUI dependencies..."
docker-compose build --no-cache

# 🔄 Step 12: Run Open WebUI on Port $PORT
echo "🚀 Starting Open WebUI on port $PORT..."
docker-compose up -d

# 🔄 Step 13: Create a Systemd Service for Open WebUI to Auto-Start
echo "🔄 Creating systemd service for Open WebUI..."
cat <<EOF | sudo tee /etc/systemd/system/open-webui.service
[Unit]
Description=Open WebUI Service
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=$WEBUI_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
Restart=always
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the Open WebUI service
sudo systemctl daemon-reload
sudo systemctl enable open-webui
sudo systemctl start open-webui

echo "✅ Installation complete! 🎉"
echo "🌐 Access your AI Assistant at: http://your-server-ip:$PORT"
