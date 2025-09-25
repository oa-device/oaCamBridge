#!/bin/bash
# oaCamBridge Helper Functions
# Utility functions for Python camera streaming operations

set -e

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load configuration from JSON
load_config() {
    local config_file="${1:-config.json}"

    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: Configuration file $config_file not found.${NC}"
        exit 1
    fi

    # Parse JSON config using Python
    export CAMERA_INDEX=$(python3 -c "import json; print(json.load(open('$config_file'))['camera_index'])" 2>/dev/null || echo "0")
    export WIDTH=$(python3 -c "import json; print(json.load(open('$config_file'))['width'])" 2>/dev/null || echo "1280")
    export HEIGHT=$(python3 -c "import json; print(json.load(open('$config_file'))['height'])" 2>/dev/null || echo "720")
    export FPS=$(python3 -c "import json; print(json.load(open('$config_file'))['fps'])" 2>/dev/null || echo "10")
    export FRAME_FPS=$(python3 -c "import json; print(json.load(open('$config_file'))['frame_fps'])" 2>/dev/null || echo "5")
    export FRAME_DIR=$(python3 -c "import json; print(json.load(open('$config_file'))['frame_dir'])" 2>/dev/null || echo "/tmp/webcam")
    export HTTP_PORT=$(python3 -c "import json; print(json.load(open('$config_file'))['http_port'])" 2>/dev/null || echo "8086")
    export QUALITY=$(python3 -c "import json; print(json.load(open('$config_file'))['quality'])" 2>/dev/null || echo "90")

    echo -e "${BLUE}Configuration loaded from $config_file${NC}"
}

# Display current configuration
show_config() {
    echo -e "${BLUE}Camera Streamer Configuration:${NC}"
    echo -e "  Camera Device: $CAMERA_INDEX"
    echo -e "  Resolution: ${WIDTH}x${HEIGHT} @ ${FPS}fps"
    echo -e "  Frame Capture: ${FRAME_FPS} FPS → $FRAME_DIR"
    echo -e "  HTTP Stream: http://localhost:${HTTP_PORT}/stream"
    echo -e "  JPEG Quality: $QUALITY%"
}

# Check if Python and OpenCV are available
check_dependencies() {
    local missing_deps=()

    if ! command -v python3 >/dev/null 2>&1; then
        missing_deps+=("python3")
    fi

    # Test OpenCV import (use .venv if available)
    if [ -f "$PROJECT_DIR/.venv/bin/python3" ]; then
        if ! "$PROJECT_DIR/.venv/bin/python3" -c "import cv2" 2>/dev/null; then
            missing_deps+=("opencv-python-headless")
        fi
    elif ! python3 -c "import cv2" 2>/dev/null; then
        missing_deps+=("opencv-python-headless")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing dependencies: ${missing_deps[*]}${NC}"
        echo -e "${YELLOW}Run './scripts/setup.sh' to install dependencies${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ All dependencies available${NC}"
}

# Test camera access
test_camera_access() {
    local camera_index="${1:-$CAMERA_INDEX}"

    echo -e "${BLUE}Testing camera access for device $camera_index...${NC}"

    # Use .venv Python if available, fallback to system Python
    local python_cmd="python3"
    if [ -f "$PROJECT_DIR/.venv/bin/python3" ]; then
        python_cmd="$PROJECT_DIR/.venv/bin/python3"
    fi
    
    $python_cmd -c "
import cv2
import sys

camera_index = '$camera_index'
if camera_index.isdigit():
    camera_index = int(camera_index)

cap = cv2.VideoCapture(camera_index)
if cap.isOpened():
    ret, frame = cap.read()
    if ret:
        height, width = frame.shape[:2]
        print(f'✓ Camera {camera_index}: {width}x{height}')
        cap.release()
        sys.exit(0)
    else:
        print('✗ Failed to capture frame')
        cap.release()
        sys.exit(1)
else:
    print('✗ Cannot open camera {camera_index}')
    sys.exit(1)
" && echo -e "${GREEN}✓ Camera test passed${NC}" || echo -e "${RED}✗ Camera test failed${NC}"
}

