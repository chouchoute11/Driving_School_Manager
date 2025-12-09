#!/bin/bash

################################################################################
# Docker Swarm Deployment Script
# Deploy the Driving School application to Docker Swarm cluster
# Supports rolling updates, scaling, and health monitoring
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVICE_NAME="driving_lesson_manager_driving-school-app"
COMPOSE_FILE="swarm/docker-compose.swarm.yml"
DOCKER_IMAGE="chouchoute11/practical_cat_driving_lesson_school_management:1.0.1"
UPDATE_TIMEOUT=300

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

# Check if docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    log_success "Docker found: $(docker version --short | head -1)"
}

# Check if swarm is initialized
check_swarm_mode() {
    log_info "Checking Docker Swarm mode..."
    
    if ! docker info | grep -q "Swarm: active"; then
        log_error "Docker Swarm is not active"
        log_info "Initialize Swarm with: docker swarm init"
        exit 1
    fi
    
    log_success "Docker Swarm is active"
    docker info | grep -A 3 "Swarm:"
}

# Check compose file exists
check_compose_file() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        log_error "Compose file not found: $COMPOSE_FILE"
        exit 1
    fi
    log_success "Compose file found: $COMPOSE_FILE"
}

# Deploy stack
deploy_stack() {
    log_info "Deploying stack..."
    
    docker stack deploy -c "$COMPOSE_FILE" driving_lesson_manager
    
    log_success "Stack deployment initiated"
    log_info "Waiting for services to start..."
    sleep 5
}

# Check service status
check_service_status() {
    log_info "Checking service status..."
    
    docker service ls --filter "label=app=driving-school"
}

# Check task/container status
check_task_status() {
    log_info "Checking task status..."
    
    docker service ps driving_lesson_manager_driving-school-app --no-trunc
}

# Get service logs
get_service_logs() {
    local service=$1
    local lines=${2:-100}
    
    log_info "Getting logs from service '$service' (last $lines lines)..."
    docker service logs --tail "$lines" "$service"
}

# Update service image
update_service_image() {
    local service=$1
    local new_image=$2
    
    log_info "Updating service '$service' with image '$new_image'..."
    
    docker service update --image "$new_image" "$service"
    
    log_success "Service update initiated"
    log_info "Waiting for update to complete..."
    
    # Monitor update progress
    local elapsed=0
    while [ $elapsed -lt $UPDATE_TIMEOUT ]; do
        local running=$(docker service ps "$service" --filter "desired-state=running" -q | wc -l)
        local replicas=$(docker service inspect "$service" --format '{{.Spec.Mode.Replicated.Replicas}}')
        
        if [ "$running" -eq "$replicas" ]; then
            log_success "Service update completed successfully"
            return 0
        fi
        
        echo -n "."
        sleep 2
        ((elapsed+=2))
    done
    
    log_error "Service update timed out after ${UPDATE_TIMEOUT}s"
    return 1
}

# Perform rolling update
perform_rolling_update() {
    local new_image=$1
    
    log_info "Performing rolling update with image: $new_image"
    
    # Update service with rolling update parameters
    docker service update \
        --image "$new_image" \
        --update-parallelism 1 \
        --update-delay 10s \
        --update-failure-action rollback \
        --update-monitor 30s \
        driving_lesson_manager_driving-school-app
    
    log_info "Rolling update initiated, monitoring progress..."
    check_task_status
}

# Scale service
scale_service() {
    local replicas=$1
    
    log_info "Scaling service to $replicas replicas..."
    
    docker service scale driving_lesson_manager_driving-school-app="$replicas"
    
    log_success "Service scaled to $replicas replicas"
    check_task_status
}

# Rollback service
rollback_service() {
    local service=$1
    
    log_warning "Rolling back service '$service'..."
    
    docker service update --rollback "$service"
    
    log_success "Rollback initiated"
    check_task_status
}

