# 🚀 Kubernetes Setup Guide - Local & Cloud Deployment

## Quick Overview

You have three options to run Kubernetes and deploy your Driving School Lesson Manager application. This guide covers all three with step-by-step instructions.

---

## Option 1: Docker Desktop (Easiest - Windows/macOS)

### Prerequisites
- Docker Desktop installed (version 3.0+)
- 4GB RAM available
- 2 CPU cores available

### Setup Steps

**Step 1: Enable Kubernetes in Docker Desktop**

1. Open Docker Desktop preferences/settings
2. Navigate to **Kubernetes** tab
3. Check **Enable Kubernetes**
4. Click **Apply & Restart** (will take 2-3 minutes)

**Step 2: Verify Installation**

```bash
# Check if kubectl is available
kubectl version --client

# Check cluster status
kubectl cluster-info

# View nodes
kubectl get nodes
```

**Step 3: Deploy Application**

```bash
# Navigate to project directory
cd ~/Documents/Driving_lesson_manager/Driving_lesson_manager

# Create namespace and configuration
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/rbac.yaml

# Deploy application
./scripts/deploy-rolling.sh 1.0.1

# Create services
kubectl apply -f k8s/service.yaml

# Verify deployment
kubectl get pods -n driving-school-manager
```

**Advantages:**
- ✅ Already installed with Docker Desktop
- ✅ Minimal setup
- ✅ Integrated with Docker
- ✅ Good for development

**Disadvantages:**
- ❌ Limited to single node
- ❌ Uses system resources
- ❌ Not ideal for multi-node testing

---

## Option 2: Minikube (Recommended for Development)

### Prerequisites
- Docker or Hypervisor installed
- 4GB RAM available
- 2+ CPU cores

### Installation

**macOS:**
```bash
# Install minikube
brew install minikube

# Install kubectl
brew install kubectl

# Start minikube
minikube start --cpus 4 --memory 4096 --driver docker
```

**Linux:**
```bash
# Install minikube
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Start minikube
minikube start --cpus 4 --memory 4096 --driver docker
```

**Windows (PowerShell as Administrator):**
```powershell
# Install minikube using Chocolatey
choco install minikube kubernetes-cli

# Or using direct download
$env:Path += ";C:\Program Files\Minikube"

# Start minikube
minikube start --cpus 4 --memory 4096 --driver hyperv
```

### Verification

```bash
# Check status
minikube status

# View cluster info
kubectl cluster-info

# List nodes
kubectl get nodes

# Access dashboard
minikube dashboard
```

### Deploy Application

```bash
# Create namespace and configuration
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/rbac.yaml

# Deploy application
./scripts/deploy-rolling.sh 1.0.1

# Create services
kubectl apply -f k8s/service.yaml

# Monitor deployment
kubectl get pods -n driving-school-manager -w

# View logs
kubectl logs -n driving-school-manager -l app=driving-school-manager -f
```

**Advantages:**
- ✅ Isolated cluster
- ✅ Easy to reset
- ✅ Dashboard included
- ✅ Good for testing
- ✅ Can simulate multi-node

**Disadvantages:**
- ❌ Slower than Docker Desktop
- ❌ More resource usage
- ❌ Single node by default

### Useful Minikube Commands

```bash
# Stop cluster (preserves data)
minikube stop

# Delete cluster (fresh start)
minikube delete

# Check CPU/memory usage
minikube stats

# SSH into cluster
minikube ssh

# View minikube logs
minikube logs

# Get IP address
minikube ip
```

---

## Option 3: Kind (Kubernetes in Docker)

### Prerequisites
- Docker installed
- 4GB RAM available
- Go 1.16+ (for development)

### Installation

**macOS/Linux:**
```bash
# Install kind
brew install kind

# Or using Go
go install sigs.k8s.io/kind@latest

# Install kubectl
brew install kubectl
```

**Windows (PowerShell):**
```powershell
# Using Chocolatey
choco install kind kubernetes-cli

# Or using direct download
curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/latest/kind-windows-amd64
Move-Item .\kind-windows-amd64.exe C:\ProgramFiles\kind.exe
```

