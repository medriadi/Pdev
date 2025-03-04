#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Installing Container Tools..."

# Update package manager
update_pkg_manager

# Install Docker
install_docker() {
    if ! command_exists "docker"; then
        local container_runtime=$(get_config_value "CONTAINER_RUNTIME" "docker")
        if [ "$container_runtime" = "docker" ]; then
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh
            rm get-docker.sh
            usermod -aG docker $SUDO_USER
            systemctl start docker
            systemctl enable docker
            
            # Install Docker Compose V2
            mkdir -p /usr/local/lib/docker/cli-plugins
            curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
            chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
            
            # Configure Docker daemon with better defaults
            cat > /etc/docker/daemon.json << EOF
{
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "default-address-pools": [
        {
            "base": "172.17.0.0/16",
            "size": 24
        }
    ],
    "features": {
        "buildkit": true
    }
}
EOF
            systemctl restart docker
        fi
    fi
}

# Install Podman
install_podman() {
    local container_runtime=$(get_config_value "CONTAINER_RUNTIME" "docker")
    if [ "$container_runtime" = "podman" ] || [ "$(get_config_value INSTALL_MULTIPLE_RUNTIMES false)" = "true" ]; then
        install_package "podman"
        install_package "buildah"
        install_package "skopeo"
        
        # Configure Podman to work rootless
        if [ "$SUDO_USER" ]; then
            su - $SUDO_USER -c "podman system migrate"
            su - $SUDO_USER -c "systemctl --user enable podman.socket"
        fi
    fi
}

# Install Kubernetes tools
install_kubernetes() {
    if [ "$(get_config_value INSTALL_KUBERNETES true)" = "true" ]; then
        # Install kubectl
        if ! command_exists "kubectl"; then
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
        fi

        # Install Minikube
        if ! command_exists "minikube"; then
            curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
            install minikube-linux-amd64 /usr/local/bin/minikube
            rm minikube-linux-amd64
        fi

        # Install Helm
        if ! command_exists "helm"; then
            curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
        fi

        # Install k9s
        if ! command_exists "k9s"; then
            curl -sL https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz | tar xz -C /usr/local/bin k9s
            chmod +x /usr/local/bin/k9s
        fi

        # Install kind if development tools are enabled
        if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
            if ! command_exists "kind"; then
                curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
                chmod +x ./kind
                mv ./kind /usr/local/bin/kind
            fi
        fi
    fi
}

# Install container development tools
install_container_tools() {
    if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
        # Install useful container tools
        install_package "dive"  # For analyzing docker images
        install_package "ctop"  # For container monitoring
        
        # Install lazydocker for better Docker TUI
        if ! command_exists "lazydocker"; then
            curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
        fi
    fi
}

# Main installation
install_docker
install_podman
install_kubernetes
install_container_tools

# Configure default runtime
DEFAULT_RUNTIME=$(get_config_value "CONTAINER_RUNTIME" "docker")
if [ "$DEFAULT_RUNTIME" = "podman" ]; then
    # Set up podman as default container runtime
    if [ -f "/usr/local/bin/docker" ]; then
        mv /usr/local/bin/docker /usr/local/bin/docker.bak
    fi
    ln -sf $(which podman) /usr/local/bin/docker
fi

# Install monitoring tools if configured
if [ "$(get_config_value INSTALL_MONITORING true)" = "true" ]; then
    install_package "prometheus"
    install_package "grafana"
    systemctl start prometheus
    systemctl enable prometheus
    systemctl start grafana-server
    systemctl enable grafana-server
fi

log_info "Container Tools installation completed!"