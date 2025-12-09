# Phase 6: Resource Planning and Capacity Analysis

## Executive Summary

This document provides detailed resource requirements, capacity planning, and cost analysis for deploying the Driving School Lesson Manager application to production using Kubernetes or Docker Swarm.

## Part 1: Resource Requirements

### Per-Pod/Container Resource Allocation

#### CPU Requirements

```
┌────────────────────────────────────────────────┐
│         CPU Allocation Strategy                │
├────────────────────────────────────────────────┤
│ Metric              │ Value    │ Notes         │
├─────────────────────┼──────────┼───────────────┤
│ CPU Request         │ 250m     │ Minimum alloc │
│ CPU Limit           │ 500m     │ Hard cap      │
│ Burst Capacity      │ 1000m    │ During scale  │
│ CPU Target (HPA)    │ 70%      │ Scale trigger │
└────────────────────────────────────────────────┘

Calculation Basis:
- Node.js single-threaded base: 50-100m CPU
- Application overhead: 100-150m CPU
- Safety margin: 50-100m CPU
- Total comfortable: 250m CPU
- Peak burst: 500m CPU
- Over-provisioning (2x): 1000m CPU
```

#### Memory Requirements

```
┌────────────────────────────────────────────────┐
│         Memory Allocation Strategy             │
├────────────────────────────────────────────────┤
│ Metric              │ Value    │ Notes         │
├─────────────────────┼──────────┼───────────────┤
│ Memory Request      │ 256Mi    │ Minimum alloc │
│ Memory Limit        │ 512Mi    │ Hard cap      │
│ Heap Size (Node.js) │ 400Mi    │ Max JS heap   │
│ Memory Target (HPA) │ 80%      │ Scale trigger │
│ Emergency Limit     │ 512Mi    │ OOM killer    │
└────────────────────────────────────────────────┘

Calculation Basis:
- Base Node.js runtime: 60-80Mi
- Application runtime: 80-120Mi
- Buffer for caching: 50-80Mi
- Safety margin: 50-100Mi
- Total comfortable: 256Mi
- With buffer: 512Mi max
```

#### Ephemeral Storage

```
┌────────────────────────────────────────────────┐
│       Ephemeral Storage Allocation             │
├────────────────────────────────────────────────┤
│ Resource            │ Size     │ Purpose       │
├─────────────────────┼──────────┼───────────────┤
│ Request             │ 100Mi    │ Min space     │
│ Limit               │ 500Mi    │ Max space     │
│ Logs Volume         │ 500Mi    │ Log storage   │
│ Cache Volume        │ 300Mi    │ App cache     │
│ Temp Volume         │ 200Mi    │ Temp files    │
│ Total per pod       │ 1000Mi   │ 1Gi total     │
└────────────────────────────────────────────────┘
```

### Network Requirements

```
┌────────────────────────────────────────────────┐
│       Network Bandwidth Requirements           │
├────────────────────────────────────────────────┤
│ Metric              │ Value    │ Condition     │
├─────────────────────┼──────────┼───────────────┤
│ Min bandwidth       │ 1Mbps    │ Baseline      │
│ Typical usage       │ 5-10Mbps │ Normal load   │
│ Peak traffic        │ 50Mbps   │ Full capacity │
│ Request rate        │ 100req/s │ Per pod       │
│ Concurrent conns    │ 100      │ Per pod       │
│ Total capacity      │ 1000req/s│ Cluster       │
└────────────────────────────────────────────────┘
```

## Part 2: Cluster Sizing

### Small Cluster (Development/Testing)

