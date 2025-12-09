# Phase 6: Deployment - Complete Guide

## Overview

Phase 6 implements a comprehensive CD (Continuous Deployment) pipeline with support for both **Kubernetes** and **Docker Swarm** orchestration platforms. This includes rolling updates, blue-green deployments, and automated scaling based on resource consumption.

## Architecture Overview

### Deployment Platforms

```
┌─────────────────────────────────────────────────────────────┐
│         Driving School Lesson Manager - Phase 6             │
│                  Deployment Architecture                    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│   Docker Image Repository               │
│  - Docker Hub (Production)              │
│  - GitHub Container Registry (GHCR)     │
└─────────────────────────────────────────┘
           ↓
    ┌──────────────┴──────────────┐
    ↓                             ↓
┌─────────────────┐      ┌─────────────────┐
│  KUBERNETES     │      │  DOCKER SWARM   │
│                 │      │                 │
│ • Rolling Upd.  │      │ • Rolling Upd.  │
│ • Blue-Green    │      │ • Global Scale  │
│ • Auto-scale    │      │ • Service Mgmt  │
│ • Resource Mgmt │      │ • Health Check  │
└─────────────────┘      └─────────────────┘
```

## Resource Requirements

### CPU and Memory Allocation

```
┌───────────────────────────────────────────────────────┐
│         Resource Allocation per Pod/Container          │
├───────────────────────────────────────────────────────┤
│ Resource Type        │ Requests      │ Limits         │
├──────────────────────┼───────────────┼────────────────┤
│ CPU                  │ 250m (0.25)   │ 500m (0.5)    │
│ Memory               │ 256Mi         │ 512Mi         │
│ Ephemeral Storage    │ 100Mi         │ 500Mi         │
│ Volumes (temp)       │ 500Mi         │ 500Mi         │
└───────────────────────────────────────────────────────┘

Cluster Sizing (Example):
- 3 nodes (High Availability)
- Each node: 2 CPU cores, 4GB RAM minimum
- Cluster total: 6 CPUs, 12GB RAM
- Available for applications: ~4 CPUs, 8GB RAM (accounting for system pods)

Pod Scaling:
- Min replicas: 2
- Max replicas: 10
- Target CPU utilization: 70%
- Target Memory utilization: 80%
```

## Kubernetes Deployment

### 1. Setup and Installation

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client

# Set up cluster context (if using managed cluster like EKS, AKS, GKE)
# For local development, install minikube or kind
```

### 2. Deploy to Kubernetes

```bash
# Deploy with rolling updates
./deploy/k8s-deploy.sh deploy

# Monitor deployment
./deploy/k8s-deploy.sh status

# Check pod health
./deploy/k8s-deploy.sh health

# View logs
./deploy/k8s-deploy.sh logs <pod-name>
```

### 3. Rolling Updates

```bash
# Perform rolling update with new image
./deploy/k8s-deploy.sh update docker.io/chouchoute11/practical_cat_driving_lesson_school_management:1.0.2

# Configuration:
# - maxSurge: 1 (one extra pod allowed during update)
# - maxUnavailable: 0 (zero downtime guarantee)
# - Update order: start-first (new pod starts before old is killed)
```

### 4. Blue-Green Deployment

```bash
# Deploy green variant alongside current blue
./deploy/k8s-deploy.sh blue-green docker.io/chouchoute11/practical_cat_driving_lesson_school_management:1.0.2

# When ready, switch traffic to green
kubectl patch service driving-school-service \
  -n driving-school \
  -p '{"spec":{"selector":{"deployment-variant":"green"}}}'

# Benefits:
# - Zero downtime
# - Instant rollback
# - Easy version comparison
```

### 5. Auto-Scaling

```bash
# Configured HPA monitors:
# - CPU utilization (target: 70%)
# - Memory utilization (target: 80%)
# 
# Automatic Actions:
# - Scale up: When utilization exceeds threshold
# - Scale down: After 5 minutes of low utilization
# - Range: 2-10 replicas

# Manual scaling
./deploy/k8s-deploy.sh scale 5
```

### 6. Health Checks

```yaml
# startupProbe: Allow 5 minutes (300 seconds) for application startup
startupProbe:
  httpGet:
    path: /health
    port: 4000
  failureThreshold: 30
  periodSeconds: 10

# livenessProbe: Restart if unhealthy for 45 seconds
livenessProbe:
  httpGet:
    path: /health
    port: 4000
  failureThreshold: 3
  periodSeconds: 15

