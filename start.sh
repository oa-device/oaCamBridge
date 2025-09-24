#!/bin/bash
# oaCamBridge - Production-ready dual-output camera streaming
# Main script containing core FFmpeg pipeline logic

set -e

# Script directory detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load helper functions
source "${SCRIPT_DIR}/scripts/helpers.sh"

echo -e "${GREEN}oaCamBridge - Production Camera Streaming${NC}"
echo -e "${BLUE}Architecture: Camera → FFmpeg → [RTSP Stream + Detection Frames]${NC}"

# Load configuration
load_config "${SCRIPT_DIR}/config.yaml"

# Display current configuration
show_config

# Check for MediaMTX binary
check_mediamtx

# Validate input source
validate_input

# Check dependencies
check_dependencies

# Setup environment
setup_frame_dir
cleanup_existing

# Start background cleanup process
echo -e "${BLUE}Starting background cleanup process...${NC}"
(
    while true; do
        sleep 60
        if [ -d "$FRAME_DIR" ]; then
            file_count=$(find "$FRAME_DIR" -type f -name "*.webp" | wc -l)
            if [ "$file_count" -gt 10000 ]; then
                files_to_remove=$((file_count - 10000))
                find "$FRAME_DIR" -type f -name "*.webp" -printf '%T@ %p\n' | sort -n | head -n "$files_to_remove" | cut -d' ' -f2- | xargs rm -f
            fi
        fi
    done
) &
CLEANUP_PID=$!
echo -e "${GREEN}✓ Background cleanup started (keeping latest 10000 files)${NC}"

# Setup signal handlers for cleanup
cleanup() {
    echo -e "\n${YELLOW}Shutting down services...${NC}"
    kill $MEDIAMTX_PID 2>/dev/null || true
    kill $CLEANUP_PID 2>/dev/null || true
    pkill -f ffmpeg 2>/dev/null || true
    pkill -f mediamtx 2>/dev/null || true
    echo -e "${GREEN}Services stopped${NC}"
}

trap cleanup EXIT INT TERM

# Start MediaMTX server
echo -e "${BLUE}Starting MediaMTX server...${NC}"
if command -v mediamtx >/dev/null 2>&1; then
    MEDIAMTX_BIN="mediamtx"
elif [ -f "./mediamtx" ]; then
    MEDIAMTX_BIN="./mediamtx"
elif command -v /opt/homebrew/bin/mediamtx >/dev/null 2>&1; then
    MEDIAMTX_BIN="/opt/homebrew/bin/mediamtx"
elif command -v /usr/local/bin/mediamtx >/dev/null 2>&1; then
    MEDIAMTX_BIN="/usr/local/bin/mediamtx"
else
    echo -e "${RED}Error: MediaMTX not found. Run './scripts/setup.sh' to install dependencies.${NC}"
    exit 1
fi

$MEDIAMTX_BIN &
MEDIAMTX_PID=$!

# Wait for MediaMTX to start
echo -e "${BLUE}Waiting for MediaMTX to start...${NC}"
timeout=30
while ! nc -z localhost "$RTSP_PORT" && [ $timeout -gt 0 ]; do
    sleep 0.5
    timeout=$((timeout - 1))
done

if [ $timeout -eq 0 ]; then
    echo -e "${RED}Error: MediaMTX failed to start within 15 seconds${NC}"
    exit 1
fi

echo -e "${GREEN}✓ MediaMTX started successfully${NC}"

# Get input arguments based on source type
INPUT_ARGS=$(get_input_args)

# Start dual-output FFmpeg pipeline (MAIN CORE LOGIC)
echo -e "${BLUE}Starting dual-output stream...${NC}"
echo -e "${GREEN}RTSP Stream: rtsp://localhost:${RTSP_PORT}/${STREAM_NAME}${NC}"
echo -e "${GREEN}Detection Frames: ${FRAME_DIR}/${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"

# Core FFmpeg dual-output pipeline
# Creates both RTSP stream (for viewing) and local frames (for AI detection)
if command -v /opt/homebrew/bin/ffmpeg >/dev/null 2>&1; then
    FFMPEG_BIN="/opt/homebrew/bin/ffmpeg"
elif command -v ffmpeg >/dev/null 2>&1; then
    FFMPEG_BIN="ffmpeg"
else
    echo -e "${RED}Error: ffmpeg not found${NC}"
    exit 1
fi

$FFMPEG_BIN \
    $INPUT_ARGS \
    -filter_complex "[0:v]split=2[rtsp][img]" \
    -map "[rtsp]" \
        -c:v libx264 \
        -preset ultrafast \
        -tune zerolatency \
        -f rtsp rtsp://localhost:${RTSP_PORT}/${STREAM_NAME} \
    -map "[img]" \
        -r $FRAME_FPS \
        -c:v libwebp \
        -preset 2 \
        -quality $FRAME_QUALITY \
        "${FRAME_DIR}/img_%06d.webp" \
    -loglevel error