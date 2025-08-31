#!/bin/bash
# Create release package

set -e

CONFIG_FILE="${CONFIG_FILE:-config.yml}"
VERSION=$(grep "version:" "$CONFIG_FILE" | head -1 | sed "s/.*: //" | tr -d '"')

if command -v gum &> /dev/null; then
    gum spin --spinner dot --title "Creating release package..." -- \
        sh -c "cd releases && tar -czf n8n-pi-os-${VERSION}.tar.gz *.img.xz 2>/dev/null || true"
    gum style --foreground 46 "✓ Release created: releases/n8n-pi-os-${VERSION}.tar.gz"
else
    echo "Creating release package..."
    cd releases && tar -czf "n8n-pi-os-${VERSION}.tar.gz" *.img.xz 2>/dev/null || true
    echo "✓ Release created: releases/n8n-pi-os-${VERSION}.tar.gz"
fi