# readinessProbe: Remove from traffic if not ready
readinessProbe:
  httpGet:
    path: /ready
    port: 4000
  failureThreshold: 2
  periodSeconds: 10
```

### 7. Resource Monitoring

```bash
# View resource usage
./deploy/k8s-deploy.sh resources

# Requires metrics-server:
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### 8. Rollback

```bash
# If deployment fails or has issues
./deploy/k8s-deploy.sh rollback

# This reverts to the previous known good version
```

## Docker Swarm Deployment

### 1. Initialize Swarm

```bash
# Initialize Docker Swarm
docker swarm init

# Join other nodes (on worker nodes)
docker swarm join --token <token> <manager-ip>:2377

# Verify swarm
docker info | grep Swarm
```

### 2. Deploy to Swarm

```bash
# Deploy stack with docker-compose
./deploy/swarm-deploy.sh deploy

# Monitor status
./deploy/swarm-deploy.sh status

# Check task health
./deploy/swarm-deploy.sh tasks
```

### 3. Rolling Updates

```bash
# Perform rolling update with new image
./deploy/swarm-deploy.sh update docker.io/chouchoute11/practical_cat_driving_lesson_school_management:1.0.2

# Configuration:
# - parallelism: 1 (update one replica at a time)
# - delay: 10s (wait 10 seconds between updates)
# - failure_action: rollback (automatically rollback on failure)
# - monitor: 30s (monitor for 30s after each update)
# - order: start-first (start new before stopping old)
```

### 4. Scaling

```bash
# Scale service to specified replicas
./deploy/swarm-deploy.sh scale 5

# Service will be rebalanced across nodes
```

### 5. Health Checks

```yaml
# Docker Swarm Health Check
healthcheck:
  test: ["CMD", "node", "healthcheck.js"]
  interval: 30s      # Check every 30 seconds
  timeout: 10s       # Timeout after 10 seconds
  retries: 3         # Mark unhealthy after 3 failures
  start_period: 10s  # Wait 10s before first check

# Container restart on unhealthy
restart_policy:
  condition: on-failure
  delay: 5s
  max_attempts: 3
```

### 6. Load Balancing

Nginx load balancer configured with:
- Round-robin with least connections
- Health check endpoints
- Rate limiting (API: 10 req/s, General: 100 req/min)
- Response caching
- Gzip compression
- Security headers

```bash
# Access application through load balancer
curl http://localhost/api/lessons
```

### 7. Service Discovery

Docker Swarm provides built-in service discovery:
- Service name: `driving-school-app`
- DNS resolution: Services accessible by name within overlay network
- Load balancing: Automatically distributes requests

## Deployment Strategies Comparison

### Rolling Update (Default)

```
Current:  [Pod1] [Pod2] [Pod3]
Step 1:   [Pod1'] [Pod2] [Pod3]
Step 2:   [Pod1'] [Pod2'] [Pod3]
Step 3:   [Pod1'] [Pod2'] [Pod3']
Result:   [Pod1'] [Pod2'] [Pod3']  ✓ Zero downtime
```

**Pros:** Zero downtime, automatic rollback capability
**Cons:** Requires more resources during update
**Best for:** Production deployments, non-breaking updates

### Blue-Green Deployment

```
Blue (v1.0.0):   [Pod1] [Pod2] [Pod3]
Green (v1.0.1):  [Pod1] [Pod2] [Pod3]
Traffic Switch:  All requests → Green
Cleanup:         Delete Blue
Result:          [Pod1] [Pod2] [Pod3] (v1.0.1) ✓ Instant rollback
```

**Pros:** Instant rollback, complete version isolation, easy comparison
**Cons:** Requires double resources, manual traffic switch
**Best for:** Major updates, risky deployments, quick rollback needs

## Monitoring and Observability

### Kubernetes Metrics

```bash
# Pod resource usage
kubectl top pods -n driving-school

# Node resource usage
kubectl top nodes

# Event logging
kubectl get events -n driving-school --sort-by='.lastTimestamp'

# Deployment history
kubectl rollout history deployment/driving-school-app -n driving-school
```

### Docker Swarm Metrics

```bash
# Service overview
docker service ls

# Task status
docker service ps driving_lesson_manager_driving-school-app

# Container resource usage
docker stats

# Service logs
docker service logs driving_lesson_manager_driving-school-app
```

