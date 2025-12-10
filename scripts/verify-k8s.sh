#!/bin/bash

# =============================================================================
# Kubernetes Deployment Verification Checklist
# Run this script to verify your Kubernetes deployment is working correctly
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="driving-school-manager"
APP_NAME="driving-school-manager"
CHECKS_PASSED=0
CHECKS_FAILED=0

print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_check() {
    echo -e "${YELLOW}▶ $1${NC}"
}

print_pass() {
    echo -e "${GREEN}  ✓ $1${NC}"
    ((CHECKS_PASSED++))
}

print_fail() {
    echo -e "${RED}  ✗ $1${NC}"
    ((CHECKS_FAILED++))
}

print_info() {
    echo -e "${BLUE}  ℹ $1${NC}"
}

# =============================================================================
# 1. Kubernetes Cluster
# =============================================================================
print_header "1. KUBERNETES CLUSTER CHECKS"

print_check "Checking cluster connectivity..."
if kubectl cluster-info &> /dev/null; then
    print_pass "Kubernetes cluster is accessible"
else
    print_fail "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_check "Checking cluster nodes..."
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
if [ $NODE_COUNT -gt 0 ]; then
    print_pass "Found $NODE_COUNT node(s)"
    kubectl get nodes --no-headers | while read line; do
        echo -e "    $line"
    done
else
    print_fail "No nodes found in cluster"
fi

# =============================================================================
# 2. Namespace
# =============================================================================
print_header "2. NAMESPACE CHECKS"

print_check "Checking namespace existence..."
if kubectl get namespace $NAMESPACE &> /dev/null; then
    print_pass "Namespace '$NAMESPACE' exists"
else
    print_fail "Namespace '$NAMESPACE' does not exist"
fi

# =============================================================================
# 3. ConfigMap
# =============================================================================
print_header "3. CONFIGMAP CHECKS"

print_check "Checking ConfigMap..."
if kubectl get configmap app-config -n $NAMESPACE &> /dev/null; then
    print_pass "ConfigMap 'app-config' exists"
    print_info "ConfigMap contents:"
    kubectl get configmap app-config -n $NAMESPACE -o yaml | grep -A 20 "data:" | head -10
else
    print_fail "ConfigMap 'app-config' not found"
fi

# =============================================================================
# 4. RBAC
# =============================================================================
print_header "4. RBAC & SECURITY CHECKS"

print_check "Checking ServiceAccount..."
if kubectl get serviceaccount $APP_NAME -n $NAMESPACE &> /dev/null; then
    print_pass "ServiceAccount '$APP_NAME' exists"
else
    print_fail "ServiceAccount '$APP_NAME' not found"
fi

print_check "Checking ClusterRole..."
if kubectl get clusterrole ${APP_NAME}-role &> /dev/null; then
    print_pass "ClusterRole '${APP_NAME}-role' exists"
else
    print_fail "ClusterRole '${APP_NAME}-role' not found"
fi

print_check "Checking Pod Disruption Budget..."
if kubectl get pdb -n $NAMESPACE &> /dev/null; then
    print_pass "Pod Disruption Budget exists"
    kubectl get pdb -n $NAMESPACE
else
    print_fail "Pod Disruption Budget not found"
fi

# =============================================================================
# 5. Deployment
# =============================================================================
print_header "5. DEPLOYMENT CHECKS"

print_check "Checking deployment existence..."
if kubectl get deployment $APP_NAME -n $NAMESPACE &> /dev/null; then
    print_pass "Deployment '$APP_NAME' exists"
else
    print_fail "Deployment '$APP_NAME' not found"
    exit 1
fi

