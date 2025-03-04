#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Validating backup integrity..."

BACKUP_DIR="/opt/pdev/backups"

# Check backup directory structure
check_backup_structure() {
    local latest_backup=$(ls -t "$BACKUP_DIR"/pdev_backup_*.tar.gz 2>/dev/null | head -n1)
    
    if [ -z "$latest_backup" ]; then
        log_error "No backup files found in $BACKUP_DIR"
        return 1
    fi
    
    # Create temporary directory for validation
    local temp_dir="/tmp/pdev_backup_validate_$(date +%s)"
    ensure_dir "$temp_dir"
    
    # Extract backup
    log_info "Extracting backup for validation: $(basename "$latest_backup")"
    if ! tar -xzf "$latest_backup" -C "$temp_dir"; then
        log_error "Failed to extract backup"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Check required directories
    local required_dirs=("config" "dotfiles" "scripts")
    local missing_dirs=0
    
    echo "Checking backup structure:"
    for dir in "${required_dirs[@]}"; do
        printf "%-20s: " "$dir"
        if [ -d "$temp_dir/$dir" ]; then
            echo -e "${GREEN}Present${NC}"
        else
            echo -e "${RED}Missing${NC}"
            ((missing_dirs++))
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    
    return $missing_dirs
}

# Validate configuration files
validate_configs() {
    echo -e "\nValidating configuration files:"
    local latest_backup=$(ls -t "$BACKUP_DIR"/pdev_backup_*.tar.gz 2>/dev/null | head -n1)
    local temp_dir="/tmp/pdev_backup_validate_$(date +%s)"
    ensure_dir "$temp_dir"
    tar -xzf "$latest_backup" -C "$temp_dir"
    
    local config_files=(
        "preferences.conf"
        "editor_config.json"
        "devenv.conf"
    )
    
    local invalid_configs=0
    
    for config in "${config_files[@]}"; do
        printf "%-20s: " "$config"
        if [ -f "$temp_dir/config/$config" ]; then
            # Try parsing the config file based on extension
            case "$config" in
                *.json)
                    if jq '.' "$temp_dir/config/$config" >/dev/null 2>&1; then
                        echo -e "${GREEN}Valid${NC}"
                    else
                        echo -e "${RED}Invalid format${NC}"
                        ((invalid_configs++))
                    fi
                    ;;
                *.conf)
                    if grep -E '^[A-Za-z0-9_]+=.*$' "$temp_dir/config/$config" >/dev/null 2>&1; then
                        echo -e "${GREEN}Valid${NC}"
                    else
                        echo -e "${RED}Invalid format${NC}"
                        ((invalid_configs++))
                    fi
                    ;;
            esac
        else
            echo -e "${YELLOW}Not present${NC}"
        fi
    done
    
    rm -rf "$temp_dir"
    return $invalid_configs
}

# Check backup size and compression
check_backup_size() {
    echo -e "\nChecking backup metrics:"
    local latest_backup=$(ls -t "$BACKUP_DIR"/pdev_backup_*.tar.gz 2>/dev/null | head -n1)
    
    if [ -f "$latest_backup" ]; then
        local size=$(du -h "$latest_backup" | cut -f1)
        local date=$(date -r "$latest_backup" "+%Y-%m-%d %H:%M:%S")
        
        echo "Latest backup: $(basename "$latest_backup")"
        echo "Size: $size"
        echo "Date: $date"
        
        # Check if backup size is reasonable (between 1KB and 1GB)
        local size_bytes=$(stat -f%z "$latest_backup")
        if [ $size_bytes -lt 1024 ]; then
            log_warn "Backup size seems too small (< 1KB)"
            return 1
        elif [ $size_bytes -gt 1073741824 ]; then
            log_warn "Backup size seems too large (> 1GB)"
            return 1
        fi
    fi
    return 0
}

# Validate backup contents
validate_contents() {
    echo -e "\nValidating backup contents:"
    local latest_backup=$(ls -t "$BACKUP_DIR"/pdev_backup_*.tar.gz 2>/dev/null | head -n1)
    local temp_dir="/tmp/pdev_backup_validate_$(date +%s)"
    
    ensure_dir "$temp_dir"
    tar -xzf "$latest_backup" -C "$temp_dir"
    
    local total_files=0
    local total_dirs=0
    
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            ((total_files++))
        elif [ -d "$file" ]; then
            ((total_dirs++))
        fi
    done < <(find "$temp_dir" -print0)
    
    echo "Total files: $total_files"
    echo "Total directories: $total_dirs"
    
    # Check for sensitive files
    echo -e "\nChecking for sensitive files:"
    local sensitive_found=0
    while IFS= read -r -d '' file; do
        case "$file" in
            *.pem|*.key|*id_rsa|*id_ed25519)
                echo -e "${YELLOW}Warning: Found sensitive file: $(basename "$file")${NC}"
                ((sensitive_found++))
                ;;
        esac
    done < <(find "$temp_dir" -type f -print0)
    
    if [ $sensitive_found -gt 0 ]; then
        log_warn "Found $sensitive_found sensitive file(s) in backup"
    fi
    
    rm -rf "$temp_dir"
    return 0
}

# Run all checks
echo "=== Backup Validation Report ==="
echo "Date: $(date)"
echo "Backup Directory: $BACKUP_DIR"
echo

check_backup_structure
validate_configs
check_backup_size
validate_contents

log_info "Backup validation completed!"