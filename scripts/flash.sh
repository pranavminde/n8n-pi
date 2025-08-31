#!/bin/bash
# Flash image to SD card

set -e

echo "Starting flash wizard..."
# TODO: Create flash-n8n-pi.sh in releases directory or implement flash functionality here
if [ -f "releases/flash-n8n-pi.sh" ]; then
    cd releases && ./flash-n8n-pi.sh
else
    echo "Flash script not found. Please create releases/flash-n8n-pi.sh or flash manually with:"
    echo "xzcat releases/*.img.xz | sudo dd of=/dev/sdX bs=4M status=progress"
fi