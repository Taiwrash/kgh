#!/bin/bash
# Build and push KGH Docker image to Docker Hub
# Usage: ./build-docker.sh [version]

set -e

VERSION="${1:-latest}"
IMAGE_NAME="taiwrash/kgh"
FULL_IMAGE="${IMAGE_NAME}:${VERSION}"

echo "🐳 Building KGH Docker Image"
echo "================================"
echo "Image: $FULL_IMAGE"
echo ""

# Build the image
echo "📦 Building image..."
docker build -t "${FULL_IMAGE}" \
    --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    --build-arg VCS_REF=$(git rev-parse --short HEAD) \
    .

# Also tag as latest if building a version
if [ "$VERSION" != "latest" ]; then
    echo "🏷️  Tagging as latest..."
    docker tag "${FULL_IMAGE}" "${IMAGE_NAME}:latest"
fi

echo ""
echo "✅ Build complete!"
echo ""
echo "📋 Image details:"
docker images | grep "${IMAGE_NAME}" | head -2

echo ""
echo "🚀 To push to Docker Hub:"
echo "   docker login"
echo "   docker push ${FULL_IMAGE}"
if [ "$VERSION" != "latest" ]; then
    echo "   docker push ${IMAGE_NAME}:latest"
fi

echo ""
echo "🧪 To test locally:"
echo "   docker run -p 8082:8082 -e WEBHOOK_SECRET=test ${FULL_IMAGE}"
