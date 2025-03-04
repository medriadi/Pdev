#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Validating DevOps tools installations..."

# Test Terraform and HashiCorp tools
test_hashicorp() {
    local tools_ok=true
    
    # Test Terraform
    if command_exists "terraform"; then
        terraform version
        
        # Create a test Terraform config
        cat > test.tf << EOF
terraform {
  required_version = ">= 1.0"
}

output "test" {
  value = "success"
}
EOF
        
        if terraform init && \
           terraform plan && \
           terraform apply -auto-approve | grep -q "success"; then
            log_info "Terraform: OK"
        else
            tools_ok=false
        fi
        
        rm -rf test.tf .terraform* terraform.tfstate*
    else
        log_error "Terraform not found"
        tools_ok=false
    fi
    
    # Test Vault
    if command_exists "vault"; then
        if vault version; then
            log_info "Vault: OK"
        else
            tools_ok=false
        fi
    else
        log_error "Vault not found"
        tools_ok=false
    fi
    
    # Test Consul
    if command_exists "consul"; then
        if consul version; then
            log_info "Consul: OK"
        else
            tools_ok=false
        fi
    else
        log_error "Consul not found"
        tools_ok=false
    fi
    
    return $tools_ok
}

# Test Ansible
test_ansible() {
    if command_exists "ansible"; then
        if ansible --version && \
           ansible localhost -m ping | grep -q "SUCCESS"; then
            log_info "Ansible: OK"
            
            # Test Ansible development tools
            if command_exists "ansible-lint" && command_exists "molecule"; then
                log_info "Ansible development tools: OK"
            fi
            
            return 0
        fi
    fi
    log_error "Ansible validation failed"
    return 1
}

# Test Jenkins
test_jenkins() {
    if systemctl is-active --quiet jenkins; then
        # Test Jenkins CLI if available
        if [ -f "/var/lib/jenkins/secrets/initialAdminPassword" ]; then
            local jenkins_url="http://localhost:8080"
            local admin_password=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
            
            if curl -s -I "$jenkins_url" | grep -q "403\|200"; then
                log_info "Jenkins: OK"
                return 0
            fi
        fi
    fi
    log_error "Jenkins validation failed"
    return 1
}

# Test GitLab Runner
test_gitlab_runner() {
    if command_exists "gitlab-runner"; then
        if gitlab-runner --version && \
           gitlab-runner verify; then
            log_info "GitLab Runner: OK"
            return 0
        fi
    fi
    log_error "GitLab Runner validation failed"
    return 1
}

# Test ArgoCD
test_argocd() {
    if command_exists "argocd"; then
        if argocd version --client && \
           kubectl get namespace argocd &>/dev/null; then
            log_info "ArgoCD: OK"
            return 0
        fi
    fi
    log_error "ArgoCD validation failed"
    return 1
}

# Test monitoring tools
test_monitoring() {
    local monitoring_ok=true
    
    # Test Prometheus
    if systemctl is-active --quiet prometheus; then
        if curl -s http://localhost:9090/-/healthy | grep -q "Prometheus"; then
            log_info "Prometheus: OK"
        else
            monitoring_ok=false
        fi
    else
        log_error "Prometheus not running"
        monitoring_ok=false
    fi
    
    # Test Grafana
    if systemctl is-active --quiet grafana-server; then
        if curl -s http://localhost:3000/api/health | grep -q "ok"; then
            log_info "Grafana: OK"
        else
            monitoring_ok=false
        fi
    else
        log_error "Grafana not running"
        monitoring_ok=false
    fi
    
    # Test Loki if installed
    if command_exists "loki"; then
        log_info "Loki: OK"
    fi
    
    return $monitoring_ok
}

# Test security tools
test_security() {
    local security_ok=true
    
    # Test Python security tools
    if command_exists "bandit"; then
        echo 'print("test")' > test.py
        if bandit test.py &>/dev/null; then
            log_info "Bandit: OK"
        else
            security_ok=false
        fi
        rm test.py
    else
        log_error "Bandit not found"
        security_ok=false
    fi
    
    # Test Snyk if installed
    if command_exists "snyk"; then
        if snyk --version; then
            log_info "Snyk: OK"
        else
            security_ok=false
        fi
    fi
    
    # Test Trivy if Docker is installed
    if command_exists "docker" && command_exists "trivy"; then
        if trivy --version; then
            log_info "Trivy: OK"
        else
            security_ok=false
        fi
    fi
    
    return $security_ok
}

# Test additional CI/CD tools
test_cicd_tools() {
    # Test GitHub CLI
    if command_exists "gh"; then
        if gh --version; then
            log_info "GitHub CLI: OK"
        fi
    fi
    
    # Test Task runner
    if command_exists "task"; then
        if task --version; then
            log_info "Task runner: OK"
        fi
    fi
}

# Run all tests
test_hashicorp
test_ansible
test_jenkins
test_gitlab_runner
test_argocd
test_monitoring
test_security
test_cicd_tools

log_info "DevOps tools validation completed!"