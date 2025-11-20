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
docker build -t "${FULL_IMAGE}" .

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
echo "   # With kubeconfig:"
echo "   docker run -p 8082:8082 \\"
echo "     -v ~/.kube/config:/home/kgh/.kube/config:ro \\"
echo "     -e WEBHOOK_SECRET=test \\"
echo "     ${FULL_IMAGE}"
echo ""
echo "   # Or in-cluster mode (requires K8s deployment):"
echo "   kubectl apply -f deployments/kubernetes/"