### Create Cluster

```bash
# Create a simple cluster
kind create cluster --name driving-school

# Create multi-node cluster
kind create cluster --name driving-school --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF

# View clusters
kind get clusters

# Check cluster status
kubectl cluster-info --context kind-driving-school
```

### Deploy Application

```bash
# Create namespace and configuration
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/rbac.yaml

# Deploy application
./scripts/deploy-rolling.sh 1.0.1

# Create services
kubectl apply -f k8s/service.yaml

# Monitor
kubectl get pods -n driving-school-manager -w
```

**Advantages:**
- ✅ Multi-node capable
- ✅ Fast startup
- ✅ Easy cleanup
- ✅ Great for CI/CD

**Disadvantages:**
- ❌ Less feature-rich than Minikube
- ❌ No built-in dashboard
- ❌ Minimal GUI tools

### Useful Kind Commands

```bash
# Load Docker image into cluster
kind load docker-image <image-name> --name driving-school

# Get kubeconfig
kind get kubeconfig --name driving-school

# Delete cluster
kind delete cluster --name driving-school

# View cluster logs
kind export logs --name driving-school
```

---

## Cloud Deployment Options

### AWS EKS (Elastic Kubernetes Service)

```bash
# Install AWS CLI and eksctl
brew install awsctl eksctl

# Create cluster
eksctl create cluster --name driving-school --region us-east-1 --nodes 3

# Deploy application
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/rbac.yaml
./scripts/deploy-rolling.sh 1.0.1
kubectl apply -f k8s/service.yaml

# Clean up
eksctl delete cluster --name driving-school --region us-east-1
```

### Google GKE (Google Kubernetes Engine)

```bash
# Install Google Cloud SDK
brew install google-cloud-sdk

# Authenticate
gcloud auth login

# Create cluster
gcloud container clusters create driving-school \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type n1-standard-2

# Deploy application
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/rbac.yaml
./scripts/deploy-rolling.sh 1.0.1
kubectl apply -f k8s/service.yaml

# Clean up
gcloud container clusters delete driving-school --zone us-central1-a
```

### Azure AKS (Azure Kubernetes Service)

```bash
# Install Azure CLI
brew install azure-cli

# Authenticate
az login

# Create resource group
az group create --name driving-school --location eastus

# Create cluster
az aks create --resource-group driving-school \
  --name driving-school-aks \
  --node-count 3 \
  --vm-set-type VirtualMachineScaleSets

# Get credentials
az aks get-credentials --resource-group driving-school --name driving-school-aks

# Deploy application
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/rbac.yaml
./scripts/deploy-rolling.sh 1.0.1
kubectl apply -f k8s/service.yaml

# Clean up
az group delete --name driving-school
```

---

## Deployment Verification

Once your cluster is running, verify the deployment:

```bash
# Check if namespace was created
kubectl get namespace driving-school-manager

# Check if ConfigMaps were created
kubectl get configmap -n driving-school-manager

# Check pods
kubectl get pods -n driving-school-manager

# Check services
kubectl get services -n driving-school-manager

# View deployment details
kubectl describe deployment driving-school-manager -n driving-school-manager

# Check logs
kubectl logs -n driving-school-manager -l app=driving-school-manager --tail=50

# Test the service
kubectl port-forward -n driving-school-manager svc/driving-school-manager 4000:4000 &
curl http://localhost:4000/health
curl http://localhost:4000/ready
```

---

## Common Issues & Troubleshooting

### Issue: kubectl: command not found

**Solution:**
```bash
# Install kubectl
brew install kubectl
# or
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Issue: Unable to connect to the server

**Solution:**
```bash
# Check cluster status
kubectl cluster-info

# Reset kubectl context
kubectl config view
kubectl config use-context <context-name>

# For Minikube
minikube start

