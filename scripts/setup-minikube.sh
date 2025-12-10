#!/bin/bash

# =============================================================================
# Minikube Setup Script for Driving School Manager
# Purpose: Automatically setup, start, and deploy to local Kubernetes cluster
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MINIKUBE_MEMORY=${MINIKUBE_MEMORY:-4096}
MINIKUBE_CPUS=${MINIKUBE_CPUS:-4}
MINIKUBE_DRIVER=${MINIKUBE_DRIVER:-docker}
NAMESPACE="driving-school-manager"
APP_NAME="driving-school-manager"
IMAGE_TAG=${1:-1.0.1}

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}║        🚀 Driving School Manager - Kubernetes Setup           ║${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print info messages
print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# =============================================================================
# 1. Check Prerequisites
# =============================================================================
print_section "1️⃣  Checking Prerequisites"

check_command() {
    if command -v "$1" &> /dev/null; then
        VERSION=$($1 --version 2>&1 | head -n 1)
        print_success "$1 is installed: $VERSION"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

MISSING_DEPS=0

if ! check_command docker; then
    print_info "Install Docker from https://www.docker.com/products/docker-desktop"
    MISSING_DEPS=1
fi

if ! check_command kubectl; then
    print_info "kubectl not found. It will be installed with minikube or:"
    print_info "  brew install kubectl  (macOS)"
    print_info "  sudo apt install kubectl  (Linux)"
    MISSING_DEPS=1
fi

if [ $MISSING_DEPS -eq 1 ]; then
    print_error "Please install missing dependencies and run again"
    exit 1
fi

# =============================================================================
# 2. Install or Update Minikube
# =============================================================================
print_section "2️⃣  Setting Up Minikube"

if command -v minikube &> /dev/null; then
    CURRENT_VERSION=$(minikube version | grep -oP 'v\d+\.\d+\.\d+' | head -1)
    print_info "Minikube already installed: $CURRENT_VERSION"
    read -p "Do you want to update it? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Updating minikube..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew upgrade minikube
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-x86_64
            sudo install minikube-linux-x86_64 /usr/local/bin/minikube
            rm minikube-linux-x86_64
        fi
        print_success "Minikube updated"
    fi
else
    print_info "Installing Minikube..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install minikube
        else
            curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-darwin-amd64
            sudo install minikube-darwin-amd64 /usr/local/bin/minikube
            rm minikube-darwin-amd64
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-x86_64
        sudo install minikube-linux-x86_64 /usr/local/bin/minikube
        rm minikube-linux-x86_64
    fi
    print_success "Minikube installed"
fi

# =============================================================================
# 3. Start Minikube
# =============================================================================
print_section "3️⃣  Starting Minikube Cluster"

MINIKUBE_STATUS=$(minikube status --format='{{.Host}}' 2>&1 || echo "Stopped")

if [ "$MINIKUBE_STATUS" = "Running" ]; then
    print_info "Minikube is already running"
    read -p "Do you want to restart it? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Restarting Minikube..."
        minikube stop
        minikube start \
            --cpus=$MINIKUBE_CPUS \
            --memory=$MINIKUBE_MEMORY \
            --driver=$MINIKUBE_DRIVER
        print_success "Minikube restarted"
    fi
else
    print_info "Starting Minikube cluster..."
    print_info "Configuration: CPUs=$MINIKUBE_CPUS, Memory=${MINIKUBE_MEMORY}MB, Driver=$MINIKUBE_DRIVER"
    
    minikube start \
        --cpus=$MINIKUBE_CPUS \
        --memory=$MINIKUBE_MEMORY \
        --driver=$MINIKUBE_DRIVER
    
    print_success "Minikube cluster started"
fi

# =============================================================================
# 4. Verify Cluster Connection
# =============================================================================
print_section "4️⃣  Verifying Cluster Connection"

if kubectl cluster-info &> /dev/null; then
    CLUSTER_INFO=$(kubectl cluster-info | head -n 1)
    print_success "Connected to cluster: $CLUSTER_INFO"
else
    print_error "Unable to connect to Kubernetes cluster"
    exit 1
fi

# Show cluster info
kubectl cluster-info
echo

# Show nodes
print_info "Cluster nodes:"
kubectl get nodes
echo

# =============================================================================
# 5. Setup Container Registry (Minikube Docker)
# =============================================================================
print_section "5️⃣  Setting Up Container Registry"

print_info "Configuring docker to use Minikube's Docker daemon..."
eval $(minikube docker-env)
print_success "Docker configured to use Minikube"

# Build Docker image
print_info "Building Docker image: ${APP_NAME}:${IMAGE_TAG}..."
docker build -t ${APP_NAME}:${IMAGE_TAG} -t ${APP_NAME}:latest .

if [ $? -eq 0 ]; then
    print_success "Docker image built successfully"
    docker images | grep ${APP_NAME}
else
    print_error "Failed to build Docker image"
    exit 1
fi

# =============================================================================
# 6. Create Kubernetes Namespace
# =============================================================================
print_section "6️⃣  Creating Kubernetes Namespace"

if kubectl get namespace $NAMESPACE &> /dev/null; then
    print_info "Namespace '$NAMESPACE' already exists"
else
    print_info "Creating namespace '$NAMESPACE'..."
    kubectl apply -f k8s/namespace.yaml
    print_success "Namespace created"
fi

# =============================================================================
# 7. Deploy ConfigMap
# =============================================================================
print_section "7️⃣  Deploying ConfigMap"

print_info "Applying ConfigMap..."
kubectl apply -f k8s/configmap.yaml
print_success "ConfigMap deployed"

# =============================================================================
# 8. Deploy RBAC
# =============================================================================
print_section "8️⃣  Deploying RBAC and Security Configuration"

print_info "Applying RBAC, PDB, and Network Policies..."
kubectl apply -f k8s/rbac.yaml
print_success "RBAC configuration deployed"

# =============================================================================
# 9. Deploy Application
# =============================================================================
print_section "9️⃣  Deploying Application (Rolling Update)"

print_info "Applying deployment manifest..."
kubectl apply -f k8s/deployment.yaml

# Update image to the one we just built
print_info "Updating deployment with built image..."
kubectl set image deployment/${APP_NAME} \
    ${APP_NAME}=${APP_NAME}:${IMAGE_TAG} \
    -n $NAMESPACE \
    --record

# Wait for rollout
print_info "Waiting for deployment to be ready (timeout: 5 minutes)..."
if kubectl rollout status deployment/${APP_NAME} -n $NAMESPACE --timeout=5m; then
    print_success "Deployment rolled out successfully"
else
    print_error "Deployment rollout failed"
    print_info "Checking pod status..."
    kubectl describe pods -n $NAMESPACE
    exit 1
fi

# =============================================================================
# 10. Deploy Service and Ingress
# =============================================================================
print_section "🔟  Deploying Service and Ingress"

print_info "Applying service configuration..."
kubectl apply -f k8s/service.yaml
print_success "Service deployed"

# =============================================================================
# 11. Wait for Ready State
# =============================================================================
print_section "1️⃣1️⃣  Waiting for Pods to be Ready"

print_info "Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod -l app=${APP_NAME} -n $NAMESPACE --timeout=300s

print_success "All pods are ready"

# =============================================================================
# 12. Display Deployment Information
# =============================================================================
print_section "1️⃣2️⃣  Deployment Summary"

echo -e "\n${BLUE}Pods:${NC}"
kubectl get pods -n $NAMESPACE

echo -e "\n${BLUE}Deployments:${NC}"
kubectl get deployments -n $NAMESPACE

echo -e "\n${BLUE}Services:${NC}"
kubectl get svc -n $NAMESPACE

echo -e "\n${BLUE}ConfigMaps:${NC}"
kubectl get configmap -n $NAMESPACE

# =============================================================================
# 13. Show How to Access Application
# =============================================================================
print_section "1️⃣3️⃣  How to Access Your Application"

echo -e "${GREEN}The application is now deployed and running!${NC}\n"

echo -e "${YELLOW}Option 1: Port Forward (Recommended for local development)${NC}"
echo -e "  kubectl port-forward -n ${NAMESPACE} svc/${APP_NAME} 4000:4000"
echo -e "  Then visit: ${BLUE}http://localhost:4000${NC}\n"

echo -e "${YELLOW}Option 2: Using Minikube Service${NC}"
echo -e "  minikube service ${APP_NAME} -n ${NAMESPACE}"
echo -e "  This will open the service in your default browser\n"

echo -e "${YELLOW}Option 3: Get Service IP${NC}"
SERVICE_IP=$(kubectl get svc ${APP_NAME} -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "N/A")
echo -e "  Service IP: ${SERVICE_IP}\n"

# =============================================================================
# 14. Useful Commands
# =============================================================================
print_section "1️⃣4️⃣  Useful kubectl Commands"

cat << 'EOF'

📋 Basic Commands:
  # View all resources
  kubectl get all -n driving-school-manager
  
  # View detailed pod info
  kubectl describe pod <pod-name> -n driving-school-manager
  
  # View pod logs
  kubectl logs -n driving-school-manager -l app=driving-school-manager
  kubectl logs -n driving-school-manager <pod-name> --tail=100 -f
  
  # Execute command in pod
  kubectl exec -it <pod-name> -n driving-school-manager -- /bin/sh
  
  # Port forward to access locally
  kubectl port-forward -n driving-school-manager svc/driving-school-manager 4000:4000

🔄 Deployment Commands:
  # See rollout history
  kubectl rollout history deployment/driving-school-manager -n driving-school-manager
  
  # Check deployment status
  kubectl rollout status deployment/driving-school-manager -n driving-school-manager -w
  
  # Scale deployment
  kubectl scale deployment driving-school-manager --replicas=5 -n driving-school-manager
  
  # Restart deployment
  kubectl rollout restart deployment/driving-school-manager -n driving-school-manager

🔍 Debugging Commands:
  # Get events in namespace
  kubectl get events -n driving-school-manager
  
  # Check HPA status
  kubectl get hpa -n driving-school-manager -w
  
  # Check resource usage
  kubectl top pods -n driving-school-manager
  kubectl top nodes
  
  # View service endpoints
  kubectl get endpoints -n driving-school-manager

📊 Minikube Commands:
  # Open Minikube dashboard
  minikube dashboard
  
  # Check Minikube status
  minikube status
  
  # Stop Minikube
  minikube stop
  
  # Start Minikube
  minikube start
  
  # Delete Minikube cluster
  minikube delete

EOF

# =============================================================================
# 15. Health Check
# =============================================================================
print_section "1️⃣5️⃣  Health Check"

echo -e "${YELLOW}Starting port-forward in background...${NC}"
kubectl port-forward -n $NAMESPACE svc/$APP_NAME 4000:4000 > /dev/null 2>&1 &
PF_PID=$!
sleep 2

echo -e "${YELLOW}Testing application endpoints...${NC}"

# Test health endpoint
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/health 2>/dev/null || echo "000")
if [ "$HEALTH" = "200" ]; then
    print_success "Health endpoint: OK (HTTP $HEALTH)"
else
    print_info "Health endpoint: HTTP $HEALTH (connection might take a moment)"
fi

# Test ready endpoint
READY=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/ready 2>/dev/null || echo "000")
if [ "$READY" = "200" ]; then
    print_success "Ready endpoint: OK (HTTP $READY)"
