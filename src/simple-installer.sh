#!/bin/bash

# Lebit.sh Simple Installer

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions
info() { echo -e "[INFO] $1"; }
success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
warning() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}" >&2; }

# Check root
if [ "$(id -u)" -eq 0 ]; then
    BIN_DIR="/usr/local/bin"
else
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
fi

# Download launcher
info "Downloading Lebit.sh launcher..."
LAUNCHER_URL="https://raw.githubusercontent.com/lebitai/lebitsh/main/src/launcher.sh"

if curl -fsSL "$LAUNCHER_URL" -o "$BIN_DIR/lebitsh"; then
    chmod +x "$BIN_DIR/lebitsh"
    success "Lebit.sh installed successfully!"
    echo ""
    info "Usage:"
    echo "  lebitsh              # Interactive menu"
    echo "  lebitsh system       # System management"
    echo "  lebitsh docker       # Docker management"
    echo "  lebitsh dev          # Development tools"
    echo "  lebitsh tools        # System utilities"
    echo "  lebitsh mining       # Mining tools"
    echo "  lebitsh help         # Show help"
    echo ""
    
    if [ "$(id -u)" -ne 0 ] && ! echo "$PATH" | grep -q "$BIN_DIR"; then
        warning "Add $BIN_DIR to your PATH:"
        echo "  echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.bashrc"
        echo "  source ~/.bashrc"
        echo ""
        info "Or run directly: $BIN_DIR/lebitsh"
    fi
else
    error "Failed to download launcher"
    exit 1
fi