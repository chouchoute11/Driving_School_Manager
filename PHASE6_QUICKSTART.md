# Phase 6: Deployment - Quick Start Guide

## 5-Minute Overview

**Goal:** Deploy Driving School Lesson Manager to production using Kubernetes or Docker Swarm

### Option 1: Docker Swarm (Easiest)

```bash
# 1. Initialize Docker Swarm (one-time setup)
docker swarm init

# 2. Deploy to Swarm
./deploy/swarm-deploy.sh deploy

# 3. Check status
./deploy/swarm-deploy.sh status

# 4. Access application
curl http://localhost/api/lessons
```

### Option 2: Kubernetes (More Powerful)

```bash
# 1. Install kubectl
curl -LO https://dl.k8s.io/release/stable.txt | \
  xargs -I {} curl -LO https://dl.k8s.io/release/{}/bin/linux/amd64/kubectl
sudo install kubectl /usr/local/bin/

# 2. Connect to cluster (e.g., minikube)
minikube start

# 3. Deploy to Kubernetes
./deploy/k8s-deploy.sh deploy

# 4. Check status
./deploy/k8s-deploy.sh status

# 5. Port forward to access
kubectl port-forward -n driving-school svc/driving-school-service 4000:4000
curl http://localhost:4000/api/lessons
```

## Configuration Overview

### Resource Allocation

```
Per Pod:
- CPU Request: 250m (guaranteed minimum)
- CPU Limit: 500m (maximum allowed)
- Memory Request: 256Mi (guaranteed minimum)
- Memory Limit: 512Mi (maximum allowed)

Cluster Minimum (recommended):
- 3 nodes
- Each node: 4 CPU, 8GB RAM
- Total: 12 CPU, 24GB RAM available for applications
```

### Replicas and Scaling

```
Default Configuration:
- Minimum replicas: 2
- Maximum replicas: 10
- Initial replicas: 3

Auto-scaling Triggers:
- Scale up when: CPU > 70% OR Memory > 80%
- Scale down when: CPU < 50% AND Memory < 60%
- Scale down delay: 5 minutes (prevents oscillation)
```

## Common Operations

### Deploy to Kubernetes

```bash
./deploy/k8s-deploy.sh deploy
```

**What it does:**
1. Creates namespace `driving-school`
2. Applies ConfigMaps, RBAC, and deployment manifests
3. Waits for deployment to be ready
4. Performs health checks
5. Displays status

**Output:**
```
[SUCCESS] kubectl found: ...
[SUCCESS] Connected to cluster: ...
[SUCCESS] Namespace 'driving-school' already exists
[INFO] Applying Kubernetes manifests...
[SUCCESS] All manifests applied successfully
[SUCCESS] Deployment 'driving-school-app' is ready
[SUCCESS] All pods are healthy
```

### Deploy to Docker Swarm

```bash
./deploy/swarm-deploy.sh deploy
```

**What it does:**
1. Verifies Docker Swarm is active
2. Deploys stack from docker-compose.swarm.yml
3. Starts load balancer and monitoring agent
4. Checks service status
5. Performs health checks

### Update Application (Rolling Update)

**Kubernetes:**
```bash
./deploy/k8s-deploy.sh update docker.io/myuser/image:1.0.2
```

**Docker Swarm:**
```bash
./deploy/swarm-deploy.sh update docker.io/myuser/image:1.0.2
```

**Rolling Update Process:**
- Update one replica at a time
- Wait 10-30 seconds between updates
- Automatically rollback if failures detected
- Zero downtime guaranteed

### Scale Application

**Kubernetes:**
```bash
./deploy/k8s-deploy.sh scale 5    # Scale to 5 replicas
```

**Docker Swarm:**
```bash
./deploy/swarm-deploy.sh scale 5   # Scale to 5 replicas
```

### View Logs

**Kubernetes:**
```bash
./deploy/k8s-deploy.sh logs <pod-name>
./deploy/k8s-deploy.sh logs driving-school-app-xyz -100  # Last 100 lines
```

**Docker Swarm:**
```bash
./deploy/swarm-deploy.sh logs
./deploy/swarm-deploy.sh logs driving_lesson_manager_driving-school-app
```

### Check Health

**Kubernetes:**
```bash
./deploy/k8s-deploy.sh health
```

**Docker Swarm:**
```bash
./deploy/swarm-deploy.sh health
```

**Output includes:**
- Pod status (Running, Pending, Failed)
- Container health status
- Number of healthy replicas

### Rollback to Previous Version

**Kubernetes:**
```bash
./deploy/k8s-deploy.sh rollback
```

