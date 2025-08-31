#!/bin/bash
# Display help information for n8n-Pi OS Builder

set -e

CONFIG_FILE="${CONFIG_FILE:-config.yml}"
VERSION=$(grep "version:" "$CONFIG_FILE" | head -1 | sed "s/.*: //" | tr -d '"')

if command -v gum &> /dev/null; then
    gum style \
        --foreground 212 \
        --border double \
        --border-foreground 57 \
        --padding "1 2" \
        --margin "1" \
        --align center \
        "n8n-Pi OS Builder v${VERSION}" \
        "" \
        "Custom Raspberry Pi OS with n8n" \
        "" \
        "Author: Stefano Amorelli" \
        "github.com/stefanoamorelli/n8n-pi"
    
    echo
    gum style --foreground 212 --bold "Available commands:"
    echo
    
    cat << EOF | gum format
- \`make help\` - Show this help
- \`make build\` - Build n8n-Pi OS image
- \`make clean\` - Clean build artifacts
- \`make release\` - Create release package
- \`make check\` - Check build requirements
- \`make version\` - Show version
- \`make download-base\` - Download Raspberry Pi OS base image
- \`make lint\` - Run linting locally
- \`make flash\` - Flash image to SD card
- \`make dev\` - Development mode - test scripts locally
EOF
else
    echo "n8n-Pi OS Builder v${VERSION}"
    echo "Author: Stefano Amorelli <stefano@amorelli.tech>"
    echo ""
    echo "Available commands:"
    echo "  make help         - Show this help"
    echo "  make build        - Build n8n-Pi OS image"
    echo "  make clean        - Clean build artifacts"
    echo "  make release      - Create release package"
    echo "  make check        - Check build requirements"
    echo "  make version      - Show version"
    echo "  make download-base - Download Raspberry Pi OS base image"
    echo "  make lint         - Run linting locally"
    echo "  make flash        - Flash image to SD card"
    echo "  make dev          - Development mode"
fi