#!/bin/bash

##############################################################################
# Rolling Update Deployment Script
# 
# This script deploys the application using the rolling update strategy.
# Features:
#   - Automatic health checks before proceeding
#   - Rollback capability if deployment fails
#   - Detailed logging of deployment progress
#   - Timeout protection
#
# Usage: ./scripts/deploy-rolling.sh <version> [namespace]
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
VERSION="${1:-1.0.1}"
NAMESPACE="${2:-driving-school-manager}"
DEPLOYMENT_NAME="driving-school-manager"
DOCKER_IMAGE="docker.io/chouchoute11/practical_cat_driving_lesson_school_management:${VERSION}"
TIMEOUT=600  # 10 minutes
WAIT_TIME=5  # 5 seconds between checks

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

log_success() {
  echo -e "${GREEN}✅ SUCCESS:${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
}

log_error() {
  echo -e "${RED}❌ ERROR:${NC} $1"
}

# Check prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."
  
  if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found. Please install kubectl."
    exit 1
  fi
  
  if ! kubectl cluster-info &> /dev/null; then
    log_error "Not connected to Kubernetes cluster."
    exit 1
  fi
  
  if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    log_error "Namespace '$NAMESPACE' does not exist."
    exit 1
  fi
  
  log_success "Prerequisites check passed"
}

# Validate version format
validate_version() {
  log_info "Validating version format: $VERSION"
  
  if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "Invalid version format: $VERSION"
    log_info "Expected format: X.Y.Z (e.g., 1.0.1)"
    exit 1
  fi
  
  log_success "Version format valid"
}

# Get current deployment status
get_current_status() {
  log_info "Getting current deployment status..."
  
  kubectl get deployment "$DEPLOYMENT_NAME" \
    -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].image}' || echo "Not deployed"
}

# Update deployment image
update_deployment() {
  log_info "Updating deployment image to: $DOCKER_IMAGE"
  
  kubectl set image deployment/"$DEPLOYMENT_NAME" \
    app="$DOCKER_IMAGE" \
    --namespace="$NAMESPACE" \
    --record || {
    log_error "Failed to update deployment"
    return 1
  }
  
  log_success "Deployment image updated"
}

# Wait for rollout to complete
wait_for_rollout() {
  log_info "Waiting for rollout to complete (timeout: ${TIMEOUT}s)..."
  
  if kubectl rollout status deployment/"$DEPLOYMENT_NAME" \
    --namespace="$NAMESPACE" \
    --timeout="${TIMEOUT}s"; then
    log_success "Rollout completed successfully"
    return 0
  else
    log_error "Rollout failed or timed out"
    return 1
  fi
}

# Verify deployment health
verify_health() {
  log_info "Verifying deployment health..."
  
  local desired_replicas
  local ready_replicas
  
  desired_replicas=$(kubectl get deployment "$DEPLOYMENT_NAME" \
    -n "$NAMESPACE" \
    -o jsonpath='{.spec.replicas}')
  
  ready_replicas=$(kubectl get deployment "$DEPLOYMENT_NAME" \
    -n "$NAMESPACE" \
    -o jsonpath='{.status.readyReplicas}')
  
  log_info "Desired replicas: $desired_replicas"
  log_info "Ready replicas: $ready_replicas"
  
  if [ "$desired_replicas" -eq "$ready_replicas" ]; then
    log_success "All replicas are ready"
    return 0
  else
    log_warn "Not all replicas are ready (${ready_replicas}/${desired_replicas})"
    return 1
  fi
}

# Rollback deployment
rollback_deployment() {
  log_warn "Rolling back deployment..."
  
  if kubectl rollout undo deployment/"$DEPLOYMENT_NAME" \
    --namespace="$NAMESPACE"; then
    
    if kubectl rollout status deployment/"$DEPLOYMENT_NAME" \
      --namespace="$NAMESPACE" \
      --timeout="${TIMEOUT}s"; then
      log_success "Rollback completed successfully"
      return 0
    else
      log_error "Rollback rollout failed"
      return 1
    fi
  else
    log_error "Failed to initiate rollback"
    return 1
  fi
}

# Display deployment summary
display_summary() {
  log_info "Deployment Summary:"
  echo ""
  
  kubectl get deployment "$DEPLOYMENT_NAME" \
    -n "$NAMESPACE" \
    -o wide
  
  echo ""
  
  kubectl get pods \
    -n "$NAMESPACE" \
    -l app="$DEPLOYMENT_NAME" \
    -o wide
  
  echo ""
  
  kubectl rollout history deployment/"$DEPLOYMENT_NAME" \
    -n "$NAMESPACE" | tail -5
}

# Main deployment flow
main() {
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║         ROLLING UPDATE DEPLOYMENT SCRIPT                   ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""
  
  log_info "Starting rolling update deployment"
  log_info "Namespace: $NAMESPACE"
  log_info "Deployment: $DEPLOYMENT_NAME"
  log_info "Version: $VERSION"
  log_info "Docker Image: $DOCKER_IMAGE"
  echo ""
  
  # Execute deployment steps
  check_prerequisites || exit 1
  validate_version || exit 1
  
  log_info "Current deployment:"
  get_current_status
  echo ""
  
  update_deployment || exit 1
  wait_for_rollout || {
    log_error "Deployment failed, initiating rollback..."
    rollback_deployment
    exit 1
  }
  
  sleep 5
  verify_health || log_warn "Health verification reported issues"
  
  echo ""
  display_summary
  
  echo ""
  log_success "Rolling update deployment completed successfully!"
  log_info "You can monitor the deployment with:"
  log_info "  kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE"
  log_info "  kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT_NAME -w"
}

# Execute main
main "$@"
