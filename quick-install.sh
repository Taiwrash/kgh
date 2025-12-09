#!/bin/bash
# KGH - Non-Interactive Quick Install
# Usage: curl -fsSL https://raw.githubusercontent.com/Taiwrash/kgh/main/quick-install.sh | bash -s -- <namespace> <webhook-secret>

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   KGH - Quick Install          ║${NC}"
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
    echo -e "${RED}✗ kubectl not found | install kubectl to continue | you can try k3s or minikube${NC}"
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
    --from-literal=GITHUB_TOKEN="$GITHUB_TOKEN" \
    --from-literal=WEBHOOK_SECRET="$WEBHOOK_SECRET" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

# Check for Ingress Controller
USE_INGRESS=false
check_ingress_controller() {
    echo "Checking for Ingress Controller..."
    if kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik 2>/dev/null | grep -q "Running"; then
        echo -e "${GREEN}✓ Traefik Ingress Controller found${NC}"
        USE_INGRESS=true
        return
    fi
     if kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx 2>/dev/null | grep -q "Running"; then
        echo -e "${GREEN}✓ NGINX Ingress Controller found${NC}"
        USE_INGRESS=true
        return
    fi
    echo "No common Ingress Controller found (Traefik/NGINX). using LoadBalancer."
}
check_ingress_controller

# Apply deployment
echo "Deploying controller..."
kubectl apply -f https://raw.githubusercontent.com/Taiwrash/kgh/main/deployments/kubernetes/deployment.yaml -n "$NAMESPACE"

if [ "$USE_INGRESS" = true ]; then
    echo "Deploying Service (ClusterIP) and Ingress..."
    # Download service, patch to ClusterIP and apply
    curl -fsSL https://raw.githubusercontent.com/Taiwrash/kgh/main/deployments/kubernetes/service.yaml | \
    sed 's/type: LoadBalancer/type: ClusterIP/' | \
    kubectl apply -f - -n "$NAMESPACE"
    
    # Apply Ingress
    kubectl apply -f https://raw.githubusercontent.com/Taiwrash/kgh/main/deployments/kubernetes/ingress.yaml -n "$NAMESPACE"
else
    echo "Deploying Service (LoadBalancer)..."
    kubectl apply -f https://raw.githubusercontent.com/Taiwrash/kgh/main/deployments/kubernetes/service.yaml -n "$NAMESPACE"
fi

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

# Cloudflare Tunnel Setup
install_cloudflared() {
    echo ""
    echo -e "${YELLOW}Checking Cloudflare Tunnel (cloudflared)...${NC}"
    
    if command -v cloudflared &> /dev/null; then
        echo -e "${GREEN}✓ cloudflared is already installed${NC}"
        return
    fi
    
    echo "Installing cloudflared..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install cloudflare/cloudflare/cloudflared
        else
             echo -e "${YELLOW}! Homebrew not found. skipping cloudflared installation.${NC}"
             return
        fi
    else
        # Detect architecture
        ARCH=$(uname -m)
        case $ARCH in
            x86_64) DEB_ARCH="amd64" ;;
            aarch64) DEB_ARCH="arm64" ;;
            armv7l) DEB_ARCH="armhf" ;;
            i386|i686) DEB_ARCH="386" ;;
            *)
                echo -e "${YELLOW}! Architecture $ARCH not supported for auto-install.${NC}"
                return
                ;;
        esac

        if command -v dpkg &> /dev/null; then
            if [ "$EUID" -ne 0 ]; then
                echo -e "${YELLOW}! Root privileges required for .deb install. Skipping.${NC}"
                return
            fi
            curl -L --output cloudflared.deb "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${DEB_ARCH}.deb"
            dpkg -i cloudflared.deb
            rm cloudflared.deb
        elif command -v rpm &> /dev/null; then
             if [ "$EUID" -ne 0 ]; then
                echo -e "${YELLOW}! Root privileges required for .rpm install. Skipping.${NC}"
                return
            fi
             RPM_ARCH=$DEB_ARCH
             if [ "$DEB_ARCH" == "amd64" ]; then RPM_ARCH="x86_64"; fi
             if [ "$DEB_ARCH" == "arm64" ]; then RPM_ARCH="aarch64"; fi
             
             curl -L --output cloudflared.rpm "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${RPM_ARCH}.rpm"
             rpm -ivh cloudflared.rpm
             rm cloudflared.rpm
        else
             # Binary install
             curl -L --output cloudflared "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${DEB_ARCH}"
             chmod +x cloudflared
             if [ "$EUID" -eq 0 ]; then
                mv cloudflared /usr/local/bin/
             else
                echo -e "${YELLOW}! Root required to move binary. Leaving in current dir.${NC}"
             fi
        fi
    fi
}

# Attempt installation
install_cloudflared

echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo "1. Configure GitHub webhook with the URL above"
echo "2. run 'cloudflared tunnel --url http://<SERVICE-IP>' to expose your service securely"

