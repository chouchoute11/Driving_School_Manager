#!/bin/bash

################################################################################
# Kubernetes Deployment Script
# Deploy the Driving School application to Kubernetes cluster
# Supports rolling updates, blue-green deployment, and health monitoring
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="driving-school"
APP_NAME="driving-school-app"
DOCKER_IMAGE="chouchoute11/practical_cat_driving_lesson_school_management:1.0.1"
DEPLOYMENT_TIMEOUT=600
HEALTH_CHECK_INTERVAL=10

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is installed
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    log_success "kubectl found: $(kubectl version --client --short)"
}

# Check cluster connectivity
check_cluster_connection() {
    log_info "Checking Kubernetes cluster connection..."
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    CLUSTER_INFO=$(kubectl cluster-info | head -1)
    log_success "Connected to cluster: $CLUSTER_INFO"
}

# Create namespace if it doesn't exist
create_namespace() {
    log_info "Creating namespace '$NAMESPACE' if it doesn't exist..."
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_warning "Namespace '$NAMESPACE' already exists"
    else
        kubectl create namespace "$NAMESPACE"
        log_success "Namespace '$NAMESPACE' created"
    fi
}

# Apply Kubernetes manifests
apply_manifests() {
    log_info "Applying Kubernetes manifests..."
    
    local manifests=(
        "k8s/namespace.yaml"
        "k8s/configmap.yaml"
        "k8s/rbac.yaml"
        "k8s/deployment.yaml"
        "k8s/service.yaml"
    )
    
    for manifest in "${manifests[@]}"; do
        if [ ! -f "$manifest" ]; then
            log_error "Manifest not found: $manifest"
            exit 1
        fi
        
        log_info "Applying $manifest..."
        kubectl apply -f "$manifest"
    done
    
    log_success "All manifests applied successfully"
}

# Wait for deployment to be ready
wait_for_deployment() {
    local deployment=$1
    local timeout=${2:-$DEPLOYMENT_TIMEOUT}
    
    log_info "Waiting for deployment '$deployment' to be ready (timeout: ${timeout}s)..."
    
    if kubectl rollout status deployment/"$deployment" \
        -n "$NAMESPACE" \
        --timeout="${timeout}s"; then
        log_success "Deployment '$deployment' is ready"
    else
        log_error "Deployment '$deployment' failed to reach ready state"
        return 1
    fi
}

# Get deployment status
get_deployment_status() {
    log_info "Deployment Status:"
    kubectl get deployment "$APP_NAME" -n "$NAMESPACE" -o wide
    
    log_info "Pod Status:"
    kubectl get pods -n "$NAMESPACE" -l app="$APP_NAME" -o wide
    
    log_info "Service Status:"
    kubectl get svc -n "$NAMESPACE" -o wide
}

# Check health of all pods
check_pod_health() {
    log_info "Checking pod health..."
    
    local pods=$(kubectl get pods -n "$NAMESPACE" -l app="$APP_NAME" -q)
    local healthy=0
    local total=0
    
    for pod in $pods; do
        ((total++))
        local status=$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
        
        if [ "$status" = "Running" ]; then
            ((healthy++))
            log_success "Pod $pod: Running"
        else
            log_warning "Pod $pod: $status"
        fi
    done
    
    log_info "Healthy pods: $healthy/$total"
    
    if [ "$healthy" -lt 1 ]; then
        log_error "No healthy pods found"
        return 1
    fi
}

# Perform rolling update
perform_rolling_update() {
    local new_image=$1
    
    log_info "Performing rolling update with image: $new_image"
    
    kubectl set image deployment/"$APP_NAME" \
        driving-school="$new_image" \
        -n "$NAMESPACE"
    
    log_info "Rolling update initiated, waiting for completion..."
    wait_for_deployment "$APP_NAME"
    
    log_success "Rolling update completed successfully"
}

# Rollback deployment
rollback_deployment() {
    log_warning "Rolling back deployment '$APP_NAME'..."
    
    kubectl rollout undo deployment/"$APP_NAME" -n "$NAMESPACE"
    
    wait_for_deployment "$APP_NAME"
    log_success "Rollback completed successfully"
}

# Get pod logs
get_pod_logs() {
    local pod=$1
    local lines=${2:-100}
    
    log_info "Getting logs from pod '$pod' (last $lines lines)..."
    kubectl logs "$pod" -n "$NAMESPACE" --tail="$lines"
}

