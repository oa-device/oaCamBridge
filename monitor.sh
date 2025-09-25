#!/bin/bash
# Monitor frame directory on macOS

while true; do
    clear
    echo "=== Camera Frame Monitor ==="
    echo "Time: $(date)"
    echo ""

    # Count files
    count=$(ls /tmp/webcam/*.jpg 2>/dev/null | wc -l | tr -d ' ')
    echo "Total frames: $count"
    echo ""

    # Show latest 10 files
    echo "Latest frames:"
    ls -lt /tmp/webcam/*.jpg 2>/dev/null | head -10 | awk '{print $9, $5}'

    # Show directory size
    echo ""
    echo "Directory size: $(du -sh /tmp/webcam 2>/dev/null | cut -f1)"

    # Check if streamer is running
    echo ""
    if pgrep -f camera_streamer.py > /dev/null; then
        echo "Status: ✓ Camera streamer is running"
    else
        echo "Status: ✗ Camera streamer is NOT running"
    fi

    sleep 2
done