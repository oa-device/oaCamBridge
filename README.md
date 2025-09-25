# oaCamBridge

A lightweight Python-based camera streaming service that captures frames from camera devices and provides HTTP/MJPEG streaming. Designed for macOS with robust camera access handling and frame output for AI processing pipelines.

## Features

- **Direct Camera Access**: OpenCV-based camera capture with macOS permission handling
- **HTTP/MJPEG Streaming**: Live video stream accessible via web browser
- **Frame Capture**: Saves JPEG frames to disk at configurable intervals
- **No Cleanup**: Stable version accumulates frames without automatic deletion
- **macOS Optimized**: Multiple camera backend attempts for reliable macOS operation
- **LaunchAgent Ready**: Service configuration for automatic startup

## Quick Start

### 1. Installation

```bash
# Install dependencies
./scripts/setup.sh

# Or manually:
pip3 install opencv-python-headless
```

### 2. Start Camera Streamer

```bash
# Start with default configuration
python3 camera_streamer.py --config config.json

# Or use helpers
source scripts/helpers.sh
start_streamer
```

### 3. Access Stream

- **Live Stream**: http://localhost:8086/stream
- **Single Frame**: http://localhost:8086/frame
- **Status JSON**: http://localhost:8086/status

## Configuration

Edit `config.json` to customize settings:

```json
{
  "camera_index": "0",
  "width": 1280,
  "height": 720,
  "fps": 10,
  "frame_fps": 5,
  "frame_dir": "/tmp/webcam",
  "quality": 95,
  "http_port": 8086
}
```

## Camera Permissions (macOS)

On first run, macOS will request camera permissions:

1. **Via VNC/Direct Access**: Run in Terminal, click "OK" when permission dialog appears
2. **Via SSH**: Camera permissions won't trigger - use VNC first
3. **Manual Grant**: System Settings → Privacy & Security → Camera → Enable for Terminal

### Troubleshooting Permissions

```bash
# Reset camera permissions
tccutil reset Camera

# Test camera access
source scripts/helpers.sh
test_camera_access
```

## Monitoring

### Real-time Monitor
```bash
./monitor.sh
```

Shows:
- Frame count and latest files
- Directory size
- Camera streamer status
- Timestamp updates

### Helper Functions
```bash
# Load helper functions
source scripts/helpers.sh

# Check status
show_streamer_status

# View configuration
load_config config.json
show_config

# Manage service
start_streamer
stop_streamer
restart_streamer
```

## Frame Management

### Output Location
Frames are saved to `/tmp/webcam/` as:
```
img_000001.jpg
img_000002.jpg
img_000003.jpg
...
```

### Cleanup (Manual)
```bash
# Clean frames older than 60 minutes
source scripts/helpers.sh
cleanup_frames 60

# Remove all frames
rm -f /tmp/webcam/img_*.jpg
```

## LaunchAgent Setup

For automatic startup on macOS:

```bash
# Install LaunchAgent (if available)
cp com.orangead.cambridge.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.orangead.cambridge.plist
```

## HTTP API

### Endpoints

| Endpoint | Description | Response |
|----------|-------------|----------|
| `/stream` | MJPEG video stream | `multipart/x-mixed-replace` |
| `/frame` | Single JPEG frame | `image/jpeg` |
| `/status` | Service status | JSON with stats |

### Status Response
```json
{
  "running": true,
  "frame_count": 1234,
  "files_on_disk": 1234,
  "frame_dir": "/tmp/webcam",
  "config": { ... }
}
```

## Architecture

### Core Components
- **camera_streamer.py**: Main streaming service
- **CameraStreamer Class**: Handles capture, streaming, and frame saving
- **ThreadedHTTPServer**: Concurrent HTTP request handling
- **macOS Camera Detection**: Multiple backend fallback methods

### Design Principles
- **Stability Over Features**: No automatic cleanup to prevent frame loss
- **Simple Dependencies**: Only OpenCV required
- **Platform Awareness**: macOS-specific camera handling
- **AI Pipeline Ready**: Frame output optimized for processing

## Troubleshooting

### Common Issues

**Camera not detected**:
```bash
# Check available cameras
python3 -c "import cv2; [print(f'Camera {i}: {cv2.VideoCapture(i).isOpened()}') for i in range(5)]"
```

**Permission denied**:
- Run via VNC/Terminal (not SSH) to trigger permission dialog
- Check System Settings → Privacy & Security → Camera

**Port already in use**:
```bash
# Check what's using the port
lsof -i :8086

# Or change port in config.json
```

**Frames not saving**:
```bash
# Check frame directory
ls -la /tmp/webcam/

# Check process is running
pgrep -f camera_streamer.py
```

### Logs
Service logs are written to stdout. For LaunchAgent, check:
```bash
tail -f ~/Library/Logs/com.orangead.cambridge/camera_streamer.log
```

## Requirements

- **Python 3.8+**
- **OpenCV (opencv-python-headless)**
- **macOS** (optimized, other platforms may work)
- **Camera device** (USB/built-in)

## License

[License file](LICENSE)

---

**Note**: This is the stable version focused on reliability. No automatic frame cleanup is performed to ensure no data loss for downstream AI processing.