**Docker Swarm:**
```bash
./deploy/swarm-deploy.sh rollback
```

### Blue-Green Deployment (Kubernetes Only)

```bash
# Deploy new version alongside current
./deploy/k8s-deploy.sh blue-green docker.io/myuser/image:1.0.2

# When ready, switch traffic
kubectl patch service driving-school-service \
  -n driving-school \
  -p '{"spec":{"selector":{"deployment-variant":"green"}}}'

# Rollback is instant (one command)
kubectl patch service driving-school-service \
  -n driving-school \
  -p '{"spec":{"selector":{"deployment-variant":"blue"}}}'
```

## Health Check Endpoints

Your application must provide these endpoints:

### `/health` - Liveness Check
Returns 200 OK if container is running
```bash
curl http://localhost:4000/health
# Response: { status: "healthy" }
```

### `/ready` - Readiness Check
Returns 200 OK if application is ready to serve traffic
```bash
curl http://localhost:4000/ready
# Response: { status: "ready" }
```

**Current implementation:**
- Located in `healthcheck.js`
- Checks Node.js process
- Returns status based on process health

## Troubleshooting

### Kubernetes

**Pods not starting:**
```bash
./deploy/k8s-deploy.sh status
kubectl describe pod <pod-name> -n driving-school
kubectl logs <pod-name> -n driving-school --previous
```

**High resource usage:**
```bash
./deploy/k8s-deploy.sh resources
# Adjust limits in k8s/deployment.yaml if needed
```

**Slow rollback:**
```bash
# Check rollout history
kubectl rollout history deployment/driving-school-app -n driving-school

# View specific revision
kubectl rollout history deployment/driving-school-app -n driving-school --revision=2
```

### Docker Swarm

**Service won't start:**
```bash
./deploy/swarm-deploy.sh tasks
docker inspect <container-id>
docker logs <container-id>
```

**Update hangs:**
```bash
docker service inspect driving_lesson_manager_driving-school-app
# Check UpdateStatus in output
```

## Cost Estimation

### Kubernetes (EKS - AWS)

```
Small cluster (3 nodes, t3.medium):
- Control plane: $73/month
- Worker nodes: $75-150/month
- Load balancer: $16/month
- Storage: $15/month
TOTAL: ~$180-250/month

Medium cluster (6 nodes, t3.large):
- Control plane: $73/month
- Worker nodes: $300-400/month
- Load balancer: $16/month
- Storage: $40/month
TOTAL: ~$430-530/month
```

### Docker Swarm (Self-hosted VPS)

```
Small cluster (3 nodes, 2CPU/4GB):
- Manager: $12/month
- Workers (2x): $50/month
- Storage: $30/month
TOTAL: ~$92/month

Medium cluster (3 nodes, 4CPU/8GB):
- Manager: $25/month
- Workers (2x): $100/month
- Storage: $60/month
TOTAL: ~$185/month
```

## Production Checklist

- [ ] Docker image pushed to registry
- [ ] Kubernetes/Docker Swarm cluster ready
- [ ] Health check endpoints verified (`/health`, `/ready`)
- [ ] Resource limits set appropriately
- [ ] Monitoring and logging configured
- [ ] Load balancer configured
- [ ] Autoscaling enabled
- [ ] Backup strategy implemented
- [ ] Disaster recovery plan documented
- [ ] Team trained on deployment scripts
- [ ] Rollback procedure tested
- [ ] Health checks tested in production
- [ ] Performance baseline established

## Next Steps

1. **Monitor deployment:**
   ```bash
   watch -n 2 'kubectl get pods -n driving-school'  # Kubernetes
   watch -n 2 'docker service ps <service-name>'     # Docker Swarm
   ```

2. **Set up logging and monitoring:**
   - Install Prometheus for metrics
   - Install ELK stack for logs
   - Configure Grafana dashboards
   - Set up alerting rules

3. **Implement CI/CD integration:**
   - GitHub Actions triggers deployment on tag push
   - Automatic rollback on failures
   - Deploy to staging before production

4. **Performance tuning:**
   - Monitor resource usage patterns
   - Adjust CPU/memory limits based on actual usage
   - Optimize scaling thresholds
   - Implement request caching

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Swarm Guide](https://docs.docker.com/engine/swarm/)
- [Resource Requests and Limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy)

## Support

For detailed documentation, see:
- `PHASE6_DEPLOY.md` - Complete deployment guide
- `PHASE6_RESOURCES.md` - Resource planning and cost analysis
- `k8s/` - Kubernetes manifests
- `swarm/` - Docker Swarm configuration

---

**Phase 6 Ready** ✅
