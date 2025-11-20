#!/bin/bash
# GitOps Controller - Non-Interactive Quick Install
# Usage: curl -fsSL https://raw.githubusercontent.com/Taiwrash/kgh/main/quick-install.sh | bash -s -- <namespace> <webhook-secret>

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   GitOps Controller - Quick Install          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""

# Parse arguments
NAMESPACE="${1:-default}"
WEBHOOK_SECRET="$2"

# Generate webhook secret if not provided
if [ -z "$WEBHOOK_SECRET" ]; then
    if command -v openssl &> /dev/null; then
        WEBHOOK_SECRET=$(openssl rand -hex 32)
    elif [ -f /dev/urandom ]; then
        WEBHOOK_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
    else
        WEBHOOK_SECRET=$(date +%s%N | sha256sum 2>/dev/null | head -c 64 || date +%s | md5sum | head -c 64)
    fi
    echo -e "${GREEN}Generated webhook secret: ${WEBHOOK_SECRET}${NC}"
fi

GITHUB_TOKEN="${3:-}"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ kubectl found${NC}"

# Check cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}✗ Cannot connect to cluster${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to cluster${NC}"

echo ""
echo -e "${YELLOW}Installing to namespace: ${NAMESPACE}${NC}"

# Create namespace
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# Download and apply RBAC
echo "Applying RBAC..."
kubectl apply -f https://raw.githubusercontent.com/Taiwrash/kgh/main/deployments/kubernetes/rbac.yaml

# Create secret
echo "Creating secret..."
kubectl create secret generic kgh-secret \
    --from-literal=github-token="$GITHUB_TOKEN" \
    --from-literal=webhook-secret="$WEBHOOK_SECRET" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

# Apply deployment
echo "Deploying controller..."
kubectl apply -f https://raw.githubusercontent.com/Taiwrash/kgh/main/deployments/kubernetes/deployment.yaml -n "$NAMESPACE"
kubectl apply -f https://raw.githubusercontent.com/Taiwrash/kgh/main/deployments/kubernetes/service.yaml -n "$NAMESPACE"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Installation Complete! 🎉             ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""

# Wait for deployment
echo "Waiting for deployment..."
kubectl wait --for=condition=available --timeout=60s deployment/kgh -n "$NAMESPACE" 2>/dev/null || true

# Get service info
echo ""
echo -e "${YELLOW}Webhook Configuration:${NC}"
echo "  Secret: $WEBHOOK_SECRET"
echo ""
echo "Get webhook URL with:"
echo "  kubectl get svc kgh -n $NAMESPACE"
echo ""
echo -e "${GREEN}Next: Configure GitHub webhook with the URL above${NC}"
