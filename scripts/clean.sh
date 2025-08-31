#!/bin/bash
# Clean build artifacts

set -e

CONFIG_FILE="${CONFIG_FILE:-config.yml}"
BUILD_DIR=$(grep "work_dir:" "$CONFIG_FILE" 2>/dev/null | sed "s/.*: //" | tr -d '"' || echo "/tmp/n8n-pi-os-build")

if command -v gum &> /dev/null; then
    gum spin --spinner dot --title "Cleaning build artifacts..." -- sh -c "
        sudo rm -rf $BUILD_DIR
        rm -rf releases/*.img
        rm -rf releases/*.img.xz
    "
    gum style --foreground 46 "✓ Cleaned"
else
    echo "Cleaning build artifacts..."
    sudo rm -rf "$BUILD_DIR"
    rm -rf releases/*.img releases/*.img.xz
    echo "✓ Cleaned"
fi