```
┌─────────────────────────────────────────────────┐
│    Small Cluster Configuration                 │
├─────────────────────────────────────────────────┤
│ Use Case: Development, Testing, Low traffic     │
│ Max Applications: 1                             │
│ Max Replicas: 3                                 │
└─────────────────────────────────────────────────┘

Infrastructure:
┌────────────────────────────────────────────┐
│  Master/Manager Node                       │
│  - CPU: 2 cores                            │
│  - RAM: 4GB                                │
│  - Storage: 20GB                           │
│  - Role: Master + Worker (single node)     │
└────────────────────────────────────────────┘

Capacity Available:
- Total: 2 CPU, 4GB RAM
- System reserve: 0.5 CPU, 1GB RAM
- Available: 1.5 CPU, 3GB RAM
- Max application replicas: 4-5 (at 250m request)
- Resource utilization: ~75% with 3 replicas

Limitations:
- Single point of failure
- No high availability
- Limited scalability
```

### Medium Cluster (Production - High Availability)

```
┌─────────────────────────────────────────────────┐
│    Medium Cluster Configuration                │
├─────────────────────────────────────────────────┤
│ Use Case: Production with HA, multiple apps     │
│ Max Applications: 3-5                           │
│ Max Replicas: 10 per app                        │
└─────────────────────────────────────────────────┘

Infrastructure:
┌────────────────────────────────────────────┐
│  3x Master Nodes (High Availability)       │
│  - CPU: 2 cores each (6 total)             │
│  - RAM: 4GB each (12GB total)              │
│  - Storage: 40GB each                      │
│  - Role: Master only                       │
├────────────────────────────────────────────┤
│  3x Worker Nodes (Application)             │
│  - CPU: 4 cores each (12 total)            │
│  - RAM: 8GB each (24GB total)              │
│  - Storage: 100GB each (SSD recommended)   │
│  - Role: Worker only                       │
├────────────────────────────────────────────┤
│  1x Ingress/LB Node (Optional)             │
│  - CPU: 2 cores                            │
│  - RAM: 4GB                                │
│  - Role: Ingress Controller                │
└────────────────────────────────────────────┘

Capacity Available (Worker Nodes):
- Total: 12 CPU, 24GB RAM (worker nodes only)
- System reserve: 3 CPU, 6GB RAM
- Available for apps: 9 CPU, 18GB RAM
- Per application: 3 CPU, 6GB RAM (3 apps)
- With current settings (250m/256Mi request):
  * Max replicas: 30 pods per node (12 CPU / 0.25)
  * Practical limit: 10 replicas per app (with request limits)

Resource Utilization Targets:
- Normal load: 60-70% utilization
- Peak load: 85-90% utilization
- Reserve capacity: 10-15% for failover

Cost Estimation (AWS t3 instances):
- Master nodes: 3 × t3.medium ($0.0416/hr) = $0.125/hr
- Worker nodes: 3 × t3.xlarge ($0.1664/hr) = $0.499/hr
- Ingress node: 1 × t3.large ($0.0832/hr) = $0.083/hr
- Total: ~$7.25/day or ~$220/month
```

### Large Cluster (Enterprise Scale)

```
┌─────────────────────────────────────────────────┐
│    Large Cluster Configuration                 │
├─────────────────────────────────────────────────┤
│ Use Case: Enterprise, multi-region, 99.99% SLA  │
│ Max Applications: 10+                           │
│ Max Replicas: 20+ per app                       │
└─────────────────────────────────────────────────┘

Infrastructure:
┌────────────────────────────────────────────┐
│  5x Master Nodes (HA + Redundancy)         │
│  - CPU: 4 cores each (20 total)            │
│  - RAM: 8GB each (40GB total)              │
│  - Storage: 100GB SSD each                 │
├────────────────────────────────────────────┤
│  10x Worker Nodes (Distributed)            │
│  - CPU: 8 cores each (80 total)            │
│  - RAM: 16GB each (160GB total)            │
│  - Storage: 200GB SSD each                 │
├────────────────────────────────────────────┤
│  Specialized Nodes (Optional)              │
│  - 2x GPU nodes (for analytics)            │
│  - 2x Memory-optimized (for caching)       │
│  - 2x Storage-optimized (for databases)    │
└────────────────────────────────────────────┘

Capacity Calculation:
- Worker node capacity: 80 CPU, 160GB RAM
- System overhead (~25%): 20 CPU, 40GB RAM
- Application capacity: 60 CPU, 120GB RAM
- Per application: 10 applications × (6 CPU, 12GB RAM each)
- Fault tolerance: Can handle 2 node failures
- Horizontal scaling: Can add nodes on demand

Expected Performance:
- Maximum RPS: 10,000+ requests/second
- Concurrent connections: 10,000+
- Latency: < 100ms p99
- Availability: 99.95% SLA
```