## Troubleshooting

### Kubernetes Issues

```bash
# Debugging failed deployment
kubectl describe deployment driving-school-app -n driving-school
kubectl describe pods <pod-name> -n driving-school

# Check pod logs
kubectl logs <pod-name> -n driving-school
kubectl logs <pod-name> -n driving-school --previous  # For crashed containers

# Test connectivity
kubectl exec -it <pod-name> -n driving-school -- /bin/sh
curl http://localhost:4000/health
```

### Docker Swarm Issues

```bash
# Check service status
docker service inspect driving_lesson_manager_driving-school-app

# View service logs
docker service logs driving_lesson_manager_driving-school-app

# Test task health
docker exec <container-id> node healthcheck.js

# Check node status
docker node ls
```

## Security Considerations

### Kubernetes Security

- **RBAC**: Service accounts with minimal permissions
- **Network Policies**: Can be added to restrict traffic
- **Security Context**: Containers run as non-root (UID 1001)
- **Read-Only Root FS**: Reduces attack surface
- **Resource Limits**: Prevents resource exhaustion attacks

### Docker Swarm Security

- **Encrypted Networks**: Overlay networks with encryption
- **Secrets Management**: Use Docker secrets for sensitive data
- **Non-Root Containers**: Containers run as non-root
- **Health Checks**: Automatic recovery from failures

## Performance Tuning

### CPU and Memory Optimization

```
Application Profiling:
- Light Load: 50-100m CPU, 100-150Mi Memory
- Normal Load: 150-250m CPU, 200-300Mi Memory
- Peak Load: 400-500m CPU, 450-512Mi Memory

Recommended Settings:
- Requests: 250m CPU, 256Mi Memory (minimum guaranteed)
- Limits: 500m CPU, 512Mi Memory (maximum allowed)
- Burst Capacity: 1000m CPU (with maxSurge=1)
```

### Scaling Thresholds

```
CPU Scaling:
- 70% utilization → Scale up
- 30% utilization → Scale down (after 5 min)

Memory Scaling:
- 80% utilization → Scale up
- 40% utilization → Scale down (after 5 min)

Network:
- Request throughput: ~100 req/s per pod
- Concurrent connections: 100 per pod
- Max total capacity: 1000 req/s (10 pods at scale)
```

## Production Checklist

- [ ] Kubernetes cluster or Docker Swarm initialized
- [ ] Docker images pushed to registries (Docker Hub + GHCR)
- [ ] Resource requests and limits configured
- [ ] Health checks verified (/health, /ready endpoints)
- [ ] Logging configured and aggregated
- [ ] Monitoring and alerting set up
- [ ] Load balancer configured
- [ ] Backup and disaster recovery plan
- [ ] Security policies and RBAC configured
- [ ] Automated rolling updates tested
- [ ] Rollback procedure tested
- [ ] Blue-green deployment procedure documented
- [ ] Traffic migration tested

## Next Steps

1. **Choose Orchestration Platform**
   - Kubernetes for large-scale, multi-cloud deployments
   - Docker Swarm for simpler, single-host or small clusters

2. **Infrastructure Setup**
   - Set up Kubernetes cluster (EKS, AKS, GKE, or self-managed)
   - Initialize Docker Swarm on nodes

3. **Deploy Application**
   - Use provided deployment scripts
   - Verify health checks
   - Monitor initial deployments

4. **Enable Monitoring**
   - Set up Prometheus for metrics
   - Configure Grafana dashboards
   - Set up alerting rules

5. **Setup CI/CD Integration**
   - Connect GitHub Actions to deployment scripts
   - Automatic deployments on tag push
   - Automated rollback on failures

## Files Overview

```
deploy/
├── k8s-deploy.sh              # Kubernetes deployment script
├── swarm-deploy.sh            # Docker Swarm deployment script
├── PHASE6_DEPLOY.md          # This file

k8s/
├── namespace.yaml             # Kubernetes namespace
├── configmap.yaml             # Configuration and metadata
├── deployment.yaml            # Rolling + Blue-Green deployments
├── rbac.yaml                  # RBAC and service accounts
├── service.yaml               # Services, HPA, PDB

swarm/
├── docker-compose.swarm.yml   # Docker Swarm composition
├── nginx.conf                 # Nginx load balancer config
```

## Support and Documentation

For detailed deployment information:
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

**Phase 6 Complete** ✅
