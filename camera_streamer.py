#!/usr/bin/env python3
"""
oaCamBridge - STABLE Camera Streaming Service
No cleanup, just reliable frame saving
"""

import cv2
import os
import sys
import time
import signal
import threading
import logging
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn
from datetime import datetime
import json
from pathlib import Path
import argparse
import platform

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class CameraStreamer:
    """Main camera streaming service"""

    def __init__(self, config):
        self.config = config
        self.camera = None
        self.frame = None
        self.frame_lock = threading.Lock()
        self.running = False
        self.frame_counter = 0

        # Create output directory
        os.makedirs(config['frame_dir'], exist_ok=True)
        logger.info(f"Frame output directory: {config['frame_dir']}")

    def start_camera(self):
        """Initialize camera with multiple backend attempts"""
        camera_index = self.config['camera_index']

        # Check if it's a video file
        if isinstance(camera_index, str) and not camera_index.isdigit():
            logger.info(f"Using video file: {camera_index}")
            self.camera = cv2.VideoCapture(camera_index)
            self.is_video_file = True

            if self.camera.isOpened():
                return True
            else:
                logger.error(f"Failed to open video file: {camera_index}")
                return False

        # Camera device
        if isinstance(camera_index, str) and camera_index.isdigit():
            camera_index = int(camera_index)

        self.is_video_file = False
        logger.info(f"Trying to open camera device: {camera_index}")

        # Try different approaches for macOS
        if platform.system() == "Darwin":
            logger.info("macOS detected, trying camera access...")

            # Method 1: Try without specifying backend (often works best)
            logger.info("Attempting default backend")
            self.camera = cv2.VideoCapture(camera_index)

            if self.camera.isOpened():
                logger.info("✓ Camera opened with default backend")
                return self._configure_camera()

            # Method 2: Try with different indices
            for idx in range(0, 5):
                logger.info(f"Trying camera index {idx}")
                self.camera = cv2.VideoCapture(idx)

                if self.camera.isOpened():
                    logger.info(f"✓ Camera opened at index {idx}")
                    self.config['camera_index'] = idx  # Update config
                    return self._configure_camera()

        else:
            # Non-macOS systems
            self.camera = cv2.VideoCapture(camera_index)
            if self.camera.isOpened():
                return self._configure_camera()

        logger.error(f"Failed to open camera after all attempts")
        return False

    def _configure_camera(self):
        """Configure camera properties"""
        if not self.is_video_file:
            # Try to set properties (may not work on all cameras)
            try:
                self.camera.set(cv2.CAP_PROP_FRAME_WIDTH, self.config['width'])
                self.camera.set(cv2.CAP_PROP_FRAME_HEIGHT, self.config['height'])
                self.camera.set(cv2.CAP_PROP_FPS, self.config['fps'])
            except:
                logger.warning("Could not set all camera properties")

        # Get actual properties
        actual_width = int(self.camera.get(cv2.CAP_PROP_FRAME_WIDTH))
        actual_height = int(self.camera.get(cv2.CAP_PROP_FRAME_HEIGHT))
        actual_fps = int(self.camera.get(cv2.CAP_PROP_FPS)) or self.config['fps']

        logger.info(f"✓ Camera initialized: {actual_width}x{actual_height}@{actual_fps}fps")

        # Test capture
        ret, test_frame = self.camera.read()
        if ret:
            logger.info("✓ Test frame captured successfully")
            return True
        else:
            logger.warning("Could not capture test frame, but will continue")
            return True

    def capture_loop(self):
        """Main capture loop - reads frames and saves to disk"""
        self.running = True
        frame_interval = 1.0 / self.config['frame_fps']
        last_frame_time = 0

        logger.info(f"Capture loop started. Frame interval: {frame_interval}s (FPS: {self.config['frame_fps']})")
        logger.info("CLEANUP DISABLED - frames will accumulate")

        while self.running:
            ret, frame = self.camera.read()
            if not ret:
                if self.is_video_file:
                    # Loop video file
                    logger.info("Video ended, restarting...")
                    self.camera.set(cv2.CAP_PROP_POS_FRAMES, 0)
                    continue
                else:
                    logger.warning("Failed to read frame from camera")
                    time.sleep(0.1)
                    continue

            # Update current frame for HTTP streaming
            with self.frame_lock:
                self.frame = frame.copy()

            # Save frame to disk at specified FPS
            current_time = time.time()
            if current_time - last_frame_time >= frame_interval:
                self.save_frame(frame)
                last_frame_time = current_time

            # Small delay to prevent CPU overload
            time.sleep(0.001)

    def save_frame(self, frame):
        """Save frame to disk as JPEG (more compatible)"""
        self.frame_counter += 1

        # Use JPEG for better compatibility
        filename = f"img_{self.frame_counter:06d}.jpg"
        filepath = os.path.join(self.config['frame_dir'], filename)

        # Save as JPEG
        success = cv2.imwrite(filepath, frame, [cv2.IMWRITE_JPEG_QUALITY, 90])

        if success:
            if self.frame_counter == 1:
                logger.info(f"✓ First frame saved: {filepath}")
            elif self.frame_counter % 50 == 0:
                # Check actual files in directory
                files = list(Path(self.config['frame_dir']).glob('img_*.jpg'))
                logger.info(f"✓ Frame {self.frame_counter} saved. Total files on disk: {len(files)}")
        else:
            logger.error(f"✗ Failed to save frame {self.frame_counter}")

    def get_jpeg_frame(self):
        """Get current frame as JPEG for HTTP streaming"""
        with self.frame_lock:
            if self.frame is None:
                return None
            # Encode frame as JPEG
            ret, jpeg = cv2.imencode('.jpg', self.frame,
                                     [cv2.IMWRITE_JPEG_QUALITY, 90])
            if ret:
                return jpeg.tobytes()
        return None

    def stop(self):
        """Stop capture and cleanup"""
        self.running = False
        if self.camera:
            self.camera.release()
        logger.info("Camera capture stopped")

        # Final report
        files = list(Path(self.config['frame_dir']).glob('img_*.jpg'))
        logger.info(f"Final: {self.frame_counter} frames captured, {len(files)} files on disk")