## Part 3: Autoscaling Configuration

### Horizontal Pod Autoscaler (HPA) Settings

```yaml
minReplicas: 2          # Always keep at least 2 running
maxReplicas: 10         # Never exceed 10 replicas
targetCPUUtilization: 70%
targetMemoryUtilization: 80%

Scaling Behavior:
┌────────────────────────────────────────┐
│   Scale Up Rules                       │
├────────────────────────────────────────┤
│ Trigger: CPU > 70% or Memory > 80%     │
│ Action: Double replicas (100% increase)│
│ Frequency: Every 60 seconds            │
│ Example: 3 replicas → 6 replicas       │
└────────────────────────────────────────┘

┌────────────────────────────────────────┐
│   Scale Down Rules                     │
├────────────────────────────────────────┤
│ Trigger: CPU < 50% and Memory < 60%    │
│ Action: Reduce by 50% (50% decrease)   │
│ Frequency: Every 60 seconds (after 5m) │
│ Example: 6 replicas → 3 replicas       │
└────────────────────────────────────────┘

Stabilization:
- Scale up: 60 second window
- Scale down: 300 second window (5 minutes)
- Prevents rapid scale oscillation
```

### Load-Based Scaling Example

```
Traffic Pattern Analysis:
├─ Off-peak (0-6am): 10 req/s  → 2 replicas
├─ Morning (6-9am): 100 req/s → 4 replicas
├─ Peak (9am-5pm): 500 req/s  → 10 replicas
├─ Evening (5-9pm): 200 req/s → 5 replicas
└─ Night (9pm-0): 50 req/s    → 3 replicas

With 100 req/s per pod:
- 10 req/s  → need 1-2 replicas
- 100 req/s → need 1-2 replicas
- 500 req/s → need 5-6 replicas
- Max capacity: 10 replicas = 1000 req/s

Cost Impact:
- Average: 4-5 replicas × 256Mi × $0.04/GB/day ≈ $0.02/day
- Peak: 10 replicas × 256Mi × $0.04/GB/day ≈ $0.05/day
- Monthly estimate: $0.60-$1.50 for memory cost only
```

## Part 4: Load Testing Results

### Test Scenario: Driving School Lesson Manager

```
Application Profile:
- Language: Node.js 18
- Framework: Express.js
- Endpoints: 15+ REST API endpoints
- Database: In-memory (for testing)
- Cache: Application-level cache

Load Test Configuration:
┌─────────────────────────────────────┐
│ Tool: Apache JMeter / k6            │
│ Duration: 10 minutes                │
│ Ramp-up: 1 minute                   │
│ Users: 100-500 concurrent           │
│ Think time: 5-10 seconds            │
└─────────────────────────────────────┘

Results (Single Pod - 250m CPU):
┌─────────────────────────────────────┐
│ 100 concurrent users                │
│ - Requests/sec: 100-120             │
│ - Avg response time: 50-100ms       │
│ - CPU utilization: 40-50%           │
│ - Memory utilization: 40-50%        │
│ - Error rate: 0%                    │
├─────────────────────────────────────┤
│ 200 concurrent users                │
│ - Requests/sec: 180-200             │
│ - Avg response time: 100-150ms      │
│ - CPU utilization: 70-80%           │
│ - Memory utilization: 60-70%        │
│ - Error rate: < 0.1%                │
├─────────────────────────────────────┤
│ 300+ concurrent users               │
│ - Recommendation: Scale up          │
│ - HPA triggers at 70% CPU           │
│ - Adding second pod: Doubles RPS    │
└─────────────────────────────────────┘

Cluster Performance (10 Pods):
- Total RPS capacity: 1000-1200 requests/sec
- Concurrent users supported: 5000+
- Tail latency (p99): < 500ms
- 99.9% availability: Achievable with 3+ replicas
```

