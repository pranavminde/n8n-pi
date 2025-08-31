#!/bin/bash
# Download Raspberry Pi OS base image

set -e

CONFIG_FILE="${CONFIG_FILE:-config.yml}"
BASE_IMAGE_URL=$(grep "base_image_url:" "$CONFIG_FILE" 2>/dev/null | sed "s/.*: //" | tr -d '"' || echo "https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-11-19/2024-11-19-raspios-bookworm-arm64-lite.img.xz")

echo "Downloading Raspberry Pi OS base image..."
mkdir -p cache
cd cache && wget -c "$BASE_IMAGE_URL"