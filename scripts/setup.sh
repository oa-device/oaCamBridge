#!/bin/bash
# oaCamBridge Setup Script
# Python-based Camera Streaming Dependencies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${GREEN}oaCamBridge Setup - Python Camera Streamer${NC}"
echo -e "${BLUE}Installing Python dependencies...${NC}"

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
echo -e "${BLUE}Detected OS: $OS${NC}"

# Check and install uv
install_uv() {
    if ! command -v uv >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing uv (Python package manager)...${NC}"
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
        echo -e "${GREEN}✓ uv installed${NC}"
    else
        echo -e "${GREEN}✓ uv already installed${NC}"
    fi
}

# Check Python 3
check_python() {
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
        echo -e "${GREEN}✓ Python 3 found: $PYTHON_VERSION${NC}"
    else
        echo -e "${RED}Error: Python 3 not found${NC}"
        if [[ "$OS" == "macos" ]]; then
            echo -e "${YELLOW}Install Python via Homebrew: brew install python@3.12${NC}"
        else
            echo -e "${YELLOW}Install Python via system package manager${NC}"
        fi
        exit 1
    fi
}

# Setup Python virtual environment
setup_venv() {
    echo -e "${BLUE}Setting up Python virtual environment...${NC}"
    cd "$PROJECT_DIR"

    # Create virtual environment
    if [ ! -d ".venv" ]; then
        uv venv .venv
        echo -e "${GREEN}✓ Virtual environment created${NC}"
    else
        echo -e "${YELLOW}Virtual environment already exists${NC}"
    fi

    # Activate virtual environment and install dependencies
    source .venv/bin/activate
    echo -e "${BLUE}Installing dependencies in virtual environment...${NC}"
    
    if [ -f "requirements.txt" ]; then
        uv pip install -r requirements.txt
        echo -e "${GREEN}✓ Dependencies installed from requirements.txt${NC}"
    else
        uv pip install opencv-python-headless
        echo -e "${GREEN}✓ OpenCV installed directly${NC}"
    fi
}

# Test camera access
test_camera() {
    echo -e "${BLUE}Testing camera access...${NC}"
    # Use virtual environment Python
    .venv/bin/python3 -c "
import cv2
cap = cv2.VideoCapture(0)
if cap.isOpened():
    print('✓ Camera access successful')
    cap.release()
else:
    print('✗ Camera access failed - check permissions')
    exit(1)
" 2>/dev/null && echo -e "${GREEN}✓ Camera test passed${NC}" || echo -e "${YELLOW}⚠ Camera test failed (may need permissions)${NC}"
}

# Create directories
setup_directories() {
    # Create frame output directory
    mkdir -p /tmp/webcam
    echo -e "${GREEN}✓ Frame directory created: /tmp/webcam${NC}"

    # Create log directory for LaunchAgent
    if [[ "$OS" == "macos" ]]; then
        LOG_DIR="$HOME/Library/Logs/com.orangead.cambridge"
        mkdir -p "$LOG_DIR"
        echo -e "${GREEN}✓ Log directory created: $LOG_DIR${NC}"
    fi
}

# Show usage instructions
show_usage() {
    echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  Start camera streamer:"
    echo -e "    ./start.sh"
    echo -e "    # Or manually:"
    echo -e "    source .venv/bin/activate && python3 camera_streamer.py --config config.json"
    echo -e ""
    echo -e "  Monitor frames:"
    echo -e "    ./monitor.sh"
    echo -e ""
    echo -e "  View stream:"
    echo -e "    http://localhost:8086/stream"
    echo -e ""
    echo -e "${YELLOW}macOS Note: Camera permissions may be required on first run${NC}"
}

# Main installation
main() {
    echo -e "${BLUE}Starting Python-based camera streamer setup...${NC}"

    check_python
    install_uv
    setup_venv
    setup_directories
    test_camera
    show_usage

    # Show installed versions
    echo -e "${YELLOW}Installed versions:${NC}"
    echo -e "  Python: $(python3 --version 2>&1 | cut -d' ' -f2)"
    echo -e "  uv: $(uv --version 2>/dev/null || echo 'installed')"
    .venv/bin/python3 -c "import cv2; print(f'  OpenCV: {cv2.__version__}')" 2>/dev/null || echo "  OpenCV: installed"
    echo -e "${YELLOW}To activate virtual environment: source .venv/bin/activate${NC}"
}

# Run main function
main "$@"