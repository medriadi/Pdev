#!/bin/bash

source "$(dirname "$0")/common.sh"

BACKUP_DIR="/opt/pdev/backups"
CONFIG_DIR="/opt/pdev/config"
SCRIPTS_DIR="$(dirname "$0")"

backup_environment() {
    log_info "Starting environment backup..."
    
    # Create backup directory with timestamp
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/pdev_backup_$timestamp"
    ensure_dir "$backup_path"
    
    # Backup configuration files
    log_info "Backing up configuration files..."
    ensure_dir "$backup_path/config"
    cp -r "$CONFIG_DIR"/* "$backup_path/config/" 2>/dev/null || true
    
    # Backup important dotfiles
    log_info "Backing up dotfiles..."
    ensure_dir "$backup_path/dotfiles"
    for dotfile in ".bashrc" ".profile" ".gitconfig" ".tmux.conf" ".vimrc" ".config/nvim"; do
        if [ -e "$HOME/$dotfile" ]; then
            cp -r "$HOME/$dotfile" "$backup_path/dotfiles/"
        fi
    done
    
    # Backup SSH configuration
    if [ -d "$HOME/.ssh" ]; then
        log_info "Backing up SSH configuration..."
        ensure_dir "$backup_path/ssh"
        cp -r "$HOME/.ssh/config" "$backup_path/ssh/" 2>/dev/null || true
        cp -r "$HOME/.ssh/known_hosts" "$backup_path/ssh/" 2>/dev/null || true
    fi
    
    # Backup custom scripts
    if [ -d "$HOME/dev/scripts" ]; then
        log_info "Backing up custom scripts..."
        ensure_dir "$backup_path/scripts"
        cp -r "$HOME/dev/scripts"/* "$backup_path/scripts/" 2>/dev/null || true
    fi
    
    # Backup database dumps if configured
    if [ "$(get_config_value BACKUP_DATABASES true)" = "true" ]; then
        log_info "Backing up databases..."
        ensure_dir "$backup_path/databases"
        
        # PostgreSQL
        if command_exists "pg_dumpall" && systemctl is-active --quiet postgresql; then
            sudo -u postgres pg_dumpall > "$backup_path/databases/postgresql_dump.sql" 2>/dev/null || true
        fi
        
        # MySQL
        if command_exists "mysqldump" && systemctl is-active --quiet mysql; then
            mysqldump --all-databases > "$backup_path/databases/mysql_dump.sql" 2>/dev/null || true
        fi
        
        # MongoDB
        if command_exists "mongodump" && systemctl is-active --quiet mongod; then
            mongodump --out "$backup_path/databases/mongodb" 2>/dev/null || true
        fi
    fi
    
    # Backup container data if configured
    if [ "$(get_config_value BACKUP_CONTAINERS true)" = "true" ] && command_exists "docker"; then
        log_info "Backing up container data..."
        ensure_dir "$backup_path/containers"
        
        # Save docker compose files
        if [ -d "$HOME/docker-compose" ]; then
            cp -r "$HOME/docker-compose" "$backup_path/containers/"
        fi
        
        # Export running container configuration
        docker ps -a --format "{{.Names}}" > "$backup_path/containers/container_list.txt"
        while read container; do
            docker inspect "$container" > "$backup_path/containers/${container}_config.json"
        done < "$backup_path/containers/container_list.txt"
    fi
    
    # Create archive
    log_info "Creating backup archive..."
    local archive_name="pdev_backup_${timestamp}.tar.gz"
    tar -czf "$BACKUP_DIR/$archive_name" -C "$backup_path" .
    rm -rf "$backup_path"
    
    log_info "Backup completed: $BACKUP_DIR/$archive_name"
    return 0
}

restore_environment() {
    local backup_file="$1"
    if [ -z "$backup_file" ]; then
        # If no backup file specified, use the most recent one
        backup_file=$(ls -t "$BACKUP_DIR"/pdev_backup_*.tar.gz 2>/dev/null | head -n1)
        if [ -z "$backup_file" ]; then
            log_error "No backup files found in $BACKUP_DIR"
            return 1
        fi
    elif [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    log_info "Starting environment restore from: $backup_file"
    
    # Create temporary directory for restoration
    local temp_dir="/tmp/pdev_restore_$(date +%s)"
    ensure_dir "$temp_dir"
    
    # Extract backup
    tar -xzf "$backup_file" -C "$temp_dir"
    
    # Restore configuration files
    if [ -d "$temp_dir/config" ]; then
        log_info "Restoring configuration files..."
        ensure_dir "$CONFIG_DIR"
        cp -r "$temp_dir/config"/* "$CONFIG_DIR/"
    fi
    
    # Restore dotfiles
    if [ -d "$temp_dir/dotfiles" ]; then
        log_info "Restoring dotfiles..."
        for dotfile in "$temp_dir/dotfiles"/*; do
            if [ -e "$dotfile" ]; then
                cp -r "$dotfile" "$HOME/$(basename "$dotfile")"
            fi
        done
    fi
    
    # Restore SSH configuration
    if [ -d "$temp_dir/ssh" ]; then
        log_info "Restoring SSH configuration..."
        ensure_dir "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        cp -r "$temp_dir/ssh"/* "$HOME/.ssh/"
        chmod 600 "$HOME/.ssh"/*
    fi
    
    # Restore custom scripts
    if [ -d "$temp_dir/scripts" ]; then
        log_info "Restoring custom scripts..."
        ensure_dir "$HOME/dev/scripts"
        cp -r "$temp_dir/scripts"/* "$HOME/dev/scripts/"
        chmod +x "$HOME/dev/scripts"/*
    fi
    
    # Restore databases if present
    if [ -d "$temp_dir/databases" ]; then
        log_info "Restoring databases..."
        
        # PostgreSQL
        if [ -f "$temp_dir/databases/postgresql_dump.sql" ] && systemctl is-active --quiet postgresql; then
            sudo -u postgres psql < "$temp_dir/databases/postgresql_dump.sql"
        fi
        
        # MySQL
        if [ -f "$temp_dir/databases/mysql_dump.sql" ] && systemctl is-active --quiet mysql; then
            mysql < "$temp_dir/databases/mysql_dump.sql"
        fi
        
        # MongoDB
        if [ -d "$temp_dir/databases/mongodb" ] && systemctl is-active --quiet mongod; then
            mongorestore "$temp_dir/databases/mongodb"
        fi
    fi
    
    # Restore container configurations if present
    if [ -d "$temp_dir/containers" ] && command_exists "docker"; then
        log_info "Restoring container configurations..."
        
        # Restore docker compose files
        if [ -d "$temp_dir/containers/docker-compose" ]; then
            ensure_dir "$HOME/docker-compose"
            cp -r "$temp_dir/containers/docker-compose"/* "$HOME/docker-compose/"
        fi
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    log_info "Environment restore completed!"
    log_warn "Please log out and log back in for all changes to take effect."
    return 0
}

# Show usage information
usage() {
    echo "Usage: $0 [backup|restore] [backup_file]"
    echo
    echo "Commands:"
    echo "  backup              Create a new backup of the environment"
    echo "  restore [file]      Restore environment from a backup file"
    echo "                      If no file is specified, uses the most recent backup"
    echo
    echo "Example:"
    echo "  $0 backup"
    echo "  $0 restore /opt/pdev/backups/pdev_backup_20230815_123456.tar.gz"
}

# Main execution
case "$1" in
    backup)
        backup_environment
        ;;
    restore)
        restore_environment "$2"
        ;;
    *)
        usage
        exit 1
        ;;
esac