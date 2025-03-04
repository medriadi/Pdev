#!/bin/bash

# Source common utilities
source "$(dirname "$0")/common.sh"

CONFIG_FILE="/opt/pdev/config/preferences.conf"
ensure_dir "$(dirname "$CONFIG_FILE")"

print_header() {
    echo "======================================"
    echo "  Development Environment Configuration"
    echo "======================================"
    echo
}

# Initialize default configuration
init_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << EOF
# PDev Configuration File

# Installation Preferences
INSTALL_RECOMMENDED=true
CREATE_BACKUPS=true
INSTALL_BETA_VERSIONS=false

# Programming Languages
NODEJS_VERSION=lts
PYTHON_VERSION=3
GO_VERSION=1.21.0
JAVA_VERSION=17

# Database Preferences
DEFAULT_DB=postgresql
INSTALL_GUI_TOOLS=true

# Editor Preferences
DEFAULT_EDITOR=vscode
INSTALL_VSCODE_EXTENSIONS=true
NEOVIM_CONFIG=basic

# Container Preferences
CONTAINER_RUNTIME=docker
INSTALL_KUBERNETES=true

# Cloud Preferences
DEFAULT_CLOUD=aws
INSTALL_MULTIPLE_CLOUDS=true

# Development Tools
INSTALL_DEBUG_TOOLS=true
INSTALL_MONITORING=true
INSTALL_SECURITY_TOOLS=true

# System Preferences
CREATE_SWAP=true
SWAP_SIZE=4G
UPDATE_SYSTEM=true
INSTALL_RECOMMENDED_PACKAGES=true
EOF
    fi
}

# Show current configuration
show_config() {
    print_header
    echo "Current configuration:"
    echo
    if [ -f "$CONFIG_FILE" ]; then
        grep -v '^#' "$CONFIG_FILE" | grep -v '^$'
    else
        log_error "No configuration file found"
        init_config
        show_config
    fi
}

# Edit configuration
edit_config() {
    if command_exists "nano"; then
        nano "$CONFIG_FILE"
    elif command_exists "vim"; then
        vim "$CONFIG_FILE"
    else
        log_error "No text editor found. Please install nano or vim."
        exit 1
    fi
}

# Get configuration value
get_config() {
    local key=$1
    local default=$2
    
    if [ -f "$CONFIG_FILE" ]; then
        local value=$(grep "^${key}=" "$CONFIG_FILE" | cut -d'=' -f2)
        echo "${value:-$default}"
    else
        echo "$default"
    fi
}

# Set configuration value
set_config() {
    local key=$1
    local value=$2
    
    if [ -f "$CONFIG_FILE" ]; then
        if grep -q "^${key}=" "$CONFIG_FILE"; then
            sed -i "s|^${key}=.*|${key}=${value}|" "$CONFIG_FILE"
        else
            echo "${key}=${value}" >> "$CONFIG_FILE"
        fi
    else
        init_config
        set_config "$key" "$value"
    fi
}

# Validate configuration
validate_config() {
    local errors=0
    
    # Validate Node.js version
    local node_ver=$(get_config "NODEJS_VERSION" "lts")
    if [[ ! "$node_ver" =~ ^(lts|[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
        log_error "Invalid Node.js version: $node_ver"
        ((errors++))
    fi
    
    # Validate Java version
    local java_ver=$(get_config "JAVA_VERSION" "17")
    if [[ ! "$java_ver" =~ ^(8|11|17|21)$ ]]; then
        log_error "Invalid Java version: $java_ver (supported: 8, 11, 17, 21)"
        ((errors++))
    fi
    
    # Validate swap size
    local swap_size=$(get_config "SWAP_SIZE" "4G")
    if [[ ! "$swap_size" =~ ^[0-9]+[GgMm]$ ]]; then
        log_error "Invalid swap size: $swap_size (format: number followed by G or M)"
        ((errors++))
    fi
    
    return $errors
}

# Reset configuration to defaults
reset_config() {
    if [ -f "$CONFIG_FILE" ]; then
        local backup="${CONFIG_FILE}.bak"
        cp "$CONFIG_FILE" "$backup"
        log_info "Existing configuration backed up to $backup"
    fi
    
    rm -f "$CONFIG_FILE"
    init_config
    log_info "Configuration reset to defaults"
}

# Main execution
case "$1" in
    "show")
        show_config
        ;;
    "edit")
        edit_config
        ;;
    "get")
        if [ -z "$2" ]; then
            echo "Usage: $0 get <key> [default_value]"
            exit 1
        fi
        get_config "$2" "$3"
        ;;
    "set")
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 set <key> <value>"
            exit 1
        fi
        set_config "$2" "$3"
        ;;
    "validate")
        validate_config
        ;;
    "reset")
        read -p "Are you sure you want to reset the configuration? [y/N] " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            reset_config
        fi
        ;;
    *)
        echo "Usage: $0 {show|edit|get|set|validate|reset}"
        echo "  show     - Display current configuration"
        echo "  edit     - Edit configuration in text editor"
        echo "  get      - Get value of a configuration key"
        echo "  set      - Set value of a configuration key"
        echo "  validate - Validate current configuration"
        echo "  reset    - Reset configuration to defaults"
        exit 1
        ;;
esac