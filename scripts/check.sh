#!/bin/bash
# Check build requirements

set -e

REQUIRED_TOOLS="wget xz losetup parted qemu-arm-static"
MISSING_TOOLS=""

if command -v gum &> /dev/null; then
    gum style --foreground 212 --bold "Checking build requirements..."
    
    for tool in $REQUIRED_TOOLS; do
        if command -v "$tool" >/dev/null 2>&1; then
            gum style --foreground 46 "✓ $tool"
        else
            gum style --foreground 196 "✗ $tool missing"
            MISSING_TOOLS="$MISSING_TOOLS $tool"
        fi
    done
    
    if [ -n "$MISSING_TOOLS" ]; then
        echo
        gum style --foreground 245 "Install missing tools with:"
        gum style --foreground 245 "sudo apt-get install wget xz-utils mount parted qemu-user-static"
        exit 1
    fi
    
    gum style --foreground 46 --bold "✓ All requirements met"
else
    echo "Checking build requirements..."
    
    for tool in $REQUIRED_TOOLS; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "✓ $tool"
        else
            echo "✗ $tool missing"
            MISSING_TOOLS="$MISSING_TOOLS $tool"
        fi
    done
    
    if [ -n "$MISSING_TOOLS" ]; then
        echo
        echo "Install missing tools with:"
        echo "sudo apt-get install wget xz-utils mount parted qemu-user-static"
        exit 1
    fi
    
    echo "✓ All requirements met"
fi