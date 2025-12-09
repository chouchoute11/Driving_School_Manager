# Phase 6: Deploy - Kubernetes Deployment Guide

## Overview

Phase 6 implements a complete Continuous Deployment (CD) pipeline with Kubernetes, featuring:
- **Rolling Updates**: Gradual deployment with zero downtime
- **Blue-Green Deployment**: Instant traffic switching with instant rollback
- **Resource Management**: Optimized CPU/memory configurations
- **Auto-scaling**: Horizontal Pod Autoscaler based on metrics
- **Security**: RBAC, Network Policies, Pod Security Standards
- **High Availability**: Pod Disruption Budgets, Anti-affinity rules

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                         │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              Ingress / Load Balancer                     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                           │                                    │
│  ┌────────────────────────▼──────────────────────────────┐   │
│  │    Service (driving-school-manager-active)            │   │
│  │    Selector: version=blue (or green)                  │   │
│  └────────────────────────▲──────────────────────────────┘   │
│              │             │             │                    │
│      ┌───────┴─────────┐   │      ┌──────┴──────┐            │
│      │                 │   │      │             │            │
│  ┌──▼──┐  ┌──┐  ┌──┐   │   │  ┌──▼──┐  ┌──┐  ┌──┐           │
│  │Blue │  │  │  │  │   │   │  │Green│  │  │  │  │           │
│  │Pod1 │  │  │  │  │   │   │  │Pod1 │  │  │  │  │           │
│  └─────┘  └──┘  └──┘   │   │  └─────┘  └──┘  └──┘           │
│  ┌──────────────────┐   │   │  ┌──────────────────┐          │
│  │ Blue Deployment  │   │   │  │ Green Deployment │          │
│  │  (Active: 3 pods)│   │   │  │  (Standby: 0)   │          │
│  └──────────────────┘   │   │  └──────────────────┘          │
│                         │   │                                │
│              ┌──────────┘   └─────────────┐                │
│              │                            │                │
│         Blue Service              Green Service           │
│    (internal routing test)   (internal routing test)     │
│                                                           │
└────────────────────────────────────────────────────────────┘
```

## Resource Requirements

### CPU and Memory Specifications

Based on profiling the Driving School Lesson Manager application:

**Container Specifications:**
```
Requests (Guaranteed Minimum):
  - CPU: 100m (0.1 cores)
  - Memory: 128Mi
  - Ephemeral Storage: 1Gi

Limits (Maximum Allowed):
  - CPU: 500m (0.5 cores)
  - Memory: 512Mi
  - Ephemeral Storage: 2Gi
```

**Calculation Basis:**

1. **CPU Request (100m)**
   - Base application: ~40-50m (Node.js + Express)
   - Request processing: ~30-40m per request
   - Buffer: ~20-30m
   - Total: 100m per pod

2. **Memory Request (128Mi)**
   - Node.js base: ~60-80Mi
   - Dependencies: ~30-40Mi
   - Runtime data: ~20-30Mi
   - Total: ~128Mi per pod

3. **CPU Limit (500m)**
   - 5x the request for burst capacity
   - Handles sudden traffic spikes
   - Prevents runaway processes

4. **Memory Limit (512Mi)**
   - 4x the request for safety margin
   - Prevents OOM kills
   - Allows temporary data growth

**Cluster Sizing:**

For 3 replicas:
```
Total CPU Request:  100m × 3 = 300m (0.3 cores)
Total CPU Limit:    500m × 3 = 1.5 cores
Total Memory Request: 128Mi × 3 = 384Mi
Total Memory Limit:  512Mi × 3 = 1.5Gi
```

Recommended node specifications:
- **Minimum**: 2 cores, 2Gi RAM per node
- **Recommended**: 4 cores, 4Gi RAM per node

## File Structure

```
k8s/
├── namespace.yaml              # Kubernetes namespace definition
├── configmap.yaml              # Application configuration
├── deployment.yaml             # Rolling update deployment (primary strategy)
├── blue-green-deployment.yaml  # Blue-green deployments (alternative strategy)
├── service.yaml                # Service and Ingress definitions
├── rbac.yaml                   # Security, RBAC, Network Policies
└── README.md                   # This file

scripts/
├── deploy-rolling.sh           # Rolling update deployment script
├── deploy-blue-green.sh        # Blue-green deployment script
├── deploy-k8s-setup.sh         # Kubernetes cluster setup (optional)
└── deploy-verify.sh            # Verification script

```

## Deployment Strategies

### 1. Rolling Update Strategy (deployment.yaml)

**When to use:**
- Standard deployments
- Can tolerate brief performance variation
- Don't need instant rollback
- Gradual rollout preferred

**How it works:**
1. New pod is created with new version
2. Old pod is terminated
3. Process continues for all pods
4. At most 4 pods during update (3 desired + 1 surge)
5. At least 2 pods always serving traffic (3 - 1 unavailable)

**Configuration:**
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1         # Max 1 extra pod
    maxUnavailable: 1   # Max 1 pod down
```

**Deploy:**
```bash
./scripts/deploy-rolling.sh 1.0.2
```

