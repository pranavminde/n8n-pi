#!/bin/bash
# Development mode - test scripts locally

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v gum &> /dev/null; then
    gum spin --spinner dot --title "Testing build script..." -- bash -n "$SCRIPT_DIR/create-image.sh"
    gum style --foreground 46 "✓ Script syntax OK"
else
    echo "Testing build script syntax..."
    bash -n "$SCRIPT_DIR/create-image.sh" && echo "✓ Script syntax OK"
fi