#!/bin/bash
# Setup Cloudflare Tunnel for KGH

set -e

echo "🌩️  Cloudflare Tunnel Setup for KGH"
echo "=================================="

# Parse arguments
INSTALL_ONLY=false
for arg in "$@"; do
    case $arg in
        --install-only)
            INSTALL_ONLY=true
            shift
            ;;
    esac
done

install_cloudflared() {
    echo "📦 Installing cloudflared..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            echo "   Using Homebrew..."
            brew install cloudflare/cloudflare/cloudflared
        else
             echo "❌ Homebrew not found. Please install Homebrew or cloudflared manually."
             exit 1
        fi
    else
        # Detect architecture
        ARCH=$(uname -m)
        case $ARCH in
            x86_64)
                DEB_ARCH="amd64"
                ;;
            aarch64) 
                DEB_ARCH="arm64" 
                ;;
            armv7l) 
                DEB_ARCH="armhf" 
                ;;
            i386|i686) 
                DEB_ARCH="386" 
                ;;
            *)
                echo "❌ Unsupported architecture: $ARCH"
                exit 1
                ;;
        esac

        echo "   Detected architecture: $ARCH (package: $DEB_ARCH)"
        
        if command -v dpkg &> /dev/null; then
            echo "   Downloading .deb package..."
            curl -L --output cloudflared.deb "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${DEB_ARCH}.deb"
            sudo dpkg -i cloudflared.deb
            rm cloudflared.deb
        elif command -v rpm &> /dev/null; then
             echo "   Downloading .rpm package..."
             # RPM naming might differ slightly, checking common pattern
             # Based on user request: cloudflared-linux-x86_64.rpm, cloudflared-linux-aarch64.rpm
             # But release usually has: cloudflared-linux-amd64.rpm, cloudflared-linux-arm64.rpm, cloudflared-linux-386.rpm
             # Let's map to what is commonly available or fallback to binary
             
             RPM_ARCH=$DEB_ARCH
             if [ "$DEB_ARCH" == "amd64" ]; then RPM_ARCH="x86_64"; fi
             if [ "$DEB_ARCH" == "arm64" ]; then RPM_ARCH="aarch64"; fi
             
             curl -L --output cloudflared.rpm "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${RPM_ARCH}.rpm"
             sudo rpm -ivh cloudflared.rpm
             rm cloudflared.rpm
        else
            echo "   Downloading binary..."
            # Fallback to direct binary
             curl -L --output cloudflared "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${DEB_ARCH}"
             chmod +x cloudflared
             sudo mv cloudflared /usr/local/bin/
        fi
    fi
}

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "❌ cloudflared not found."
    install_cloudflared
else
    echo "✅ cloudflared is installed"
fi

if [ "$INSTALL_ONLY" = true ]; then
    echo "✅ Installation complete."
    exit 0
fi

# Default service URL
DEFAULT_URL="http://10.3.0.18:80"
read -p "Enter your KGH service URL [${DEFAULT_URL}]: " SERVICE_URL
SERVICE_URL=${SERVICE_URL:-$DEFAULT_URL}

echo ""
echo "🚀 Starting Cloudflare Tunnel..."
echo "   This will create a temporary public URL for your service."
echo "   Look for the URL ending in .trycloudflare.com in the output below."
echo "   Press Ctrl+C to stop."
echo ""

cloudflared tunnel --url "$SERVICE_URL"
