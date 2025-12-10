# 🚀 Kubernetes Setup Guide - Driving School Manager

## Quick Start (Recommended)

The easiest way to set up Kubernetes for your project is to run the automated setup script:

```bash
./scripts/setup-minikube.sh 1.0.1
```

This script will:
1. ✅ Check prerequisites (Docker, kubectl)
2. ✅ Install/update Minikube
3. ✅ Start the Minikube cluster
4. ✅ Build your Docker image
5. ✅ Deploy all Kubernetes manifests
6. ✅ Verify the deployment
7. ✅ Provide access instructions

**Time: ~5-10 minutes**

---

## Prerequisites

Before running the setup, ensure you have:

### 1. Docker Desktop
- **macOS/Windows**: [Download Docker Desktop](https://www.docker.com/products/docker-desktop)
- **Linux**: 
  ```bash
  sudo apt update && sudo apt install docker.io
  sudo usermod -aG docker $USER
  newgrp docker
  ```

### 2. kubectl
```bash
# macOS
brew install kubectl

# Linux
sudo apt install kubectl

# Windows (if not using Docker Desktop)
choco install kubernetes-cli
```

### 3. Verify Installation
```bash
docker --version      # Should be 20.10+
kubectl version       # Should be 1.20+
```

---

## Setup Options

### Option 1: Automated Setup (Recommended ⭐)

```bash
# Run the automated setup script
./scripts/setup-minikube.sh 1.0.1

# Or specify different version
./scripts/setup-minikube.sh 1.0.2
```

The script handles everything:
- Checks prerequisites
- Installs Minikube
- Starts cluster
- Builds Docker image
- Deploys all manifests
- Verifies deployment
- Provides access instructions

### Option 2: Manual Setup

If you prefer to set things up step-by-step, follow these commands:

#### 2.1 Install Minikube

**macOS:**
```bash
brew install minikube
```

**Linux:**
```bash
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-x86_64
sudo install minikube-linux-x86_64 /usr/local/bin/minikube
rm minikube-linux-x86_64
```

**Windows (PowerShell):**
```powershell
choco install minikube
```

#### 2.2 Start Minikube

```bash
minikube start \
  --cpus=4 \
  --memory=4096 \
  --driver=docker
```

**Wait for cluster to start.** First start takes 2-3 minutes.

#### 2.3 Configure Docker

```bash
# Use Minikube's Docker daemon
eval $(minikube docker-env)

# Verify
docker ps  # Should work without sudo
```

#### 2.4 Build Docker Image

```bash
docker build -t driving-school-manager:1.0.1 .
```

#### 2.5 Deploy Kubernetes Manifests

```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy ConfigMap
kubectl apply -f k8s/configmap.yaml

# Deploy RBAC & Security
kubectl apply -f k8s/rbac.yaml

# Deploy application
kubectl apply -f k8s/deployment.yaml

# Wait for deployment
kubectl rollout status deployment/driving-school-manager -n driving-school-manager

# Deploy service
kubectl apply -f k8s/service.yaml
```

#### 2.6 Verify Deployment

```bash
kubectl get pods -n driving-school-manager
kubectl get svc -n driving-school-manager
kubectl describe pod <pod-name> -n driving-school-manager
```

---

## Accessing Your Application

### Method 1: Port Forward (Best for Development)

```bash
kubectl port-forward -n driving-school-manager svc/driving-school-manager 4000:4000
```

Then visit: **http://localhost:4000**

Keep the port-forward running while you develop. Open another terminal for other commands.

### Method 2: Minikube Service

```bash
minikube service driving-school-manager -n driving-school-manager
```

This opens your browser automatically to the service.

### Method 3: Get Minikube IP

```bash
minikube ip
# Visit: http://<ip>:4000 (requires NodePort service)
```

---

## Useful kubectl Commands

### Pod Management

```bash
# List all pods
kubectl get pods -n driving-school-manager

# Get detailed pod info
kubectl describe pod <pod-name> -n driving-school-manager

# View pod logs
kubectl logs -n driving-school-manager -l app=driving-school-manager

# Follow logs in real-time
kubectl logs -n driving-school-manager <pod-name> -f

# Execute command in pod
kubectl exec -it <pod-name> -n driving-school-manager -- /bin/sh

# Get pod IP
kubectl get pod <pod-name> -n driving-school-manager -o jsonpath='{.status.podIP}'
```

### Deployment Management

```bash
# Check deployment status
kubectl rollout status deployment/driving-school-manager -n driving-school-manager

# See rollout history
kubectl rollout history deployment/driving-school-manager -n driving-school-manager

# Restart deployment
kubectl rollout restart deployment/driving-school-manager -n driving-school-manager

# Scale deployment
kubectl scale deployment/driving-school-manager --replicas=5 -n driving-school-manager

# View deployment details
kubectl describe deployment/driving-school-manager -n driving-school-manager
```

### Service & Network

```bash
# List services
kubectl get svc -n driving-school-manager

# Get service endpoints
kubectl get endpoints -n driving-school-manager

# Describe service
kubectl describe svc driving-school-manager -n driving-school-manager

# Port forward
kubectl port-forward svc/driving-school-manager 4000:4000 -n driving-school-manager
```

### Monitoring & Debugging

```bash
# Get events in namespace
kubectl get events -n driving-school-manager

# Check resource usage
kubectl top pods -n driving-school-manager
kubectl top nodes

# Get all resources
kubectl get all -n driving-school-manager

# View HPA status
kubectl get hpa -n driving-school-manager

# Check node status
kubectl get nodes

# Get node details
kubectl describe node <node-name>
```

### ConfigMap & RBAC

```bash
# View ConfigMap
kubectl get configmap -n driving-school-manager
kubectl describe configmap app-config -n driving-school-manager

# View service account
kubectl get serviceaccount -n driving-school-manager

# View role bindings
kubectl get rolebinding -n driving-school-manager
```

---

## Minikube Dashboard

Open the Kubernetes dashboard:

```bash
minikube dashboard
```

The dashboard opens in your browser and shows:
- Pods, deployments, services
- Real-time logs
- Resource usage
- Event logs
- Easy namespace switching

---

## Testing the Deployment

### 1. Port Forward to Local Port

```bash
kubectl port-forward -n driving-school-manager svc/driving-school-manager 4000:4000
```

### 2. Test Endpoints

In another terminal:

```bash
# Health check
curl http://localhost:4000/health

# Ready check
curl http://localhost:4000/ready

# Get metrics
curl http://localhost:4000/metrics

# Make a request (example)
curl http://localhost:4000/
```

### 3. View Logs

```bash
# View logs from all pods
kubectl logs -n driving-school-manager -l app=driving-school-manager --all-containers=true

# Follow logs from specific pod
kubectl logs -n driving-school-manager <pod-name> -f
```

---

## Scaling Your Application

### Manual Scaling

```bash
# Scale to 5 replicas
kubectl scale deployment/driving-school-manager --replicas=5 -n driving-school-manager

# Scale back to 3
kubectl scale deployment/driving-school-manager --replicas=3 -n driving-school-manager

# View current replicas
kubectl get deployment/driving-school-manager -n driving-school-manager
```

### Auto-scaling (HPA)

The deployment already includes HPA configuration. Check its status:

```bash
# View HPA status
kubectl get hpa -n driving-school-manager

# Watch HPA
kubectl get hpa -n driving-school-manager -w

# Describe HPA
kubectl describe hpa driving-school-manager -n driving-school-manager
```

The HPA will automatically scale between 2-10 replicas based on:
- CPU usage (target: 70%)
- Memory usage (target: 80%)

---

## Deployment Strategies

Your project includes two deployment strategies:

### Strategy 1: Rolling Update (Default)

Gradually replaces pods with new version:

```bash
# Check deployment strategy
kubectl get deployment/driving-school-manager -n driving-school-manager -o yaml | grep -A 5 "strategy:"

# Update image (triggers rolling update)
kubectl set image deployment/driving-school-manager \
  driving-school-manager=driving-school-manager:1.0.2 \
  -n driving-school-manager

# Monitor rollout
kubectl rollout status deployment/driving-school-manager -n driving-school-manager -w

# Rollback if needed
kubectl rollout undo deployment/driving-school-manager -n driving-school-manager
```

**Features:**
- No downtime
- Gradual pod replacement
- Automatic rollback on failure
- Takes 2-5 minutes for full deployment

### Strategy 2: Blue-Green Deployment

Deploy new version alongside current, switch instantly:

```bash
# Deploy blue-green configuration
kubectl apply -f k8s/blue-green-deployment.yaml

# Run deployment script
./scripts/deploy-blue-green.sh 1.0.2

# Instant rollback
kubectl patch service driving-school-manager \
  -p '{"spec":{"selector":{"version":"blue"}}}' \
  -n driving-school-manager
```

**Features:**
- Instant traffic switching
- Instant rollback
- Full smoke testing before switch
- Zero downtime

---

## Troubleshooting

### Problem: Minikube won't start

```bash
# Try deleting and recreating cluster
minikube delete
minikube start --cpus=4 --memory=4096 --driver=docker

# Check Docker is running
docker ps
```

### Problem: Pods stuck in Pending

```bash
# Check what's preventing pod scheduling
kubectl describe pod <pod-name> -n driving-school-manager

# Check node resources
kubectl top nodes
kubectl describe node <node-name>

# Check events
kubectl get events -n driving-school-manager --sort-by='.lastTimestamp'
```

### Problem: ImagePullBackOff error

```bash
# The image must be in Minikube's Docker daemon
# Configure kubectl to use Minikube Docker
eval $(minikube docker-env)

# Rebuild image
docker build -t driving-school-manager:1.0.1 .

# Set imagePullPolicy to Never
kubectl set env deployment/driving-school-manager \
  DOCKER_CONFIG='' \
  -n driving-school-manager
```

### Problem: kubectl: command not found

```bash
# Install kubectl
brew install kubectl  # macOS
sudo apt install kubectl  # Linux
choco install kubernetes-cli  # Windows

# Verify
kubectl version --client
```

### Problem: Unable to connect to server

```bash
# Check Minikube status
minikube status

# Start Minikube if stopped
minikube start

# Check kubectl config
kubectl config view
kubectl config current-context

# Reset config if needed
kubectl config use-context minikube
```

### Problem: Port 4000 already in use

```bash
# Use a different local port
kubectl port-forward -n driving-school-manager svc/driving-school-manager 5000:4000

# Visit http://localhost:5000
```

### Problem: Pods restart continuously

```bash
# Check pod logs
kubectl logs -n driving-school-manager <pod-name> --previous

# Check health checks
kubectl get pod <pod-name> -n driving-school-manager -o yaml | grep -A 5 "livenessProbe"

# Check resource requests
kubectl describe pod <pod-name> -n driving-school-manager
```

---

## Advanced Topics

### View Kubernetes Manifest

```bash
# See all deployed resources
kubectl get all -n driving-school-manager

# View deployment YAML
kubectl get deployment/driving-school-manager -n driving-school-manager -o yaml

# View service YAML
kubectl get svc driving-school-manager -n driving-school-manager -o yaml
```

### Resource Limits

The deployment specifies resource requests and limits:

```bash
# View resource settings
kubectl describe deployment/driving-school-manager -n driving-school-manager | grep -A 10 "Limits"

# Edit resource limits (opens editor)
kubectl edit deployment/driving-school-manager -n driving-school-manager
```

Current limits:
- **Requests**: 100m CPU, 128Mi memory
- **Limits**: 500m CPU, 512Mi memory

### Health Checks

The deployment includes three health checks:

```bash
# View health checks
kubectl get pod <pod-name> -n driving-school-manager -o yaml | grep -A 5 "Probe"
```

1. **Startup Probe**: Allows 30 failures (5 minutes)
2. **Liveness Probe**: Checks every 10 seconds
3. **Readiness Probe**: Checks every 5 seconds

---

## Cleanup & Uninstall

### Delete Kubernetes Resources

```bash
# Delete namespace (deletes all resources in it)
kubectl delete namespace driving-school-manager

# Or delete individual resources
kubectl delete -f k8s/deployment.yaml -n driving-school-manager
kubectl delete -f k8s/service.yaml -n driving-school-manager
kubectl delete -f k8s/configmap.yaml -n driving-school-manager
kubectl delete -f k8s/rbac.yaml -n driving-school-manager
kubectl delete -f k8s/namespace.yaml
```

### Stop Minikube

```bash
# Stop cluster (can be restarted)
minikube stop

# Delete cluster (permanent)
minikube delete
```

### Uninstall Minikube

```bash
# macOS
brew uninstall minikube

# Linux
sudo rm /usr/local/bin/minikube

# Windows
choco uninstall minikube
```

---

## Next Steps

1. ✅ Run the setup script: `./scripts/setup-minikube.sh 1.0.1`
2. ✅ Access the application: `kubectl port-forward -n driving-school-manager svc/driving-school-manager 4000:4000`
3. ✅ Visit: http://localhost:4000
4. ✅ View logs: `kubectl logs -n driving-school-manager -l app=driving-school-manager -f`
5. ✅ Open dashboard: `minikube dashboard`

---

## Reference Documents

- **KUBERNETES_SETUP_GUIDE.md** - Comprehensive guide with all options
- **PHASE6_KUBERNETES_GUIDE.md** - Detailed Kubernetes architecture
- **PHASE6_DEPLOY_QUICKSTART.md** - 5-minute quick start
- **PHASE6_RESOURCE_REQUIREMENTS.md** - Resource planning and limits

---

## Support

If you encounter issues:

1. Check the Troubleshooting section above
2. Read the detailed guides in the reference documents
3. Check pod logs: `kubectl logs <pod-name> -n driving-school-manager`
4. Check events: `kubectl get events -n driving-school-manager`
5. Open Minikube dashboard: `minikube dashboard`

Happy deploying! 🚗✨
