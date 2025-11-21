#!/bin/bash
# Fast multi-platform build using local Go compilation
# Usage: ./fast-build.sh

set -e

IMAGE_NAME="taiwrash/kgh"
VERSION="latest"

echo "🚀 Fast Multi-Platform Build"
echo "=============================="
echo ""

# Build for AMD64 (Linux servers)
echo "📦 Building AMD64 binary..."
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build \
    -ldflags="-w -s" \
    -o bin/kgh-amd64 ./cmd/kgh

# Build for ARM64 (Mac, Raspberry Pi)
echo "📦 Building ARM64 binary..."
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build \
    -ldflags="-w -s" \
    -o bin/kgh-arm64 ./cmd/kgh

echo ""
echo "✅ Binaries built successfully!"
ls -lh bin/

echo ""
echo "🐳 Building and pushing multi-platform images..."

# Build and push AMD64 image
echo "  → AMD64 image..."
docker buildx build \
    --platform linux/amd64 \
    --build-arg TARGETARCH=amd64 \
    -t ${IMAGE_NAME}:latest-amd64 \
    -f Dockerfile.fast \
    --push .

# Build and push ARM64 image
echo "  → ARM64 image..."
docker buildx build \
    --platform linux/arm64 \
    --build-arg TARGETARCH=arm64 \
    -t ${IMAGE_NAME}:latest-arm64 \
    -f Dockerfile.fast \
    --push .

echo ""
echo "📋 Creating multi-platform manifest..."
docker buildx imagetools create \
    -t ${IMAGE_NAME}:latest \
    ${IMAGE_NAME}:latest-amd64 \
    ${IMAGE_NAME}:latest-arm64

echo ""
echo "✅ Multi-platform image pushed to Docker Hub!"
echo ""
echo "🧪 Test on AMD64 (NixOS):"
echo "   docker run -p 8082:8082 \\"
echo "     -v \$HOME/.kube/config:/app/.kube/config:ro \\"
echo "     -e KUBECONFIG=/app/.kube/config \\"
echo "     -e WEBHOOK_SECRET=test \\"
echo "     ${IMAGE_NAME}:latest"
