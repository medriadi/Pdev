#!/bin/bash

# Source common utilities
source "$(dirname "$0")/common.sh"

# Initialize log file
LOG_FILE="/var/log/pdev-setup.log"
touch "$LOG_FILE"

# Progress tracking
TOTAL_STEPS=0
CURRENT_STEP=0

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run with sudo"
    exit 1
fi

# Display system information
show_system_info() {
    log_info "System Information:"
    echo "OS: $(uname -s)"
    echo "Distribution: $(detect_distro)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "CPU Cores: $(nproc)"
    echo "Total RAM: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Free Disk Space: $(df -h / | awk 'NR==2 {print $4}')"
    echo
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    local deps=("curl" "wget" "gpg" "tar" "gzip")
    
    log_info "Checking dependencies..."
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_warn "Missing dependencies: ${missing_deps[*]}"
        read -p "Would you like to install missing dependencies? [Y/n] " install_deps
        if [[ $install_deps =~ ^[Yy]$ ]] || [ -z "$install_deps" ]; then
            for dep in "${missing_deps[@]}"; do
                install_package "$dep"
            done
        else
            log_error "Required dependencies missing. Installation may fail."
            exit 1
        fi
    fi
}

print_header() {
    echo "======================================"
    echo "  Professional Development Environment Setup"
    echo "======================================"
    echo
}

# Display progress bar
show_progress() {
    local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local completed=$((percent / 2))
    local remaining=$((50 - completed))
    
    printf "\rProgress: ["
    printf "%${completed}s" | tr ' ' '='
    printf "%${remaining}s" | tr ' ' ' '
    printf "] %d%%" "$percent"
}

# Display menu and get user selection
show_menu() {
    print_header
    echo "Please select which categories to install:"
    echo
    echo "1) All categories (complete setup)"
    echo "2) Core Development Tools (git, compilers, build tools)"
    echo "3) Programming Languages (Node.js, Python, Java, Go, Rust)"
    echo "4) Databases (MongoDB, PostgreSQL, MySQL, Redis)"
    echo "5) Container Tools (Docker, Kubernetes tools, Podman)"
    echo "6) Cloud Development (AWS CLI, Azure CLI, Google Cloud SDK)"
    echo "7) Utility Tools (curl, wget, jq, htop, tmux, etc.)"
    echo "8) Code Editors (VSCode, Neovim, Sublime Text)"
    echo "9) DevOps Tools (Terraform, Ansible, CI tools)"
    echo "0) Exit"
    echo
    read -p "Enter your choices (space-separated numbers): " choices
}

# Count total steps based on selections
calculate_total_steps() {
    local choices=($1)
    TOTAL_STEPS=0
    
    for choice in "${choices[@]}"; do
        case $choice in
            1) TOTAL_STEPS=$((TOTAL_STEPS + 8)) ;;
            *) TOTAL_STEPS=$((TOTAL_STEPS + 1)) ;;
        esac
    done
}

# Handle errors
handle_error() {
    local exit_code=$1
    local error_msg=$2
    
    if [ $exit_code -ne 0 ]; then
        log_error "$error_msg" | tee -a "$LOG_FILE"
        echo "Check $LOG_FILE for detailed error information."
        exit $exit_code
    fi
}

# Run installation script with progress tracking
run_with_progress() {
    local script=$1
    
    echo "Running: $script" >> "$LOG_FILE"
    if bash "$script" 2>> "$LOG_FILE"; then
        CURRENT_STEP=$((CURRENT_STEP + 1))
        show_progress
    else
        handle_error $? "Failed to execute $script"
    fi
}

# Install selected categories
install_categories() {
    local choices=($1)
    calculate_total_steps "$1"
    CURRENT_STEP=0
    
    echo "Starting installation at $(date)" >> "$LOG_FILE"
    echo "Selected categories: $1" >> "$LOG_FILE"
    
    for choice in "${choices[@]}"; do
        case $choice in
            1)
                # Install all categories
                run_with_progress "$(dirname "$0")/core/install.sh"
                run_with_progress "$(dirname "$0")/languages/install.sh"
                run_with_progress "$(dirname "$0")/databases/install.sh"
                run_with_progress "$(dirname "$0")/containers/install.sh"
                run_with_progress "$(dirname "$0")/cloud/install.sh"
                run_with_progress "$(dirname "$0")/utils/install.sh"
                run_with_progress "$(dirname "$0")/editors/install.sh"
                run_with_progress "$(dirname "$0")/devops/install.sh"
                ;;
            2) run_with_progress "$(dirname "$0")/core/install.sh" ;;
            3) run_with_progress "$(dirname "$0")/languages/install.sh" ;;
            4) run_with_progress "$(dirname "$0")/databases/install.sh" ;;
            5) run_with_progress "$(dirname "$0")/containers/install.sh" ;;
            6) run_with_progress "$(dirname "$0")/cloud/install.sh" ;;
            7) run_with_progress "$(dirname "$0")/utils/install.sh" ;;
            8) run_with_progress "$(dirname "$0")/editors/install.sh" ;;
            9) run_with_progress "$(dirname "$0")/devops/install.sh" ;;
            0) exit 0 ;;
            *) log_error "Invalid option: $choice" ;;
        esac
    done
    
    echo -e "\nInstallation completed at $(date)" >> "$LOG_FILE"
    echo -e "\nInstallation completed successfully!"
}

# Create backup of important config files
backup_configs() {
    BACKUP_DIR="/root/pdev_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # List of important config files to backup
    CONFIG_FILES=(
        "/etc/apt/sources.list"
        "/etc/environment"
        "$HOME/.bashrc"
        "$HOME/.profile"
    )
    
    for file in "${CONFIG_FILES[@]}"; do
        if [ -f "$file" ]; then
            cp "$file" "$BACKUP_DIR/"
        fi
    done
    
    log_info "Configuration files backed up to $BACKUP_DIR"
}

# Main execution
show_system_info
check_dependencies
backup_configs
show_menu
install_categories "$choices"