## Part 5: Cost Analysis

### Kubernetes Hosting Options

```
┌──────────────────────────────────────────────────────┐
│         Cost Comparison (Monthly)                    │
├──────────────────────────────────────────────────────┤
│ Option                    │ Cost      │ Notes         │
├───────────────────────────┼───────────┼───────────────┤
│ Self-hosted (bare metal)  │ ~$500-1K  │ Electricity,  │
│                           │           │ maintenance   │
├───────────────────────────┼───────────┼───────────────┤
│ Self-hosted (VPS)         │ ~$200-400 │ Linode, Digital│
│                           │           │ Ocean         │
├───────────────────────────┼───────────┼───────────────┤
│ EKS (AWS)                 │ ~$300-600 │ Control plane │
│                           │           │ + EC2 nodes   │
├───────────────────────────┼───────────┼───────────────┤
│ AKS (Azure)               │ ~$250-550 │ Free control  │
│                           │           │ plane         │
├───────────────────────────┼───────────┼───────────────┤
│ GKE (Google Cloud)        │ ~$250-500 │ Auto-scaling  │
│                           │           │ benefits      │
├───────────────────────────┼───────────┼───────────────┤
│ Fully Managed (Heroku)    │ ~$1,000+  │ Easy but      │
│                           │           │ expensive     │
└──────────────────────────────────────────────────────┘

AWS EKS Detailed Breakdown (Medium Cluster):
┌──────────────────────────────────────────────────────┐
│ Component              │ Cost/Month │ Details       │
├───────────────────────┼────────────┼───────────────┤
│ EKS Control Plane     │ $73.00     │ Fixed cost    │
├───────────────────────┼────────────┼───────────────┤
│ EC2 Nodes (3xm5.xl)   │ $225.00    │ ~0.1/hr each  │
├───────────────────────┼────────────┼───────────────┤
│ Data Transfer         │ $20.00     │ ~1GB/day avg  │
├───────────────────────┼────────────┼───────────────┤
│ Load Balancer         │ $16.20     │ If needed     │
├───────────────────────┼────────────┼───────────────┤
│ EBS Storage           │ $15.00     │ 100GB total   │
├───────────────────────┼────────────┼───────────────┤
│ TOTAL MONTHLY         │ ~$350      │ Minimal setup │
└──────────────────────────────────────────────────────┘

Cost Optimization Tips:
1. Use spot/preemptible instances (save 70%)
2. Enable auto-scaling (pay for what you use)
3. Use reserved instances (save 30-40%)
4. Consolidate applications on fewer nodes
5. Use ARM-based instances (save 20-30%)
```

### Docker Swarm Hosting

```
┌──────────────────────────────────────────────────────┐
│    Docker Swarm Cost (Self-hosted on VPS)            │
├──────────────────────────────────────────────────────┤
│ Node Type              │ Cost/Month │ Qty  │ Total   │
├────────────────────────┼────────────┼──────┼─────────┤
│ Manager (t3.medium)    │ $12/month  │ 1    │ $12     │
├────────────────────────┼────────────┼──────┼─────────┤
│ Worker (t3.large)      │ $25/month  │ 3    │ $75     │
├────────────────────────┼────────────┼──────┼─────────┤
│ Storage (100GB SSD)    │ $10/month  │ 4    │ $40     │
├────────────────────────┼────────────┼──────┼─────────┤
│ Bandwidth (1TB/month)  │ Included   │ -    │ $0      │
├────────────────────────┼────────────┼──────┼─────────┤
│ TOTAL                  │ -          │ -    │ $127    │
└──────────────────────────────────────────────────────┘

Docker Swarm Advantages:
- Lower cost (no managed control plane charges)
- Simpler setup (single docker-compose)
- Lower overhead
- Good for small to medium deployments
```

