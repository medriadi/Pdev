#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONFIG_FILE="/opt/pdev/config/preferences.conf"

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

# Call load_config at script start
load_config

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        DISTRO=$(uname -s)
    fi
    echo $DISTRO
}

# Log messages with colors
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Run installation script
run_script() {
    local script_path="$(dirname "$0")/$1"
    if [ -f "$script_path" ]; then
        log_info "Running: $1"
        bash "$script_path"
    else
        log_error "Script not found: $1"
        return 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_system_requirements() {
    local min_ram=2048 # 2GB in MB
    local min_disk=10240 # 10GB in MB
    
    # Check RAM
    local total_ram=$(free -m | awk '/^Mem:/ {print $2}')
    if [ $total_ram -lt $min_ram ]; then
        log_warn "System has less than 2GB RAM ($total_ram MB). Some tools may not work properly."
    fi
    
    # Check disk space
    local free_disk=$(df -m / | awk 'NR==2 {print $4}')
    if [ $free_disk -lt $min_disk ]; then
        log_warn "Less than 10GB free disk space available ($free_disk MB). Installation may fail."
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        log_error "No internet connection detected."
        return 1
    fi
}

# Package manager commands based on distribution
get_pkg_manager() {
    local distro=$(detect_distro)
    case $distro in
        "ubuntu"|"debian")
            echo "apt-get"
            ;;
        "fedora")
            echo "dnf"
            ;;
        "centos"|"rhel")
            echo "yum"
            ;;
        "arch")
            echo "pacman"
            ;;
        *)
            log_error "Unsupported distribution: $distro"
            exit 1
            ;;
    esac
}

# Update package manager
update_pkg_manager() {
    local pkg_manager=$(get_pkg_manager)
    log_info "Updating package manager..."
    case $pkg_manager in
        "apt-get")
            apt-get update
            ;;
        "dnf"|"yum")
            $pkg_manager check-update
            ;;
        "pacman")
            pacman -Sy
            ;;
    esac
}

# Install package using the appropriate package manager
install_package() {
    local pkg_manager=$(get_pkg_manager)
    local package=$1
    
    log_info "Installing $package..."
    case $pkg_manager in
        "apt-get")
            DEBIAN_FRONTEND=noninteractive apt-get install -y $package
            ;;
        "dnf"|"yum")
            $pkg_manager install -y $package
            ;;
        "pacman")
            pacman -S --noconfirm $package
            ;;
    esac
}

# Check if a service is running
is_service_running() {
    local service_name=$1
    systemctl is-active --quiet $service_name
    return $?
}

# Add a line to a file if it doesn't exist
add_line_to_file() {
    local line=$1
    local file=$2
    grep -qF -- "$line" "$file" || echo "$line" >> "$file"
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}

# Download file with progress
download_file() {
    local url=$1
    local output=$2
    if command_exists "wget"; then
        wget -O "$output" "$url" 2>&1 | \
        stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }'
    else
        curl -#L "$url" -o "$output"
    fi
}

# Check version of installed package
get_version() {
    local command=$1
    if command_exists "$command"; then
        case $command in
            docker) docker --version | cut -d ' ' -f3 | tr -d ',' ;;
            node) node --version | tr -d 'v' ;;
            python3) python3 --version | cut -d ' ' -f2 ;;
            *) $command --version 2>/dev/null || echo "unknown" ;;
        esac
    else
        echo "not installed"
    fi
}

# Cleanup temporary files and package manager cache
cleanup() {
    local pkg_manager=$(get_pkg_manager)
    case $pkg_manager in
        "apt-get")
            apt-get clean
            apt-get autoremove -y
            ;;
        "dnf"|"yum")
            $pkg_manager clean all
            ;;
        "pacman")
            pacman -Sc --noconfirm
            ;;
    esac
    
    # Remove temporary files
    rm -rf /tmp/pdev_*
}

# New helper functions for configuration
get_config_value() {
    local key=$1
    local default=$2
    
    if [ -f "$CONFIG_FILE" ]; then
        local value=$(grep "^${key}=" "$CONFIG_FILE" | cut -d'=' -f2)
        echo "${value:-$default}"
    else
        echo "$default"
    fi
}

# Function to create swap if needed
setup_swap() {
    if [ "$(get_config_value CREATE_SWAP true)" = "true" ]; then
        local swap_size=$(get_config_value SWAP_SIZE "4G")
        if ! swapon --show | grep -q '/swapfile'; then
            log_info "Creating swap file with size $swap_size"
            fallocate -l "$swap_size" /swapfile
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            echo '/swapfile none swap sw 0 0' >> /etc/fstab
        fi
    fi
}

# Update system if configured
update_system() {
    if [ "$(get_config_value UPDATE_SYSTEM true)" = "true" ]; then
        log_info "Updating system packages..."
        update_pkg_manager
        local pkg_manager=$(get_pkg_manager)
        case $pkg_manager in
            "apt-get")
                apt-get upgrade -y
                ;;
            "dnf"|"yum")
                $pkg_manager upgrade -y
                ;;
            "pacman")
                pacman -Syu --noconfirm
                ;;
        esac
    fi
}

# Install recommended packages if configured
install_recommended() {
    if [ "$(get_config_value INSTALL_RECOMMENDED_PACKAGES true)" = "true" ]; then
        log_info "Installing recommended packages..."
        local pkg_manager=$(get_pkg_manager)
        case $pkg_manager in
            "apt-get")
                apt-get install -y $(apt-cache depends --recurse --no-recommends --no-suggests \
                    --no-conflicts --no-breaks --no-replaces --no-enhances \
                    --no-pre-depends "$@" | grep "^\w")
                ;;
            "dnf"|"yum")
                $pkg_manager install -y --setopt=install_weak_deps=True "$@"
                ;;
            "pacman")
                pacman -S --asdeps --noconfirm "$@"
                ;;
        esac
    fi
}