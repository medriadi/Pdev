#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Installing Programming Languages..."

# Update package manager
update_pkg_manager

# Install Node.js and npm using nvm
install_nodejs() {
    if ! command_exists "node"; then
        local version=$(get_config_value "NODEJS_VERSION" "lts")
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        if [ "$version" = "lts" ]; then
            nvm install --lts
            nvm use --lts
        else
            nvm install "$version"
            nvm use "$version"
        fi
        nvm alias default $(nvm current)
    fi
}

# Install Python and pip
install_python() {
    local version=$(get_config_value "PYTHON_VERSION" "3")
    install_package "python${version}"
    install_package "python${version}-pip"
    install_package "python${version}-venv"
    
    # Install development tools if configured
    if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
        pip3 install ipython debugpy pylint black
    fi
}

# Install Java
install_java() {
    local version=$(get_config_value "JAVA_VERSION" "17")
    case $version in
        "8")
            install_package "openjdk-8-jdk"
            ;;
        "11")
            install_package "openjdk-11-jdk"
            ;;
        "17")
            install_package "openjdk-17-jdk"
            ;;
        "21")
            install_package "openjdk-21-jdk"
            ;;
        *)
            log_error "Unsupported Java version: $version"
            return 1
            ;;
    esac
    
    # Install build tools
    install_package "maven"
    install_package "gradle"
}

# Install Go
install_go() {
    if ! command_exists "go"; then
        local version=$(get_config_value "GO_VERSION" "1.21.0")
        curl -LO "https://go.dev/dl/go${version}.linux-amd64.tar.gz"
        rm -rf /usr/local/go
        tar -C /usr/local -xzf "go${version}.linux-amd64.tar.gz"
        rm "go${version}.linux-amd64.tar.gz"
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        
        # Install common Go tools if debug tools are enabled
        if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
            export PATH=$PATH:/usr/local/go/bin
            go install golang.org/x/tools/gopls@latest
            go install github.com/go-delve/delve/cmd/dlv@latest
        fi
    fi
}

# Install Rust
install_rust() {
    if ! command_exists "rustc"; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        
        # Install common Rust tools if debug tools are enabled
        if [ "$(get_config_value INSTALL_DEBUG_TOOLS true)" = "true" ]; then
            rustup component add rustfmt
            rustup component add clippy
            rustup component add rust-analyzer
        fi
    fi
}

# Install all languages
install_nodejs
install_python
install_java
install_go
install_rust

# Install recommended packages if configured
if [ "$(get_config_value INSTALL_RECOMMENDED_PACKAGES true)" = "true" ]; then
    install_package "build-essential"
    install_package "pkg-config"
    install_package "libssl-dev"
    install_package "zlib1g-dev"
fi

log_info "Programming Languages installation completed!"