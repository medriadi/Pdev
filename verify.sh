#!/bin/bash

source "$(dirname "$0")/common.sh"

log_info "Running quick environment health check..."

# Check system load and resources
check_system_health() {
    echo "System Health:"
    echo "-------------"
    
    # CPU Load
    local cpu_load=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1)
    printf "CPU Load: "
    if (( $(echo "$cpu_load > 2.0" | bc -l) )); then
        echo -e "${RED}High ($cpu_load)${NC}"
    else
        echo -e "${GREEN}Normal ($cpu_load)${NC}"
    fi
    
    # Memory Usage
    local mem_free=$(free -m | awk '/^Mem:/ {print $4}')
    local mem_total=$(free -m | awk '/^Mem:/ {print $2}')
    local mem_usage=$((100 - (mem_free * 100 / mem_total)))
    printf "Memory Usage: "
    if [ $mem_usage -gt 90 ]; then
        echo -e "${RED}Critical ($mem_usage%)${NC}"
    elif [ $mem_usage -gt 75 ]; then
        echo -e "${YELLOW}High ($mem_usage%)${NC}"
    else
        echo -e "${GREEN}Normal ($mem_usage%)${NC}"
    fi
    
    # Disk Space
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    printf "Disk Usage: "
    if [ $disk_usage -gt 90 ]; then
        echo -e "${RED}Critical ($disk_usage%)${NC}"
    elif [ $disk_usage -gt 75 ]; then
        echo -e "${YELLOW}High ($disk_usage%)${NC}"
    else
        echo -e "${GREEN}Normal ($disk_usage%)${NC}"
    fi
}

# Check essential services status
check_services_health() {
    echo -e "\nEssential Services:"
    echo "------------------"
    local services=(
        "docker"
        "postgresql"
        "mysql"
        "mongodb"
        "jenkins"
        "prometheus"
        "grafana-server"
    )
    
    for service in "${services[@]}"; do
        printf "%-15s: " "$service"
        if systemctl is-active --quiet $service; then
            echo -e "${GREEN}Running${NC}"
        else
            echo -e "${YELLOW}Not running${NC}"
        fi
    done
}

# Check network connectivity
check_network() {
    echo -e "\nNetwork Connectivity:"
    echo "-------------------"
    local targets=(
        "github.com"
        "registry.npmjs.org"
        "pypi.org"
        "registry.hub.docker.com"
        "docs.docker.com"
    )
    
    for target in "${targets[@]}"; do
        printf "%-25s: " "$target"
        if ping -c 1 -W 2 $target >/dev/null 2>&1; then
            echo -e "${GREEN}Reachable${NC}"
        else
            echo -e "${RED}Unreachable${NC}"
        fi
    done
}

# Check development tools availability
check_dev_tools() {
    echo -e "\nDevelopment Tools:"
    echo "-----------------"
    local tools=(
        "git"
        "docker"
        "python3"
        "node"
        "java"
        "go"
    )
    
    for tool in "${tools[@]}"; do
        printf "%-10s: " "$tool"
        if command_exists "$tool"; then
            local version=$($tool --version 2>/dev/null | head -n1)
            echo -e "${GREEN}Available${NC} ($version)"
        else
            echo -e "${RED}Not found${NC}"
        fi
    done
}

# Check environment variables
check_env_vars() {
    echo -e "\nEnvironment Variables:"
    echo "--------------------"
    local vars=(
        "JAVA_HOME"
        "GOPATH"
        "NODE_PATH"
        "PATH"
        "EDITOR"
    )
    
    for var in "${vars[@]}"; do
        printf "%-12s: " "$var"
        if [ -n "${!var}" ]; then
            echo -e "${GREEN}Set${NC}"
        else
            echo -e "${YELLOW}Not set${NC}"
        fi
    done
}

# Check common development directories
check_directories() {
    echo -e "\nDevelopment Directories:"
    echo "----------------------"
    local dirs=(
        "$HOME/dev"
        "$HOME/dev/projects"
        "$HOME/dev/tools"
        "$HOME/.config"
        "$HOME/.local/share"
    )
    
    for dir in "${dirs[@]}"; do
        printf "%-25s: " "$(basename $dir)"
        if [ -d "$dir" ]; then
            echo -e "${GREEN}Exists${NC}"
        else
            echo -e "${YELLOW}Missing${NC}"
        fi
    done
}

# Main execution
print_header() {
    echo "======================================="
    echo "  PDev Environment Quick Health Check"
    echo "======================================="
    echo
    echo "Timestamp: $(date)"
    echo "User: $USER"
    echo "Host: $(hostname)"
    echo
}

print_header
check_system_health
check_services_health
check_network
check_dev_tools
check_env_vars
check_directories

echo -e "\nHealth check completed. For detailed validation, run run-tests.sh with sudo."