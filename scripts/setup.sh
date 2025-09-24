#!/bin/bash
# oaCamBridge Setup Script
# Lightweight dependency installer for camera streaming

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${GREEN}oaCamBridge Setup - Lightweight Dependency Installer${NC}"
echo -e "${BLUE}Installing only what's needed...${NC}"

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

# Check and install Homebrew on macOS
install_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo -e "${GREEN}✓ Homebrew already installed${NC}"
    fi
}

# Install FFmpeg
install_ffmpeg() {
    if command -v ffmpeg >/dev/null 2>&1 || command -v /opt/homebrew/bin/ffmpeg >/dev/null 2>&1; then
        echo -e "${GREEN}✓ FFmpeg already installed${NC}"
        return
    fi

    case $OS in
        "macos")
            install_homebrew
            echo -e "${YELLOW}Installing FFmpeg via Homebrew...${NC}"
            brew install ffmpeg
            ;;
        "linux")
            if command -v apt >/dev/null 2>&1; then
                echo -e "${YELLOW}Installing FFmpeg via APT...${NC}"
                sudo apt update && sudo apt install -y ffmpeg
            elif command -v yum >/dev/null 2>&1; then
                echo -e "${YELLOW}Installing FFmpeg via YUM...${NC}"
                sudo yum install -y ffmpeg
            else
                echo -e "${RED}Error: No supported package manager found${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}Error: Unsupported OS${NC}"
            exit 1
            ;;
    esac
    echo -e "${GREEN}✓ FFmpeg installed${NC}"
}

# Install MediaMTX
install_mediamtx() {
    if command -v mediamtx >/dev/null 2>&1; then
        echo -e "${GREEN}✓ MediaMTX already installed${NC}"
        return
    fi

    # Check if we have a local binary
    if [ -f "$PROJECT_DIR/mediamtx" ]; then
        echo -e "${GREEN}✓ MediaMTX binary found locally${NC}"
        return
    fi

    case $OS in
        "macos")
            install_homebrew
            # Try homebrew first
            if brew list --formula | grep -q "^mediamtx$"; then
                echo -e "${GREEN}✓ MediaMTX already installed via Homebrew${NC}"
            else
                echo -e "${YELLOW}Installing MediaMTX via Homebrew...${NC}"
                brew install bluenviron/tap/mediamtx || {
                    echo -e "${YELLOW}Homebrew install failed, downloading binary...${NC}"
                    download_mediamtx_binary
                }
            fi
            ;;
        "linux")
            echo -e "${YELLOW}Downloading MediaMTX binary for Linux...${NC}"
            download_mediamtx_binary
            ;;
        *)
            echo -e "${RED}Error: Unsupported OS${NC}"
            exit 1
            ;;
    esac
    echo -e "${GREEN}✓ MediaMTX installed${NC}"
}

# Download MediaMTX binary as fallback
download_mediamtx_binary() {
    local version="v1.15.0"
    local arch
    local os_name

    case $OS in
        "macos")
            os_name="darwin"
            arch="arm64"  # Default to ARM64 for Apple Silicon
            if [[ "$(uname -m)" == "x86_64" ]]; then
                arch="amd64"
            fi
            ;;
        "linux")
            os_name="linux"
            arch="amd64"
            if [[ "$(uname -m)" == "aarch64" ]]; then
                arch="arm64"
            fi
            ;;
    esac

    local download_url="https://github.com/bluenviron/mediamtx/releases/download/${version}/mediamtx_${version}_${os_name}_${arch}.tar.gz"
    local temp_dir="/tmp/mediamtx_install"

    echo -e "${BLUE}Downloading from: $download_url${NC}"

    mkdir -p "$temp_dir"
    curl -L "$download_url" | tar -xz -C "$temp_dir"

    if [ -f "$temp_dir/mediamtx" ]; then
        chmod +x "$temp_dir/mediamtx"
        sudo mv "$temp_dir/mediamtx" /usr/local/bin/mediamtx
        rm -rf "$temp_dir"
        echo -e "${GREEN}✓ MediaMTX binary installed to /usr/local/bin/mediamtx${NC}"
    else
        echo -e "${RED}Error: Failed to extract MediaMTX binary${NC}"
        rm -rf "$temp_dir"
        exit 1
    fi
}

# Install netcat if needed
install_netcat() {
    if command -v nc >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Netcat already installed${NC}"
        return
    fi

    case $OS in
        "macos")
            install_homebrew
            echo -e "${YELLOW}Installing netcat via Homebrew...${NC}"
            brew install netcat
            ;;
        "linux")
            if command -v apt >/dev/null 2>&1; then
                echo -e "${YELLOW}Installing netcat via APT...${NC}"
                sudo apt install -y netcat-openbsd
            elif command -v yum >/dev/null 2>&1; then
                echo -e "${YELLOW}Installing netcat via YUM...${NC}"
                sudo yum install -y netcat
            fi
            ;;
    esac
    echo -e "${GREEN}✓ Netcat installed${NC}"
}

# Create MediaMTX config if it doesn't exist
create_mediamtx_config() {
    local config_file="$PROJECT_DIR/mediamtx.yml"
    if [ ! -f "$config_file" ]; then
        echo -e "${YELLOW}Creating MediaMTX configuration...${NC}"
        cat > "$config_file" << 'EOF'
# MediaMTX configuration for oaCamBridge
logLevel: warn
logDestinations: [stdout]
logFile: ""

rtspAddress: :8554
rtmpAddress: :1935
hlsAddress: :8888
webrtcAddress: :8889
srtAddress: :8890

paths:
  all:
    readUser: ""
    readPass: ""
    publishUser: ""
    publishPass: ""
EOF
        echo -e "${GREEN}✓ MediaMTX configuration created${NC}"
    else
        echo -e "${GREEN}✓ MediaMTX configuration already exists${NC}"
    fi
}

# Main installation
main() {
    echo -e "${BLUE}Starting dependency installation...${NC}"

    install_ffmpeg
    install_mediamtx
    install_netcat
    create_mediamtx_config

    echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
    echo -e "${BLUE}You can now run: ./start.sh${NC}"

    # Show installed versions
    echo -e "${YELLOW}Installed versions:${NC}"
    if command -v ffmpeg >/dev/null 2>&1; then
        echo -e "  FFmpeg: $(ffmpeg -version | head -n1 | cut -d' ' -f3)"
    elif command -v /opt/homebrew/bin/ffmpeg >/dev/null 2>&1; then
        echo -e "  FFmpeg: $(/opt/homebrew/bin/ffmpeg -version | head -n1 | cut -d' ' -f3)"
    fi

    if command -v mediamtx >/dev/null 2>&1; then
        echo -e "  MediaMTX: $(mediamtx --version 2>&1 | head -n1 | cut -d' ' -f2 || echo 'installed')"
    elif command -v /usr/local/bin/mediamtx >/dev/null 2>&1; then
        echo -e "  MediaMTX: $(/usr/local/bin/mediamtx --version 2>&1 | head -n1 | cut -d' ' -f2 || echo 'installed')"
    fi
}

# Run main function
main "$@"