else
    print_info "Ready endpoint: HTTP $READY"
fi

# Stop port-forward
kill $PF_PID 2>/dev/null || true

# =============================================================================
# Final Summary
# =============================================================================
print_section "✨ Setup Complete!"

cat << EOF

${GREEN}🎉 Your Driving School Manager is now running on Kubernetes!${NC}

Configuration:
  • Cluster: Minikube (Docker driver)
  • Namespace: ${NAMESPACE}
  • App Version: ${IMAGE_TAG}
  • Replicas: 3
  • Image Pull Policy: Never (using local Docker image)

Next Steps:
  1. Access the application:
     kubectl port-forward -n ${NAMESPACE} svc/${APP_NAME} 4000:4000
     Then visit http://localhost:4000

  2. View the Minikube dashboard:
     minikube dashboard

  3. Monitor logs:
     kubectl logs -n ${NAMESPACE} -l app=${APP_NAME} -f

  4. Test deployment:
     curl http://localhost:4000/health

${YELLOW}Documentation:${NC}
  • Read: KUBERNETES_SETUP_GUIDE.md
  • Read: PHASE6_KUBERNETES_GUIDE.md
  • Read: PHASE6_DEPLOY_QUICKSTART.md

Happy coding! 🚗

EOF

print_success "Setup completed successfully!"
