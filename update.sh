#!/bin/bash

echo "🚀 Updating AI Assistant components while preserving memory..."

# Update System Packages
echo "🔄 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Update Ollama
echo "🔄 Updating Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh

# Pull Latest DeepSeek 7B (Ensures No Data Loss)
echo "🔄 Updating DeepSeek 7B Model..."
ollama pull deepseek-llm:7b

# Restart Ollama to apply updates
echo "🔄 Restarting Ollama..."
sudo systemctl restart ollama

# Update Open WebUI (Docker)
echo "🔄 Pulling latest Open WebUI updates..."
cd /home/$(whoami)/open-webui
sudo docker-compose pull
sudo docker-compose up -d

echo "✅ Update complete! AI Assistant is up-to-date. 🌐 Access at: http://your-server-ip"
