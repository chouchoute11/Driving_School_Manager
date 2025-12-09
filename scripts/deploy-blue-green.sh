#!/bin/bash

##############################################################################
# Blue-Green Deployment Script
#
# This script implements blue-green deployment strategy:
#   - Deploys new version to green environment (zero traffic)
#   - Runs smoke tests on green environment
#   - Switches traffic from blue to green
#   - Maintains blue for instant rollback
#
# Usage: ./scripts/deploy-blue-green.sh <version> [namespace]
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
VERSION="${1:-1.0.1}"
NAMESPACE="${2:-driving-school-manager}"
DOCKER_IMAGE="docker.io/chouchoute11/practical_cat_driving_lesson_school_management:${VERSION}"
TIMEOUT=600
WAIT_TIME=5

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}ℹ️  INFO:${NC} $1"; }
log_success() { echo -e "${GREEN}✅ SUCCESS:${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠️  WARNING:${NC} $1"; }
log_error() { echo -e "${RED}❌ ERROR:${NC} $1"; }

# Check prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."
  
  if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found"
    exit 1
  fi
  
  if ! kubectl cluster-info &> /dev/null; then
    log_error "Not connected to Kubernetes cluster"
    exit 1
  fi
  
  if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    log_error "Namespace '$NAMESPACE' does not exist"
    exit 1
  fi
  
  log_success "Prerequisites check passed"
}

# Get current active environment
get_active_env() {
  local selector
  selector=$(kubectl get service "driving-school-manager-active" \
    -n "$NAMESPACE" \
    -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "blue")
  echo "$selector"
}

# Get inactive environment
get_inactive_env() {
  local active
  active=$(get_active_env)
  
  if [ "$active" = "blue" ]; then
    echo "green"
  else
    echo "blue"
  fi
}

# Update green deployment with new version
update_green_deployment() {
  local inactive
  inactive=$(get_inactive_env)
  
  log_info "Updating $inactive deployment to version: $VERSION"
  
  kubectl set image deployment/"driving-school-manager-${inactive}" \
    app="$DOCKER_IMAGE" \
    --namespace="$NAMESPACE" \
    --record || {
    log_error "Failed to update deployment"
    return 1
  }
  
  log_success "$inactive deployment image updated"
}

# Scale inactive deployment up
scale_up_deployment() {
  local inactive
  inactive=$(get_inactive_env)
  
  log_info "Scaling up $inactive deployment (3 replicas)..."
  
  kubectl scale deployment "driving-school-manager-${inactive}" \
    --replicas=3 \
    --namespace="$NAMESPACE" || {
    log_error "Failed to scale deployment"
    return 1
  }
  
  log_success "$inactive deployment scaled to 3 replicas"
}

# Wait for deployment to be ready
wait_for_ready() {
  local inactive
  inactive=$(get_inactive_env)
  
  log_info "Waiting for $inactive deployment to be ready..."
  
  if kubectl rollout status deployment/"driving-school-manager-${inactive}" \
    --namespace="$NAMESPACE" \
    --timeout="${TIMEOUT}s"; then
    log_success "$inactive deployment ready"
    return 0
  else
    log_error "$inactive deployment failed to become ready"
    return 1
  fi
}

# Smoke test on new deployment
smoke_test() {
  local inactive
  inactive=$(get_inactive_env)
  local service_name="driving-school-manager-${inactive}"
  
  log_info "Running smoke tests on $inactive environment..."
  log_info "Service: $service_name"
  
  # Port-forward to test service
  kubectl port-forward \
    "service/${service_name}" \
    8888:4000 \
    --namespace="$NAMESPACE" &
  
  local pf_pid=$!
  sleep 3
  
  # Run smoke tests
  local test_passed=true
  
  # Test health endpoint
  if ! curl -s -f http://localhost:8888/health &>/dev/null; then
    log_error "Health check failed"
    test_passed=false
  else
    log_success "Health check passed"
  fi
  
  # Test ready endpoint
  if ! curl -s -f http://localhost:8888/ready &>/dev/null; then
    log_error "Ready check failed"
    test_passed=false
  else
    log_success "Ready check passed"
  fi
  
  # Clean up port-forward
  kill $pf_pid 2>/dev/null || true
  
  if [ "$test_passed" = false ]; then
    log_error "Smoke tests failed"
    return 1
  fi
  
  log_success "Smoke tests passed"
  return 0
}

# Switch traffic to new deployment
switch_traffic() {
  local inactive
  inactive=$(get_inactive_env)
  
  log_info "Switching traffic to $inactive deployment..."
  
  kubectl patch service "driving-school-manager-active" \
    -n "$NAMESPACE" \
    -p '{"spec":{"selector":{"version":"'${inactive}'"}}}' || {
    log_error "Failed to switch traffic"
    return 1
  }
  
  log_success "Traffic switched to $inactive deployment"
  sleep 5
}

# Scale down old deployment
scale_down_old() {
  local active
  active=$(get_active_env)
  
  log_info "Scaling down old $active deployment..."
  
  kubectl scale deployment "driving-school-manager-${active}" \
    --replicas=0 \
    --namespace="$NAMESPACE" || {
    log_error "Failed to scale down old deployment"
    return 1
  }
  
  log_success "$active deployment scaled down"
}

# Rollback to previous version
rollback() {
  local active
  active=$(get_active_env)
  local inactive
  inactive=$(get_inactive_env)
  
  log_warn "Rolling back to $inactive..."
  
  # Switch traffic back
  kubectl patch service "driving-school-manager-active" \
    -n "$NAMESPACE" \
    -p '{"spec":{"selector":{"version":"'${inactive}'"}}}'
  
  log_success "Rollback completed - traffic switched back to $inactive"
}

# Display deployment summary
display_summary() {
  echo ""
  log_info "Deployment Summary:"
  echo ""
  
  local active
  active=$(get_active_env)
  
  echo "Active Environment: $active"
  echo ""
  
  kubectl get deployments \
    -n "$NAMESPACE" \
    -l app=driving-school-manager \
    -o wide
  
  echo ""
  
  kubectl get services \
    -n "$NAMESPACE" \
    -l app=driving-school-manager \
    -o wide
}

# Main deployment flow
main() {
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║         BLUE-GREEN DEPLOYMENT SCRIPT                       ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""
  
  log_info "Starting blue-green deployment"
  log_info "Namespace: $NAMESPACE"
  log_info "Version: $VERSION"
  log_info "Docker Image: $DOCKER_IMAGE"
  echo ""
  
  local active
  active=$(get_active_env)
  local inactive
  inactive=$(get_inactive_env)
  
  log_info "Current active: $active"
  log_info "Target inactive: $inactive"
  echo ""
  
  # Execute deployment steps
  check_prerequisites || exit 1
  update_green_deployment || exit 1
  scale_up_deployment || exit 1
  wait_for_ready || {
    log_error "New deployment not ready, aborting"
    exit 1
  }
  
  if smoke_test; then
    switch_traffic || {
      log_error "Failed to switch traffic, rolling back"
      rollback
      exit 1
    }
    scale_down_old || log_warn "Failed to scale down old deployment"
  else
    log_error "Smoke tests failed, keeping old version active"
    scale_down_old || true
    exit 1
  fi
  
  display_summary
  
  echo ""
  log_success "Blue-green deployment completed successfully!"
  log_info "Active environment: $inactive"
  log_info "To rollback, run: kubectl patch service driving-school-manager-active -n $NAMESPACE -p '{\"spec\":{\"selector\":{\"version\":\"'${active}'\"}}}'"
}

# Execute main
main "$@"
