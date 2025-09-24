#!/bin/bash
# oaCamBridge Helper Functions
# Utility functions for camera streaming operations

set -e

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

# Load configuration from config.yaml
load_config() {
    local config_file="${1:-config.yaml}"

    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: Configuration file $config_file not found.${NC}"
        exit 1
    fi

    # Parse YAML config (basic parsing for our simple structure)
    export CAMERA_INDEX=$(grep "camera_index:" "$config_file" | cut -d':' -f2 | cut -d'#' -f1 | xargs)
    export VIDEO_SIZE=$(grep "resolution:" "$config_file" | cut -d':' -f2 | cut -d'#' -f1 | xargs)
    export INPUT_FPS=$(grep "^fps:" "$config_file" | cut -d':' -f2 | cut -d'#' -f1 | xargs)
    export FRAME_FPS=$(grep "frame_fps:" "$config_file" | cut -d':' -f2 | cut -d'#' -f1 | xargs)
    export FRAME_QUALITY=$(grep "quality:" "$config_file" | cut -d':' -f2 | cut -d'#' -f1 | xargs)
    export FRAME_DIR=$(grep "frame_dir:" "$config_file" | cut -d':' -f2 | cut -d'#' -f1 | xargs | sed 's/^"//' | sed 's/"$//')
    export RTSP_PORT=$(grep "rtsp_port:" "$config_file" | cut -d':' -f2 | cut -d'#' -f1 | xargs)
    export STREAM_NAME=$(grep "stream_name:" "$config_file" | cut -d':' -f2 | cut -d'#' -f1 | xargs | sed 's/^"//' | sed 's/"$//')

    # Set defaults if not found in config
    CAMERA_INDEX=${CAMERA_INDEX:-"0"}
    VIDEO_SIZE=${VIDEO_SIZE:-"1280x720"}
    INPUT_FPS=${INPUT_FPS:-10}
    FRAME_FPS=${FRAME_FPS:-5}
    FRAME_QUALITY=${FRAME_QUALITY:-95}
    FRAME_DIR=${FRAME_DIR:-"/tmp/webcam"}
    RTSP_PORT=${RTSP_PORT:-8554}
    STREAM_NAME=${STREAM_NAME:-"webcam"}
}

# Display current configuration
show_config() {
    echo -e "${BLUE}Configuration:${NC}"
    echo -e "  Camera: $CAMERA_INDEX"
    echo -e "  Resolution: $VIDEO_SIZE @ ${INPUT_FPS}fps"
    echo -e "  RTSP Stream: rtsp://localhost:${RTSP_PORT}/${STREAM_NAME}"
    echo -e "  Frame Output: $FRAME_DIR (${FRAME_FPS} FPS)"
    echo -e "  Frame Quality: $FRAME_QUALITY"
}

# Check if required dependencies are installed
check_dependencies() {
    local missing_deps=()

    if ! command -v ffmpeg >/dev/null 2>&1 && ! command -v /opt/homebrew/bin/ffmpeg >/dev/null 2>&1; then
        missing_deps+=("ffmpeg")
    fi

    if ! command -v nc >/dev/null 2>&1; then
        missing_deps+=("netcat")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing dependencies: ${missing_deps[*]}${NC}"
        echo -e "${YELLOW}Please install the missing dependencies and try again.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ All dependencies found${NC}"
}

# Check if MediaMTX is available
check_mediamtx() {
    if command -v mediamtx >/dev/null 2>&1; then
        echo -e "${GREEN}✓ MediaMTX found in PATH${NC}"
        return
    elif [ -f "./mediamtx" ]; then
        echo -e "${GREEN}✓ MediaMTX binary found locally${NC}"
        return
    elif command -v /opt/homebrew/bin/mediamtx >/dev/null 2>&1; then
        echo -e "${GREEN}✓ MediaMTX found in /opt/homebrew/bin${NC}"
        return
    elif command -v /usr/local/bin/mediamtx >/dev/null 2>&1; then
        echo -e "${GREEN}✓ MediaMTX found in /usr/local/bin${NC}"
        return
    else
        echo -e "${RED}Error: MediaMTX not found. Run './scripts/setup.sh' to install dependencies.${NC}"
        echo -e "${YELLOW}Or download from: https://github.com/bluenviron/mediamtx/releases${NC}"
        exit 1
    fi
}

# Validate input source
validate_input() {
    if [[ -f "$CAMERA_INDEX" ]]; then
        echo -e "${GREEN}Using video file: $CAMERA_INDEX${NC}"
    else
        echo -e "${GREEN}Using camera device: $CAMERA_INDEX${NC}"
    fi
}

# Create frame output directory
setup_frame_dir() {
    mkdir -p "$FRAME_DIR"
    echo -e "${GREEN}✓ Frame directory ready: $FRAME_DIR${NC}"
}

# Kill any existing processes
cleanup_existing() {
    pkill -f mediamtx 2>/dev/null || true
    pkill -f ffmpeg 2>/dev/null || true
    echo -e "${YELLOW}Cleaned up existing processes${NC}"
}

# Get FFmpeg input arguments based on source type
get_input_args() {
    if [[ -f "$CAMERA_INDEX" ]]; then
        echo "-re -stream_loop -1 -i $CAMERA_INDEX"
    else
        echo "-f avfoundation -pixel_format uyvy422 -video_size $VIDEO_SIZE -framerate $INPUT_FPS -i $CAMERA_INDEX"
    fi
}