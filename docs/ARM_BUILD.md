# Building KGH for ARM Architecture

## Problem

The Docker image `taiwrash/kgh:latest` on Docker Hub was built for AMD64 architecture, but your Kubernetes cluster nodes are running ARM64 (likely Raspberry Pi or similar ARM-based hardware).

**Error**: `exec ./kgh: exec format error`

## Solution: Build Locally on Your Cluster

Since your cluster nodes are ARM-based, the easiest solution is to build the image directly on one of your nodes.

### Option 1: Build on Cluster Node (Recommended)

SSH into one of your Kubernetes nodes and run:

```bash
# Clone the repository
git clone https://github.com/Taiwrash/kgh.git
cd kgh

# Build the image locally (will automatically use ARM64)
docker build -t taiwrash/kgh:latest .

# The image is now available locally on this node
# Kubernetes will use it when deploying
```

### Option 2: Build and Push to Local Registry

If you have a local container registry:

```bash
# Build for ARM64
docker build -t your-registry.local/kgh:latest .

# Push to your registry
docker push your-registry.local/kgh:latest

# Update deployment to use your registry
kubectl set image deployment/kgh controller=your-registry.local/kgh:latest
```

### Option 3: Use ImagePullPolicy Never

Build on each node that might run the pod:

```bash
# On each node, build the image
docker build -t taiwrash/kgh:latest .
```

Then update the deployment:

```yaml
spec:
  template:
    spec:
      containers:
      - name: controller
        image: taiwrash/kgh:latest
        imagePullPolicy: Never  # Use local image only
```

Apply the change:

```bash
kubectl patch deployment kgh -p '{"spec":{"template":{"spec":{"containers":[{"name":"controller","imagePullPolicy":"Never"}]}}}}'
```

### Option 4: Quick Fix Script

Save this as `build-and-deploy-arm.sh`:

```bash
#!/bin/bash
set -e

echo "Building KGH for ARM64..."

# Clone if not exists
if [ ! -d "kgh" ]; then
    git clone https://github.com/Taiwrash/kgh.git
fi

cd kgh

# Build the image
docker build -t taiwrash/kgh:latest .

echo "✅ Image built successfully!"
echo ""
echo "Now restart your deployment:"
echo "  kubectl rollout restart deployment kgh"
echo ""
echo "Or if using imagePullPolicy: Never, just delete the pod:"
echo "  kubectl delete pod -l app=kgh"
```

Make it executable and run:

```bash
chmod +x build-and-deploy-arm.sh
./build-and-deploy-arm.sh
```

## Verify Architecture

After building, verify the image is ARM64:

```bash
docker inspect taiwrash/kgh:latest | grep Architecture
```

Should show: `"Architecture": "arm64"`

## Deploy

Once the image is built locally:

```bash
# Restart the deployment to use the new local image
kubectl rollout restart deployment kgh

# Watch it come up
kubectl get pods -l app=kgh -w
```

## Long-term Solution

I'll work on pushing a proper multi-platform image to Docker Hub that supports both AMD64 and ARM64. In the meantime, building locally is the fastest solution.
