#!/bin/bash
# This script installs Ollama, pulls the DeepSeek 7B model, creates a custom memory‑enabled model,
# and sets up Open WebUI from GitHub.
# It removes conflicting tools (containerd.io, containerd, podman) and ensures all deployed components
# (Docker containers, Ollama service, etc.) restart automatically after a reboot.
#
# WARNING: This script will remove packages (containerd.io, containerd, podman) and may delete some Docker-related files.
# Please review before running.

set -e

# Function: Check exit status and exit with an error message if a command fails.
function check_exit {
    if [ $? -ne 0 ]; then
        echo "❌ Error: $1"
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# STEP 0: Remove Conflicting Packages and Tools
# ------------------------------------------------------------------------------
echo "🔄 Removing conflicting packages/tools..."
# Remove containerd.io if installed.
if dpkg -l | grep -q '^ii\s\+containerd.io\s'; then
    echo "⚠️ Removing containerd.io..."
    sudo apt remove -y containerd.io
    check_exit "Failed to remove containerd.io"
    sudo apt --fix-broken install -y
fi
# Remove containerd if installed.
if dpkg -l | grep -q '^ii\s\+containerd\s'; then
    echo "⚠️ Removing containerd..."
    sudo apt remove -y containerd
fi
# Remove podman if installed.
if dpkg -l | grep -q '^ii\s\+podman\s'; then
    echo "⚠️ Removing podman..."
    sudo apt remove -y podman
fi

# ------------------------------------------------------------------------------
# STEP 1: Update System Packages
# ------------------------------------------------------------------------------
echo "🔄 Updating system packages..."
sudo apt update && sudo apt upgrade -y
check_exit "System package update failed."

# ------------------------------------------------------------------------------
# STEP 2: Install Required Dependencies
# ------------------------------------------------------------------------------
echo "🔄 Installing required dependencies..."
sudo apt install -y python3 python3-venv python3-pip nginx curl wget unzip git docker.io docker-compose
check_exit "Failed to install dependencies."

# ------------------------------------------------------------------------------
# STEP 3: Ensure Containerd and Docker Are Running
# ------------------------------------------------------------------------------
echo "🔄 Starting containerd..."
sudo systemctl enable --now containerd || true
sleep 2
if ! sudo systemctl is-active --quiet containerd; then
    echo "❌ containerd failed to start. Restarting manually..."
    sudo systemctl restart containerd
    sleep 5
    if ! sudo systemctl is-active --quiet containerd; then
        echo "🚨 ERROR: containerd could not be started. Check system logs!"
        exit 1
    fi
fi
echo "✅ containerd is running."

# Remove stale Docker PID/socket files if they exist
echo "🔄 Cleaning up any stale Docker files..."
sudo rm -f /var/run/docker.pid || true
sudo rm -f /var/run/docker.sock || true

echo "🔄 Starting Docker..."
sudo systemctl enable --now docker
sudo systemctl stop docker || true
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl start docker
sleep 2
if ! sudo systemctl is-active --quiet docker; then
    echo "❌ Docker failed to start. Restarting manually..."
    sudo systemctl restart docker
    sleep 5
    if ! sudo systemctl is-active --quiet docker; then
        echo "🚨 ERROR: Docker could not be started. Check system logs!"
        exit 1
    fi
fi
echo "✅ Docker is running."

# ------------------------------------------------------------------------------
# STEP 4: Install Ollama and Ensure It Auto-Restarts
# ------------------------------------------------------------------------------
echo "🔄 Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh
check_exit "Ollama installation failed."

echo "🔄 Enabling and starting Ollama service..."
sudo systemctl enable --now ollama
sleep 5
if ! sudo systemctl is-active --quiet ollama; then
    echo "❌ Ollama service failed to start."
    exit 1
fi

# ------------------------------------------------------------------------------
# STEP 5: Create Systemd Override for Ollama to Auto-Load Custom Model
# ------------------------------------------------------------------------------
# The ExecStartPost command now has a leading dash and "|| true" to ignore errors.
echo "🔄 Creating systemd override for Ollama to auto-load the custom model..."
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<'EOF'
[Service]
ExecStartPost=-/bin/bash -c 'sleep 10; \
  while ! /usr/local/bin/ollama list | grep -q my-deepseek-memory; do \
    echo "Waiting for custom model my-deepseek-memory to be available..."; \
    sleep 5; \
  done; \
  /usr/local/bin/ollama run my-deepseek-memory || true'
EOF
sudo systemctl daemon-reload
sudo systemctl restart ollama

# ------------------------------------------------------------------------------
# STEP 6: Pull DeepSeek 7B Model
# ------------------------------------------------------------------------------
echo "🔄 Downloading DeepSeek LLM 7B..."
ollama pull deepseek-llm:7b || {
    echo "❌ Failed to download DeepSeek 7B on first attempt. Retrying in 5 seconds..."
    sleep 5
    ollama pull deepseek-llm:7b || { echo "❌ Failed to download DeepSeek 7B after retry."; exit 1; }
}

# ------------------------------------------------------------------------------
# STEP 7: Create Persistent Data Directory and Custom Model File
# ------------------------------------------------------------------------------
USER_NAME=$(whoami)
DATA_DIR="/home/$USER_NAME/data"
WEBUI_DIR="/home/$USER_NAME/open-webui"

echo "🔄 Creating persistent data directory at $DATA_DIR..."
if [ ! -d "$DATA_DIR" ]; then
    mkdir -p "$DATA_DIR"
    check_exit "Failed to create data directory at $DATA_DIR."
fi

echo "🔄 Creating custom model file with memory support..."
cat <<EOF > "$DATA_DIR/memory_model.modelfile"
FROM deepseek-llm:7b
PARAMETER memory=True
EOF
if [ ! -s "$DATA_DIR/memory_model.modelfile" ]; then
    echo "❌ Error: Memory model file was not created correctly."
    exit 1
fi

echo "🔄 Creating custom memory-enabled model 'my-deepseek-memory'..."
ollama create my-deepseek-memory -f "$DATA_DIR/memory_model.modelfile" || {
    echo "❌ Failed to create the custom memory model. Retrying in 5 seconds..."
    sleep 5
    ollama create my-deepseek-memory -f "$DATA_DIR/memory_model.modelfile" || { echo "❌ Failed to create the custom memory model after retry."; exit 1; }
}
echo "✅ Custom model 'my-deepseek-memory' created successfully."

# ------------------------------------------------------------------------------
# STEP 8: Clone and Prepare Open WebUI
# ------------------------------------------------------------------------------
echo "🔄 Installing Open WebUI from GitHub..."
if [ -d "$WEBUI_DIR" ]; then
    echo "⚠️ Open WebUI directory already exists. Removing old installation..."
    sudo rm -rf "$WEBUI_DIR"
fi
mkdir -p "$WEBUI_DIR"
cd "$WEBUI_DIR"
git clone https://github.com/open-webui/open-webui.git .
check_exit "Failed to clone Open WebUI repository."

# ------------------------------------------------------------------------------
# STEP 9: Build Open WebUI Docker Image
# ------------------------------------------------------------------------------
echo "🔄 Building Open WebUI Docker image..."
sudo docker-compose build
check_exit "Docker-compose build failed."

# ------------------------------------------------------------------------------
# STEP 10: Configure Open WebUI Docker Compose
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# STEP 11: Remove Unused Docker Images
# ------------------------------------------------------------------------------
echo "🗑️ Removing unused Docker images..."
sudo docker system prune -af

# ------------------------------------------------------------------------------
# STEP 12: Create a Systemd Service for Open WebUI
# ------------------------------------------------------------------------------
echo "🔄 Creating systemd service for Open WebUI..."
sudo tee /etc/systemd/system/open-webui.service > /dev/null <<EOF
[Unit]
Description=Open WebUI Service
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=$WEBUI_DIR
ExecStart=/usr/bin/docker-compose up -d --build
ExecStop=/usr/bin/docker-compose down
Restart=always
User=$USER_NAME

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable open-webui
sudo systemctl start open-webui

# ------------------------------------------------------------------------------
# STEP 13: Final Message
# ------------------------------------------------------------------------------
echo "✅ Installation complete! 🎉"
echo "🌐 Access your AI Assistant at: http://your-server-ip"