**Pros:**
- Simple to understand
- Standard Kubernetes feature
- Gradual traffic shift
- Good for testing

**Cons:**
- Can't instantly rollback
- Running two versions simultaneously
- Takes time for full deployment

### 2. Blue-Green Deployment Strategy (blue-green-deployment.yaml)

**When to use:**
- Critical production systems
- Need instant rollback capability
- Large data migration deployments
- Want to test before traffic switch

**How it works:**
1. Blue (current) serves all traffic
2. Green (new) is scaled up (replicas=0 initially)
3. Update green with new version
4. Run smoke tests on green
5. Instantly switch traffic to green
6. Keep blue for instant rollback

**Configuration:**
```yaml
Blue Deployment:
  - replicas: 3 (active)
  - version: 1.0.1

Green Deployment:
  - replicas: 0 (standby)
  - version: 1.0.2
```

**Deploy:**
```bash
./scripts/deploy-blue-green.sh 1.0.2
```

**Rollback (instant):**
```bash
kubectl patch service driving-school-manager-active \
  -n driving-school-manager \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

**Pros:**
- Instant traffic switch
- Instant rollback
- Full environment test before go-live
- No version overlap
- Zero downtime

**Cons:**
- Requires 2x resources during deployment
- More complex to manage
- Need to clean up after rollback

## Getting Started

### Prerequisites

1. **Kubernetes cluster** (1.20+)
   - kubectl configured
   - Context pointing to target cluster
   - At least 2GB RAM available

2. **Docker image** pushed to Docker Hub
   ```bash
   docker push chouchoute11/practical_cat_driving_lesson_school_management:1.0.2
   ```

3. **kubectl access** to the cluster
   ```bash
   kubectl cluster-info
   kubectl auth can-i create deployments --as=system:serviceaccount:driving-school-manager:driving-school-manager
   ```

### Step 1: Create Namespace and Configuration

```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Create ConfigMaps
kubectl apply -f k8s/configmap.yaml

# Create RBAC resources
kubectl apply -f k8s/rbac.yaml

# Verify
kubectl get namespace driving-school-manager
kubectl get configmap -n driving-school-manager
```

### Step 2: Deploy Application (Choose One Strategy)

**Option A: Rolling Update (Recommended for first deployment)**
```bash
# Deploy with rolling update
./scripts/deploy-rolling.sh 1.0.1

# Monitor
kubectl get deployment -n driving-school-manager -w
kubectl get pods -n driving-school-manager -w
```

**Option B: Blue-Green (For updates with rollback capability)**
```bash
# First deployment uses rolling update
./scripts/deploy-rolling.sh 1.0.1

# Subsequent deployments use blue-green
kubectl apply -f k8s/blue-green-deployment.yaml
./scripts/deploy-blue-green.sh 1.0.2

# If needed, rollback instantly
kubectl patch service driving-school-manager-active \
  -n driving-school-manager \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

### Step 3: Create Service and Ingress

```bash
# Create services and ingress
kubectl apply -f k8s/service.yaml

# Verify
kubectl get service -n driving-school-manager
kubectl get ingress -n driving-school-manager
```

### Step 4: Verify Deployment

```bash
# Check deployment status
kubectl get deployment -n driving-school-manager
kubectl get pods -n driving-school-manager

# Check logs
kubectl logs -n driving-school-manager -l app=driving-school-manager --tail=100

# Test health endpoints
kubectl port-forward -n driving-school-manager svc/driving-school-manager 4000:4000 &
curl http://localhost:4000/health
curl http://localhost:4000/ready
```

## Monitoring and Logging

### Pod Health Status

```bash
# Watch rolling update
kubectl rollout status deployment/driving-school-manager \
  -n driving-school-manager

# View rollout history
kubectl rollout history deployment/driving-school-manager \
  -n driving-school-manager

# View specific revision
kubectl rollout history deployment/driving-school-manager \
  -n driving-school-manager --revision=2
```

### Logging

```bash
# View recent logs
kubectl logs -n driving-school-manager \
  -l app=driving-school-manager \
  --tail=100

# Stream logs from all pods
kubectl logs -n driving-school-manager \
  -l app=driving-school-manager \
  -f

# View specific pod
kubectl logs -n driving-school-manager <pod-name>

# Previous logs (from crashed container)
kubectl logs -n driving-school-manager <pod-name> --previous
```

### Resource Usage

```bash
# Check resource usage
kubectl top pods -n driving-school-manager

# Check node usage
kubectl top nodes

# Describe deployment for resource info
kubectl describe deployment driving-school-manager \
  -n driving-school-manager
```

### Pod Events

```bash
# View events
kubectl get events -n driving-school-manager --sort-by='.lastTimestamp'

# Describe pod for detailed status
kubectl describe pod <pod-name> -n driving-school-manager
```

## Rollback Procedures

### Rolling Update Rollback

```bash
# Automatic rollback
./scripts/deploy-rolling.sh 1.0.1

# Manual rollback to previous version
kubectl rollout undo deployment/driving-school-manager \
  -n driving-school-manager

# Rollback to specific revision
kubectl rollout undo deployment/driving-school-manager \
  -n driving-school-manager --to-revision=3

# Check rollout history
kubectl rollout history deployment/driving-school-manager \
  -n driving-school-manager
```

