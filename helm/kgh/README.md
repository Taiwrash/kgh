# Helm Chart README

## GitOps Controller Helm Chart

This Helm chart deploys the GitOps Controller to your Kubernetes cluster.

## Quick Start

```bash
# Generate webhook secret
WEBHOOK_SECRET=$(openssl rand -hex 32)

# Install the chart
helm install gitops-controller . \
  --set github.webhookSecret="$WEBHOOK_SECRET"
```

See [HOMELAB_INSTALL.md](../../HOMELAB_INSTALL.md) for detailed installation guide.
