# Phase 6: Deploy - Quick Start Guide

## 5-Minute Kubernetes Deployment

### Prerequisites (1 minute)
```bash
# Check kubectl is configured
kubectl cluster-info
kubectl get nodes

# Ensure image is available
docker pull chouchoute11/practical_cat_driving_lesson_school_management:1.0.1
```

### Deploy (4 minutes)

**Option 1: Rolling Update (Standard)**
```bash
# Step 1: Create namespace and config
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/rbac.yaml

# Step 2: Deploy application
./scripts/deploy-rolling.sh 1.0.1

# Step 3: Create service
kubectl apply -f k8s/service.yaml

# Step 4: Test
kubectl port-forward -n driving-school-manager svc/driving-school-manager 4000:4000 &
curl http://localhost:4000/health
```

**Option 2: Blue-Green (Instant Rollback)**
```bash
# Step 1-3: Same as above

# Step 4: Deploy blue-green setup
kubectl apply -f k8s/blue-green-deployment.yaml

# Step 5: Deploy new version
./scripts/deploy-blue-green.sh 1.0.2

# Step 6: If needed, instant rollback
kubectl patch service driving-school-manager-active \
  -n driving-school-manager \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

## Key Commands

```bash
# Monitor deployment
kubectl get pods -n driving-school-manager -w
kubectl rollout status deployment/driving-school-manager -n driving-school-manager

# View logs
kubectl logs -n driving-school-manager -l app=driving-school-manager -f

# Scale manually
kubectl scale deployment driving-school-manager --replicas=5 -n driving-school-manager

# View resource usage
kubectl top pods -n driving-school-manager
kubectl top nodes

# Rollback
kubectl rollout undo deployment/driving-school-manager -n driving-school-manager
```

## Resource Summary

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 100m | 500m |
| Memory | 128Mi | 512Mi |
| Storage | 1Gi | 2Gi |

**Total (3 replicas):**
- CPU: 300m (0.3 cores)
- Memory: 384Mi

## Deployment Comparison

| Feature | Rolling | Blue-Green |
|---------|---------|-----------|
| Downtime | None | None |
| Rollback Speed | Minutes | Instant |
| Resource Overhead | ~33% | ~100% |
| Complexity | Low | Medium |
| Best For | Standard | Critical |

## Troubleshooting

```bash
# Pod not ready
kubectl describe pod <pod-name> -n driving-school-manager

# Image pull error
kubectl get pods -n driving-school-manager -o jsonpath='{.items[0].status.containerStatuses[0].state}'

# Service not accessible
kubectl get endpoints -n driving-school-manager

# Logs
kubectl logs <pod-name> -n driving-school-manager --tail=50
```

## Next Steps

1. ✅ Deploy to development cluster
2. Run smoke tests
3. Set up monitoring and alerts
4. Configure auto-scaling thresholds
5. Document runbooks
6. Train team on deployment procedures

See **PHASE6_KUBERNETES_GUIDE.md** for detailed documentation.
