#!/bin/bash

source "$(dirname "$0")/common.sh"

log_info "Running post-installation validation..."

# Function to check if services are running properly
check_services() {
    local services=(
        "docker"
        "postgresql"
        "mysql"
        "mongodb"
        "redis-server"
        "jenkins"
        "elasticsearch"
        "prometheus"
        "grafana-server"
    )
    
    echo "Checking service status:"
    for service in "${services[@]}"; do
        printf "%-20s: " "$service"
        if systemctl is-enabled "$service" &>/dev/null; then
            if systemctl is-active "$service" &>/dev/null; then
                echo -e "${GREEN}✓ (running)${NC}"
            else
                echo -e "${YELLOW}⚠ (installed but not running)${NC}"
            fi
        else
            echo -e "${BLUE}○ (not installed)${NC}"
        fi
    done
}

# Check if all configuration files are in place
check_configs() {
    local config_files=(
        "/opt/pdev/config/preferences.conf"
        "$HOME/.bashrc"
        "$HOME/.gitconfig"
        "$HOME/.tmux.conf"
    )
    
    echo -e "\nChecking configuration files:"
    for config in "${config_files[@]}"; do
        printf "%-30s: " "$config"
        if [ -f "$config" ]; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗ (missing)${NC}"
        fi
    done
}

# Validate development tools installation
validate_dev_tools() {
    local tools=(
        "git" "gcc" "g++" "make" "cmake"
        "python3" "node" "go" "rustc" "java"
        "docker" "kubectl" "terraform" "ansible"
    )
    
    echo -e "\nValidating development tools:"
    for tool in "${tools[@]}"; do
        printf "%-15s: " "$tool"
        if command_exists "$tool"; then
            local version=$($tool --version 2>/dev/null | head -n1)
            echo -e "${GREEN}✓${NC} ($version)"
        else
            echo -e "${RED}✗ (not found)${NC}"
        fi
    done
}

# Check system resources
check_resources() {
    echo -e "\nSystem resources:"
    echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
    echo "Memory Usage: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "Disk Usage: $(df -h / | awk 'NR==2 {print $5 " (" $3 "/" $2 ")"}')"
    
    # Check for potential issues
    local mem_free=$(free | awk '/^Mem:/ {print $4}')
    local disk_free=$(df / | awk 'NR==2 {print $4}')
    
    if [ $mem_free -lt 1048576 ]; then  # Less than 1GB free
        log_warn "Low memory available: $(free -h | awk '/^Mem:/ {print $4}')"
    fi
    
    if [ $disk_free -lt 5242880 ]; then  # Less than 5GB free
        log_warn "Low disk space available: $(df -h / | awk 'NR==2 {print $4}')"
    fi
}

# Check network connectivity to important services
check_connectivity() {
    local services=(
        "github.com"
        "registry.npmjs.org"
        "pypi.org"
        "registry.hub.docker.com"
    )
    
    echo -e "\nChecking network connectivity:"
    for service in "${services[@]}"; do
        printf "%-25s: " "$service"
        if ping -c 1 -W 5 "$service" &>/dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
        fi
    done
}

# Check for common post-installation issues
check_common_issues() {
    echo -e "\nChecking for common issues:"
    
    # Check PATH configuration
    printf "%-30s: " "PATH configuration"
    if echo $PATH | grep -q "/usr/local/bin"; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ (missing /usr/local/bin)${NC}"
    fi
    
    # Check user permissions
    printf "%-30s: " "Docker group membership"
    if groups $USER | grep -q docker; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠ (not in docker group)${NC}"
    fi
    
    # Check SSH key setup
    printf "%-30s: " "SSH key configuration"
    if [ -f "$HOME/.ssh/id_rsa" ] || [ -f "$HOME/.ssh/id_ed25519" ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠ (no SSH key found)${NC}"
    fi
}

# Generate summary report
generate_report() {
    local report_file="/opt/pdev/post_install_report_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "=== PDev Post-Installation Report ==="
        echo "Generated: $(date)"
        echo "System: $(uname -a)"
        echo "Distribution: $(detect_distro)"
        echo
        echo "=== Service Status ==="
        check_services
        echo
        echo "=== Configuration Files ==="
        check_configs
        echo
        echo "=== Development Tools ==="
        validate_dev_tools
        echo
        echo "=== System Resources ==="
        check_resources
        echo
        echo "=== Network Connectivity ==="
        check_connectivity
        echo
        echo "=== Common Issues ==="
        check_common_issues
    } | tee "$report_file"
    
    log_info "Report saved to: $report_file"
}

# Main execution
check_services
check_configs
validate_dev_tools
check_resources
check_connectivity
check_common_issues
generate_report

log_info "Post-installation validation completed!"