#!/bin/bash
# Run linting checks on all scripts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v gum &> /dev/null; then
    gum style --foreground 212 --bold "Running lint checks..."
    
    # Check main build script
    if bash -n "$SCRIPT_DIR/create-image.sh" 2>/dev/null; then
        gum style --foreground 46 "✓ scripts/create-image.sh syntax OK"
    else
        gum style --foreground 196 "✗ scripts/create-image.sh syntax errors"
        exit 1
    fi
    
    # Check all other scripts in scripts directory
    for script in "$SCRIPT_DIR"/*.sh; do
        if [ -f "$script" ] && [ "$(basename "$script")" != "create-image.sh" ]; then
            script_name=$(basename "$script")
            if bash -n "$script" 2>/dev/null; then
                gum style --foreground 46 "✓ scripts/$script_name syntax OK"
            else
                gum style --foreground 196 "✗ scripts/$script_name syntax errors"
                exit 1
            fi
        fi
    done
    
    # Check Makefile
    if make -n help > /dev/null 2>&1; then
        gum style --foreground 46 "✓ Makefile OK"
    else
        gum style --foreground 196 "✗ Makefile errors"
        exit 1
    fi
    
    # Run shellcheck if available
    if command -v shellcheck &> /dev/null; then
        gum style --foreground 245 "Running shellcheck..."
        shellcheck "$SCRIPT_DIR"/*.sh || true
    fi
    
    gum style --foreground 46 --bold "✓ All checks passed"
else
    echo "Running lint checks..."
    
    # Check main build script
    if bash -n "$SCRIPT_DIR/create-image.sh" 2>/dev/null; then
        echo "✓ scripts/create-image.sh syntax OK"
    else
        echo "✗ scripts/create-image.sh syntax errors"
        exit 1
    fi
    
    # Check all other scripts
    for script in "$SCRIPT_DIR"/*.sh; do
        if [ -f "$script" ] && [ "$(basename "$script")" != "create-image.sh" ]; then
            script_name=$(basename "$script")
            if bash -n "$script" 2>/dev/null; then
                echo "✓ scripts/$script_name syntax OK"
            else
                echo "✗ scripts/$script_name syntax errors"
                exit 1
            fi
        fi
    done
    
    # Check Makefile
    if make -n help > /dev/null 2>&1; then
        echo "✓ Makefile OK"
    else
        echo "✗ Makefile errors"
        exit 1
    fi
    
    # Run shellcheck if available
    if command -v shellcheck &> /dev/null; then
        echo "Running shellcheck..."
        shellcheck "$SCRIPT_DIR"/*.sh || true
    fi
    
    echo "✓ All checks passed"
fi