print_check "Checking desired replicas..."
DESIRED=$(kubectl get deployment $APP_NAME -n $NAMESPACE -o jsonpath='{.spec.replicas}')
READY=$(kubectl get deployment $APP_NAME -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
AVAILABLE=$(kubectl get deployment $APP_NAME -n $NAMESPACE -o jsonpath='{.status.availableReplicas}')

if [ "$READY" = "$DESIRED" ] && [ "$AVAILABLE" = "$DESIRED" ]; then
    print_pass "All $DESIRED replicas are ready and available"
else
    print_fail "Not all replicas are ready (Desired: $DESIRED, Ready: $READY, Available: $AVAILABLE)"
fi

# =============================================================================
# 6. Pods
# =============================================================================
print_header "6. POD CHECKS"

print_check "Listing pods..."
POD_COUNT=$(kubectl get pods -n $NAMESPACE -l app=$APP_NAME --no-headers 2>/dev/null | wc -l)
if [ $POD_COUNT -gt 0 ]; then
    print_pass "Found $POD_COUNT pod(s)"
    kubectl get pods -n $NAMESPACE -l app=$APP_NAME --no-headers | while read line; do
        echo -e "    $line"
    done
else
    print_fail "No pods found"
fi

print_check "Checking pod status..."
RUNNING=$(kubectl get pods -n $NAMESPACE -l app=$APP_NAME -o jsonpath='{range .items[*]}{.status.phase}' | grep -o "Running" | wc -l)
if [ $RUNNING -gt 0 ]; then
    print_pass "$RUNNING pod(s) are running"
else
    print_fail "No pods are running"
fi

print_check "Checking pod readiness..."
READY_PODS=$(kubectl get pods -n $NAMESPACE -l app=$APP_NAME -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' | grep -c "True" || echo 0)
if [ $READY_PODS -gt 0 ]; then
    print_pass "$READY_PODS pod(s) are ready"
else
    print_fail "No pods are ready"
fi

# Check each pod in detail
echo -e "\n${YELLOW}Pod Details:${NC}"
kubectl get pods -n $NAMESPACE -l app=$APP_NAME -o wide

# =============================================================================
# 7. Service
# =============================================================================
print_header "7. SERVICE CHECKS"

print_check "Checking service existence..."
if kubectl get svc $APP_NAME -n $NAMESPACE &> /dev/null; then
    print_pass "Service '$APP_NAME' exists"
else
    print_fail "Service '$APP_NAME' not found"
fi

print_check "Checking service type..."
SVC_TYPE=$(kubectl get svc $APP_NAME -n $NAMESPACE -o jsonpath='{.spec.type}')
print_pass "Service type: $SVC_TYPE"

print_check "Checking service endpoints..."
ENDPOINTS=$(kubectl get endpoints $APP_NAME -n $NAMESPACE -o jsonpath='{.subsets[0].addresses[*].ip}' | wc -w)
if [ $ENDPOINTS -gt 0 ]; then
    print_pass "Service has $ENDPOINTS endpoint(s)"
else
    print_fail "Service has no endpoints"
fi

print_check "Service details:"
kubectl get svc $APP_NAME -n $NAMESPACE
echo

# =============================================================================
# 8. HPA (Horizontal Pod Autoscaler)
# =============================================================================
print_header "8. AUTO-SCALING CHECKS"

print_check "Checking HPA..."
if kubectl get hpa $APP_NAME -n $NAMESPACE &> /dev/null; then
    print_pass "HPA for '$APP_NAME' exists"
    echo -e "\n${YELLOW}HPA Status:${NC}"
    kubectl get hpa $APP_NAME -n $NAMESPACE
    echo
else
    print_fail "HPA for '$APP_NAME' not found"
fi

# =============================================================================
# 9. Resource Usage
# =============================================================================
print_header "9. RESOURCE USAGE CHECKS"

print_check "Checking pod resource usage..."
if command -v kubectl &> /dev/null; then
    if kubectl top nodes &> /dev/null; then
        echo -e "\n${YELLOW}Node Resource Usage:${NC}"
        kubectl top nodes
        echo
        echo -e "${YELLOW}Pod Resource Usage:${NC}"
        kubectl top pods -n $NAMESPACE -l app=$APP_NAME 2>/dev/null || print_info "Metrics not yet available (wait 1-2 minutes)"
    else
        print_info "Metrics server not installed (optional feature)"
    fi
else
    print_fail "kubectl top command not available"
fi

# =============================================================================
# 10. Events
# =============================================================================
print_header "10. RECENT EVENTS"

print_check "Checking for recent events..."
echo -e "\n${YELLOW}Recent Events (last 10):${NC}"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -11

# =============================================================================
# 11. Container Image
# =============================================================================
print_header "11. CONTAINER IMAGE CHECKS"

print_check "Checking container images..."
kubectl get pods -n $NAMESPACE -l app=$APP_NAME -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' | sort | uniq | while read img; do
    print_pass "Image: $img"
done

# =============================================================================
# 12. Health Endpoints
# =============================================================================
print_header "12. APPLICATION HEALTH CHECKS"

print_check "Testing application endpoints..."

# Port forward in background
kubectl port-forward -n $NAMESPACE svc/$APP_NAME 4000:4000 > /dev/null 2>&1 &
PF_PID=$!
sleep 2

HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/health 2>/dev/null || echo "000")
if [ "$HEALTH_STATUS" = "200" ]; then
    print_pass "Health endpoint responding (HTTP $HEALTH_STATUS)"
else
    print_fail "Health endpoint not responding (HTTP $HEALTH_STATUS)"
fi

READY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/ready 2>/dev/null || echo "000")
if [ "$READY_STATUS" = "200" ]; then
    print_pass "Ready endpoint responding (HTTP $READY_STATUS)"
