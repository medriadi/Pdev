#!/bin/bash

source "$(dirname "$0")/common.sh"

# Function to ask for confirmation
confirm() {
    read -p "$1 [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Remove programming languages
uninstall_languages() {
    log_info "Removing programming languages..."
    
    # Node.js and npm
    if command_exists "node"; then
        apt-get remove -y nodejs npm
        rm -rf ~/.npm ~/.node-gyp
    fi
    
    # Python and pip
    if command_exists "python3"; then
        apt-get remove -y python3 python3-pip
        rm -rf ~/.local/lib/python* ~/.cache/pip
    fi
    
    # Go
    if command_exists "go"; then
        apt-get remove -y golang-go
        rm -rf ~/go
    fi
    
    # Rust
    if command_exists "rustc"; then
        rustup self uninstall -y
    fi
    
    # Java
    if command_exists "java"; then
        apt-get remove -y default-jdk maven gradle
        rm -rf ~/.m2
    fi
}

# Remove databases
uninstall_databases() {
    log_info "Removing databases..."
    
    # PostgreSQL
    if command_exists "psql"; then
        apt-get remove -y postgresql postgresql-contrib
        rm -rf /var/lib/postgresql
    fi
    
    # MySQL
    if command_exists "mysql"; then
        apt-get remove -y mysql-server mysql-client
        rm -rf /var/lib/mysql
    fi
    
    # MongoDB
    if command_exists "mongod"; then
        apt-get remove -y mongodb mongodb-org*
        rm -rf /var/lib/mongodb
    fi
    
    # Redis
    if command_exists "redis-server"; then
        apt-get remove -y redis-server
        rm -rf /var/lib/redis
    fi
}

# Remove container tools
uninstall_containers() {
    log_info "Removing container tools..."
    
    # Docker and related tools
    if command_exists "docker"; then
        docker system prune -af
        apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        rm -rf ~/.docker /var/lib/docker
    fi
    
    # Kubernetes tools
    if command_exists "kubectl"; then
        apt-get remove -y kubectl
        rm -rf ~/.kube
    fi
    
    if command_exists "minikube"; then
        minikube delete --all
        apt-get remove -y minikube
    fi
    
    # Podman and related tools
    if command_exists "podman"; then
        apt-get remove -y podman buildah skopeo
    fi
}

# Remove cloud tools
uninstall_cloud() {
    log_info "Removing cloud tools..."
    
    # AWS CLI
    if command_exists "aws"; then
        rm -rf /usr/local/aws-cli
        rm -f /usr/local/bin/aws
        rm -f /usr/local/bin/aws_completer
        rm -rf ~/.aws
    fi
    
    # Azure CLI
    if command_exists "az"; then
        apt-get remove -y azure-cli
        rm -rf ~/.azure
    fi
    
    # Google Cloud SDK
    if command_exists "gcloud"; then
        apt-get remove -y google-cloud-sdk
        rm -rf ~/.config/gcloud
    fi
    
    # Other cloud tools
    if command_exists "doctl"; then
        rm -f /usr/local/bin/doctl
    fi
    
    if command_exists "terraform"; then
        apt-get remove -y terraform
        rm -rf ~/.terraform.d
    fi
}

# Remove DevOps tools
uninstall_devops() {
    log_info "Removing DevOps tools..."
    
    # Jenkins
    if command_exists "jenkins"; then
        systemctl stop jenkins
        apt-get remove -y jenkins
        rm -rf /var/lib/jenkins
    fi
    
    # Ansible
    if command_exists "ansible"; then
        apt-get remove -y ansible
        rm -rf ~/.ansible
    fi
    
    # GitLab Runner
    if command_exists "gitlab-runner"; then
        gitlab-runner uninstall
        apt-get remove -y gitlab-runner
    fi
    
    # Monitoring tools
    systemctl stop prometheus grafana-server || true
    apt-get remove -y prometheus grafana
    rm -rf /var/lib/prometheus /var/lib/grafana
}

# Remove development editors
uninstall_editors() {
    log_info "Removing development editors..."
    
    # VS Code
    if command_exists "code"; then
        apt-get remove -y code
        rm -rf ~/.vscode ~/.config/Code
    fi
    
    # Neovim
    if command_exists "nvim"; then
        apt-get remove -y neovim
        rm -rf ~/.config/nvim ~/.local/share/nvim
    fi
    
    # Sublime Text
    if command_exists "subl"; then
        apt-get remove -y sublime-text
        rm -rf ~/.config/sublime-text-3
    fi
}

# Remove utility tools
uninstall_utils() {
    log_info "Removing utility tools..."
    
    local utils=(
        "htop"
        "tmux"
        "jq"
        "tree"
        "git-lfs"
        "ripgrep"
        "fzf"
        "shellcheck"
        "moreutils"
        "tig"
        "ncdu"
        "bat"
        "exa"
        "fd-find"
        "httpie"
    )
    
    for util in "${utils[@]}"; do
        apt-get remove -y "$util"
    done
    
    # Remove configurations
    rm -rf ~/.tmux* ~/.fzf*
}

# Clean up system
cleanup_system() {
    log_info "Cleaning up system..."
    
    # Remove all packages that were automatically installed to satisfy dependencies
    apt-get autoremove -y
    
    # Clean apt cache
    apt-get clean
    
    # Remove PDev specific directories and files
    rm -rf /opt/pdev
    rm -rf ~/dev
    
    # Remove added repositories
    rm -f /etc/apt/sources.list.d/*
    
    # Reset bashrc to original state
    if [ -f ~/.bashrc.orig ]; then
        mv ~/.bashrc.orig ~/.bashrc
    fi
}

# Main execution
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root"
    exit 1
fi

echo "WARNING: This will remove all development tools and configurations installed by PDev."
echo "It is recommended to backup your data first using backup-restore.sh"
echo

if ! confirm "Do you want to continue?"; then
    exit 0
fi

# Optional component removal
if confirm "Remove programming languages?"; then
    uninstall_languages
fi

if confirm "Remove databases?"; then
    uninstall_databases
fi

if confirm "Remove container tools?"; then
    uninstall_containers
fi

if confirm "Remove cloud tools?"; then
    uninstall_cloud
fi

if confirm "Remove DevOps tools?"; then
    uninstall_devops
fi

if confirm "Remove development editors?"; then
    uninstall_editors
fi

if confirm "Remove utility tools?"; then
    uninstall_utils
fi

if confirm "Clean up system (removes all PDev related files and configurations)?"; then
    cleanup_system
fi

log_info "Uninstallation completed! Please restart your system for changes to take full effect."