# Check if camera streamer process is running
is_streamer_running() {
    if pgrep -f "camera_streamer.py" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Start camera streamer
start_streamer() {
    local config_file="${1:-config.json}"

    if is_streamer_running; then
        echo -e "${YELLOW}Camera streamer is already running${NC}"
        return
    fi

    echo -e "${BLUE}Starting camera streamer...${NC}"
    cd "$PROJECT_DIR"

    if [ ! -f "camera_streamer.py" ]; then
        echo -e "${RED}Error: camera_streamer.py not found${NC}"
        exit 1
    fi

    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: Configuration file $config_file not found${NC}"
        exit 1
    fi

    # Use .venv Python if available
    local python_cmd="python3"
    if [ -f ".venv/bin/python3" ]; then
        python_cmd=".venv/bin/python3"
        echo -e "${BLUE}Using virtual environment Python${NC}"
    else
        echo -e "${YELLOW}Virtual environment not found, using system Python${NC}"
    fi

    $python_cmd camera_streamer.py --config "$config_file" &
    local pid=$!

    # Wait a moment and check if it started successfully
    sleep 2
    if kill -0 $pid 2>/dev/null; then
        echo -e "${GREEN}✓ Camera streamer started (PID: $pid)${NC}"
        echo -e "${BLUE}Stream: http://localhost:${HTTP_PORT}/stream${NC}"
        echo -e "${BLUE}Status: http://localhost:${HTTP_PORT}/status${NC}"
    else
        echo -e "${RED}✗ Failed to start camera streamer${NC}"
    fi
}

# Stop camera streamer
stop_streamer() {
    echo -e "${BLUE}Stopping camera streamer...${NC}"

    pkill -f "camera_streamer.py" 2>/dev/null && \
        echo -e "${GREEN}✓ Camera streamer stopped${NC}" || \
        echo -e "${YELLOW}No camera streamer process found${NC}"
}

# Restart camera streamer
restart_streamer() {
    local config_file="${1:-config.json}"

    echo -e "${BLUE}Restarting camera streamer...${NC}"
    stop_streamer
    sleep 1
    start_streamer "$config_file"
}

# Show streamer status
show_streamer_status() {
    if is_streamer_running; then
        local pid=$(pgrep -f "camera_streamer.py")
        echo -e "${GREEN}✓ Camera streamer is running (PID: $pid)${NC}"

        # Show frame directory status
        if [ -d "$FRAME_DIR" ]; then
            local frame_count=$(ls -1 "$FRAME_DIR"/*.webp 2>/dev/null | wc -l | tr -d ' ')
            local dir_size=$(du -sh "$FRAME_DIR" 2>/dev/null | cut -f1 || echo "unknown")
            echo -e "${BLUE}  Frames: $frame_count files, Directory size: $dir_size${NC}"
        fi

        # Test HTTP endpoint
        if command -v curl >/dev/null 2>&1; then
            if curl -s "http://localhost:${HTTP_PORT}/status" >/dev/null 2>&1; then
                echo -e "${GREEN}  HTTP server responding on port ${HTTP_PORT}${NC}"
            else
                echo -e "${YELLOW}  HTTP server not responding${NC}"
            fi
        fi
    else
        echo -e "${RED}✗ Camera streamer is not running${NC}"
    fi
}

# Clean old frames
cleanup_frames() {
    local retention_minutes="${1:-60}"

    if [ ! -d "$FRAME_DIR" ]; then
        echo -e "${YELLOW}Frame directory $FRAME_DIR does not exist${NC}"
        return
    fi

    echo -e "${BLUE}Cleaning frames older than ${retention_minutes} minutes...${NC}"

    local deleted=0
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            rm -f "$file"
            ((deleted++))
        fi
    done < <(find "$FRAME_DIR" -name "img_*.webp" -mmin +${retention_minutes} -print0 2>/dev/null)

    if [ $deleted -gt 0 ]; then
        echo -e "${GREEN}✓ Cleaned $deleted old frames${NC}"
    else
        echo -e "${BLUE}No old frames to clean${NC}"
    fi
}

# Setup frame output directory
setup_frame_dir() {
    mkdir -p "$FRAME_DIR"
    echo -e "${GREEN}✓ Frame directory ready: $FRAME_DIR${NC}"
}

# Get system info
show_system_info() {
    echo -e "${BLUE}System Information:${NC}"
    echo -e "  OS: $(uname -s) $(uname -r)"
    echo -e "  Python: $(python3 --version 2>&1)"

    if python3 -c "import cv2" 2>/dev/null; then
        local cv_version=$(python3 -c "import cv2; print(cv2.__version__)" 2>/dev/null)
        echo -e "  OpenCV: $cv_version"
    else
        echo -e "  OpenCV: Not installed"
    fi

    if command -v uv >/dev/null 2>&1; then
        echo -e "  uv: $(uv --version 2>/dev/null | cut -d' ' -f2)"
    fi
}