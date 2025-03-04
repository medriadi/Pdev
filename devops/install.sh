#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Installing DevOps Tools..."

# Update package manager
update_pkg_manager

# Install Terraform and HashiCorp tools
install_terraform() {
    if ! command_exists "terraform"; then
        curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
        update_pkg_manager
        install_package "terraform"
        
        # Install additional HashiCorp tools
        install_package "vault"
        install_package "consul"
        install_package "nomad"
        
        # Install Terraform docs if debug tools are enabled
        if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
            curl -Lo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/latest/download/terraform-docs-$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep tag_name | cut -d '"' -f 4)-linux-amd64.tar.gz
            tar -xzf terraform-docs.tar.gz
            chmod +x terraform-docs
            mv terraform-docs /usr/local/bin/
            rm terraform-docs.tar.gz
        fi
    fi
}

# Install Ansible
install_ansible() {
    if ! command_exists "ansible"; then
        install_package "ansible"
        
        # Install Ansible development tools
        if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
            pip3 install ansible-lint molecule docker
        fi
        
        # Configure Ansible
        ensure_dir "/etc/ansible"
        cat > "/etc/ansible/ansible.cfg" << EOF
[defaults]
inventory = /etc/ansible/hosts
remote_tmp = /tmp/.ansible-\${USER}/tmp
local_tmp = /tmp/.ansible-\${USER}/tmp
host_key_checking = False
deprecation_warnings = False
command_warnings = False
interpreter_python = auto_silent
EOF
    fi
}

# Install Jenkins
install_jenkins() {
    if ! command_exists "jenkins"; then
        # Install Java if not already installed
        if ! command_exists "java"; then
            install_package "openjdk-11-jdk"
        fi
        
        curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
        echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list
        update_pkg_manager
        install_package "jenkins"
        
        # Start and enable Jenkins
        systemctl start jenkins
        systemctl enable jenkins
        
        # Wait for Jenkins to start and get initial admin password
        log_info "Waiting for Jenkins to start..."
        sleep 30
        if [ -f "/var/lib/jenkins/secrets/initialAdminPassword" ]; then
            log_info "Jenkins initial admin password: $(cat /var/lib/jenkins/secrets/initialAdminPassword)"
        fi
    fi
}

# Install GitLab Runner
install_gitlab_runner() {
    if ! command_exists "gitlab-runner"; then
        curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash
        install_package "gitlab-runner"
        
        # Configure GitLab Runner to use Docker if available
        if command_exists "docker"; then
            gitlab-runner register \
                --non-interactive \
                --url "https://gitlab.com/" \
                --executor "docker" \
                --docker-image "alpine:latest" \
                --description "Docker Runner" \
                --tag-list "docker"
        fi
    fi
}

# Install ArgoCD
install_argocd() {
    if [ "$(get_config_value INSTALL_KUBERNETES true)" = "true" ]; then
        if command_exists "kubectl"; then
            kubectl create namespace argocd || true
            kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
            
            # Install Argo CD CLI
            curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
            install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
            rm argocd-linux-amd64
        fi
    fi
}

# Install monitoring and observability tools
install_monitoring() {
    if [ "$(get_config_value INSTALL_MONITORING true)" = "true" ]; then
        # Install Prometheus
        if ! command_exists "prometheus"; then
            install_package "prometheus"
            systemctl start prometheus
            systemctl enable prometheus
        fi
        
        # Install Grafana
        if ! command_exists "grafana-server"; then
            curl -fsSL https://packages.grafana.com/gpg.key | gpg --dearmor -o /usr/share/keyrings/grafana-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/grafana-archive-keyring.gpg] https://packages.grafana.com/oss/deb stable main" | tee /etc/apt/sources.list.d/grafana.list
            update_pkg_manager
            install_package "grafana"
            systemctl start grafana-server
            systemctl enable grafana-server
        fi
        
        # Install Loki
        if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
            curl -O -L "https://github.com/grafana/loki/releases/latest/download/loki-linux-amd64.zip"
            unzip "loki-linux-amd64.zip"
            chmod a+x "loki-linux-amd64"
            mv "loki-linux-amd64" "/usr/local/bin/loki"
            rm "loki-linux-amd64.zip"
        fi
    fi
}

# Install security tools
install_security_tools() {
    if [ "$(get_config_value INSTALL_SECURITY_TOOLS true)" = "true" ]; then
        # Install SAST tools
        install_package "bandit"  # Python security linter
        npm install -g snyk       # Vulnerability scanning
        
        # Install container security tools
        if command_exists "docker"; then
            install_package "trivy"  # Container vulnerability scanner
        fi
        
        # Install infrastructure security tools
        pip3 install detect-secrets checkov
    fi
}

# Main installation
install_terraform
install_ansible
install_jenkins
install_gitlab_runner
install_argocd
install_monitoring
install_security_tools

# Install additional CI/CD tools if debug tools are enabled
if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
    # Install GitHub CLI
    if ! command_exists "gh"; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        update_pkg_manager
        install_package "gh"
    fi
    
    # Install task runner
    if ! command_exists "task"; then
        sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
    fi
fi

log_info "DevOps Tools installation completed!"