#!/bin/bash
# oaCamBridge - Quick Start Script
# Simple wrapper to start the camera streamer using virtual environment

cd "$(dirname "$0")"

# Check if virtual environment exists
if [ ! -f ".venv/bin/python3" ]; then
    echo "Error: Virtual environment not found. Run ./scripts/setup.sh first."
    exit 1
fi

# Use virtual environment Python
exec .venv/bin/python3 camera_streamer.py --config config.json