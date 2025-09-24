# oaCamBridge - Production-Ready Camera Streaming

A clean, lightweight dual-output camera streaming solution that captures from USB cameras and provides both RTSP streams and AI-ready detection frames.

## Architecture

```
Camera → FFmpeg → [RTSP Stream + Detection Frames]
```

## Features

✅ **Dual-Output Pipeline**: Single capture → RTSP stream + WebP frames
✅ **Lightweight Repository**: No binaries stored in repo, dependencies installed on demand
✅ **Smart Path Detection**: Automatically finds MediaMTX and FFmpeg in system PATH
✅ **Cross-Platform Support**: macOS and Linux with platform-specific optimizations
✅ **Production Ready**: Error handling, signal management, background cleanup
✅ **Configurable**: YAML configuration with sensible defaults

## Quick Start

1. **Setup dependencies** (first time only):
   ```bash
   ./scripts/setup.sh
   ```

2. **Configure** (optional):
   ```bash
   # Edit config.yaml for custom settings
   nano config.yaml
   ```

3. **Start streaming**:
   ```bash
   ./start.sh
   ```

## Outputs

- **RTSP Stream**: `rtsp://localhost:8554/webcam`
- **Detection Frames**: `/tmp/webcam/img_XXXXXX.webp` (5 FPS, 95% quality)

## Architecture

### Core Components

- **`start.sh`**: Main script containing core FFmpeg pipeline logic
- **`scripts/helpers.sh`**: Utility functions for configuration and dependency checking
- **`scripts/setup.sh`**: Lightweight dependency installer (FFmpeg, MediaMTX, netcat)
- **`config.yaml`**: Configuration file with camera settings, output paths, and streaming parameters

### Key Improvements

1. **MediaMTX Path Resolution**: Automatically detects MediaMTX in multiple common locations:
   - System PATH
   - `/opt/homebrew/bin/mediamtx` (Homebrew on Apple Silicon)
   - `/usr/local/bin/mediamtx` (Manual install)
   - `./mediamtx` (Local binary fallback)

2. **FFmpeg Path Detection**: Handles both standard and Homebrew FFmpeg installations

3. **Dependency Management**: Smart installer that:
   - Only installs what's missing
   - Uses appropriate package managers (Homebrew on macOS, APT/YUM on Linux)
   - Downloads binaries as fallback when package managers fail
   - Keeps repository lightweight by avoiding binary storage

4. **Production Features**:
   - Background frame cleanup (maintains 10,000 latest frames)
   - Proper signal handling for graceful shutdown
   - Robust error handling with clear messages
   - YAML configuration with comment support

## Configuration

Edit `config.yaml` to customize:

```yaml
# Camera Settings
camera_index: "0"          # Camera device or video file path
resolution: "1280x720"     # Video resolution
fps: 10                    # Input frame rate

# Frame Output Settings
frame_fps: 5               # Detection frame rate
quality: 95                # WebP quality (0-100)
frame_dir: "/tmp/webcam"   # Detection frames directory

# RTSP Stream Settings
rtsp_port: 8554           # RTSP server port
stream_name: "webcam"     # RTSP stream name
```

## Dependencies

- **FFmpeg**: Video processing and camera capture
- **MediaMTX v1.15.0**: RTSP streaming server
- **netcat**: Network connectivity testing

All dependencies are automatically installed by `scripts/setup.sh`.

## Platform Support

- **macOS**: Uses AVFoundation for camera access, Homebrew for dependencies
- **Linux**: Uses Video4Linux, APT/YUM for dependencies
- **Architecture**: Supports both Intel and ARM processors

## Stopping

Press `Ctrl+C` to stop the streaming. The cleanup handler will:
- Stop MediaMTX and FFmpeg processes
- Clean up background tasks
- Provide clean shutdown confirmation

## Troubleshooting

### MediaMTX Not Found
```bash
Error: MediaMTX not found. Run './scripts/setup.sh' to install dependencies.
```
**Solution**: Run `./scripts/setup.sh` to install MediaMTX

### FFmpeg Not Found
```bash
Error: ffmpeg not found
```
**Solution**: Run `./scripts/setup.sh` to install FFmpeg

### Camera Access Issues
- Check camera permissions on macOS (System Preferences → Security & Privacy → Camera)
- Verify camera device index with: `ffmpeg -f avfoundation -list_devices true -i ""`
- Try different `camera_index` values in config.yaml