### Blue-Green Rollback

```bash
# Instant rollback (switch traffic back)
kubectl patch service driving-school-manager-active \
  -n driving-school-manager \
  -p '{"spec":{"selector":{"version":"blue"}}}'

# Scale down new version
kubectl scale deployment driving-school-manager-green \
  --replicas=0 \
  -n driving-school-manager
```

## High Availability Features

### Pod Disruption Budget (PDB)

Ensures minimum availability during cluster maintenance:
```yaml
minAvailable: 2  # At least 2 pods must be available
```

Verifies before eviction:
```bash
kubectl get poddisruptionbudgets -n driving-school-manager
```

### Pod Anti-Affinity

Spreads pods across different nodes:
```yaml
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        topologyKey: kubernetes.io/hostname
```

### Health Checks

**Liveness Probe**: Restarts unhealthy containers
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 4000
  initialDelaySeconds: 15
  periodSeconds: 10
  failureThreshold: 3
```

**Readiness Probe**: Marks pod ready/not ready
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 4000
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 2
```

**Startup Probe**: Gives app time to initialize
```yaml
startupProbe:
  httpGet:
    path: /health
    port: 4000
  failureThreshold: 30  # 30 × 2s = 60s startup time
```

### Horizontal Pod Autoscaling (HPA)

Automatically scales based on metrics:
```yaml
metrics:
  - CPU: 70% utilization → add pod
  - Memory: 80% utilization → add pod

scaleDown: Max 50% reduction per 5 minutes
scaleUp: Max 100% increase per 30 seconds
```

View HPA status:
```bash
kubectl get hpa -n driving-school-manager
kubectl describe hpa driving-school-manager-hpa \
  -n driving-school-manager
```

## Security

### Network Policies

Restricts traffic between pods:
- Allow: Ingress nginx → app
- Allow: Prometheus → app (for metrics)
- Allow: App → external DNS
- Allow: App → external HTTP/HTTPS

Test connectivity:
```bash
# Test internal service
kubectl run -it --rm debug --image=curlimages/curl \
  -n driving-school-manager -- \
  sh -c 'curl http://driving-school-manager:4000/health'
```

### RBAC

Limits pod permissions:
```bash
kubectl get rolebindings -n driving-school-manager
kubectl describe clusterrolebinding driving-school-manager
```

### Pod Security

- Non-root user (UID: 1001)
- Read-only root filesystem option
- Drop unnecessary capabilities

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n driving-school-manager

# Check logs
kubectl logs <pod-name> -n driving-school-manager

# Check resource availability
kubectl top nodes
kubectl describe nodes
```

### CrashLoopBackOff

```bash
# View previous logs
kubectl logs <pod-name> -n driving-school-manager --previous

# Check probes
kubectl get pod <pod-name> -n driving-school-manager -o yaml | grep -A 20 livenessProbe

# Test locally
docker run -it driving-school-manager:1.0.1 /bin/sh
```

### Image Pull Errors

```bash
# Verify image exists
docker pull docker.io/chouchoute11/practical_cat_driving_lesson_school_management:1.0.1

# Check image pull secrets
kubectl get secrets -n driving-school-manager
kubectl describe pod <pod-name> -n driving-school-manager | grep -i image
```

### Service not accessible

```bash
# Check service endpoints
kubectl get endpoints -n driving-school-manager

# Check DNS
kubectl run -it --rm debug --image=curlimages/curl \
  -n driving-school-manager -- \
  nslookup driving-school-manager

# Port forward and test
kubectl port-forward -n driving-school-manager svc/driving-school-manager 4000:4000
curl http://localhost:4000/health
```

## Advanced Configuration

### Custom Resource Limits

Adjust for your environment:
```yaml
resources:
  requests:
    memory: "256Mi"  # Increase for heavy workloads
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### Scaling Settings

Manual scale:
```bash
kubectl scale deployment driving-school-manager \
  --replicas=5 \
  -n driving-school-manager
```

### Environment Variables

Update in configmap.yaml and restart pods:
```bash
kubectl patch configmap driving-school-config \
  -n driving-school-manager \
  -p '{"data":{"NODE_ENV":"staging"}}'

kubectl rollout restart deployment/driving-school-manager \
  -n driving-school-manager
```

## Integration with CI/CD

The deployment scripts integrate with GitHub Actions:

1. Test phase passes
2. Docker image is built and pushed
3. GitHub release is created
4. CD pipeline triggers deployment

See `.github/workflows/release.yml` for pipeline configuration.

## References

- [Kubernetes Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
- [Blue-Green Deployments](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#blue-green-deployment)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Pod Disruption Budgets](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

## Support

For issues or questions:
1. Check deployment logs: `kubectl logs -n driving-school-manager -l app=driving-school-manager`
2. Verify cluster resources: `kubectl top nodes`
3. Check pod status: `kubectl describe pod <pod-name> -n driving-school-manager`
4. Review deployment events: `kubectl get events -n driving-school-manager`