# Get service resource usage
get_resource_usage() {
    log_info "Resource usage for containers:"
    
    local containers=$(docker ps --filter "label=app=driving-school" -q)
    
    for container in $containers; do
        docker stats --no-stream "$container"
    done
}

# Get service events
get_events() {
    log_info "Recent Docker events:"
    
    docker events --filter "label=app=driving-school" --since 1m --until now
}

# Health check
health_check() {
    log_info "Performing health check..."
    
    local replicas=$(docker service inspect driving_lesson_manager_driving-school-app --format '{{.Spec.Mode.Replicated.Replicas}}')
    local running=$(docker service ps driving_lesson_manager_driving-school-app --filter "desired-state=running" -q | wc -l)
    
    log_info "Replicas: Running=$running, Desired=$replicas"
    
    if [ "$running" -eq "$replicas" ]; then
        log_success "All replicas are running"
    else
        log_warning "Some replicas are not running"
    fi
    
    # Check health of each container
    local containers=$(docker ps --filter "label=app=driving-school" -q)
    
    for container in $containers; do
        local health=$(docker inspect "$container" --format '{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
        local name=$(docker inspect "$container" --format '{{.Name}}' | sed 's/^///')
        
        if [ "$health" = "healthy" ]; then
            log_success "Container $name: $health"
        else
            log_warning "Container $name: $health"
        fi
    done
}

# Remove stack
remove_stack() {
    log_warning "This will remove the entire stack and all services"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        docker stack rm driving_lesson_manager
        log_success "Stack removed"
    else
        log_info "Removal cancelled"
    fi
}

# Get detailed service info
get_service_info() {
    log_info "Service configuration:"
    docker service inspect driving_lesson_manager_driving-school-app
}

################################################################################
# Main Menu
################################################################################

show_usage() {
    cat << EOF
${BLUE}Docker Swarm Deployment Manager${NC}

${GREEN}Usage:${NC}
  $0 <command> [options]

${GREEN}Commands:${NC}
  deploy              Deploy stack to Docker Swarm
  update <image>      Update service with new image (rolling)
  rollback            Rollback service to previous version
  scale <replicas>    Scale service to specified number of replicas
  status              Get service status
  tasks               Get task/container status
  logs <service>      Get logs from service
  health              Perform health check
  resources           Get resource usage
  events              Get recent events
  info                Get detailed service info
  remove              Remove entire stack
  help                Show this help message

${GREEN}Examples:${NC}
  $0 deploy
  $0 update docker.io/user/image:v1.0.2
  $0 rollback
  $0 scale 5
  $0 logs driving_lesson_manager_driving-school-app
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
    check_docker
    check_swarm_mode
    check_compose_file
    
    case "$command" in
        deploy)
            deploy_stack
            sleep 3
            check_service_status
            check_task_status
            health_check
            ;;
        
        update)
            if [ $# -eq 0 ]; then
                log_error "Image URL required for update command"
                echo "Usage: $0 update <image>"
                exit 1
            fi
            perform_rolling_update "$1"
            ;;
        
        rollback)
            rollback_service "driving_lesson_manager_driving-school-app"
            ;;
        
        scale)
            if [ $# -eq 0 ]; then
                log_error "Number of replicas required for scale command"
                echo "Usage: $0 scale <replicas>"
                exit 1
            fi
            scale_service "$1"
            ;;
        
        status)
            check_service_status
            check_task_status
            ;;
        
        tasks)
            check_task_status
            ;;
        
        logs)
            if [ $# -eq 0 ]; then
                get_service_logs "driving_lesson_manager_driving-school-app"
            else
                get_service_logs "$1" "${2:-100}"
            fi
            ;;
        
        health)
            health_check
            ;;
        
        resources)
            get_resource_usage
            ;;
        
        events)
            get_events
            ;;
        
        info)
            get_service_info
            ;;
        
        remove)
            remove_stack
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
