# GitOps Kubernetes Controller

A lightweight GitOps controller for Kubernetes that automatically applies changes from your Git repository to your homelab cluster. Edit YAML files, commit to Git, and watch your cluster update automatically!

## 🚀 Features

- **Universal Resource Support**: Deploy any Kubernetes resource type (Deployments, Services, ConfigMaps, Secrets, StatefulSets, DaemonSets, Jobs, CronJobs, Ingress, PVCs, and more)
- **GitHub Integration**: Webhook-driven updates triggered by Git pushes
- **Smart Deployment**: Automatically creates or updates resources based on current cluster state
- **Multi-Document Support**: Process multiple YAML resources in a single file
- **In-Cluster & Local**: Auto-detects running environment (in-cluster vs local development)
- **Health Checks**: Built-in liveness and readiness probes
- **Graceful Shutdown**: Proper signal handling for clean shutdowns

## 📋 Prerequisites

- Kubernetes cluster (homelab, Minikube, Kind, K3s, etc.)
- Go 1.25+ (for building from source)
- GitHub repository for your manifests
- `kubectl` configured to access your cluster

## 🏗️ Architecture

```
┌─────────────┐
│   GitHub    │
│  Repository │
└──────┬──────┘
       │ Push Event
       │ (Webhook)
       ▼
┌─────────────────────┐
│ KGH - Kubernetes GitOps Homelab   │
│                     │
│ ┌─────────────────┐ │
│ │ Webhook Handler │ │
│ └────────┬────────┘ │
│          │          │
│ ┌────────▼────────┐ │
│ │ Resource Applier│ │
│ └────────┬────────┘ │
└──────────┼──────────┘
           │
           ▼
    ┌─────────────┐
    │ Kubernetes  │
    │   Cluster   │
    └─────────────┘
```

## 🛠️ Installation

### Option 1: Local Development Mode

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Taiwrash/k8s-gitops.git
   cd k8s-gitops
   ```

2. **Set up environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your values
   ```

3. **Generate a webhook secret**:
   ```bash
   openssl rand -hex 32
   ```

4. **Configure `.env`**:
   ```env
   GITHUB_TOKEN=ghp_your_token_here
   WEBHOOK_SECRET=your_generated_secret_here
   SERVER_PORT=8082
   NAMESPACE=default
   ```

5. **Build and run**:
   ```bash
   go build -o kgh ./cmd/kgh
   ./kgh
   ```

### Option 2: In-Cluster Deployment (Recommended for Production)

1. **Build Docker image**:
   ```bash
   docker build -t kgh:latest .
   ```

2. **Create Kubernetes secret**:
   ```bash
   # Copy the example secret
   cp deployments/kubernetes/secret.yaml.example deployments/kubernetes/secret.yaml
   
   # Edit with your actual values
   vim deployments/kubernetes/secret.yaml
   ```

3. **Deploy to Kubernetes**:
   ```bash
   # Apply RBAC permissions
   kubectl apply -f deployments/kubernetes/rbac.yaml
   
   # Apply secret
   kubectl apply -f deployments/kubernetes/secret.yaml
   
   # Deploy controller
   kubectl apply -f deployments/kubernetes/deployment.yaml
   
   # Expose via service
   kubectl apply -f deployments/kubernetes/service.yaml
   ```

4. **Get the external IP**:
   ```bash
   kubectl get svc kgh
   ```

## 🔧 GitHub Webhook Configuration

1. Go to your GitHub repository → **Settings** → **Webhooks** → **Add webhook**

2. Configure:
   - **Payload URL**: `http://your-controller-ip/webhook`
   - **Content type**: `application/json`
   - **Secret**: Your `WEBHOOK_SECRET` value
   - **Events**: Select "Just the push event"
   - **Active**: ✓ Checked

3. Click **Add webhook**

4. Test by pushing a YAML file to your repository!

## 📝 Usage

### Basic Workflow

1. **Create a Kubernetes manifest** in your Git repository:
   ```yaml
   # nginx-deployment.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx
     namespace: default
   spec:
     replicas: 3
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
           image: nginx:1.25-alpine
           ports:
           - containerPort: 80
   ```

2. **Commit and push**:
   ```bash
   git add nginx-deployment.yaml
   git commit -m "Deploy nginx"
   git push origin main
   ```

3. **Watch the magic happen**:
   ```bash
   kubectl get deployments -w
   ```

### Multi-Resource Files

You can include multiple resources in a single YAML file using `---` separator:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  environment: production
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  # ... deployment spec
---
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  # ... service spec
```

### Supported Resource Types

The controller supports **all Kubernetes resource types**, including:

- **Workloads**: Deployments, StatefulSets, DaemonSets, Jobs, CronJobs, Pods
- **Services**: Service, Ingress, NetworkPolicy
- **Config**: ConfigMap, Secret
- **Storage**: PersistentVolumeClaim, PersistentVolume, StorageClass
- **RBAC**: Role, RoleBinding, ClusterRole, ClusterRoleBinding, ServiceAccount
- **Custom Resources**: Any CRD installed in your cluster

## 🔍 Monitoring

### Health Checks

- **Liveness**: `http://controller:8082/health`
- **Readiness**: `http://controller:8082/ready`

### Logs

```bash
# View controller logs
kubectl logs -f deployment/kgh

# Follow logs in real-time
kubectl logs -f -l app=kgh
```

## 🔒 Security Best Practices

1. **Never commit secrets**: Use `.gitignore` to exclude `.env` and `secret.yaml` files
2. **Use Kubernetes Secrets**: Store sensitive data in Kubernetes secrets, not in Git
3. **Limit RBAC permissions**: Adjust `rbac.yaml` to grant only necessary permissions
4. **Use private repositories**: Keep your infrastructure manifests in private repos
5. **Rotate tokens**: Regularly rotate your GitHub PAT and webhook secrets

## 🐛 Troubleshooting

### Controller not receiving webhooks

1. Check webhook delivery in GitHub (Settings → Webhooks → Recent Deliveries)
2. Verify the service is accessible: `kubectl get svc kgh`
3. Check controller logs: `kubectl logs -f deployment/kgh`
4. Ensure webhook secret matches in both GitHub and Kubernetes secret

### Resources not applying

1. Check controller logs for errors
2. Verify RBAC permissions: `kubectl auth can-i create deployments --as=system:serviceaccount:default:kgh`
3. Validate YAML syntax: `kubectl apply --dry-run=client -f your-file.yaml`

### Permission denied errors

Update RBAC permissions in `deployments/kubernetes/rbac.yaml` to include the required resources.

## 📚 Examples

See the `deployments/examples/` directory for sample manifests:

- `deployment.yaml` - Example Nginx deployment
- `service.yaml` - Example service
- `configmap.yaml` - Example ConfigMap

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - feel free to use this in your homelab or production environments!

## 🙏 Acknowledgments

Built with:
- [client-go](https://github.com/kubernetes/client-go) - Kubernetes Go client
- [go-github](https://github.com/google/go-github) - GitHub API client
- [oauth2](https://golang.org/x/oauth2) - OAuth2 authentication

---

**Happy GitOps-ing! 🚀**