# Scale deployment
scale_deployment() {
    local replicas=$1
    
    log_info "Scaling deployment '$APP_NAME' to $replicas replicas..."
    
    kubectl scale deployment "$APP_NAME" \
        --replicas="$replicas" \
        -n "$NAMESPACE"
    
    log_success "Deployment scaled to $replicas replicas"
}

# Perform blue-green deployment
perform_blue_green_deployment() {
    local new_image=$1
    
    log_info "Performing blue-green deployment..."
    log_warning "This strategy requires manual traffic switch. Green deployment will be created with 0 replicas"
    
    # Create or update green deployment
    log_info "Preparing green deployment..."
    kubectl scale deployment driving-school-app-blue --replicas=3 -n "$NAMESPACE"
    
    # Update image for green deployment
    kubectl set image deployment/driving-school-app-blue \
        driving-school="$new_image" \
        -n "$NAMESPACE"
    
    # Wait for green deployment to be ready
    wait_for_deployment "driving-school-app-blue"
    
    log_success "Green deployment ready. To complete switch, update service selector to 'deployment-variant: blue'"
    log_info "Run: kubectl patch service driving-school-service -n driving-school -p '{\"spec\":{\"selector\":{\"deployment-variant\":\"blue\"}}}'"
}

# Delete deployment
delete_deployment() {
    log_warning "This will delete the entire deployment"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        kubectl delete namespace "$NAMESPACE"
        log_success "Deployment deleted"
    else
        log_info "Deletion cancelled"
    fi
}

# Get resource usage
get_resource_usage() {
    log_info "Resource usage for deployment:"
    kubectl top nodes 2>/dev/null || log_warning "Metrics server not installed. Run: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
    
    log_info "Pod resource usage:"
    kubectl top pods -n "$NAMESPACE" 2>/dev/null || log_warning "Cannot get pod metrics"
}

# Get events
get_events() {
    log_info "Recent events in namespace '$NAMESPACE':"
    kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp'
}

################################################################################
# Main Menu
################################################################################

show_usage() {
    cat << EOF
${BLUE}Kubernetes Deployment Manager${NC}

${GREEN}Usage:${NC}
  $0 <command> [options]

${GREEN}Commands:${NC}
  deploy              Deploy application to Kubernetes
  update <image>      Perform rolling update with new image
  rollback            Rollback to previous deployment version
  scale <replicas>    Scale deployment to specified number of replicas
  blue-green <image>  Perform blue-green deployment
  status              Get deployment status
  logs <pod>          Get logs from a pod
  health              Check health of all pods
  resources           Get resource usage
  events              Get recent events
  delete              Delete entire deployment
  help                Show this help message

${GREEN}Examples:${NC}
  $0 deploy
  $0 update docker.io/user/image:v1.0.2
  $0 rollback
  $0 scale 5
  $0 blue-green docker.io/user/image:v1.1.0
  $0 logs driving-school-app-xyz123
  $0 status

EOF
}

################################################################################
# Main Script
################################################################################

main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    local command=$1
    shift || true
    
    # Perform common checks
    check_kubectl
    check_cluster_connection
    
    case "$command" in
        deploy)
            create_namespace
            apply_manifests
            wait_for_deployment "$APP_NAME"
            get_deployment_status
            check_pod_health
            get_events
            ;;
        
        update)
            if [ $# -eq 0 ]; then
                log_error "Image URL required for update command"
                echo "Usage: $0 update <image>"
                exit 1
            fi
            perform_rolling_update "$1"
            get_deployment_status
            ;;
        
        rollback)
            rollback_deployment
            get_deployment_status
            ;;
        
        scale)
            if [ $# -eq 0 ]; then
                log_error "Number of replicas required for scale command"
                echo "Usage: $0 scale <replicas>"
                exit 1
            fi
            scale_deployment "$1"
            wait_for_deployment "$APP_NAME" 300
            get_deployment_status
            ;;
        
        blue-green)
            if [ $# -eq 0 ]; then
                log_error "Image URL required for blue-green deployment"
                echo "Usage: $0 blue-green <image>"
                exit 1
            fi
            perform_blue_green_deployment "$1"
            ;;
        
        status)
            get_deployment_status
            ;;
        
        logs)
            if [ $# -eq 0 ]; then
                log_error "Pod name required for logs command"
                echo "Usage: $0 logs <pod-name>"
                exit 1
            fi
            get_pod_logs "$1" "${2:-100}"
            ;;
        
        health)
            check_pod_health
            ;;
        
        resources)
            get_resource_usage
            ;;
        
        events)
            get_events
            ;;
        
        delete)
            delete_deployment
            ;;
        
        help|--help|-h)
            show_usage
            ;;
        
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
