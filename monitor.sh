#!/bin/bash
# Monitor frame directory on macOS

# Get format from config.json
if [ -f "config.json" ]; then
    FORMAT=$(python3 -c "import json; print(json.load(open('config.json')).get('format', 'webp'))" 2>/dev/null || echo "webp")
    FRAME_DIR=$(python3 -c "import json; print(json.load(open('config.json'))['frame_dir'])" 2>/dev/null || echo "/tmp/webcam")
else
    FORMAT="webp"
    FRAME_DIR="/tmp/webcam"
fi

while true; do
    clear
    echo "=== Camera Frame Monitor ==="
    echo "Time: $(date)"
    echo ""

    # Count files
    count=$(ls ${FRAME_DIR}/*.$FORMAT 2>/dev/null | wc -l | tr -d ' ')
    echo "Total frames: $count"
    echo ""

    # Show latest 10 files
    echo "Latest frames:"
    ls -lt ${FRAME_DIR}/*.$FORMAT 2>/dev/null | head -10 | awk '{print $9, $5}'

    # Show directory size
    echo ""
    echo "Directory size: $(du -sh $FRAME_DIR 2>/dev/null | cut -f1)"

    # Check if streamer is running
    echo ""
    if pgrep -f camera_streamer.py > /dev/null; then
        echo "Status: ✓ Camera streamer is running"
    else
        echo "Status: ✗ Camera streamer is NOT running"
    fi

    sleep 2
done