else
    print_fail "Ready endpoint not responding (HTTP $READY_STATUS)"
fi

# Kill port forward
kill $PF_PID 2>/dev/null || true

# =============================================================================
# 13. Storage (if applicable)
# =============================================================================
print_header "13. STORAGE CHECKS"

print_check "Checking for volumes..."
VOLUMES=$(kubectl get pods -n $NAMESPACE -l app=$APP_NAME -o jsonpath='{range .items[*]}{.spec.volumes[*].name}{"\n"}{end}' | grep -v "^$" | sort | uniq)
if [ -z "$VOLUMES" ]; then
    print_pass "No persistent volumes required (stateless application)"
else
    print_pass "Volumes found:"
    echo "$VOLUMES" | while read vol; do
        echo "    - $vol"
    done
fi

# =============================================================================
# 14. Network Policies
# =============================================================================
print_header "14. NETWORK POLICY CHECKS"

print_check "Checking network policies..."
POLICIES=$(kubectl get networkpolicies -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
if [ $POLICIES -gt 0 ]; then
    print_pass "Found $POLICIES network policy(ies)"
    kubectl get networkpolicies -n $NAMESPACE
else
    print_info "No network policies configured (optional)"
fi

# =============================================================================
# SUMMARY
# =============================================================================
print_header "VERIFICATION SUMMARY"

TOTAL=$((CHECKS_PASSED + CHECKS_FAILED))

echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"
echo -e "${RED}Failed: $CHECKS_FAILED${NC}"
echo -e "${BLUE}Total:  $TOTAL${NC}"
echo

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Your deployment is healthy.${NC}"
    echo
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  1. Access the application:"
    echo -e "     kubectl port-forward -n ${NAMESPACE} svc/${APP_NAME} 4000:4000"
    echo -e "  2. Visit http://localhost:4000"
    echo -e "  3. View logs: kubectl logs -n ${NAMESPACE} -l app=${APP_NAME} -f"
    echo
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Review the output above.${NC}"
    echo
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo -e "  1. Check pod logs: kubectl logs -n ${NAMESPACE} <pod-name>"
    echo -e "  2. Describe pods: kubectl describe pod -n ${NAMESPACE} -l app=${APP_NAME}"
    echo -e "  3. Check events: kubectl get events -n ${NAMESPACE}"
    echo
    exit 1
fi
