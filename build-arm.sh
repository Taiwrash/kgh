#!/bin/bash
# Quick build script for ARM-based Kubernetes clusters
# Run this on one of your cluster nodes

set -e

echo "🔨 Building KGH for ARM64 Architecture"
echo "========================================"
echo ""

# Check if we're in the kgh directory
if [ ! -f "Dockerfile" ]; then
    echo "❌ Error: Dockerfile not found"
    echo "Please run this script from the kgh repository root"
    exit 1
fi

# Check if docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker not found"
    echo "Please install Docker first"
    exit 1
fi

# Build the image
echo "📦 Building Docker image..."
docker build -t taiwrash/kgh:latest .

echo ""
echo "✅ Build complete!"
echo ""

# Check architecture
ARCH=$(docker inspect taiwrash/kgh:latest | grep -m1 Architecture | awk '{print $2}' | tr -d '",')
echo "🏗️  Image architecture: $ARCH"
echo ""

# Provide next steps
echo "📋 Next steps:"
echo ""
echo "1. Update deployment to use local image:"
echo "   kubectl patch deployment kgh -p '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"controller\",\"imagePullPolicy\":\"Never\"}]}}}}'"
echo ""
echo "2. Restart the deployment:"
echo "   kubectl rollout restart deployment kgh"
echo ""
echo "3. Watch pods come up:"
echo "   kubectl get pods -l app=kgh -w"
echo ""
echo "🎉 Done! Your ARM-compatible image is ready."
