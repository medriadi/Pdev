#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Validating container tools installations..."

# Test Docker
test_docker() {
    if command_exists "docker"; then
        if docker run --rm hello-world | grep -q "Hello from Docker!"; then
            # Test Docker Compose
            if command_exists "docker-compose" || docker compose version >/dev/null 2>&1; then
                log_info "Docker and Docker Compose: OK"
                return 0
            fi
        fi
    fi
    log_error "Docker validation failed"
    return 1
}

# Test Podman
test_podman() {
    if command_exists "podman"; then
        if podman run --rm hello-world | grep -q "Hello from Docker!"; then
            # Test Buildah and Skopeo
            if command_exists "buildah" && command_exists "skopeo"; then
                log_info "Podman, Buildah, and Skopeo: OK"
                return 0
            fi
        fi
    fi
    log_error "Podman validation failed"
    return 1
}

# Test Kubernetes tools
test_kubernetes() {
    local k8s_tools_ok=true

    # Test kubectl
    if ! command_exists "kubectl"; then
        log_error "kubectl not found"
        k8s_tools_ok=false
    fi

    # Test minikube
    if ! command_exists "minikube"; then
        log_error "minikube not found"
        k8s_tools_ok=false
    fi

    # Test helm
    if ! command_exists "helm"; then
        log_error "helm not found"
        k8s_tools_ok=false
    fi

    # Test k9s
    if ! command_exists "k9s"; then
        log_error "k9s not found"
        k8s_tools_ok=false
    fi

    if [ "$k8s_tools_ok" = true ]; then
        # Try starting minikube if not running
        if ! minikube status | grep -q "Running"; then
            minikube start --driver=docker
        fi

        # Test basic kubectl functionality
        if kubectl get nodes | grep -q "minikube"; then
            log_info "Kubernetes tools: OK"
            return 0
        fi
    fi

    log_error "Kubernetes tools validation failed"
    return 1
}

# Test container monitoring tools
test_monitoring_tools() {
    local monitoring_ok=true

    # Test dive (for Docker image analysis)
    if ! command_exists "dive"; then
        log_error "dive not found"
        monitoring_ok=false
    fi

    # Test ctop (for container monitoring)
    if ! command_exists "ctop"; then
        log_error "ctop not found"
        monitoring_ok=false
    fi

    # Test lazydocker
    if ! command_exists "lazydocker"; then
        log_error "lazydocker not found"
        monitoring_ok=false
    fi

    if [ "$monitoring_ok" = true ]; then
        log_info "Container monitoring tools: OK"
        return 0
    fi

    log_error "Container monitoring tools validation failed"
    return 1
}

# Create a test container environment
create_test_environment() {
    # Create a test docker-compose file
    cat > test-docker-compose.yml << EOF
version: '3'
services:
  test-web:
    image: nginx:alpine
    ports:
      - "8080:80"
EOF

    # Test docker-compose functionality
    if docker compose -f test-docker-compose.yml up -d && \
       curl -s http://localhost:8080 | grep -q "Welcome to nginx" && \
       docker compose -f test-docker-compose.yml down; then
        rm test-docker-compose.yml
        log_info "Docker Compose environment test: OK"
        return 0
    fi

    rm test-docker-compose.yml
    log_error "Docker Compose environment test failed"
    return 1
}

# Test container networking
test_container_networking() {
    # Create a test network
    if docker network create test-network && \
       docker run --rm --network test-network alpine ping -c 1 google.com && \
       docker network rm test-network; then
        log_info "Container networking: OK"
        return 0
    fi

    log_error "Container networking validation failed"
    return 1
}

# Run all tests
test_docker
test_podman
test_kubernetes
test_monitoring_tools
create_test_environment
test_container_networking

# Clean up any remaining test resources
cleanup() {
    docker system prune -f >/dev/null 2>&1
    minikube stop >/dev/null 2>&1
}

# Register cleanup function to run on script exit
trap cleanup EXIT