# For Docker Desktop
# Re-enable Kubernetes in settings
```

### Issue: Pods stuck in Pending state

**Solution:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n driving-school-manager

# Check node resources
kubectl top nodes
kubectl top pods -n driving-school-manager

# Check if images can be pulled
kubectl get events -n driving-school-manager
```

### Issue: Image pull errors

**Solution:**
```bash
# For local cluster (Minikube/Kind), load image directly
minikube image load <image-name>
# or
kind load docker-image <image-name>

# For Docker Desktop, image should be available automatically
```

### Issue: Service not accessible

**Solution:**
```bash
# Check service endpoints
kubectl get endpoints -n driving-school-manager

# Port forward to test
kubectl port-forward -n driving-school-manager svc/driving-school-manager 4000:4000

# Test from another pod
kubectl run -it --rm debug --image=curlimages/curl -n driving-school-manager -- sh
curl http://driving-school-manager:4000/health
```

---

## Recommended Setup for Development

### Best Choice: **Minikube**

Why Minikube is recommended:
1. ✅ Excellent for development and testing
2. ✅ Includes dashboard
3. ✅ Easy to reset and clean up
4. ✅ Good performance
5. ✅ Works on all platforms
6. ✅ Great documentation

### Setup Steps (Summary)

```bash
# 1. Install
brew install minikube kubectl

# 2. Start cluster
minikube start --cpus 4 --memory 4096

# 3. Deploy
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/rbac.yaml
./scripts/deploy-rolling.sh 1.0.1
kubectl apply -f k8s/service.yaml

# 4. Monitor
kubectl get pods -n driving-school-manager -w

# 5. Access dashboard
minikube dashboard
```

---

## Next Steps After Deployment

### 1. Monitor Deployment
```bash
kubectl get pods -n driving-school-manager -w
kubectl logs -n driving-school-manager -l app=driving-school-manager -f
```

### 2. Test Application
```bash
kubectl port-forward -n driving-school-manager svc/driving-school-manager 4000:4000 &
curl http://localhost:4000/health
curl http://localhost:4000/ready
```

### 3. Scale Application
```bash
kubectl scale deployment driving-school-manager --replicas=5 -n driving-school-manager
```

### 4. Update Application
```bash
./scripts/deploy-rolling.sh 1.0.2
```

### 5. Blue-Green Deployment
```bash
kubectl apply -f k8s/blue-green-deployment.yaml
./scripts/deploy-blue-green.sh 1.0.2
```

---

## Cleanup

### For Minikube
```bash
# Stop cluster
minikube stop

# Delete cluster
minikube delete
```

### For Kind
```bash
kind delete cluster --name driving-school
```

### For Docker Desktop
```bash
# Disable Kubernetes in settings
# Or just leave running for next session
```

### For Cloud (AWS/GCP/Azure)
```bash
# AWS
eksctl delete cluster --name driving-school

# GCP
gcloud container clusters delete driving-school

# Azure
az group delete --name driving-school
```

---

## Reference: kubectl Common Commands

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes
kubectl get namespaces

# Deployment management
kubectl apply -f <file.yaml>
kubectl delete -f <file.yaml>
kubectl get deployments -n <namespace>
kubectl describe deployment <name> -n <namespace>

# Pod management
kubectl get pods -n <namespace>
kubectl describe pod <name> -n <namespace>
kubectl logs <name> -n <namespace>
kubectl exec -it <name> -n <namespace> -- /bin/sh

# Services
kubectl get services -n <namespace>
kubectl port-forward svc/<service> <local-port>:<remote-port> -n <namespace>

# Troubleshooting
kubectl get events -n <namespace>
kubectl top pods -n <namespace>
kubectl top nodes
```

---

## Support Resources

- **Minikube**: https://minikube.sigs.k8s.io/docs/
- **Kind**: https://kind.sigs.k8s.io/docs/
- **Kubernetes**: https://kubernetes.io/docs/
- **kubectl**: https://kubernetes.io/docs/reference/kubectl/

---

**Next Step**: Choose your deployment option and run the setup commands above!

For more information about deploying to production, see `PHASE6_KUBERNETES_GUIDE.md`.
