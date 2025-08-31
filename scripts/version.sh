#!/bin/bash
# Show version information

set -e

CONFIG_FILE="${CONFIG_FILE:-config.yml}"
VERSION=$(grep "version:" "$CONFIG_FILE" | head -1 | sed "s/.*: //" | tr -d '"')
BUILD_DATE=$(date +%Y%m%d)

if command -v gum &> /dev/null; then
    gum style --foreground 212 "n8n-Pi OS Builder v${VERSION}"
    gum style --foreground 245 "Build Date: ${BUILD_DATE}"
else
    echo "n8n-Pi OS Builder v${VERSION}"
    echo "Build Date: ${BUILD_DATE}"
fi