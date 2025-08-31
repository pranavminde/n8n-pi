#!/bin/bash
# Build n8n-Pi OS image

set -e

CONFIG_FILE="${CONFIG_FILE:-config.yml}"

if command -v gum &> /dev/null; then
    gum style --foreground 212 --bold "Building n8n-Pi OS image..."
else
    echo "Building n8n-Pi OS image..."
fi

# Run the main build script with config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo "$SCRIPT_DIR/create-image.sh" "$CONFIG_FILE"