class StreamingHandler(BaseHTTPRequestHandler):
    """HTTP request handler for MJPEG streaming"""

    def do_GET(self):
        if self.path == '/stream':
            self.send_mjpeg_stream()
        elif self.path == '/frame':
            self.send_single_frame()
        elif self.path == '/status':
            self.send_status()
        else:
            self.send_error(404)

    def send_mjpeg_stream(self):
        """Send MJPEG stream"""
        self.send_response(200)
        self.send_header('Content-Type', 'multipart/x-mixed-replace; boundary=--frame')
        self.end_headers()

        try:
            while True:
                frame = self.server.camera_streamer.get_jpeg_frame()
                if frame:
                    self.send_header('Content-Type', 'image/jpeg')
                    self.send_header('Content-Length', str(len(frame)))
                    self.end_headers()
                    self.wfile.write(frame)
                    self.wfile.write(b'--frame\r\n')
                time.sleep(0.033)  # ~30fps for viewing
        except Exception as e:
            logger.debug(f"Stream closed: {e}")

    def send_single_frame(self):
        """Send single JPEG frame"""
        frame = self.server.camera_streamer.get_jpeg_frame()
        if frame:
            self.send_response(200)
            self.send_header('Content-Type', 'image/jpeg')
            self.send_header('Content-Length', str(len(frame)))
            self.end_headers()
            self.wfile.write(frame)
        else:
            self.send_error(503, "No frame available")

    def send_status(self):
        """Send service status as JSON"""
        # Count actual files
        files = list(Path(self.server.camera_streamer.config['frame_dir']).glob('img_*.jpg'))

        status = {
            'running': self.server.camera_streamer.running,
            'frame_count': self.server.camera_streamer.frame_counter,
            'files_on_disk': len(files),
            'frame_dir': self.server.camera_streamer.config['frame_dir'],
            'config': self.server.camera_streamer.config
        }

        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(status, indent=2).encode())

    def log_message(self, format, *args):
        """Suppress default HTTP logging"""
        pass


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    """Threaded HTTP server for handling multiple connections"""

    def __init__(self, address, handler, camera_streamer):
        super().__init__(address, handler)
        self.camera_streamer = camera_streamer


def load_config(config_file=None):
    """Load configuration from file or use defaults"""
    default_config = {
        'camera_index': 0,
        'width': 1280,
        'height': 720,
        'fps': 10,
        'frame_fps': 5,
        'frame_dir': '/tmp/webcam',
        'quality': 90,
        'http_port': 8086,
        'max_frames': 10000  # Not used in stable version
    }

    if config_file and os.path.exists(config_file):
        try:
            with open(config_file) as f:
                config = json.load(f)
                default_config.update(config)
        except Exception as e:
            logger.error(f"Failed to load config: {e}")

    return default_config


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='oaCamBridge STABLE Camera Streamer')
    parser.add_argument('--config', help='Configuration file (JSON)')
    parser.add_argument('--camera', type=str, help='Camera index or device')
    parser.add_argument('--port', type=int, help='HTTP server port')
    parser.add_argument('--frame-dir', help='Frame output directory')
    parser.add_argument('--frame-fps', type=int, help='Frame capture FPS')

    args = parser.parse_args()

    # Load configuration
    config = load_config(args.config)

    # Override with command line arguments
    if args.camera is not None:
        config['camera_index'] = args.camera
    if args.port:
        config['http_port'] = args.port
    if args.frame_dir:
        config['frame_dir'] = args.frame_dir
    if args.frame_fps:
        config['frame_fps'] = args.frame_fps

    logger.info("=== oaCamBridge STABLE Version ===")
    logger.info("NO CLEANUP - Frames will accumulate!")
    logger.info(f"Configuration: {json.dumps(config, indent=2)}")

    # Create camera streamer
    streamer = CameraStreamer(config)

    # Start camera
    if not streamer.start_camera():
        logger.error("Failed to initialize camera")
        sys.exit(1)

    # Start capture thread
    capture_thread = threading.Thread(target=streamer.capture_loop)
    capture_thread.daemon = True
    capture_thread.start()

    # Start HTTP server
    server_address = ('', config['http_port'])
    httpd = ThreadedHTTPServer(server_address, StreamingHandler, streamer)

    logger.info(f"✓ HTTP server started on port {config['http_port']}")
    logger.info(f"✓ MJPEG stream: http://localhost:{config['http_port']}/stream")
    logger.info(f"✓ Status: http://localhost:{config['http_port']}/status")
    logger.info(f"✓ Frame output: {config['frame_dir']}/")
    logger.info("✓ Frames saved as JPEG for compatibility")

    # Handle signals
    def signal_handler(sig, frame):
        logger.info("Shutting down...")
        streamer.stop()
        httpd.shutdown()
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        streamer.stop()
        httpd.shutdown()


if __name__ == '__main__':
    main()