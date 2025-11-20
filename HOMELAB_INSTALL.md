# Homelab Installation Guide

This guide helps you deploy the GitOps controller to your multi-node Kubernetes homelab cluster.

## Installation Methods

### Method 1: Quick Install Script (Recommended)

The easiest way to install:

```bash
./install.sh
```

The script will:
- ✅ Check prerequisites (kubectl, helm)
- ✅ Prompt for configuration (GitHub repo, webhook secret)
- ✅ Auto-generate webhook secret if needed
- ✅ Install using Helm (if available) or kubectl
- ✅ Provide next steps with webhook URL

### Method 2: Helm Install

If you prefer manual Helm installation:

```bash
# Generate webhook secret
WEBHOOK_SECRET=$(openssl rand -hex 32)

# Install with Helm
helm install gitops-controller ./helm/gitops-controller \
  --namespace default \
  --set github.webhookSecret="$WEBHOOK_SECRET" \
  --set github.token="YOUR_GITHUB_TOKEN"

# Get webhook URL
kubectl get svc gitops-controller
```

### Method 3: kubectl Install

For manual kubectl installation:

```bash
# 1. Apply RBAC
kubectl apply -f deployments/kubernetes/rbac.yaml

# 2. Create secret
kubectl create secret generic gitops-controller-secret \
  --from-literal=github-token="YOUR_TOKEN" \
  --from-literal=webhook-secret="$(openssl rand -hex 32)"

# 3. Deploy controller
kubectl apply -f deployments/kubernetes/deployment.yaml
kubectl apply -f deployments/kubernetes/service.yaml
```

## Configuration Options

### Helm Values

Customize your installation by editing `helm/gitops-controller/values.yaml`:

```yaml
# Number of replicas (for HA)
replicaCount: 1

# Docker image
image:
  repository: gitops-controller
  tag: "latest"

# Service type (LoadBalancer, NodePort, ClusterIP)
service:
  type: LoadBalancer
  port: 80

# Resource limits
resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

# GitHub configuration
github:
  token: ""  # Optional for public repos
  webhookSecret: ""  # Required

# Target namespace for deployments
namespace: default
```

## Multi-Node Considerations

### High Availability

For multi-node clusters, you can run multiple replicas:

```bash
helm upgrade gitops-controller ./helm/gitops-controller \
  --set replicaCount=2
```

### Node Affinity

To ensure the controller runs on specific nodes:

```yaml
# Add to values.yaml
nodeSelector:
  node-role: control-plane

# Or use affinity
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
```

### Storage Considerations

The controller is stateless, so no persistent storage is needed.

## Network Configuration

### LoadBalancer

For homelab with MetalLB or similar:

```yaml
service:
  type: LoadBalancer
```

### NodePort

For clusters without LoadBalancer:

```yaml
service:
  type: NodePort
  nodePort: 30080  # Optional: specify port
```

Then access via: `http://<NODE-IP>:30080/webhook`

### Ingress

For production homelab with Ingress controller:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gitops-controller
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - gitops.yourdomain.com
    secretName: gitops-tls
  rules:
  - host: gitops.yourdomain.com
    http:
      paths:
      - path: /webhook
        pathType: Prefix
        backend:
          service:
            name: gitops-controller
            port:
              number: 80
```

## Post-Installation

### 1. Verify Installation

```bash
# Check deployment
kubectl get deployment gitops-controller

# Check pods
kubectl get pods -l app=gitops-controller

# View logs
kubectl logs -f deployment/gitops-controller
```

### 2. Get Webhook URL

```bash
# For LoadBalancer
kubectl get svc gitops-controller

# For NodePort
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
NODE_PORT=$(kubectl get svc gitops-controller -o jsonpath='{.spec.ports[0].nodePort}')
echo "Webhook URL: http://$NODE_IP:$NODE_PORT/webhook"
```

### 3. Configure GitHub Webhook

1. Go to your repository settings
2. Webhooks → Add webhook
3. Configure:
   - Payload URL: `http://YOUR-IP/webhook`
   - Content type: `application/json`
   - Secret: Your webhook secret
   - Events: Just the push event

### 4. Test Deployment

```bash
# Create a test deployment in your repo
cat > test-app.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
EOF

# Commit and push
git add test-app.yaml
git commit -m "Test GitOps deployment"
git push

# Watch it deploy
kubectl get deployments -w
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod -l app=gitops-controller

# Check logs
kubectl logs -l app=gitops-controller
```

### Webhook Not Working

```bash
# Check service
kubectl get svc gitops-controller

# Test health endpoint
curl http://<SERVICE-IP>/health

# Check GitHub webhook deliveries
# Go to repo → Settings → Webhooks → Recent Deliveries
```

### RBAC Issues

```bash
# Verify service account
kubectl get sa gitops-controller

# Check cluster role binding
kubectl get clusterrolebinding gitops-controller
```

## Upgrading

### Helm Upgrade

```bash
helm upgrade gitops-controller ./helm/gitops-controller \
  --reuse-values \
  --set image.tag=new-version
```

### kubectl Upgrade

```bash
# Update deployment
kubectl apply -f deployments/kubernetes/deployment.yaml

# Restart pods
kubectl rollout restart deployment/gitops-controller
```

## Uninstalling

### Helm Uninstall

```bash
helm uninstall gitops-controller
```

### kubectl Uninstall

```bash
kubectl delete -f deployments/kubernetes/
kubectl delete clusterrolebinding gitops-controller
kubectl delete clusterrole gitops-controller
```

## Advanced Configuration

### Custom Namespace

Deploy to a specific namespace:

```bash
helm install gitops-controller ./helm/gitops-controller \
  --namespace gitops-system \
  --create-namespace \
  --set namespace=default  # Target namespace for deployments
```

### Multiple Controllers

Run separate controllers for different namespaces:

```bash
# Controller for production
helm install gitops-prod ./helm/gitops-controller \
  --namespace gitops-system \
  --set namespace=production

# Controller for staging
helm install gitops-staging ./helm/gitops-controller \
  --namespace gitops-system \
  --set namespace=staging
```

## Security Best Practices

1. **Use Secrets**: Never commit tokens to Git
2. **Rotate Secrets**: Regularly rotate webhook secrets and tokens
3. **Network Policies**: Restrict controller network access
4. **RBAC**: Use least privilege principle
5. **TLS**: Use HTTPS with valid certificates for webhooks

## Support

For issues or questions:
- Check logs: `kubectl logs -f deployment/gitops-controller`
- Review GitHub webhook deliveries
- See main [README.md](../README.md) for more details
