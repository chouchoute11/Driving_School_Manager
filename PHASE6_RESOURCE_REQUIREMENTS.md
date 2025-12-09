# Phase 6: Resource Requirements and Capacity Planning

## Executive Summary

The Driving School Lesson Manager application is optimized for efficient resource utilization with the following profile:

- **Per Pod CPU**: 100m request / 500m limit
- **Per Pod Memory**: 128Mi request / 512Mi limit
- **Recommended Replicas**: 3-10 (auto-scaled)
- **Node Requirement**: 2 core / 2GB minimum

## Resource Analysis

### Application Profiling

Based on the application architecture (Node.js + Express):

**Memory Breakdown:**
```
Node.js Runtime:        60-80 MB
Dependencies (Express): 30-40 MB
Application Code:       10-15 MB
Runtime Buffer:         20-30 MB
─────────────────────────────────
Total Base:            120-165 MB
```

**CPU Breakdown:**
```
Idle State:             5-10m
Request Processing:     30-40m
Database Queries:       20-30m
Concurrency Buffer:     10-20m
─────────────────────────────────
Peak Per Pod:          65-100m
```

### Request Specifications

```yaml
resources:
  requests:
    cpu: 100m              # Guaranteed minimum allocation
    memory: 128Mi          # Guaranteed minimum allocation
    ephemeralStorage: 1Gi  # Temporary storage (logs, cache)
  limits:
    cpu: 500m              # Maximum allowed (5x request)
    memory: 512Mi          # Maximum allowed (4x request)
    ephemeralStorage: 2Gi  # Maximum storage growth
```

### Limit Rationale

**CPU Limit (500m = 5x request):**
- Allows burst handling during traffic spikes
- Prevents runaway processes
- Typical ratio: 3-5x for web applications
- Choice of 5x balances performance and stability

**Memory Limit (512Mi = 4x request):**
- Safety margin for heap growth
- Prevents OutOfMemory (OOM) kills
- Allows temporary data structures
- Typical ratio: 2-4x for Node.js apps
- Choice of 4x prevents unnecessary restarts

**Storage Limit (2Gi):**
- Logs: ~500-700MB per pod (with rotation)
- Temporary files: ~500-800MB
- Cache: ~200-300MB
- Safety margin: ~300-500MB

## Scaling Scenarios

### Scenario 1: Single Pod (Development)
```
Resource Allocation:
  CPU Request:  100m
  CPU Limit:    500m
  Memory Request: 128Mi
  Memory Limit:  512Mi
  
Node Requirement: 0.1 core / 128Mi
```

### Scenario 2: Three Pods (Production - Standard)
```
Resource Allocation:
  CPU Request:  300m (100m × 3)
  CPU Limit:    1.5 core (500m × 3)
  Memory Request: 384Mi (128Mi × 3)
  Memory Limit:  1.5Gi (512Mi × 3)
  
Node Requirement: 0.3 cores / 384Mi per node
Recommended Node: 2 cores / 2Gi RAM (4x safety)
```

### Scenario 3: Six Pods (High Availability)
```
Resource Allocation:
  CPU Request:  600m (100m × 6)
  CPU Limit:    3.0 cores (500m × 6)
  Memory Request: 768Mi (128Mi × 6)
  Memory Limit:  3Gi (512Mi × 6)
  
Node Requirement: 
  Option 1: 2 nodes × (0.3 cores / 384Mi) per pod
  Option 2: 1 node × (0.6 cores / 768Mi)
Recommended: 2 nodes with 2 cores / 2Gi each
```

### Scenario 4: Ten Pods (Maximum Autoscale)
```
Resource Allocation:
  CPU Request:  1.0 core (100m × 10)
  CPU Limit:    5.0 cores (500m × 10)
  Memory Request: 1.28Gi (128Mi × 10)
  Memory Limit:  5.0Gi (512Mi × 10)
  
Node Requirement:
  Option 1: 5 nodes × (0.2 cores / 256Mi) per node
  Option 2: 3 nodes × (0.35 cores / 427Mi) per node
Recommended: 3 nodes with 2 cores / 2Gi each
```

## Auto-scaling Configuration

### Horizontal Pod Autoscaler (HPA)

```yaml
minReplicas: 2
maxReplicas: 10

metrics:
  - CPU Utilization: 70%
  - Memory Utilization: 80%

behavior:
  scaleUp:
    - Percent: 100% per 30 seconds
    - Pods: +2 pods per 30 seconds
  scaleDown:
    - Percent: 50% per 5 minutes
```

### Scaling Behavior Example

```
Initial Load: 3 pods
  ↓
CPU reaches 70% (request 300m × 0.7 = 210m actual)
  ↓
Add 1 pod (30 seconds) → 4 pods
CPU reaches 210m / 4 = 52.5m per pod ✅ Back to 52.5%
  ↓
Wait 5 minutes before scaling down
```

## Cluster Capacity Planning

### Minimum Cluster Size

```
1 Kubernetes Master Node:
  - 2 cores
  - 2GB RAM
  - 50GB disk

3 Worker Nodes:
  - 2 cores each
  - 2GB RAM each
  - 50GB disk each

Total: 6 cores, 6GB RAM
```

### Recommended Cluster Size

```
1 Kubernetes Master Node:
  - 4 cores
  - 4GB RAM
  - 100GB disk

3 Worker Nodes:
  - 4 cores each
  - 4GB RAM each
  - 100GB disk each

Total: 12 cores, 12GB RAM

Allocation per node:
  System services: 1 core / 500Mi
  Available for apps: 3 cores / 3.5Gi per node
```

