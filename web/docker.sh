#!/bin/bash

# This script is the entry point for docker.lebit.sh

# Get the absolute path to the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Import module directly
source "${PROJECT_ROOT}/modules/docker/main.sh"
