#!/bin/bash

echo "🛑 Stopping Ollama and Open WebUI..."

# Stop running containers
docker stop ollama open-webui

# Optionally remove stopped containers to free up space
echo "🗑️ Removing stopped containers..."
docker rm ollama open-webui

echo "✅ All services stopped!"