### Large Scale Cluster (100+ microservices)

```
1 Kubernetes Master Node:
  - 8 cores
  - 8GB RAM
  - 200GB disk

5 Worker Nodes:
  - 8 cores each
  - 8GB RAM each
  - 200GB disk each

Total: 40 cores, 40GB RAM
```

## Storage Requirements

### Ephemeral Storage

```
Per Pod:
  Request: 1Gi
  Limit: 2Gi

Purpose:
  - Temporary files
  - Logs (with rotation)
  - Cache
  - Runtime temp data
```

### Persistent Volume (if needed)

```
For database or persistent state:
  - 10Gi per environment (dev/stage/prod)
  - SSD preferred for performance
  - Backup: Daily snapshots
  - Retention: 30 days
```

## Network Requirements

### Bandwidth

```
Per Pod:
  Baseline: 1-5 Mbps
  Peak: 50-100 Mbps
  
3 Pods:
  Baseline: 3-15 Mbps
  Peak: 150-300 Mbps
  
10 Pods:
  Baseline: 10-50 Mbps
  Peak: 500-1000 Mbps
```

### Network Policies

- Internal pod-to-pod: 40Gbps (Kubernetes limit)
- External ingress: Limited by load balancer
- Recommended: 1Gbps+ network interface

## Cost Estimation

### AWS EKS Pricing (Example)

**Control Plane**: $0.10 per hour = $73/month

**Worker Nodes (3 × t3.medium)**:
- Compute: 3 × $0.0416/hour = $91/month
- Storage: 3 × 50GB × $0.10/GB-month = $15/month

**Load Balancer**: $16/month (if used)

**Data Transfer**: ~$5/month (typical)

**Total**: ~$200/month

### Google GKE Pricing (Example)

**Control Plane**: Included in GKE standard

**Worker Nodes (3 × n1-standard-2)**:
- Compute: 3 × $0.095/hour = $209/month
- Storage: 3 × 50GB × $0.17/GB-month = $26/month

**Network**: ~$10/month

**Total**: ~$250/month

### Azure AKS Pricing (Example)

**Control Plane**: Included in AKS

**Worker Nodes (3 × Standard_B2s)**:
- Compute: 3 × $0.074/hour = $163/month
- Storage: 3 × 50GB × $0.05/GB-month = $8/month

**Network**: ~$5/month

**Total**: ~$175/month

## Performance Metrics

### Typical Response Times

```
P50 (Median): 50-100ms
P95 (95th percentile): 200-500ms
P99 (99th percentile): 500-1000ms

Max requests per pod: ~100-200 req/s
```

### Throughput

```
Per Pod: 100-200 req/s
3 Pods: 300-600 req/s
10 Pods: 1000-2000 req/s
```

### Resource Usage Under Load

```
CPU Usage: 50-70% of request (headroom for bursts)
Memory Usage: 70-80% of request (predictable growth)
Network: 10-30 Mbps per pod (normal traffic)
```

## Monitoring and Alerts

### Key Metrics to Monitor

1. **Pod CPU Usage**
   - Alert if > 80% of limit
   - Scale up if > 70% of request

2. **Pod Memory Usage**
   - Alert if > 90% of limit
   - Scale up if > 80% of request

3. **Pod Restart Count**
   - Alert if > 0 restarts per hour

4. **Response Time**
   - Alert if P95 > 1 second

5. **Error Rate**
   - Alert if > 1% of requests

### Recommended Monitoring Tools

- **Prometheus**: Metric collection
- **Grafana**: Visualization
- **AlertManager**: Alerting
- **Jaeger**: Distributed tracing

## Optimization Tips

### 1. Right-size Resources
```bash
# Analyze actual usage
kubectl top pods -n driving-school-manager
kubectl describe node <node-name>

# Adjust requests/limits based on metrics
# Increase by 20-30% for headroom
```

### 2. Enable Pod Disruption Budgets
```yaml
minAvailable: 2  # Keep at least 2 running
```

### 3. Use Horizontal Pod Autoscaling
```yaml
minReplicas: 2
maxReplicas: 10
target: 70% CPU / 80% Memory
```

### 4. Implement Health Checks
```yaml
livenessProbe: Restart if unhealthy
readinessProbe: Remove from service if not ready
startupProbe: Give time to initialize
```

### 5. Use Node Affinity
```yaml
podAntiAffinity: Spread pods across nodes
tolerations: Schedule on special nodes if needed
```

## Capacity Planning Worksheet

```
Expected Users: ___________
Concurrent Users: ___________
Requests per Second: ___________
Average Response Time Target: ___________

Current Setup:
  Replicas: ___________
  Node Type: ___________
  Total CPU: ___________
  Total Memory: ___________

Projected 6-Month Growth:
  Scaling Factor: ___________
  Required CPU: ___________
  Required Memory: ___________
  Required Nodes: ___________

Budget (Monthly): $___________
```

## Checklist

- [ ] Resource requests/limits defined
- [ ] Auto-scaling configured
- [ ] Monitoring and alerts set up
- [ ] Disaster recovery plan in place
- [ ] Load testing completed
- [ ] Performance benchmarks established
- [ ] Cost tracking enabled
- [ ] Capacity planning scheduled (quarterly)
- [ ] Right-sizing review scheduled (monthly)
- [ ] Team trained on scaling procedures

## References

- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [HorizontalPodAutoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Cluster Sizing Calculator](https://kubernetes.io/docs/setup/best-practices/cluster-large/)
- [Performance Tuning Guide](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/)
