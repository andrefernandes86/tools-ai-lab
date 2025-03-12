#!/bin/bash
# This script installs Ollama, pulls the DeepSeek 7B model, and sets up Open WebUI from GitHub.
# It includes safeguards to detect and fix problems.

# Exit immediately if a command exits with a non-zero status
set -e

# Function to check command exit status and exit with a message if failed
function check_exit {
    if [ $? -ne 0 ]; then
        echo "❌ Error: $1"
        exit 1
    fi
}

# Detect username dynamically
USER_NAME=$(whoami)
DATA_DIR="/home/$USER_NAME/data"
WEBUI_DIR="/home/$USER_NAME/open-webui"

echo "🚀 Starting installation of Ollama + DeepSeek 7B + Open WebUI (GitHub Version)..."

# 1️⃣ Update System Packages
echo "🔄 Checking and updating system packages..."
sudo apt update && sudo apt upgrade -y
check_exit "System package update failed."

# 2️⃣ Install Required Dependencies
echo "🔄 Installing required dependencies..."
sudo apt install -y python3 python3-venv python3-pip nginx curl wget unzip git docker.io docker-compose
check_exit "Failed to install dependencies."

# 3️⃣ Ensure Docker is running
echo "🔄 Ensuring Docker is running..."
sudo systemctl enable --now docker
sudo systemctl stop docker || true
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl start docker
sleep 2
if ! sudo systemctl is-active --quiet docker; then
    echo "❌ Docker failed to start. Attempting manual restart..."
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
check_exit "Ollama installation failed."

# Start and enable Ollama service
echo "🔄 Starting Ollama service..."
sudo systemctl enable --now ollama
sleep 5
if ! sudo systemctl is-active --quiet ollama; then
    echo "❌ Ollama service failed to start."
    exit 1
fi

# 5️⃣ Pull DeepSeek 7B Model
echo "🔄 Downloading DeepSeek LLM 7B..."
ollama pull deepseek-llm:7b
if [ $? -ne 0 ]; then
    echo "❌ Failed to download DeepSeek 7B on first attempt. Retrying in 5 seconds..."
    sleep 5
    ollama pull deepseek-llm:7b || { echo "❌ Failed to download DeepSeek 7B after retry."; exit 1; }
fi

# 6️⃣ Clone Open WebUI from GitHub
echo "🔄 Installing Open WebUI from GitHub..."
if [ -d "$WEBUI_DIR" ]; then
    echo "⚠️ Open WebUI directory already exists. Removing old installation..."
    sudo rm -rf "$WEBUI_DIR"
fi
mkdir -p "$WEBUI_DIR"
cd "$WEBUI_DIR"
git clone https://github.com/open-webui/open-webui.git .
check_exit "Failed to clone Open WebUI repository."

# 7️⃣ Build Open WebUI Docker Image
echo "🔄 Building Open WebUI Docker image..."
sudo docker-compose build
check_exit "Docker-compose build failed."

# 8️⃣ Create Persistent Data Directory
echo "🔄 Checking and creating persistent data directory..."
if [ ! -d "$DATA_DIR" ]; then
    mkdir -p "$DATA_DIR"
    check_exit "Failed to create data directory at $DATA_DIR."
fi

# 9️⃣ Create Custom Model File with Memory Enabled
echo "🔄 Creating custom model file with memory support..."
cat <<EOF > "$DATA_DIR/memory_model.modelfile"
FROM deepseek-llm:7b
PARAMETER memory=True
EOF

if [ ! -s "$DATA_DIR/memory_model.modelfile" ]; then
    echo "❌ Error: Memory model file was not created correctly."
    exit 1
fi

# 🔟 Create the Custom Memory-Enabled Model in Ollama
echo "🔄 Creating custom memory-enabled model 'my-deepseek-memory'..."
ollama create my-deepseek-memory -f "$DATA_DIR/memory_model.modelfile"
if [ $? -ne 0 ]; then
    echo "❌ Failed to create the custom memory model. Retrying in 5 seconds..."
    sleep 5
    ollama create my-deepseek-memory -f "$DATA_DIR/memory_model.modelfile" || { echo "❌ Failed to create the custom memory model after retry."; exit 1; }
fi
echo "✅ Custom model 'my-deepseek-memory' created successfully."

# 1️⃣1️⃣ Configure Open WebUI (Docker Compose File)
echo "🔄 Configuring Open WebUI..."
cat <<EOF > "$WEBUI_DIR/docker-compose.yml"
version: '3.8'
services:
  open-webui:
    build: .
    container_name: open-webui
    restart: always
    ports:
      - "80:3000"
    environment:
      - OLLAMA_BASE_URL=http://127.0.0.1:11434
      - MODEL=my-deepseek-memory
    volumes:
      - "$DATA_DIR:/app/data"
EOF

if [ $? -ne 0 ]; then
    echo "❌ Failed to write docker-compose.yml."
    exit 1
fi

# 1️⃣2️⃣ Remove Unused Docker Images
echo "🗑️ Removing unused Docker images..."
sudo docker system prune -af

# 1️⃣3️⃣ Start Open WebUI Using Docker Compose
echo "🚀 Starting Open WebUI..."
cd "$WEBUI_DIR"
sudo docker-compose up -d --build
if [ $? -ne 0 ]; then
    echo "❌ Failed to start Open WebUI. Retrying in 5 seconds..."
    sleep 5
    sudo docker-compose up -d --build || { echo "❌ Failed to start Open WebUI after retry."; exit 1; }
fi

echo "✅ Installation complete! 🎉"
echo "🌐 Access your AI Assistant at: http://your-server-ip"