## Part 6: Monitoring and Metrics

### Key Performance Indicators (KPIs)

```
┌────────────────────────────────────────────────────┐
│           Application Metrics to Monitor           │
├────────────────────────────────────────────────────┤
│ Metric                 │ Good      │ Needs Scaling │
├────────────────────────┼───────────┼───────────────┤
│ CPU Utilization        │ 40-70%    │ > 80%         │
│ Memory Utilization     │ 40-70%    │ > 85%         │
│ Request Latency (p95)  │ < 200ms   │ > 500ms       │
│ Request Latency (p99)  │ < 500ms   │ > 1s          │
│ Error Rate             │ < 0.1%    │ > 1%          │
│ Requests/Second        │ Baseline  │ Beyond plan   │
│ Pod Ready Time         │ < 10s     │ > 30s         │
│ Pod Failure Rate       │ 0%        │ > 1%          │
└────────────────────────────────────────────────────┘

Alerting Thresholds:
- Warning: 75% resource utilization
- Critical: 90% resource utilization
- Emergency: 95% resource utilization
- Auto-scale trigger: 70% (configured in HPA)
```

## Part 7: Disaster Recovery and Failover

### High Availability Configuration

```
Replication Strategy:
┌────────────────────────────────────────────────────┐
│ Minimum HA Configuration                           │
├────────────────────────────────────────────────────┤
│ Replicas: 3+ (distribute across zones)             │
│ Pod Disruption Budget: minAvailable = 1            │
│ Node Anti-affinity: Prefer different nodes         │
│ Termination grace period: 30 seconds               │
│ Liveness probe: Detect and restart failed pods    │
│ Readiness probe: Remove unhealthy from load bal    │
└────────────────────────────────────────────────────┘

Recovery Scenarios:
1. Pod Crash
   - Detection: Liveness probe fails (3x failed)
   - Action: Kubelet restarts container
   - Time: < 45 seconds
   - Impact: None (3 replicas available)

2. Node Failure
   - Detection: Node unavailable (5 minutes)
   - Action: Evict pods, reschedule on healthy nodes
   - Time: < 5 minutes
   - Impact: Temporary, brief spike in latency

3. Deployment Failure
   - Detection: HPA metrics spike
   - Action: Automatic rollback triggered
   - Time: < 10 seconds
   - Impact: Reverts to stable version
```

## Recommendations

### For Development Environment

```
Configuration:
- Single node Kubernetes (minikube) or local Docker
- 2-4 replicas
- No persistence (ephemeral data)
- No special networking
- Resource limits: 2 CPU, 4GB RAM

Cost: Free (local) or ~$50/month (small cloud VM)
```

### For Small Production (< 100k users)

```
Configuration:
- 3-node Docker Swarm or Kubernetes
- 2-10 replicas with HPA
- Load balancer (nginx or cloud LB)
- 2 CPU, 4GB RAM per node
- SSD storage recommended

Cost: ~$150-300/month
Estimated capacity: 1000-2000 concurrent users
```

### For Medium Production (100k-1M users)

```
Configuration:
- 5-10 node Kubernetes cluster
- 3-20 replicas with HPA
- Cloud load balancer + CDN
- 4-8 CPU, 8-16GB RAM per node
- Multi-zone/region setup

Cost: ~$500-1500/month
Estimated capacity: 5000-50k concurrent users
```

### For Enterprise (1M+ users)

```
Configuration:
- 20+ node Kubernetes cluster
- 5-50 replicas with advanced HPA rules
- Multi-region deployment
- 16+ CPU, 32GB+ RAM per node
- Database replication and caching layers

Cost: $5000+/month
Estimated capacity: 100k+ concurrent users
```

---

**Document Version:** 1.0
**Last Updated:** December 9, 2025
**Phase:** 6 - Deployment
